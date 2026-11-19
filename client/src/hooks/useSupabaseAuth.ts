import { useCallback, useEffect, useState } from "react";
import type { Session, User } from "@supabase/supabase-js";
import { getSupabaseClient, normalizePhone } from "@/lib/supabase";

export type Profile = {
  id: string;
  full_name: string;
  phone: string;
  avatar_url: string | null;
  university_card_path: string | null;
  role: "student" | "supervisor" | "representative";
  status: "pending" | "active" | "rejected" | "suspended";
  approval_note: string | null;
  last_seen_at: string | null;
  created_at: string;
};

type AuthState = {
  session: Session | null;
  user: User | null;
  profile: Profile | null;
  loading: boolean;
  error: string | null;
};

function toArabicError(message: string): string {
  if (message.includes("Invalid login credentials")) return "رقم الهاتف أو كلمة المرور غير صحيحة.";
  if (message.includes("User already registered")) return "يوجد حساب مسجل بهذا الرقم بالفعل.";
  if (message.includes("Phone provider is not enabled")) return "تسجيل الدخول برقم الهاتف غير مفعّل في Supabase بعد.";
  if (message.includes("Password should be at least")) return "يجب أن تكون كلمة المرور أطول وأكثر أماناً.";
  return message;
}

export function useSupabaseAuth() {
  const [state, setState] = useState<AuthState>({ session: null, user: null, profile: null, loading: true, error: null });

  const loadProfile = useCallback(async (user: User | null) => {
    if (!user) {
      setState((current) => ({ ...current, profile: null, loading: false }));
      return;
    }
    const supabase = await getSupabaseClient();
    await supabase.rpc("bootstrap_representative");
    const { data, error } = await supabase.from("profiles").select("*").eq("id", user.id).maybeSingle();
    if (error) throw error;
    setState((current) => ({ ...current, user, profile: (data as Profile | null) ?? null, loading: false, error: null }));
  }, []);

  useEffect(() => {
    let mounted = true;
    let unsubscribe: () => void = () => undefined;
    getSupabaseClient()
      .then(async (supabase) => {
        if (!mounted) return;
        const { data } = await supabase.auth.getSession();
        if (data.session) {
          setState((current) => ({ ...current, session: data.session, user: data.session.user }));
          await loadProfile(data.session.user);
        } else {
          setState((current) => ({ ...current, loading: false }));
        }
        const subscription = supabase.auth.onAuthStateChange((_event, session) => {
          setState((current) => ({ ...current, session, user: session?.user ?? null, loading: true, error: null }));
          void loadProfile(session?.user ?? null);
        });
        unsubscribe = () => subscription.data.subscription.unsubscribe();
      })
      .catch((error: Error) => {
        if (mounted) setState((current) => ({ ...current, loading: false, error: toArabicError(error.message) }));
      });
    return () => {
      mounted = false;
      unsubscribe();
    };
  }, [loadProfile]);

  const signIn = useCallback(async (phone: string, password: string) => {
    setState((current) => ({ ...current, loading: true, error: null }));
    try {
      const supabase = await getSupabaseClient();
      const result = await supabase.auth.signInWithPassword({ phone: normalizePhone(phone), password });
      if (result.error) throw result.error;
      await loadProfile(result.data.user);
      return { ok: true, needsVerification: false };
    } catch (error) {
      const message = toArabicError(error instanceof Error ? error.message : "تعذر تسجيل الدخول.");
      setState((current) => ({ ...current, loading: false, error: message }));
      return { ok: false, needsVerification: false, error: message };
    }
  }, [loadProfile]);

  const signUp = useCallback(async (input: { fullName: string; phone: string; password: string; avatarFile?: File | null; cardFile?: File | null }) => {
    setState((current) => ({ ...current, loading: true, error: null }));
    try {
      const supabase = await getSupabaseClient();
      const phone = normalizePhone(input.phone);
      const result = await supabase.auth.signUp({
        phone,
        password: input.password,
        options: { data: { full_name: input.fullName, phone } },
      });
      if (result.error) throw result.error;
      if (!result.data.session) {
        setState((current) => ({ ...current, loading: false }));
        return { ok: true, needsVerification: true };
      }
      if (result.data.user) {
        const updates: Record<string, string> = { full_name: input.fullName };
        if (input.avatarFile) {
          const path = `${result.data.user.id}/${crypto.randomUUID()}-${input.avatarFile.name}`;
          const upload = await supabase.storage.from("avatars").upload(path, input.avatarFile, { upsert: true });
          if (upload.error) throw upload.error;
          updates.avatar_url = supabase.storage.from("avatars").getPublicUrl(path).data.publicUrl;
        }
        if (input.cardFile) {
          const path = `${result.data.user.id}/${crypto.randomUUID()}-${input.cardFile.name}`;
          const upload = await supabase.storage.from("university-cards").upload(path, input.cardFile, { upsert: true });
          if (upload.error) throw upload.error;
          updates.university_card_path = path;
        }
        await supabase.from("profiles").update(updates).eq("id", result.data.user.id);
      }
      await loadProfile(result.data.user);
      return { ok: true, needsVerification: false };
    } catch (error) {
      const message = toArabicError(error instanceof Error ? error.message : "تعذر إنشاء الحساب.");
      setState((current) => ({ ...current, loading: false, error: message }));
      return { ok: false, needsVerification: false, error: message };
    }
  }, [loadProfile]);

  const signOut = useCallback(async () => {
    const supabase = await getSupabaseClient();
    await supabase.auth.signOut();
    setState({ session: null, user: null, profile: null, loading: false, error: null });
  }, []);

  return { ...state, signIn, signUp, signOut };
}
