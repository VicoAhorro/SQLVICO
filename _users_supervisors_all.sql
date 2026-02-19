create materialized view public._users_supervisors_all as
with recursive
  supervisor_chain as (
    select
      u1.user_id,
      u1.supervisor_id,
      array[u1.user_id, u1.supervisor_id] as all_supervisors
    from
      users u1
    where
      u1.supervisor_id is not null
    union all
    select
      sc.user_id,
      u1.supervisor_id,
      sc.all_supervisors || u1.supervisor_id
    from
      supervisor_chain sc
      join users u1 on u1.user_id = sc.supervisor_id
    where
      u1.supervisor_id is not null
  ),
  admins as (
    select
      COALESCE(array_agg(u_1.user_id), array[]::uuid[]) as ids
    from
      users u_1
    where
      u_1.is_admin = true
  ),
  racc_group as (
    select
      COALESCE(array_agg(u_1.user_id), array[]::uuid[]) as ids
    from
      users u_1
    where
      u_1.racc = true
  )
select
  u.tenant,
  u.user_id,
  case
    when u.racc = true then (
      select
        ARRAY(
          select distinct
            x.x
          from
            unnest(rg.ids || a.ids) x (x)
        ) as "array"
      from
        racc_group rg,
        admins a
    )
    else (
      select
        ARRAY(
          select distinct
            x.x
          from
            unnest(
              COALESCE(
                (
                  select
                    sc2.all_supervisors
                  from
                    supervisor_chain sc2
                  where
                    sc2.user_id = u.user_id
                  order by
                    (array_length(sc2.all_supervisors, 1)) desc
                  limit
                    1
                ),
                array[u.user_id]
              ) || a.ids
            ) x (x)
        ) as "array"
      from
        admins a
    )
  end as supervisors,
  u.email,
  concat(u.name, ' ', u.last_name) as display_name,
  case
    when u.tenant = 1 then u.email
    else COALESCE(
      NULLIF(
        btrim(
          concat(u.name, ' ', COALESCE(u.last_name, ''::text))
        ),
        ''::text
      ),
      case
        when u.name = '-'::text then null::text
        else null::text
      end,
      u.email
    )
  end as flutter_name
from
  users u;