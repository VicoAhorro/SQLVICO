drop materialized view if exists public.mat_all_data cascade;
create materialized view public.mat_all_data as
with
  latest_val as (
    select distinct
      on (
        cv.client_email,
        cv.advisor_id
      ) cv.client_email,
      cv.advisor_id,
      cv.id as valuation_id,
      cv.created_at as valuation_created_at,
      cv.pdf_proposal
    from
      clients_valuations cv
    order by
      cv.client_email,
      cv.advisor_id,
      cv.created_at desc
  ),
  latest_val_by_contract as (
    select distinct
      on (cv.contract_id) cv.contract_id,
      cv.id as valuation_id,
      cv.created_at as valuation_created_at,
      cv.pdf_proposal,
      cv.rate_type
    from
      clients_valuations cv
    where
      cv.contract_id is not null
    order by
      cv.contract_id,
      cv.created_at desc
  ),
  latest_cmp as (
    select distinct
      on (mat_comparisons_historic.valuation_id) mat_comparisons_historic.valuation_id,
      mat_comparisons_historic.id as comparison_id,
      mat_comparisons_historic.created_at as comparison_created_at,
      mat_comparisons_historic.pdf_invoice
    from
      mat_comparisons_historic
    order by
      mat_comparisons_historic.valuation_id,
      mat_comparisons_historic.created_at desc
  ),
  latest_incident as (
    select distinct on (contract_id)
      ci.contract_id,
      ci.created_at as incident_date,
      it.name as incident_type
    from contract_incidents ci
    left join incidents_type it on it.id = ci.incident_type_id
    order by ci.contract_id, ci.created_at desc
  )
select
  u.tenant,
  'contract'::text as source,
  c.id,
  c.created_at::timestamp with time zone,
  c.activation_date,
  c.client_email,
  c.advisor_id,
  u.email as advisor_email,
  cl.name,
  cl.last_name,
  cl."DNI",
  ca.address,
  cl.phone_number as phone,
  cl.client_type,
  c.contract_type,
  c.new_company,
  c.new_rate as new_rate_name,
  c.new_subrate,
  c.saving_percentage::double precision,
  c.pdf_invoice,
  c.saving_percentage::double precision as total_savings,
  c."CUPS",
  c.status,
  c.subestadocompanias,
  c.last_update,
  c.fecha_baja::timestamp without time zone,
  c.baja_firma_delegada::timestamp without time zone,
  c.firma_date,
  lvc.valuation_id,
  lvc.valuation_created_at,
  lvc.pdf_proposal,
  lcc.comparison_id,
  lcc.comparison_created_at,
  c.deleted,
  c.deleted_reason,
  c.deleted_at,
  case when c.status = 'INCIDENCIA' then li.incident_date else null end as incident_date,
  case when c.status = 'INCIDENCIA' then li.incident_type else null end as incident_type,
  lvc.rate_type
from
  clients_contracts c
  join users u on u.user_id = c.advisor_id
  left join clients cl on cl.id = c.client_id
  left join clients_addresses ca on ca.id = c.client_address_id
  left join latest_val_by_contract lvc on lvc.contract_id = c.id
  left join latest_cmp lcc on lcc.valuation_id = lvc.valuation_id
  left join latest_incident li on li.contract_id = c.id
union all
select
  c.tenant,
  'comparison'::text as source,
  c.id,
  c.created_at::timestamp with time zone,
  null::timestamp without time zone as activation_date,
  c.client_email,
  c.advisor_id,
  u.email as advisor_email,
  c.client_name as name,
  c.client_last_name as last_name,
  c."DNI",
  null::text as address,
  COALESCE(nullif(c.temp_client_phone, ''), c.phone) as phone,
  null::text as client_type,
  c.contract_type,
  c.new_company,
  c.new_rate_name,
  c.new_subrate,
  c.saving_percentage::double precision,
  c.pdf_invoice,
  null::double precision as total_savings,
  c."CUPS",
  null::text as status,
  null::text as subestadocompanias,
  null::timestamp without time zone as last_update,
  null::timestamp without time zone as fecha_baja,
  null::timestamp without time zone as baja_firma_delegada,
  null::timestamp without time zone as firma_date,
  c.valuation_id,
  v.created_at as valuation_created_at,
  v.pdf_proposal,
  c.id as comparison_id,
  c.created_at::timestamp without time zone as comparison_created_at,
  c.deleted,
  c.deleted_reason,
  c.deleted_at,
  null::timestamp without time zone as incident_date,
  null::text as incident_type,
  NULL::public.rate_mode_type as rate_type
