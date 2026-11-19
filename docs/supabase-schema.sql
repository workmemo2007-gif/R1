-- تطبيق ممثلي | Supabase schema draft
-- الحالة: مسودة قابلة للمراجعة. لم يتم تشغيل هذا الملف.
-- يعتمد على Supabase Auth: كلمات المرور لا تُخزّن في public.profiles.
-- قبل التنفيذ: راجع الأدوار، سياسات RLS، واسم bucket في Supabase Storage.

create extension if not exists pgcrypto;

-- ---------- Enums ----------

do $$ begin
  create type public.app_role as enum ('student', 'supervisor', 'representative');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.account_status as enum ('pending', 'active', 'rejected', 'suspended');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.study_file_status as enum ('pending', 'pending_representative', 'published', 'rejected', 'hidden');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.schedule_kind as enum ('lecture', 'exam', 'other');
exception when duplicate_object then null; end $$;

-- ---------- Profiles ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text not null,
  avatar_url text,
  university_card_path text,
  university_card_original_name text,
  university_card_mime_type text,
  university_card_size_bytes bigint,
  role public.app_role not null default 'student',
  status public.account_status not null default 'pending',
  approval_note text,
  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_full_name_length check (char_length(full_name) between 2 and 120),
  constraint profiles_phone_length check (char_length(phone) between 7 and 30)
);

create unique index if not exists profiles_phone_unique_idx on public.profiles(phone);
create index if not exists profiles_status_idx on public.profiles(status);

-- ---------- Configurable permissions ----------
-- The phone number is a bootstrap identifier only; the account must also be
-- authenticated and verified by Supabase Auth before this privilege is used.
create table if not exists public.permission_catalog (
  key text primary key,
  label text not null,
  description text,
  is_active boolean not null default true
);

create table if not exists public.user_permissions (
  user_id uuid not null references public.profiles(id) on delete cascade,
  permission_key text not null references public.permission_catalog(key) on delete cascade,
  enabled boolean not null default true,
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  primary key (user_id, permission_key)
);

create index if not exists user_permissions_user_idx on public.user_permissions(user_id);

-- ---------- Helpers ----------
create or replace function public.current_profile()
returns public.profiles
language sql stable security definer set search_path = public
as $$
  select p from public.profiles p where p.id = auth.uid();
$$;

create or replace function public.has_role(required_role public.app_role)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = required_role and status = 'active'
  );
$$;

create or replace function public.is_active_user()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and status = 'active'
  );
$$;

create or replace function public.is_reviewer()
returns boolean
language sql stable security definer set search_path = public
as $$
  select public.has_role('representative') or public.has_role('supervisor');
$$;

create or replace function public.is_super_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    join auth.users au on au.id = p.id
    where p.id = auth.uid()
      and p.role = 'representative'
      and p.status = 'active'
      and regexp_replace(p.phone, '[^0-9]', '', 'g') = '07723681360'
      and au.phone_confirmed_at is not null
  );
$$;

