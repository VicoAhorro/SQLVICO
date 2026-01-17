-- Nota: Postgres no permite cambiar la query de una materialized view "in-place".
-- Este script la reconstruye con un swap usando ALTER MATERIALIZED VIEW (sin dropear la MV actual).
-- Ojo: si tienes otras vistas que dependen de esta MV por OID, el swap por rename NO las redirige automáticamente.

drop materialized view if exists public.mat_comparisons_historic;

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
  coalesce(nullif(b.temp_client_name, ''), v.client_name) as client_name,
  coalesce(nullif(b.temp_client_last_name, ''), v.client_last_name) as client_last_name,
  v.client_dni as "DNI",
  v.client_phone_number as phone,
  v.contract_type,
  v.new_company,
  v.new_rate as new_rate_name,
  v.new_subrate,
  v.saving_percentage,
  coalesce(nullif(b."CUPS", ''), v."CUPS") as "CUPS",
  b.pdf_invoice,
  b.source,
  b.deleted,
  b.deleted_reason,
  b.deleted_at
from
  base b
  left join _valuations_detailed v on v.id = b.valuation_id
  left join users u on u.user_id = coalesce(b.advisor_id, v.advisor_id)
with no data;

refresh materialized view public.mat_comparisons_historic__new;

do $$
begin
  if to_regclass('public.mat_comparisons_historic__old') is not null then
    execute 'drop materialized view public.mat_comparisons_historic__old';
  end if;

  if to_regclass('public.mat_comparisons_historic') is not null then
    execute 'alter materialized view public.mat_comparisons_historic rename to mat_comparisons_historic__old';
  end if;

  execute 'alter materialized view public.mat_comparisons_historic__new rename to mat_comparisons_historic';
end $$;
