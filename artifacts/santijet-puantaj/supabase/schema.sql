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

-- Proje oluşturma (RLS/grant sorunlarını aşmak için security definer)
create or replace function public.create_saha_project(
  p_name text,
  p_code text,
  p_company text default '',
  p_logo_base64 text default '',
  p_logo_mime_type text default 'image/jpeg'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_code text;
  v_email text;
  v_display text;
begin
  if auth.uid() is null then
    raise exception 'Oturum gerekli';
  end if;

  v_code := upper(trim(coalesce(p_code, '')));
  if v_code = '' then
    raise exception 'İş kodu gerekli';
  end if;
  if trim(coalesce(p_name, '')) = '' then
    raise exception 'İş adı boş olamaz';
  end if;

  insert into public.profiles (id, email, display_name)
  select
    u.id,
    coalesce(u.email, ''),
    coalesce(u.raw_user_meta_data->>'display_name', '')
  from auth.users u
  where u.id = auth.uid()
  on conflict (id) do nothing;

  select email, display_name into v_email, v_display
  from public.profiles
  where id = auth.uid();

  v_id := gen_random_uuid();

  insert into public.saha_projects (
    id, code, name, company, owner_id, logo_base64, logo_mime_type
  ) values (
    v_id,
    v_code,
    trim(p_name),
    coalesce(p_company, ''),
    auth.uid(),
    coalesce(p_logo_base64, ''),
    coalesce(nullif(trim(p_logo_mime_type), ''), 'image/jpeg')
  );

  insert into public.saha_project_members (
    project_id, user_id, email, display_name, role, can_edit
  ) values (
    v_id,
    auth.uid(),
    coalesce(v_email, ''),
    coalesce(v_display, ''),
    'owner',
    true
  );

  return v_id;
end;
$$;

grant execute on function public.create_saha_project(text, text, text, text, text) to authenticated;

-- authenticated rolüne tablo izinleri (RLS yine satır bazında kısıtlar)
grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.saha_projects to authenticated;
grant select, insert, update, delete on table public.saha_project_members to authenticated;
grant select, insert, update, delete on table public.saha_snapshots to authenticated;

-- RLS yardımcıları (tablolar arası policy sorgusu sonsuz döngü yaratmasın)
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

-- saha_projects (doğrudan members tablosuna bakma → recursion yok)
drop policy if exists "saha_projects_select_member" on saha_projects;
create policy "saha_projects_select_member" on saha_projects
  for select using (
    owner_id = auth.uid() or public.is_saha_member(id)
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

-- snapshots: üyeler okur; editor yazar
drop policy if exists "saha_snapshots_select_member" on saha_snapshots;
create policy "saha_snapshots_select_member" on saha_snapshots
  for select using (public.is_saha_member(project_id));

drop policy if exists "saha_snapshots_upsert_editor" on saha_snapshots;
create policy "saha_snapshots_upsert_editor" on saha_snapshots
  for all using (public.is_saha_editor(project_id))
  with check (public.is_saha_editor(project_id));

-- ---------------------------------------------------------------------------
-- Satır bazlı domain tabloları + Realtime (çok cihazlı hızlı senkron)
-- ---------------------------------------------------------------------------

create table if not exists saha_attendance (
  id text not null,
  project_id uuid not null references saha_projects(id) on delete cascade,
  person_id text not null,
  person_name text not null default '',
  date text not null,
  status text not null default 'absent',
  hours integer not null default 0,
  overtime_hours double precision not null default 0,
  note text not null default '',
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  primary key (project_id, person_id, date)
);

create index if not exists idx_saha_attendance_project
  on saha_attendance (project_id);

create table if not exists saha_personnel (
  id text not null,
  project_id uuid not null references saha_projects(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  primary key (project_id, id)
);

create index if not exists idx_saha_personnel_project
  on saha_personnel (project_id);

create table if not exists saha_production (
  id text not null,
  project_id uuid not null references saha_projects(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  primary key (project_id, id)
);

create index if not exists idx_saha_production_project
  on saha_production (project_id);

create table if not exists saha_tasks (
  id text not null,
  project_id uuid not null references saha_projects(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  primary key (project_id, id)
);

create index if not exists idx_saha_tasks_project
  on saha_tasks (project_id);

create table if not exists saha_daily_reports (
  id text not null,
  project_id uuid not null references saha_projects(id) on delete cascade,
  date text not null,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  primary key (project_id, date)
);

create index if not exists idx_saha_daily_reports_project
  on saha_daily_reports (project_id);

create table if not exists saha_yevmiyeli (
  id text not null,
  project_id uuid not null references saha_projects(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  primary key (project_id, id)
);

create index if not exists idx_saha_yevmiyeli_project
  on saha_yevmiyeli (project_id);

create table if not exists saha_uninsured_teams (
  id text not null,
  project_id uuid not null references saha_projects(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id),
  primary key (project_id, id)
);

create index if not exists idx_saha_uninsured_teams_project
  on saha_uninsured_teams (project_id);

alter table saha_attendance enable row level security;
alter table saha_personnel enable row level security;
alter table saha_production enable row level security;
alter table saha_tasks enable row level security;
alter table saha_daily_reports enable row level security;
alter table saha_yevmiyeli enable row level security;
alter table saha_uninsured_teams enable row level security;

grant select, insert, update, delete on table public.saha_attendance to authenticated;
grant select, insert, update, delete on table public.saha_personnel to authenticated;
grant select, insert, update, delete on table public.saha_production to authenticated;
grant select, insert, update, delete on table public.saha_tasks to authenticated;
grant select, insert, update, delete on table public.saha_daily_reports to authenticated;
grant select, insert, update, delete on table public.saha_yevmiyeli to authenticated;
grant select, insert, update, delete on table public.saha_uninsured_teams to authenticated;

-- Üye okur; can_edit yazar (tüm satır tabloları)
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
    execute format(
      'drop policy if exists %I on %I',
      t || '_select_member', t
    );
    execute format(
      'create policy %I on %I for select using (public.is_saha_member(project_id))',
      t || '_select_member', t
    );

    execute format(
      'drop policy if exists %I on %I',
      t || '_write_editor', t
    );
    execute format(
      'create policy %I on %I for all using (public.is_saha_editor(project_id))
       with check (public.is_saha_editor(project_id))',
      t || '_write_editor', t
    );
  end loop;
end $$;

-- Realtime (Supabase dashboard'da da publication kontrol edilmeli)
do $$
begin
  begin
    alter publication supabase_realtime add table saha_attendance;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table saha_personnel;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table saha_production;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table saha_tasks;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table saha_daily_reports;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table saha_yevmiyeli;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table saha_uninsured_teams;
  exception when duplicate_object then null;
  end;
end $$;
