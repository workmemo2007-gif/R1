-- Bootstrap the configured owner account after Supabase Auth phone verification.
-- The function can only promote the currently authenticated user whose profile phone matches.

create or replace function public.bootstrap_representative()
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.profiles;
begin
  update public.profiles p
  set role = 'representative',
      status = 'active',
      approval_note = 'تمت التهيئة تلقائياً للحساب الممثل الأعلى.',
      approved_by = auth.uid(),
      approved_at = coalesce(p.approved_at, now()),
      last_seen_at = now(),
      updated_at = now()
  where p.id = auth.uid()
    and regexp_replace(p.phone, '[^0-9]', '', 'g') = '07723681360';

  select p into result from public.profiles p where p.id = auth.uid();
  return result;
end;
$$;

grant execute on function public.bootstrap_representative() to authenticated;
