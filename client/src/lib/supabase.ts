import { createClient, type SupabaseClient } from "@supabase/supabase-js";

export type SupabasePublicConfig = {
  url: string;
  anonKey: string;
};

let clientPromise: Promise<SupabaseClient> | null = null;

async function loadPublicConfig(): Promise<SupabasePublicConfig> {
  const envUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined;
  const envKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
  if (envUrl && envKey) return { url: envUrl, anonKey: envKey };

  const response = await fetch("/api/supabase/config", { credentials: "same-origin" });
  if (!response.ok) throw new Error("لم يتم إعداد اتصال Supabase العام بعد.");
  const config = (await response.json()) as Partial<SupabasePublicConfig>;
  if (!config.url || !config.anonKey) throw new Error("إعدادات Supabase العامة غير مكتملة.");
  return { url: config.url, anonKey: config.anonKey };
}

export function getSupabaseClient(): Promise<SupabaseClient> {
  if (!clientPromise) {
    clientPromise = loadPublicConfig().then(({ url, anonKey }) =>
      createClient(url, anonKey, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
        },
      })
    );
  }
  return clientPromise;
}

export function normalizePhone(phone: string): string {
  const digits = phone.replace(/[^0-9]/g, "");
  if (digits.startsWith("00964")) return `+${digits.slice(2)}`;
  if (digits.startsWith("964")) return `+${digits}`;
  if (digits.startsWith("0")) return `+964${digits.slice(1)}`;
  return `+${digits}`;
}

export function displayPhone(phone: string | null | undefined): string {
  if (!phone) return "";
  return phone.replace(/^\+964/, "0");
}