create or replace function public.has_permission(permission_key_input text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select public.is_super_admin()
    or exists (
      select 1 from public.profiles p
      join public.user_permissions up on up.user_id = p.id
      where p.id = auth.uid()
        and p.status = 'active'
        and up.permission_key = permission_key_input
        and up.enabled = true
    );
$$;

-- The configured phone number becomes the top representative after authentication.
create or replace function public.bootstrap_representative()
returns public.profiles
language plpgsql security definer set search_path = public
as $$
declare result public.profiles;
begin
  update public.profiles p
  set role = 'representative', status = 'active',
      approval_note = 'تمت التهيئة تلقائياً للحساب الممثل الأعلى.',
      approved_by = auth.uid(), approved_at = coalesce(p.approved_at, now()),
      last_seen_at = now(), updated_at = now()
  where p.id = auth.uid()
    and regexp_replace(p.phone, '[^0-9]', '', 'g') = '07723681360';
  select p into result from public.profiles p where p.id = auth.uid();
  return result;
end;
$$;
grant execute on function public.bootstrap_representative() to authenticated;

create or replace function public.can_approve_accounts()
returns boolean language sql stable security definer set search_path = public
as $$ select public.has_permission('approve_accounts'); $$;

create or replace function public.can_approve_student_files()
returns boolean language sql stable security definer set search_path = public
as $$ select public.has_permission('approve_student_files'); $$;

create or replace function public.can_approve_supervisor_files()
returns boolean language sql stable security definer set search_path = public
as $$ select public.has_permission('approve_supervisor_files'); $$;

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.prevent_self_privilege_escalation()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_super_admin() and (new.role <> old.role or new.status <> old.status) then
    raise exception 'Only the super admin can change role or account status';
  end if;
  return new;
end;
$$;

-- ---------- Library taxonomy ----------
create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  section_name text,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists subjects_name_section_unique_idx
  on public.subjects(lower(name), coalesce(section_name, ''));

create table if not exists public.file_types (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- Study files ----------
create table if not exists public.study_files (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  file_type_id uuid not null references public.file_types(id) on delete restrict,
  storage_path text not null,
  original_file_name text not null,
  mime_type text,
  file_size_bytes bigint,
  uploaded_by uuid not null references public.profiles(id) on delete restrict,
  status public.study_file_status not null default 'pending',
  rejection_reason text,
  published_at timestamptz,
  published_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint study_files_title_length check (char_length(title) between 1 and 200),
  constraint study_files_size_positive check (file_size_bytes is null or file_size_bytes > 0)
);
create index if not exists study_files_subject_type_idx on public.study_files(subject_id, file_type_id);
create index if not exists study_files_status_idx on public.study_files(status);
create index if not exists study_files_uploader_idx on public.study_files(uploaded_by);

create table if not exists public.file_reviews (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references public.study_files(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete restrict,
  decision text not null check (decision in ('approved', 'rejected', 'hidden', 'requested_changes')),
  note text,
  created_at timestamptz not null default now()
);
create index if not exists file_reviews_file_idx on public.file_reviews(file_id, created_at desc);

-- ---------- Announcements ----------
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  is_pinned boolean not null default false,
  is_published boolean not null default true,
  created_by uuid not null references public.profiles(id) on delete restrict,
  published_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists announcements_published_idx on public.announcements(is_published, is_pinned, published_at desc);

create table if not exists public.announcement_likes (
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (announcement_id, user_id)
);

-- ---------- Schedule ----------
create table if not exists public.schedule_items (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references public.subjects(id) on delete set null,
  title text not null,
  kind public.schedule_kind not null default 'lecture',
  starts_at timestamptz not null,
  ends_at timestamptz,
  room text,
  notes text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint schedule_time_order check (ends_at is null or ends_at >= starts_at)
);
create index if not exists schedule_items_starts_at_idx on public.schedule_items(starts_at);

-- ---------- Public chat ----------
create table if not exists public.public_chat_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete restrict,
  body text not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references public.profiles(id) on delete set null,
  constraint public_chat_body_length check (char_length(body) between 1 and 4000)
);
create index if not exists public_chat_created_at_idx on public.public_chat_messages(created_at desc);

-- Run this function every hour using Supabase Cron or an Edge Function.
create or replace function public.delete_expired_public_chat_messages()
returns integer language plpgsql security definer set search_path = public
as $$
declare deleted_count integer;
begin
  delete from public.public_chat_messages
  where created_at < now() - interval '24 hours';
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

-- ---------- Private messaging ----------
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  last_read_at timestamptz,
  delete_messages_after_24h boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.private_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete restrict,
  body text,
  study_file_id uuid references public.study_files(id) on delete set null,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  constraint private_message_body_length check (body is null or char_length(body) between 0 and 4000)
);
create index if not exists private_messages_conversation_idx on public.private_messages(conversation_id, created_at);

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
  created_at timestamptz not null default now()
);

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
  updated_at timestamptz not null default now()
);

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
  updated_at timestamptz not null default now()
);

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
  updated_at timestamptz not null default now()
);

