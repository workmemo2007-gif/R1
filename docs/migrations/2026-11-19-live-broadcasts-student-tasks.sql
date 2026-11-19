-- Momathili migration: permission-gated live broadcasts + private student tasks

create table if not exists public.live_broadcasts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  room_code text not null unique,
  started_by uuid not null references public.profiles(id) on delete restrict,
  status text not null default 'live' check (status in ('scheduled', 'live', 'ended')),
  scheduled_at timestamptz,
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint live_broadcasts_title_length check (char_length(title) between 1 and 160)
);
create index if not exists live_broadcasts_status_idx on public.live_broadcasts(status, scheduled_at desc);
create index if not exists live_broadcasts_started_by_idx on public.live_broadcasts(started_by, created_at desc);

create table if not exists public.live_broadcast_viewers (
  broadcast_id uuid not null references public.live_broadcasts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (broadcast_id, user_id)
);

create table if not exists public.student_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  due_date date not null default current_date,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_tasks_title_length check (char_length(title) between 1 and 200)
);
create index if not exists student_tasks_user_date_idx on public.student_tasks(user_id, due_date, is_completed, created_at);

create or replace function public.can_start_group_broadcast()
returns boolean
language sql stable security definer set search_path = public
as $$
  select public.has_role('representative')
    or (public.has_role('supervisor') and public.has_permission('group_broadcast'));
$$;

grant execute on function public.can_start_group_broadcast() to authenticated;

alter table public.live_broadcasts enable row level security;
alter table public.live_broadcast_viewers enable row level security;
alter table public.student_tasks enable row level security;

drop policy if exists live_broadcasts_select_active on public.live_broadcasts;
create policy live_broadcasts_select_active on public.live_broadcasts
for select using (public.is_active_user() and (status = 'live' or started_by = auth.uid() or public.can_start_group_broadcast()));
drop policy if exists live_broadcasts_insert_allowed on public.live_broadcasts;
create policy live_broadcasts_insert_allowed on public.live_broadcasts
for insert with check (public.is_active_user() and public.can_start_group_broadcast() and started_by = auth.uid());
drop policy if exists live_broadcasts_update_owner on public.live_broadcasts;
create policy live_broadcasts_update_owner on public.live_broadcasts
for update using (public.can_start_group_broadcast() and started_by = auth.uid())
with check (public.can_start_group_broadcast() and started_by = auth.uid());
drop policy if exists live_broadcasts_delete_owner on public.live_broadcasts;
create policy live_broadcasts_delete_owner on public.live_broadcasts
for delete using (public.can_start_group_broadcast() and started_by = auth.uid());

drop policy if exists live_broadcast_viewers_select_member on public.live_broadcast_viewers;
create policy live_broadcast_viewers_select_member on public.live_broadcast_viewers
for select using (user_id = auth.uid() or public.can_start_group_broadcast());
drop policy if exists live_broadcast_viewers_insert_self on public.live_broadcast_viewers;
create policy live_broadcast_viewers_insert_self on public.live_broadcast_viewers
for insert with check (public.is_active_user() and user_id = auth.uid() and exists (select 1 from public.live_broadcasts b where b.id = broadcast_id and b.status = 'live'));
drop policy if exists live_broadcast_viewers_update_self on public.live_broadcast_viewers;
create policy live_broadcast_viewers_update_self on public.live_broadcast_viewers
for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists student_tasks_select_self on public.student_tasks;
create policy student_tasks_select_self on public.student_tasks for select using (user_id = auth.uid());
drop policy if exists student_tasks_insert_self on public.student_tasks;
create policy student_tasks_insert_self on public.student_tasks for insert with check (public.is_active_user() and user_id = auth.uid());
drop policy if exists student_tasks_update_self on public.student_tasks;
create policy student_tasks_update_self on public.student_tasks for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists student_tasks_delete_self on public.student_tasks;
create policy student_tasks_delete_self on public.student_tasks for delete using (user_id = auth.uid());

insert into public.permission_catalog (key, label, description)
values ('group_broadcast', 'البث الجماعي المباشر', 'بدء وإدارة بث مباشر جماعي للشعبة')
on conflict (key) do update set label = excluded.label, description = excluded.description;

-- Add new records to Supabase Realtime when it is available.
do $realtime$
declare table_name text;
begin
  foreach table_name in array array['live_broadcasts', 'live_broadcast_viewers', 'student_tasks'] loop
    if not exists (
      select 1 from pg_publication_rel pr
      join pg_class c on c.oid = pr.prrelid
      join pg_namespace n on n.oid = c.relnamespace
      join pg_publication p on p.oid = pr.prpubid
      where p.pubname = 'supabase_realtime' and n.nspname = 'public' and c.relname = table_name
    ) then
      begin
        execute format('alter publication supabase_realtime add table public.%I', table_name);
      exception when undefined_object then null;
      end;
    end if;
  end loop;
end;
$realtime$;
