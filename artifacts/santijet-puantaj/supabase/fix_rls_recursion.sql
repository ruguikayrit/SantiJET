-- ŞantiJET SAHA — "infinite recursion detected in policy for relation saha_projects"
-- SQL Editor → New query → bu dosyanın tamamını yapıştır → Run

-- Yardımcı fonksiyonlar (RLS'yi bypass ederek kontrol eder → döngü kırılır)
create or replace function public.is_saha_member(p_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.saha_project_members
    where project_id = p_project_id and user_id = auth.uid()
  );
$$;

create or replace function public.is_saha_owner(p_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.saha_projects
    where id = p_project_id and owner_id = auth.uid()
  );
$$;

create or replace function public.is_saha_editor(p_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1 from public.saha_projects
      where id = p_project_id and owner_id = auth.uid()
    )
    or exists (
      select 1 from public.saha_project_members
      where project_id = p_project_id
        and user_id = auth.uid()
        and can_edit = true
    );
$$;

grant execute on function public.is_saha_member(uuid) to authenticated;
grant execute on function public.is_saha_owner(uuid) to authenticated;
grant execute on function public.is_saha_editor(uuid) to authenticated;

-- saha_projects
drop policy if exists "saha_projects_select_member" on saha_projects;
create policy "saha_projects_select_member" on saha_projects
  for select using (
    owner_id = auth.uid() or public.is_saha_member(id)
  );

-- members
drop policy if exists "saha_members_select_peers" on saha_project_members;
create policy "saha_members_select_peers" on saha_project_members
  for select using (public.is_saha_owner(project_id));

drop policy if exists "saha_members_insert_self_owner" on saha_project_members;
create policy "saha_members_insert_self_owner" on saha_project_members
  for insert with check (
    auth.uid() = user_id
    and role = 'owner'
    and can_edit = true
    and public.is_saha_owner(project_id)
  );

drop policy if exists "saha_members_update_owner" on saha_project_members;
create policy "saha_members_update_owner" on saha_project_members
  for update using (public.is_saha_owner(project_id));

-- snapshots
drop policy if exists "saha_snapshots_select_member" on saha_snapshots;
create policy "saha_snapshots_select_member" on saha_snapshots
  for select using (public.is_saha_member(project_id));

drop policy if exists "saha_snapshots_upsert_editor" on saha_snapshots;
create policy "saha_snapshots_upsert_editor" on saha_snapshots
  for all using (public.is_saha_editor(project_id))
  with check (public.is_saha_editor(project_id));

-- satır tabloları
do $$
declare
  t text;
begin
  foreach t in array array[
    'saha_attendance',
    'saha_personnel',
    'saha_production',
    'saha_tasks',
    'saha_daily_reports',
    'saha_yevmiyeli',
    'saha_uninsured_teams'
  ]
  loop
    execute format('drop policy if exists %I on %I', t || '_select_member', t);
    execute format(
      'create policy %I on %I for select using (public.is_saha_member(project_id))',
      t || '_select_member', t
    );
    execute format('drop policy if exists %I on %I', t || '_write_editor', t);
    execute format(
      'create policy %I on %I for all using (public.is_saha_editor(project_id))
       with check (public.is_saha_editor(project_id))',
      t || '_write_editor', t
    );
  end loop;
end $$;