-- ---------- Notifications and Web Push ----------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  kind text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists notifications_user_unread_idx on public.notifications(user_id, read_at, created_at desc);

create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  user_agent text,
  last_used_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists push_subscriptions_user_idx on public.push_subscriptions(user_id);

-- ---------- Administrative audit ----------
create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists audit_logs_created_at_idx on public.audit_logs(created_at desc);
create index if not exists audit_logs_actor_idx on public.audit_logs(actor_id);

-- ---------- Updated-at triggers ----------
drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists profiles_protect_privileges on public.profiles;
create trigger profiles_protect_privileges before update on public.profiles for each row execute function public.prevent_self_privilege_escalation();
drop trigger if exists subjects_updated_at on public.subjects;
create trigger subjects_updated_at before update on public.subjects for each row execute function public.set_updated_at();
drop trigger if exists file_types_updated_at on public.file_types;
create trigger file_types_updated_at before update on public.file_types for each row execute function public.set_updated_at();
drop trigger if exists study_files_updated_at on public.study_files;
create trigger study_files_updated_at before update on public.study_files for each row execute function public.set_updated_at();
drop trigger if exists announcements_updated_at on public.announcements;
create trigger announcements_updated_at before update on public.announcements for each row execute function public.set_updated_at();
drop trigger if exists schedule_items_updated_at on public.schedule_items;
create trigger schedule_items_updated_at before update on public.schedule_items for each row execute function public.set_updated_at();
drop trigger if exists conversations_updated_at on public.conversations;
create trigger conversations_updated_at before update on public.conversations for each row execute function public.set_updated_at();

-- ---------- Row Level Security ----------
alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.file_types enable row level security;
alter table public.study_files enable row level security;
alter table public.file_reviews enable row level security;
alter table public.announcements enable row level security;
alter table public.announcement_likes enable row level security;
alter table public.schedule_items enable row level security;
alter table public.public_chat_messages enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.private_messages enable row level security;
alter table public.live_broadcasts enable row level security;
alter table public.live_broadcast_viewers enable row level security;
alter table public.student_tasks enable row level security;
alter table public.notifications enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.audit_logs enable row level security;
alter table public.permission_catalog enable row level security;
alter table public.user_permissions enable row level security;

-- Profiles: active users can see basic profiles; users edit only their own basic data.
drop policy if exists profiles_select_active on public.profiles;
create policy profiles_select_active on public.profiles for select using (
  public.is_active_user() and (status = 'active' or id = auth.uid() or public.has_role('representative') or public.has_permission('approve_accounts') or public.has_permission('manage_accounts'))
);
drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles for insert with check (id = auth.uid() and role = 'student' and status = 'pending');
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists profiles_manage_representative on public.profiles;
create policy profiles_manage_representative on public.profiles for all using (public.has_permission('manage_accounts')) with check (public.has_permission('manage_accounts'));

-- Only the super admin (the verified bootstrap account) can define user permissions.
drop policy if exists permission_catalog_select_active on public.permission_catalog;
create policy permission_catalog_select_active on public.permission_catalog for select using (public.is_active_user());
drop policy if exists permission_catalog_manage_super_admin on public.permission_catalog;
create policy permission_catalog_manage_super_admin on public.permission_catalog for all using (public.is_super_admin()) with check (public.is_super_admin());
drop policy if exists user_permissions_select_super_admin on public.user_permissions;
create policy user_permissions_select_super_admin on public.user_permissions for select using (public.is_super_admin() or user_id = auth.uid());
drop policy if exists user_permissions_manage_super_admin on public.user_permissions;
create policy user_permissions_manage_super_admin on public.user_permissions for all using (public.is_super_admin()) with check (public.is_super_admin());

