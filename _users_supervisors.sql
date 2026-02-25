create materialized view public._users_supervisors as
with recursive
  supervisor_chain as (
    select
      u_1.user_id,
      u_1.supervisor_id,
      array[u_1.user_id, u_1.supervisor_id] as all_supervisors
    from
      users u_1
    where
      u_1.supervisor_id is not null
    union all
    select
      sc.user_id,
      u_1.supervisor_id,
      sc.all_supervisors || u_1.supervisor_id
    from
      supervisor_chain sc
      join users u_1 on u_1.user_id = sc.supervisor_id
    where
      u_1.supervisor_id is not null
  )
select
  u.user_id,
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
  ) || (
    (
      select
        array_agg(admin.user_id) as array_agg
      from
        users admin
      where
        admin.is_admin = true
    )
  ) as supervisors,
  u.email,
  concat(u.name, ' ', u.last_name) as display_name
from
  users u;