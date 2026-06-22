-- ŞantiJET DEMİR — Proje oluşturma + senkron RLS düzeltmesi
-- Supabase SQL Editor'da çalıştırın (mevcut projeler için).

-- Eksik profil satırı (eski hesaplar) uygulama tarafından eklenebilsin.
drop policy if exists "profiles_insert_own" on profiles;
create policy "profiles_insert_own" on profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on profiles;
create policy "profiles_update_own" on profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id);

-- Trigger kurulmadan önce açılmış hesapların profiles satırını tamamla.
insert into public.profiles (id, email, display_name)
select
  id,
  coalesce(email, ''),
  coalesce(raw_user_meta_data->>'display_name', '')
from auth.users
on conflict (id) do nothing;

-- Proje sahibi, üye kaydı eklenmeden önce de kendi projesini okuyabilsin.
drop policy if exists "projects_select_owner" on projects;
create policy "projects_select_owner" on projects
  for select using (auth.uid() = owner_id);

-- Üye listesi: kendi satırını okuyabilsin.
drop policy if exists "members_select_same_project" on project_members;
drop policy if exists "members_select_own" on project_members;
create policy "members_select_own" on project_members
  for select using (auth.uid() = user_id);

-- Proje sahibi ekip üyelerini görebilsin (project_members üzerinde döngü yok).
drop policy if exists "members_select_project_peers" on project_members;
create policy "members_select_project_peers" on project_members
  for select using (
    exists (
      select 1 from projects p
      where p.id = project_members.project_id
        and p.owner_id = auth.uid()
    )
  );

-- Yalnızca proje sahibi, kendi owner üyeliğini oluşturabilsin.
drop policy if exists "members_insert_self" on project_members;
create policy "members_insert_self" on project_members
  for insert with check (
    auth.uid() = user_id
    and role = 'owner'
    and can_edit = true
    and exists (
      select 1 from projects p
      where p.id = project_members.project_id
        and p.owner_id = auth.uid()
    )
  );

-- Sahip, ekip yetkilerini güncelleyebilsin (döngüsüz).
drop policy if exists "members_update_owner" on project_members;
create policy "members_update_owner" on project_members
  for update using (
    exists (
      select 1 from projects p
      where p.id = project_members.project_id
        and p.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from projects p
      where p.id = project_members.project_id
        and p.owner_id = auth.uid()
    )
  );