-- Taxonomy: active users read; representative manages.
drop policy if exists subjects_select_active on public.subjects;
create policy subjects_select_active on public.subjects for select using (public.is_active_user() and is_active);
drop policy if exists subjects_manage_representative on public.subjects;
create policy subjects_manage_representative on public.subjects for all using (public.has_permission('manage_subjects')) with check (public.has_permission('manage_subjects'));
drop policy if exists file_types_select_active on public.file_types;
create policy file_types_select_active on public.file_types for select using (public.is_active_user() and is_active);
drop policy if exists file_types_manage_representative on public.file_types;
create policy file_types_manage_representative on public.file_types for all using (public.has_permission('manage_file_types')) with check (public.has_permission('manage_file_types'));

-- Files: active users see published; uploader sees own; reviewers see pending.
drop policy if exists study_files_select on public.study_files;
create policy study_files_select on public.study_files for select using (
  public.is_active_user() and (status = 'published' or uploaded_by = auth.uid() or public.is_reviewer())
);
drop policy if exists study_files_insert on public.study_files;
create policy study_files_insert on public.study_files for insert with check (
  public.is_active_user() and uploaded_by = auth.uid()
  and ((public.has_permission('upload_files') and public.has_role('representative') and status = 'published') or
       (public.has_permission('upload_files') and public.has_role('supervisor') and status = 'pending_representative') or
       (public.has_permission('upload_files') and public.has_role('student') and status = 'pending'))
);
drop policy if exists study_files_update_reviewer on public.study_files;
create policy study_files_update_reviewer on public.study_files for update using (
  public.has_permission('approve_student_files') or public.has_permission('approve_supervisor_files') or public.has_permission('manage_content') or uploaded_by = auth.uid()
) with check (
  public.has_permission('approve_student_files') or public.has_permission('approve_supervisor_files') or public.has_permission('manage_content') or (uploaded_by = auth.uid() and status in ('pending', 'pending_representative'))
);
drop policy if exists study_files_delete_representative on public.study_files;
create policy study_files_delete_representative on public.study_files for delete using (public.has_permission('manage_content'));

-- File review records: reviewers only.
drop policy if exists file_reviews_reviewer_only on public.file_reviews;
create policy file_reviews_reviewer_only on public.file_reviews for all using (public.has_permission('approve_student_files') or public.has_permission('approve_supervisor_files')) with check (public.has_permission('approve_student_files') or public.has_permission('approve_supervisor_files'));

-- Announcements and likes.
drop policy if exists announcements_select_active on public.announcements;
create policy announcements_select_active on public.announcements for select using (public.is_active_user() and is_published);
drop policy if exists announcements_manage_representative on public.announcements;
create policy announcements_manage_representative on public.announcements for all using (public.has_permission('manage_announcements')) with check (public.has_permission('manage_announcements'));
drop policy if exists likes_select_active on public.announcement_likes;
create policy likes_select_active on public.announcement_likes for select using (public.is_active_user());
drop policy if exists likes_insert_self on public.announcement_likes;
create policy likes_insert_self on public.announcement_likes for insert with check (public.is_active_user() and public.has_permission('like_announcements') and user_id = auth.uid());
drop policy if exists likes_delete_self on public.announcement_likes;
create policy likes_delete_self on public.announcement_likes for delete using (user_id = auth.uid());

-- Schedule: active users read; representative manages.
drop policy if exists schedule_select_active on public.schedule_items;
create policy schedule_select_active on public.schedule_items for select using (public.is_active_user());
drop policy if exists schedule_manage_representative on public.schedule_items;
create policy schedule_manage_representative on public.schedule_items for all using (public.has_permission('manage_schedule')) with check (public.has_permission('manage_schedule'));

-- Public chat: active users read/write; representative deletes for everyone.
drop policy if exists public_chat_select_active on public.public_chat_messages;
create policy public_chat_select_active on public.public_chat_messages for select using (public.is_active_user());
drop policy if exists public_chat_insert_self on public.public_chat_messages;
create policy public_chat_insert_self on public.public_chat_messages for insert with check (public.is_active_user() and public.has_permission('public_chat') and sender_id = auth.uid());
drop policy if exists public_chat_delete_representative on public.public_chat_messages;
create policy public_chat_delete_representative on public.public_chat_messages for delete using (public.has_permission('delete_public_messages'));

