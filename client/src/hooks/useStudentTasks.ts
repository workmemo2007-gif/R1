import { useCallback, useEffect, useState } from "react";
import { getSupabaseClient } from "@/lib/supabase";

export type StudentTask = {
  id: string;
  title: string;
  due_date: string;
  is_completed: boolean;
  completed_at: string | null;
};

export function useStudentTasks(userId: string) {
  const [tasks, setTasks] = useState<StudentTask[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    const supabase = await getSupabaseClient();
    const { data, error: queryError } = await supabase
      .from("student_tasks")
      .select("id,title,due_date,is_completed,completed_at")
      .eq("user_id", userId)
      .eq("is_completed", false)
      .order("due_date", { ascending: true })
      .order("created_at", { ascending: true });
    if (queryError) throw queryError;
    setTasks((data ?? []) as StudentTask[]);
  }, [userId]);

  useEffect(() => {
    let mounted = true;
    setLoading(true);
    refresh()
      .catch((queryError: Error) => { if (mounted) setError(queryError.message); })
      .finally(() => { if (mounted) setLoading(false); });
    return () => { mounted = false; };
  }, [refresh]);

  const addTask = useCallback(async (title: string) => {
    const cleanTitle = title.trim();
    if (!cleanTitle) return;
    const supabase = await getSupabaseClient();
    const { data, error: insertError } = await supabase
      .from("student_tasks")
      .insert({ user_id: userId, title: cleanTitle, due_date: new Date().toISOString().slice(0, 10) })
      .select("id,title,due_date,is_completed,completed_at")
      .single();
    if (insertError) throw insertError;
    setTasks((current) => [...current, data as StudentTask]);
  }, [userId]);

  const completeTask = useCallback(async (id: string) => {
    const supabase = await getSupabaseClient();
    const { error: updateError } = await supabase
      .from("student_tasks")
      .update({ is_completed: true, completed_at: new Date().toISOString() })
      .eq("id", id)
      .eq("user_id", userId);
    if (updateError) throw updateError;
    setTasks((current) => current.filter((task) => task.id !== id));
  }, [userId]);

  return { tasks, loading, error, addTask, completeTask, refresh };
}
