-- ŞantiJET SAHA — sahip senkron: saha_attendance RLS 42501
-- SQL Editor → Run (deploy gerekmez)

-- 1) Sahip her zaman yazabilsin (can_edit kapalı olsa bile)
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

grant execute on function public.is_saha_editor(uuid) to authenticated;

-- 2) Mevcut sahip satırlarında can_edit açık olsun
update public.saha_project_members m
set can_edit = true,
    role = 'owner'
from public.saha_projects p
where m.project_id = p.id
  and m.user_id = p.owner_id
  and (m.can_edit = false or m.role is distinct from 'owner');

-- 3) Tablo yazma izinleri (eksikse)
grant select, insert, update, delete on table public.saha_attendance to authenticated;
grant select, insert, update, delete on table public.saha_personnel to authenticated;
grant select, insert, update, delete on table public.saha_production to authenticated;
grant select, insert, update, delete on table public.saha_tasks to authenticated;
grant select, insert, update, delete on table public.saha_daily_reports to authenticated;
grant select, insert, update, delete on table public.saha_yevmiyeli to authenticated;
grant select, insert, update, delete on table public.saha_uninsured_teams to authenticated;
grant select, insert, update, delete on table public.saha_snapshots to authenticated;