-- Private conversations: membership controls access.
drop policy if exists conversation_members_select_self on public.conversation_members;
create policy conversation_members_select_self on public.conversation_members for select using (user_id = auth.uid() or public.has_role('representative'));
drop policy if exists conversation_members_insert_self on public.conversation_members;
create policy conversation_members_insert_self on public.conversation_members for insert with check (user_id = auth.uid() or public.has_role('representative'));
drop policy if exists conversations_select_member on public.conversations;
create policy conversations_select_member on public.conversations for select using (
  exists (select 1 from public.conversation_members cm where cm.conversation_id = id and cm.user_id = auth.uid())
);
drop policy if exists conversations_insert_active on public.conversations;
create policy conversations_insert_active on public.conversations for insert with check (public.is_active_user());
drop policy if exists private_messages_select_member on public.private_messages;
create policy private_messages_select_member on public.private_messages for select using (
  exists (select 1 from public.conversation_members cm where cm.conversation_id = private_messages.conversation_id and cm.user_id = auth.uid())
);
drop policy if exists private_messages_insert_member on public.private_messages;
create policy private_messages_insert_member on public.private_messages for insert with check (
  public.is_active_user() and public.has_permission('private_messages') and sender_id = auth.uid() and exists (
    select 1 from public.conversation_members cm where cm.conversation_id = private_messages.conversation_id and cm.user_id = auth.uid()
  ) and (study_file_id is null or exists (
    select 1 from public.study_files sf where sf.id = private_messages.study_file_id and sf.status = 'published'
  ))
);

-- Group live broadcast: representatives, and supervisors explicitly granted the permission.
create or replace function public.can_start_group_broadcast()
returns boolean language sql stable security definer set search_path = public
as $$ select public.has_role('representative') or (public.has_role('supervisor') and public.has_permission('group_broadcast')); $$;
drop policy if exists live_broadcasts_select_active on public.live_broadcasts;
create policy live_broadcasts_select_active on public.live_broadcasts for select using (public.is_active_user() and (status = 'live' or started_by = auth.uid() or public.can_start_group_broadcast()));
drop policy if exists live_broadcasts_insert_allowed on public.live_broadcasts;
create policy live_broadcasts_insert_allowed on public.live_broadcasts for insert with check (public.is_active_user() and public.can_start_group_broadcast() and started_by = auth.uid());
drop policy if exists live_broadcasts_update_owner on public.live_broadcasts;
create policy live_broadcasts_update_owner on public.live_broadcasts for update using (public.can_start_group_broadcast() and started_by = auth.uid()) with check (public.can_start_group_broadcast() and started_by = auth.uid());
drop policy if exists live_broadcasts_delete_owner on public.live_broadcasts;
create policy live_broadcasts_delete_owner on public.live_broadcasts for delete using (public.can_start_group_broadcast() and started_by = auth.uid());
drop policy if exists live_broadcast_viewers_select_member on public.live_broadcast_viewers;
create policy live_broadcast_viewers_select_member on public.live_broadcast_viewers for select using (user_id = auth.uid() or public.can_start_group_broadcast());
drop policy if exists live_broadcast_viewers_insert_self on public.live_broadcast_viewers;
create policy live_broadcast_viewers_insert_self on public.live_broadcast_viewers for insert with check (public.is_active_user() and user_id = auth.uid());
drop policy if exists student_tasks_select_self on public.student_tasks;
create policy student_tasks_select_self on public.student_tasks for select using (user_id = auth.uid());
drop policy if exists student_tasks_insert_self on public.student_tasks;
create policy student_tasks_insert_self on public.student_tasks for insert with check (public.is_active_user() and user_id = auth.uid());
drop policy if exists student_tasks_update_self on public.student_tasks;
create policy student_tasks_update_self on public.student_tasks for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists student_tasks_delete_self on public.student_tasks;
create policy student_tasks_delete_self on public.student_tasks for delete using (user_id = auth.uid());

