-- 0021: Scope Centre Master access to a Centre login's hierarchy.
-- Super Admin and ASO Viewer retain global access. Centre logins can see and
-- manage only their own centre tree, including SUB CENTRE and POINT rows.

create or replace function public.is_master_user()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role in ('SUPERADMIN', 'ASO_VIEWER')
  );
$$;

grant execute on function public.is_master_user() to authenticated;

create or replace function public.centre_in_user_scope(target_id bigint)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select public.is_master_user()
    or exists (
      with recursive tree(id) as (
        select p."centreId"
        from public.profiles p
        where p.id = auth.uid()
          and p.role = 'CENTRE'
          and p."centreId" is not null
        union all
        select c.id
        from public.centres c
        join tree t on c."parentId" = t.id
      )
      select 1 from tree where id = target_id
    );
$$;

grant execute on function public.centre_in_user_scope(bigint) to authenticated;

drop policy if exists "centres_select" on public.centres;
drop policy if exists "centres_admin_insert" on public.centres;
drop policy if exists "centres_admin_update" on public.centres;
drop policy if exists "centres_admin_delete" on public.centres;
drop policy if exists "centres_insert_all" on public.centres;
drop policy if exists "centres_update_all" on public.centres;
drop policy if exists "centres_delete_all" on public.centres;

create policy "centres_select_scoped" on public.centres
  for select to authenticated
  using (public.centre_in_user_scope(id));

create policy "centres_insert_scoped" on public.centres
  for insert to authenticated
  with check (
    public.is_master_user()
    or (
      exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.role = 'CENTRE'
      )
      and type in ('SUB CENTRE', 'POINT')
      and "parentId" is not null
      and public.centre_in_user_scope("parentId")
    )
  );

create policy "centres_update_scoped" on public.centres
  for update to authenticated
  using (public.centre_in_user_scope(id))
  with check (
    public.is_master_user()
    or (
      type in ('SUB CENTRE', 'POINT')
      and "parentId" is not null
      and public.centre_in_user_scope("parentId")
      and not exists (
        select 1
        from public.profiles p
        where p.id = auth.uid()
          and p.role = 'CENTRE'
          and p."centreId" = public.centres.id
      )
    )
  );

create policy "centres_delete_scoped" on public.centres
  for delete to authenticated
  using (
    public.centre_in_user_scope(id)
    and (
      public.is_master_user()
      or not exists (
        select 1
        from public.profiles p
        where p.id = auth.uid()
          and p.role = 'CENTRE'
          and p."centreId" = public.centres.id
      )
    )
  );
