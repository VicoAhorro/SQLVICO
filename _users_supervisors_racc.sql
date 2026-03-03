create or replace view public._users_supervisors_racc as
select
  user_id,
  supervisors,
  email,
  display_name
from
  public._users_supervisors_all
where
  tenant = 1;