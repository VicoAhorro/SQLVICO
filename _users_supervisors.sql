create or replace view public._users_supervisors as
select
  user_id,
  supervisors,
  email,
  display_name
from
  public._users_supervisors_all;