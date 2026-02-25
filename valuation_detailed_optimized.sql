create view public._valuations_detailed_optimized as
select
  idx.id,
  idx.contract_id,
  v.contract_type,
  idx.temp_client_name,
  idx.temp_client_last_name,
  idx.cups as "CUPS",
  idx.saving_percentage,
  idx.crs,
  idx.deleted,
  idx.supervisors,
  idx.contract_type_filter,
  idx.advisor_filter,
  idx.new_company_filter,
  idx.search,
  idx.created_month,
  idx.created_year,
  idx.created_at,
  idx.client_email,
  idx.deleted_reason
from
  valuations_search_index idx
  join clients_valuations v on idx.id = v.id;