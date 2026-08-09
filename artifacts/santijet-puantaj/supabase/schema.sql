-- ŞantiJET SAHA (Puantaj) — çok kullanıcılı iş paylaşımı
-- Demir projelerinden bağımsız tablolar (aynı Supabase projesinde yan yana çalışır).

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  created_at timestamptz not null default now()
);

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
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table if not exists saha_projects (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  company text not null default '',
  owner_id uuid not null references profiles(id),
  logo_base64 text not null default '',
  logo_mime_type text not null default 'image/jpeg',
  created_at timestamptz not null default now()
);

create table if not exists saha_project_members (
  project_id uuid not null references saha_projects(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  role text not null check (role in ('owner', 'editor', 'viewer')),
  can_edit boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (project_id, user_id)
);

create index if not exists idx_saha_projects_code on saha_projects (code);
create index if not exists idx_saha_project_members_user on saha_project_members (user_id);

-- Domain veri anlık görüntüleri (personel, puantaj, rapor, görev, imalat)
create table if not exists saha_snapshots (
  project_id uuid not null references saha_projects(id) on delete cascade,
  kind text not null,
  payload jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  primary key (project_id, kind)
);

create or replace function public.join_saha_project_by_code(p_code text)
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
  if auth.uid() is null then
    raise exception 'Oturum gerekli';
  end if;

  select id into v_project_id
  from saha_projects
  where upper(code) = upper(trim(p_code));

  if v_project_id is null then
    raise exception 'Proje kodu bulunamadı';
  end if;

  select email, display_name into v_email, v_name
  from profiles where id = auth.uid();

  insert into saha_project_members (
    project_id, user_id, email, display_name, role, can_edit
  ) values (
    v_project_id, auth.uid(), coalesce(v_email, ''), coalesce(v_name, ''), 'viewer', false
  )
  on conflict (project_id, user_id) do nothing;

  return v_project_id;
end;
$$;

grant execute on function public.join_saha_project_by_code(text) to authenticated;

alter table profiles enable row level security;
alter table saha_projects enable row level security;
alter table saha_project_members enable row level security;
alter table saha_snapshots enable row level security;

-- profiles
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

-- saha_projects
drop policy if exists "saha_projects_select_member" on saha_projects;
create policy "saha_projects_select_member" on saha_projects
  for select using (
    exists (
      select 1 from saha_project_members pm
      where pm.project_id = saha_projects.id and pm.user_id = auth.uid()
    )
    or owner_id = auth.uid()
  );

drop policy if exists "saha_projects_insert_owner" on saha_projects;
create policy "saha_projects_insert_owner" on saha_projects
  for insert with check (auth.uid() = owner_id);

drop policy if exists "saha_projects_update_owner" on saha_projects;
create policy "saha_projects_update_owner" on saha_projects
  for update using (auth.uid() = owner_id);

drop policy if exists "saha_projects_delete_owner" on saha_projects;
create policy "saha_projects_delete_owner" on saha_projects
  for delete using (auth.uid() = owner_id);

-- members
drop policy if exists "saha_members_select_own" on saha_project_members;
create policy "saha_members_select_own" on saha_project_members
  for select using (auth.uid() = user_id);

drop policy if exists "saha_members_select_peers" on saha_project_members;
create policy "saha_members_select_peers" on saha_project_members
  for select using (
    exists (
      select 1 from saha_projects p
      where p.id = saha_project_members.project_id
        and p.owner_id = auth.uid()
    )
  );

drop policy if exists "saha_members_insert_self_owner" on saha_project_members;
create policy "saha_members_insert_self_owner" on saha_project_members
  for insert with check (
    auth.uid() = user_id
    and role = 'owner'
    and can_edit = true
    and exists (
      select 1 from saha_projects p
      where p.id = saha_project_members.project_id
        and p.owner_id = auth.uid()
    )
  );

drop policy if exists "saha_members_update_owner" on saha_project_members;
create policy "saha_members_update_owner" on saha_project_members
  for update using (
    exists (
      select 1 from saha_projects p
      where p.id = saha_project_members.project_id
        and p.owner_id = auth.uid()
    )
  );

-- snapshots: üyeler okur; can_edit / owner yazar
drop policy if exists "saha_snapshots_select_member" on saha_snapshots;
create policy "saha_snapshots_select_member" on saha_snapshots
  for select using (
    exists (
      select 1 from saha_project_members pm
      where pm.project_id = saha_snapshots.project_id
        and pm.user_id = auth.uid()
    )
  );

drop policy if exists "saha_snapshots_upsert_editor" on saha_snapshots;
create policy "saha_snapshots_upsert_editor" on saha_snapshots
  for all using (
    exists (
      select 1 from saha_project_members pm
      where pm.project_id = saha_snapshots.project_id
        and pm.user_id = auth.uid()
        and pm.can_edit = true
    )
  )
  with check (
    exists (
      select 1 from saha_project_members pm
      where pm.project_id = saha_snapshots.project_id
        and pm.user_id = auth.uid()
        and pm.can_edit = true
    )
  );
