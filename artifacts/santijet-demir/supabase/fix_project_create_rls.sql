-- ŞantiJET DEMİR — Proje oluşturma RLS düzeltmesi
-- Supabase SQL Editor'da çalıştırın (mevcut projeler için).

-- Proje sahibi, üye kaydı eklenmeden önce de kendi projesini okuyabilsin.
drop policy if exists "projects_select_owner" on projects;
create policy "projects_select_owner" on projects
  for select using (auth.uid() = owner_id);

-- Üye listesi: kendi satırını okuyabilsin (sonsuz RLS döngüsünü önler).
drop policy if exists "members_select_same_project" on project_members;
drop policy if exists "members_select_own" on project_members;
create policy "members_select_own" on project_members
  for select using (auth.uid() = user_id);

-- Aynı projedeki diğer üyeleri görmek (sahip/ekip ekranı).
drop policy if exists "members_select_project_peers" on project_members;
create policy "members_select_project_peers" on project_members
  for select using (
    exists (
      select 1 from project_members me
      where me.project_id = project_members.project_id
        and me.user_id = auth.uid()
    )
  );
