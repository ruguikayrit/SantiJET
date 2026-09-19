-- ŞantiJET SAHA — proje oluşturma RLS hatası düzeltmesi
-- SQL Editor'da bu dosyanın tamamını yapıştırıp Run edin.
-- Mevcut uygulamayı hemen açmak için GRANT + politikalar yeter;
-- create_saha_project RPC sonraki deploy ile kullanılır.

-- Tablo izinleri
grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.saha_projects to authenticated;
grant select, insert, update, delete on table public.saha_project_members to authenticated;
grant select, insert, update, delete on table public.saha_snapshots to authenticated;

-- Politikaları yeniden kur
drop policy if exists "saha_projects_insert_owner" on saha_projects;
create policy "saha_projects_insert_owner" on saha_projects
  for insert with check (auth.uid() = owner_id);

drop policy if exists "saha_projects_select_member" on saha_projects;
create policy "saha_projects_select_member" on saha_projects
  for select using (
    exists (
      select 1 from saha_project_members pm
      where pm.project_id = saha_projects.id and pm.user_id = auth.uid()
    )
    or owner_id = auth.uid()
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

drop policy if exists "profiles_insert_own" on profiles;
create policy "profiles_insert_own" on profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles_select_own" on profiles;
create policy "profiles_select_own" on profiles
  for select using (auth.uid() = id);

-- Güvenli oluşturma fonksiyonu (sonraki app sürümü kullanır; şimdiden ekleyin)
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
