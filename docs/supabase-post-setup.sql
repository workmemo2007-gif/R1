-- تطبيق ممثلي | Supabase post-setup
-- يُنفذ بعد docs/supabase-schema.sql.
-- هذا الملف ينشئ Storage buckets، trigger للحسابات، دوال الاعتماد، وRealtime.

-- ---------- Account creation ----------
-- Supabase Auth remains the source of truth for phone/password credentials.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  phone_value text;
  name_value text;
begin
  phone_value := coalesce(new.phone, new.raw_user_meta_data ->> 'phone', '');
  name_value := coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), 'طالب جديد');

  if char_length(phone_value) < 7 then
    raise exception 'A valid phone number is required to create an application profile';
  end if;

  insert into public.profiles (
    id, full_name, phone, avatar_url,
    university_card_path, university_card_original_name,
    university_card_mime_type, university_card_size_bytes,
    role, status
  )
  values (
    new.id,
    name_value,
    phone_value,
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'university_card_path',
    new.raw_user_meta_data ->> 'university_card_original_name',
    new.raw_user_meta_data ->> 'university_card_mime_type',
    nullif(new.raw_user_meta_data ->> 'university_card_size_bytes', '')::bigint,
    'student',
    'pending'
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    phone = excluded.phone,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------- Approval helpers ----------
create or replace function public.approve_account(
  target_user_id uuid,
  target_status public.account_status,
  note text default null
)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.can_approve_accounts() then
    raise exception 'You do not have permission to approve accounts';
  end if;

  if target_status not in ('active', 'rejected', 'pending') then
    raise exception 'Invalid account approval status';
  end if;

  update public.profiles
  set status = target_status,
      approval_note = note,
      approved_by = auth.uid(),
      approved_at = case when target_status = 'active' then now() else approved_at end,
      updated_at = now()
  where id = target_user_id;

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, details)
  values (
    auth.uid(),
    'account_status_changed',
    'profile',
    target_user_id,
    jsonb_build_object('status', target_status, 'note', note)
  );
end;
$$;
grant execute on function public.approve_account(uuid, public.account_status, text) to authenticated;

-- ---------- Storage ----------
-- Avatars are public-readable; study-files remain private and should be served by signed URLs.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('study-files', 'study-files', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('university-cards', 'university-cards', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('private-message-media', 'private-message-media', false)
on conflict (id) do nothing;

drop policy if exists university_cards_insert_own on storage.objects;
create policy university_cards_insert_own on storage.objects
for insert to authenticated
with check (
  bucket_id = 'university-cards'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists university_cards_select_allowed on storage.objects;
create policy university_cards_select_allowed on storage.objects
for select to authenticated
using (
  bucket_id = 'university-cards'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.has_permission('approve_accounts')
    or public.has_permission('manage_accounts')
  )
);

drop policy if exists university_cards_update_own on storage.objects;
create policy university_cards_update_own on storage.objects
for update to authenticated
using (bucket_id = 'university-cards' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'university-cards' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists university_cards_delete_allowed on storage.objects;
create policy university_cards_delete_allowed on storage.objects
for delete to authenticated
using (
  bucket_id = 'university-cards'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.has_permission('manage_accounts'))
);

drop policy if exists private_message_media_insert_own on storage.objects;
create policy private_message_media_insert_own on storage.objects
for insert to authenticated
with check (
  bucket_id = 'private-message-media'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists private_message_media_select_member on storage.objects;
create policy private_message_media_select_member on storage.objects
for select to authenticated
using (
  bucket_id = 'private-message-media'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1 from public.private_message_attachments a
      join public.private_messages pm on pm.id = a.message_id
      join public.conversation_members cm on cm.conversation_id = pm.conversation_id
      where a.storage_path = name and cm.user_id = auth.uid()
    )
  )
);

create or replace function public.can_read_study_file(path text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select public.is_active_user() and exists (
    select 1 from public.study_files sf
    where sf.storage_path = path
      and (sf.status = 'published' or sf.uploaded_by = auth.uid() or public.has_permission('manage_content'))
  );
$$;

drop policy if exists avatars_insert_own on storage.objects;
create policy avatars_insert_own on storage.objects
for insert to authenticated
with check (
  bucket_id = 'avatars'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists avatars_update_own on storage.objects;
create policy avatars_update_own on storage.objects
for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatars_delete_own on storage.objects;
create policy avatars_delete_own on storage.objects
for delete to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists study_files_insert_own on storage.objects;
create policy study_files_insert_own on storage.objects
for insert to authenticated
with check (
  bucket_id = 'study-files'
  and public.is_active_user()
  and public.has_permission('upload_files')
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists study_files_select_allowed on storage.objects;
create policy study_files_select_allowed on storage.objects
for select to authenticated
using (bucket_id = 'study-files' and public.can_read_study_file(name));

drop policy if exists study_files_update_allowed on storage.objects;
create policy study_files_update_allowed on storage.objects
for update to authenticated
using (
  bucket_id = 'study-files'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.has_permission('manage_content'))
)
with check (bucket_id = 'study-files');

drop policy if exists study_files_delete_allowed on storage.objects;
create policy study_files_delete_allowed on storage.objects
for delete to authenticated
using (
  bucket_id = 'study-files'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.has_permission('manage_content'))
);

-- ---------- Realtime ----------
do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'public_chat_messages',
    'conversations',
    'conversation_members',
    'private_messages',
    'private_message_attachments',
    'student_reminders',
    'notifications'
  ] loop
    if not exists (
      select 1
      from pg_publication_rel pr
      join pg_class c on c.oid = pr.prrelid
      join pg_namespace n on n.oid = c.relnamespace
      join pg_publication p on p.oid = pr.prpubid
      where p.pubname = 'supabase_realtime'
        and n.nspname = 'public'
        and c.relname = replace(table_name, 'public_', '')
    ) then
      begin
        execute format('alter publication supabase_realtime add table public.%I', table_name);
      exception when undefined_object then
        null;
      end;
    end if;
  end loop;
end;
$$;

-- ---------- Notes ----------
-- 1) Schedule select public.delete_expired_public_chat_messages() hourly using Supabase Cron.
-- 2) Use an Edge Function for Web Push delivery from push_subscriptions.
-- 3) Upload study_files with a path beginning with the authenticated user's UUID,
--    then insert the matching row into public.study_files.
