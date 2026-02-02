create materialized view public.user_dashboard_summary as
with
  user_collaborators as (
    select
      us.user_id as supervisor_id,
      count(distinct sub.user_id) as total_collaborators
    from
      _users_supervisors us
      join users u_supervisor on us.user_id = u_supervisor.user_id
      join roles r_supervisor on u_supervisor.role_id = r_supervisor.id
      join _users_supervisors sub on us.user_id = any (sub.supervisors)
      join roles r_subordinate on (select role_id from users where user_id = sub.user_id) = r_subordinate.id
    where
      r_supervisor.hierarchy < r_subordinate.hierarchy
      and us.user_id::text <> ''
    group by
      us.user_id
  ),
  supervisor_crs as (
    select
      us.user_id as supervisor_id,
      sum(cc.crs) as total_crs_collaborators
    from
      _users_supervisors us
      join users u_supervisor on us.user_id = u_supervisor.user_id
      join roles r_supervisor on u_supervisor.role_id = r_supervisor.id
      join _users_supervisors sub on us.user_id = any (sub.supervisors)
      join clients_contracts cc on cc.advisor_id = sub.user_id
      join roles r_subordinate on (select role_id from users where user_id = sub.user_id) = r_subordinate.id
    where
      r_supervisor.hierarchy < r_subordinate.hierarchy
      and us.user_id::text <> ''
    group by
      us.user_id
  ),
  user_clients as (
    select
      c.advisor_id as user_id,
      count(*) as total_clients
    from
      clients c
    where
      c.advisor_id is not null and c.advisor_id::text <> ''
    group by
      c.advisor_id
  ),
  user_contracts as (
    select
      cc.advisor_id as user_id,
      count(*) as total_contracts,
      sum(cc.crs) as total_crs_own
    from
      clients_contracts cc
    where
      cc.advisor_id is not null and cc.advisor_id::text <> ''
    group by
      cc.advisor_id
  ),
  main_data as (
    select
      u.user_id,
      concat(
        COALESCE(u.name, ''::text),
        ' ',
        COALESCE(u.last_name, ''::text)
      ) as advisor_name,
      COALESCE(uc.total_clients, 0::bigint) as total_clients,
      COALESCE(ucol.total_collaborators, 0::bigint) as total_collaborators,
      COALESCE(scrs.total_crs_collaborators, 0::real) as total_crs_collaborators,
      COALESCE(uct.total_crs_own, 0::real) as total_crs_own,
      COALESCE(uct.total_contracts, 0::bigint) as total_contracts
    from
      users u
      left join user_clients uc on u.user_id = uc.user_id
      left join user_collaborators ucol on u.user_id = ucol.supervisor_id
      left join user_contracts uct on u.user_id = uct.user_id
      left join supervisor_crs scrs on u.user_id = scrs.supervisor_id
  )
select
  main_data.user_id,
  main_data.advisor_name,
  main_data.total_clients,
  main_data.total_collaborators,
  main_data.total_crs_collaborators,
  main_data.total_crs_own,
  main_data.total_contracts
from
  main_data
where
  main_data.user_id <> '0f317d06-93a8-4b2d-b18d-9a0264e1d288'::uuid
  and main_data.user_id::text <> ''
union all
select
  '0f317d06-93a8-4b2d-b18d-9a0264e1d288'::uuid as user_id,
  'Total General'::text as advisor_name,
  sum(main_data.total_clients) as total_clients,
  sum(main_data.total_collaborators) as total_collaborators,
  sum(main_data.total_crs_collaborators) as total_crs_collaborators,
  sum(main_data.total_crs_own) as total_crs_own,
  sum(main_data.total_contracts) as total_contracts
from
  main_data; 