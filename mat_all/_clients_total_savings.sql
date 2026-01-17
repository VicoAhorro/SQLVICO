create materialized view public._clients_total_savings as
select
  _contracts_detailed.client_email,
  sum(_contracts_detailed.total_savings) as total_savings
from
  _contracts_detailed
group by
  _contracts_detailed.client_email;