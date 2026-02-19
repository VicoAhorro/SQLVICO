create or replace view public.view_clients_count as
select
  count(*) filter (where ur.user_id is not null) as racc_count,
  count(*) filter (where ur.user_id is null) as non_racc_count
from public.clients c
left join public.users_racc ur on c.advisor_id = ur.user_id;