-- Momathili migration: university card in approval requests + library attachments in private chat

alter table public.profiles
  add column if not exists university_card_path text,
  add column if not exists university_card_original_name text,
  add column if not exists university_card_mime_type text,
  add column if not exists university_card_size_bytes bigint;

alter table public.private_messages
  add column if not exists study_file_id uuid references public.study_files(id) on delete set null;

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
    new.id, name_value, phone_value,
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'university_card_path',
    new.raw_user_meta_data ->> 'university_card_original_name',
    new.raw_user_meta_data ->> 'university_card_mime_type',
    nullif(new.raw_user_meta_data ->> 'university_card_size_bytes', '')::bigint,
    'student', 'pending'
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    phone = excluded.phone,
    avatar_url = excluded.avatar_url,
    university_card_path = excluded.university_card_path,
    university_card_original_name = excluded.university_card_original_name,
    university_card_mime_type = excluded.university_card_mime_type,
    university_card_size_bytes = excluded.university_card_size_bytes,
    updated_at = now();
  return new;
end;
$$;

alter table public.profiles drop constraint if exists profiles_university_card_size_positive;
alter table public.profiles add constraint profiles_university_card_size_positive
  check (university_card_size_bytes is null or university_card_size_bytes > 0);

drop policy if exists profiles_select_active on public.profiles;
create policy profiles_select_active on public.profiles for select using (
  public.is_active_user()
  and (
    status = 'active'
    or id = auth.uid()
    or public.has_role('representative')
    or public.has_permission('approve_accounts')
    or public.has_permission('manage_accounts')
  )
);

drop policy if exists private_messages_insert_member on public.private_messages;
create policy private_messages_insert_member on public.private_messages for insert with check (
  public.is_active_user()
  and public.has_permission('private_messages')
  and sender_id = auth.uid()
  and exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = private_messages.conversation_id
      and cm.user_id = auth.uid()
  )
  and (
    study_file_id is null
    or exists (
      select 1 from public.study_files sf
      where sf.id = private_messages.study_file_id
        and sf.status = 'published'
    )
  )
);

insert into storage.buckets (id, name, public)
values ('university-cards', 'university-cards', false)
on conflict (id) do nothing;

drop policy if exists university_cards_insert_own on storage.objects;
create policy university_cards_insert_own on storage.objects
for insert to authenticated with check (
  bucket_id = 'university-cards'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists university_cards_select_allowed on storage.objects;
create policy university_cards_select_allowed on storage.objects
for select to authenticated using (
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
for delete to authenticated using (
  bucket_id = 'university-cards'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.has_permission('manage_accounts')
  )
);
