-- ŞantiJET DEMİR — Supabase şeması (çok proje + paylaşım + tek oturum)
-- Supabase SQL Editor'da çalıştırın.

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null default '',
  current_session_id text,
  created_at timestamptz not null default now()
);

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  location text not null default '',
  owner_id uuid not null references profiles(id),
  start_date date,
  end_date date,
  progress numeric not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists project_members (
  project_id uuid not null references projects(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  role text not null check (role in ('owner', 'editor', 'viewer')),
  can_edit boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (project_id, user_id)
);

create index if not exists idx_projects_code on projects (code);
create index if not exists idx_project_members_user on project_members (user_id);

-- Yeni kullanıcı profili
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'display_name', '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Daha önce oluşturulmuş ve trigger çalışmamış kullanıcıları tamamla.
insert into public.profiles (id, email, display_name)
select
  id,
  coalesce(email, ''),
  coalesce(raw_user_meta_data->>'display_name', '')
from auth.users
on conflict (id) do nothing;

-- Proje kodu ile katılma
create or replace function public.join_project_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_project_id uuid;
  v_email text;
  v_name text;
begin
  select id into v_project_id
  from projects
  where upper(code) = upper(trim(p_code));

  if v_project_id is null then
    raise exception 'Proje kodu bulunamadı';
  end if;

  select email, display_name into v_email, v_name
  from profiles where id = auth.uid();

  insert into project_members (
    project_id, user_id, email, display_name, role, can_edit
  ) values (
    v_project_id, auth.uid(), coalesce(v_email, ''), coalesce(v_name, ''), 'viewer', false
  )
  on conflict (project_id, user_id) do nothing;

  return v_project_id;
end;
$$;

grant execute on function public.join_project_by_code(text) to authenticated;

-- RLS
alter table profiles enable row level security;
alter table projects enable row level security;
alter table project_members enable row level security;

drop policy if exists "profiles_select_own" on profiles;
create policy "profiles_select_own" on profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on profiles;
create policy "profiles_insert_own" on profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on profiles;
create policy "profiles_update_own" on profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "projects_select_member" on projects;
create policy "projects_select_member" on projects
  for select using (
    exists (
      select 1 from project_members pm
      where pm.project_id = projects.id and pm.user_id = auth.uid()
    )
  );

drop policy if exists "projects_select_owner" on projects;
create policy "projects_select_owner" on projects
  for select using (auth.uid() = owner_id);

drop policy if exists "projects_insert_owner" on projects;
create policy "projects_insert_owner" on projects
  for insert with check (auth.uid() = owner_id);

drop policy if exists "projects_update_owner" on projects;
create policy "projects_update_owner" on projects
  for update using (auth.uid() = owner_id);

drop policy if exists "members_select_same_project" on project_members;
drop policy if exists "members_select_own" on project_members;
create policy "members_select_own" on project_members
  for select using (auth.uid() = user_id);

drop policy if exists "members_select_project_peers" on project_members;
create policy "members_select_project_peers" on project_members
  for select using (
    exists (
      select 1 from projects p
      where p.id = project_members.project_id
        and p.owner_id = auth.uid()
    )
  );

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