-- Notifications: recipient only. Push subscriptions: owner only.
drop policy if exists notifications_select_self on public.notifications;
create policy notifications_select_self on public.notifications for select using (user_id = auth.uid());
drop policy if exists notifications_update_self on public.notifications;
create policy notifications_update_self on public.notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists push_select_self on public.push_subscriptions;
create policy push_select_self on public.push_subscriptions for select using (user_id = auth.uid());
drop policy if exists push_insert_self on public.push_subscriptions;
create policy push_insert_self on public.push_subscriptions for insert with check (user_id = auth.uid());
drop policy if exists push_update_self on public.push_subscriptions;
create policy push_update_self on public.push_subscriptions for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists push_delete_self on public.push_subscriptions;
create policy push_delete_self on public.push_subscriptions for delete using (user_id = auth.uid());

-- Audit log: representative reads; inserts should be performed by trusted server functions.
drop policy if exists audit_select_representative on public.audit_logs;
create policy audit_select_representative on public.audit_logs for select using (public.has_permission('view_audit_logs'));

-- ---------- Permission catalog seed ----------
insert into public.permission_catalog (key, label, description)
values
  ('approve_accounts', 'اعتماد الحسابات', 'الموافقة على الحسابات الجديدة'),
  ('approve_student_files', 'اعتماد ملفات الطلاب', 'اعتماد ملفات الطلاب ونشرها'),
  ('approve_supervisor_files', 'اعتماد ملفات المشرفين', 'اعتماد ملفات المشرفين ونشرها'),
  ('upload_files', 'رفع الملفات', 'رفع الملفات الدراسية'),
  ('public_chat', 'الدردشة العامة', 'قراءة وإرسال رسائل الدردشة العامة'),
  ('private_messages', 'الرسائل الخاصة', 'إرسال الرسائل الخاصة'),
  ('group_broadcast', 'البث الجماعي المباشر', 'بدء وإدارة بث مباشر جماعي للشعبة'),
  ('like_announcements', 'الإعجاب بالتبليغات', 'الإعجاب بالتبليغات'),
  ('manage_accounts', 'إدارة الحسابات', 'تعديل وإيقاف الحسابات'),
  ('manage_subjects', 'إدارة المواد', 'إضافة وتعديل المواد'),
  ('manage_file_types', 'إدارة أنواع الملفات', 'إضافة وتعديل أنواع الملفات'),
  ('manage_content', 'إدارة المحتوى', 'تعديل وحذف المحتوى'),
  ('manage_announcements', 'إدارة التبليغات', 'إضافة وتعديل وحذف التبليغات'),
  ('manage_schedule', 'إدارة الجدول', 'إضافة وتعديل وحذف الجدول'),
  ('delete_public_messages', 'حذف رسائل العامة', 'حذف الرسائل لدى الجميع'),
  ('suspend_accounts', 'إيقاف الحسابات', 'إيقاف وإعادة تفعيل الحسابات'),
  ('view_audit_logs', 'سجل العمليات', 'عرض سجل العمليات الإدارية')
on conflict (key) do update set label = excluded.label, description = excluded.description;

-- ---------- Seed default file types ----------
insert into public.file_types (name, slug)
values ('ملخص', 'summary'), ('ملزمة', 'handout'), ('محاضرة', 'lecture')
on conflict (slug) do nothing;

-- ---------- Storage notes ----------
-- Create these buckets from Supabase Dashboard or a reviewed Storage migration:
--   avatars     (recommended: public read, authenticated owner write)
--   study-files (recommended: private; access through signed URLs after RLS checks)
-- Storage object policies are intentionally not included here because their exact rules
-- depend on the chosen bucket visibility and upload path convention.

-- ---------- Manual follow-up ----------
-- 1) Create a Supabase Auth trigger that creates a pending profile after sign-up.
-- 2) Configure Supabase Cron/Edge Function to call:
--      select public.delete_expired_public_chat_messages();
--    at least once per hour.
-- 3) Use an Edge Function or server to send Web Push notifications using push_subscriptions.
-- 4) Review all policies in a staging project before production execution.
