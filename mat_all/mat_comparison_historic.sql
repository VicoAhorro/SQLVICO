drop materialized view if exists public.mat_comparisons_historic cascade;

create materialized view public.mat_comparisons_historic as
with
  base as (
    select
      cl.id,
      cl.created_at,
      cl.valuation_id,
      cl.client_email,
      cl.advisor_id,
      cl.temp_client_name,
      cl.temp_client_last_name,
      cl.temp_client_phone,
      cl."CUPS",
      cl.pdf_invoice,
      'light'::text as source,
      cl.deleted,
      cl.deleted_reason,
      cl.deleted_at
    from
      comparison_light cl
    union all
    select
      c30.id,
      c30.created_at,
      c30.valuation_id,
      c30.client_email,
      c30.advisor_id,
      c30.temp_client_name,
      c30.temp_client_last_name,
      c30.temp_client_phone,
      c30."CUPS",
      c30.pdf_invoice,
      '3_0'::text as source,
      c30.deleted,
      c30.deleted_reason,
      c30.deleted_at
    from
      comparison_3_0 c30
    union all
    select
      cg.id,
      cg.created_at,
      cg.valuation_id,
      cg.client_email,
      cg.advisor_id,
      cg.temp_client_name,
      cg.temp_client_last_name,
      cg.temp_client_phone,
      cg."CUPS",
      cg.pdf_invoice,
      'gas'::text as source,
      cg.deleted,
      cg.deleted_reason,
      cg.deleted_at
    from
      comparison_gas cg
    union all
    select
      cp.id,
      cp.created_at::timestamp without time zone as created_at,
      cp.valuation_id,
      cp.client_email,
      cp.advisor_id,
      cp.temp_client_name,
      cp.temp_client_last_name,
      cp.temp_client_phone,
      NULL as "CUPS",
      cp.pdf_invoice,
      'phone'::text as source,
      cp.deleted,
      cp.deleted_reason,
      cp.deleted_at
    from
      comparison_phone cp
  )
select
  b.id,
  b.created_at,
  b.valuation_id,
  coalesce(nullif(b.client_email, ''), v.client_email) as client_email,
  coalesce(b.advisor_id, v.advisor_id) as advisor_id,
  u.tenant,
  coalesce(nullif(b.temp_client_name, ''), cl.name, v.temp_client_name) as client_name,
  coalesce(nullif(b.temp_client_last_name, ''), cl.last_name, v.temp_client_last_name) as client_last_name,
  coalesce(cl."DNI", v.temp_dni) as "DNI",
  coalesce(nullif(b.temp_client_phone, ''), cl.phone_number, v.temp_mobile_number) as phone,
  v.contract_type,
  v.new_company,
  v.new_rate as new_rate_name,
  v.new_subrate,
  v.saving_percentage,
  coalesce(nullif(b."CUPS", ''), v."CUPS") as "CUPS",
  b.pdf_invoice,
  b.temp_client_phone,
  b.source,
  b.deleted,
  b.deleted_reason,
  b.deleted_at
from
  base b
  left join clients_valuations v on v.id = b.valuation_id
  left join (
    select distinct on (email, advisor_id)
      email,
      advisor_id,
      name,
      last_name,
      "DNI",
      phone_number
    from clients
    order by email, advisor_id, created_at desc
  ) cl on cl.email = v.client_email and cl.advisor_id = v.advisor_id
  left join users u on u.user_id = coalesce(b.advisor_id, v.advisor_id)
with no data;

-- Índices esenciales para el rendimiento de mat_all_data
CREATE UNIQUE INDEX IF NOT EXISTS idx_mat_comparisons_historic_id ON public.mat_comparisons_historic (id);
create index if not exists idx_mat_comparisons_historic_valuation_id on public.mat_comparisons_historic (valuation_id);
create index if not exists idx_mat_comparisons_historic_created_at on public.mat_comparisons_historic (valuation_id, created_at desc);

refresh materialized view public.mat_comparisons_historic;