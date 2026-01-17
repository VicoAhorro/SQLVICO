create view public.view_clients_count as
select
  count(*) filter (
    where
      _clients_detailed.is_racc = true
  ) as racc_count,
  count(*) filter (
    where
      _clients_detailed.is_racc = false
  ) as non_racc_count
from
  _clients_detailed;