from
  mat_comparisons_historic c
  left join clients_valuations v on v.id = c.valuation_id
  left join users u on u.user_id = c.advisor_id
union all
select
  u.tenant,
  'valuation'::text as source,
  v.id,
  v.created_at::timestamp with time zone,
  null::timestamp without time zone as activation_date,
  v.client_email,
  v.advisor_id,
  u.email as advisor_email,
  COALESCE(cl.name, v.temp_client_name) as name,
  COALESCE(cl.last_name, v.temp_client_last_name) as last_name,
  COALESCE(cl."DNI", v.temp_dni) as "DNI",
  null::text as address,
  COALESCE(cl.phone_number, v.temp_mobile_number) as phone,
  cl.client_type,
  v.contract_type,
  v.new_company,
  v.new_rate as new_rate_name,
  v.new_subrate,
  v.saving_percentage::double precision,
  v.pdf_invoice,
  null::double precision as total_savings,
  v."CUPS",
  v.status,
  null::text as subestadocompanias,
  null::timestamp without time zone as last_update,
  null::timestamp without time zone as fecha_baja,
  null::timestamp without time zone as baja_firma_delegada,
  null::timestamp without time zone as firma_date,
  v.id as valuation_id,
  v.created_at as valuation_created_at,
  v.pdf_proposal,
  null::uuid as comparison_id,
  null::timestamp without time zone as comparison_created_at,
  v.deleted,
  v.deleted_reason,
  v.deleted_at,
  null::timestamp without time zone as incident_date,
  null::text as incident_type,
  v.rate_type
from
  clients_valuations v
  left join users u on u.user_id = v.advisor_id
  left join (
    select distinct on (email, advisor_id)
      email,
      advisor_id,
      name,
      last_name,
      "DNI",
      phone_number,
      client_type
    from clients
    order by email, advisor_id, created_at desc
  ) cl on cl.email = v.client_email and cl.advisor_id = v.advisor_id
union all
select
  u.tenant,
  'client'::text as source,
  cl.id,
  cl.created_at,
  null::timestamp without time zone as activation_date,
  cl.email as client_email,
  cl.advisor_id,
  u.email as advisor_email,
  cl.name,
  cl.last_name,
  cl."DNI",
  null::text as address,
  cl.phone_number as phone,
  cl.client_type,
  null::text as contract_type,
  null::text as new_company,
  null::text as new_rate_name,
  null::text as new_subrate,
  null::double precision as saving_percentage,
  lc.pdf_invoice,
  null::double precision as total_savings,
  null::text as "CUPS",
  cl.status,
  null::text as subestadocompanias,
  null::timestamp without time zone as last_update,
  null::timestamp without time zone as fecha_baja,
  null::timestamp without time zone as baja_firma_delegada,
  null::timestamp without time zone as firma_date,
  lv.valuation_id,
  lv.valuation_created_at,
  lv.pdf_proposal,
  lc.comparison_id,
  lc.comparison_created_at,
  cl.inactive::boolean as deleted,
  null::text as deleted_reason,
  null::timestamp without time zone as deleted_at,
  null::timestamp without time zone as incident_date,
  null::text as incident_type,
  NULL::public.rate_mode_type as rate_type
from
  clients cl
  left join users u on u.user_id = cl.advisor_id
  left join latest_val lv on lv.client_email = cl.email
  and lv.advisor_id = cl.advisor_id
  left join latest_cmp lc on lc.valuation_id = lv.valuation_id
with no data;

-- Índices para mejorar las búsquedas sobre la vista materializada unificada
CREATE UNIQUE INDEX IF NOT EXISTS mat_all_data_unique_idx ON public.mat_all_data (source, id);
CREATE INDEX IF NOT EXISTS idx_mat_all_data_client_email ON public.mat_all_data (client_email);
CREATE INDEX IF NOT EXISTS idx_mat_all_data_advisor_id ON public.mat_all_data (advisor_id);
CREATE INDEX IF NOT EXISTS idx_mat_all_data_created_at ON public.mat_all_data (created_at DESC);

REFRESH MATERIALIZED VIEW public.mat_all_data;