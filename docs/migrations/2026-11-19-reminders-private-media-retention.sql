-- Momathili migration: student reminders + private chat media + per-conversation retention

-- Each member controls the retention preference for conversations they belong to.
alter table public.conversation_members
  add column if not exists delete_messages_after_24h boolean not null default false;

-- A message may contain text, a library file, or one/more uploaded media attachments.
alter table public.private_messages
  alter column body drop not null;

alter table public.private_messages drop constraint if exists private_message_body_length;
alter table public.private_messages add constraint private_message_body_length
  check (body is null or char_length(body) between 0 and 4000);

create table if not exists public.private_message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.private_messages(id) on delete cascade,
  uploaded_by uuid not null references public.profiles(id) on delete restrict,
  attachment_kind text not null check (attachment_kind in ('image', 'video', 'audio')),
  storage_path text not null,
  original_file_name text,
  mime_type text,
  file_size_bytes bigint,
  duration_seconds numeric(8,2),
  created_at timestamptz not null default now(),
  constraint private_attachment_size_positive check (file_size_bytes is null or file_size_bytes > 0),
  constraint private_attachment_duration_positive check (duration_seconds is null or duration_seconds > 0)
);
create index if not exists private_message_attachments_message_idx
  on public.private_message_attachments(message_id, created_at);

create table if not exists public.student_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  notes text,
  remind_at timestamptz not null,
  timezone text not null default 'Asia/Baghdad',
  recurrence text not null default 'none' check (recurrence in ('none', 'daily', 'weekly')),
  sound_name text not null default 'classic-bell',
  is_enabled boolean not null default true,
  last_triggered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_reminders_title_length check (char_length(title) between 1 and 160)
);
create index if not exists student_reminders_due_idx
  on public.student_reminders(is_enabled, remind_at);
create index if not exists student_reminders_user_idx
  on public.student_reminders(user_id, remind_at);

create or replace function public.delete_expired_private_messages()
returns integer
language plpgsql
security definer set search_path = public
as $$
declare deleted_count integer;
begin
  delete from public.private_messages pm
  where pm.created_at < now() - interval '24 hours'
    and exists (
      select 1
      from public.conversation_members cm
      where cm.conversation_id = pm.conversation_id
      group by cm.conversation_id
      having bool_and(cm.delete_messages_after_24h)
    );
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

alter table public.conversation_members enable row level security;
alter table public.private_message_attachments enable row level security;
alter table public.student_reminders enable row level security;

drop policy if exists conversation_members_update_self_retention on public.conversation_members;
create policy conversation_members_update_self_retention on public.conversation_members
for update using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists private_message_attachments_select_member on public.private_message_attachments;
create policy private_message_attachments_select_member on public.private_message_attachments
for select using (
  exists (
    select 1 from public.private_messages pm
    join public.conversation_members cm on cm.conversation_id = pm.conversation_id
    where pm.id = private_message_attachments.message_id and cm.user_id = auth.uid()
  )
);

drop policy if exists private_message_attachments_insert_member on public.private_message_attachments;
create policy private_message_attachments_insert_member on public.private_message_attachments
for insert with check (
  public.is_active_user()
  and uploaded_by = auth.uid()
  and exists (
    select 1 from public.private_messages pm
    join public.conversation_members cm on cm.conversation_id = pm.conversation_id
    where pm.id = private_message_attachments.message_id and cm.user_id = auth.uid()
  )
);

drop policy if exists student_reminders_select_self on public.student_reminders;
create policy student_reminders_select_self on public.student_reminders for select using (user_id = auth.uid());
drop policy if exists student_reminders_insert_self on public.student_reminders;
create policy student_reminders_insert_self on public.student_reminders for insert with check (public.is_active_user() and user_id = auth.uid());
drop policy if exists student_reminders_update_self on public.student_reminders;
create policy student_reminders_update_self on public.student_reminders for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists student_reminders_delete_self on public.student_reminders;
create policy student_reminders_delete_self on public.student_reminders for delete using (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('private-message-media', 'private-message-media', false)
on conflict (id) do nothing;

drop policy if exists private_message_media_insert_own on storage.objects;
create policy private_message_media_insert_own on storage.objects
for insert to authenticated with check (
  bucket_id = 'private-message-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists private_message_media_select_member on storage.objects;
create policy private_message_media_select_member on storage.objects
for select to authenticated using (
  bucket_id = 'private-message-media'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1
      from public.private_message_attachments a
      join public.private_messages pm on pm.id = a.message_id
      join public.conversation_members cm on cm.conversation_id = pm.conversation_id
      where a.storage_path = name and cm.user_id = auth.uid()
    )
  )
);

-- Run cleanup periodically when pg_cron is available in the Supabase project.
do $setup$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron')
     and not exists (select 1 from cron.job where jobname = 'momathili-delete-private-messages') then
    perform cron.schedule('momathili-delete-private-messages', '*/10 * * * *', $job$select public.delete_expired_private_messages();$job$);
  end if;
exception when undefined_table or undefined_function then
  null;
end;
$setup$;

do $realtime$
declare table_name text;
begin
  foreach table_name in array array['private_message_attachments', 'student_reminders'] loop
    if not exists (
      select 1
      from pg_publication_rel pr
      join pg_class c on c.oid = pr.prrelid
      join pg_namespace n on n.oid = c.relnamespace
      join pg_publication p on p.oid = pr.prpubid
      where p.pubname = 'supabase_realtime'
        and n.nspname = 'public'
        and c.relname = table_name
    ) then
      begin
        execute format('alter publication supabase_realtime add table public.%I', table_name);
      exception when undefined_object then null;
      end;
    end if;
  end loop;
end;
$realtime$;
