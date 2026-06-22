-- ŞantiJET DEMİR — çok projeli paylaşım şeması (Supabase/Postgres)
-- Bu dosya cihazlar arası proje kodu paylaşımı için sunucu tarafı referansıdır.

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null,
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
  role text not null check (role in ('owner', 'editor', 'viewer')),
  can_edit boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (project_id, user_id)
);

create index if not exists idx_projects_code on projects (code);
create index if not exists idx_project_members_user on project_members (user_id);
