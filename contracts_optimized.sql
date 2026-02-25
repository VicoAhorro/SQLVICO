create view public._contracts_optimized as
select
  idx.id,
  c.status,
  c.contract_type,
  idx.client_name,
  idx.client_last_name,
  idx.cups as "CUPS",
  c.in_process_substatus,
  idx.created_at,
  c.saving_percentage,
  c.crs,
  c.subestadocompanias as subestado_companias,
  idx.supervisors,
  idx.contract_type_filter,
  idx.advisor_filter,
  idx.search,
  idx.created_month,
  idx.created_year,
  idx.deleted,
  idx.new_company_filter,
  idx.is_racc,
  c.last_update,
  idx.contract_subestatus_filter
from
  contracts_search_index idx
  join clients_contracts c on idx.id = c.id;