create materialized view public.mat_comparisons_historic as
with
  base as (
    select
      cl.id,
      cl.created_at,
      cl.valuation_id,
      cl.pdf_invoice,
      'light'::text as source,
      cl.deleted,
      cl.deleted_reason
    from
      comparison_light cl
    union all
    select
      c30.id,
      c30.created_at,
      c30.valuation_id,
      c30.pdf_invoice,
      '3_0'::text as source,
      c30.deleted
      c30.deleted_reason
    from
      comparison_3_0 c30
    union all
    select
      cg.id,
      cg.created_at,
      cg.valuation_id,
      cg.pdf_invoice,
      'gas'::text as source,
      cg.deleted
      cg.deleted_reason
    from
      comparison_gas cg
    union all
    select
      cp.id,
      cp.created_at::timestamp without time zone as created_at,
      cp.valuation_id,
      cp.pdf_invoice,
      'phone'::text as source,
      cp.deleted
      cp.deleted_reason
    from
      comparison_phone cp
  )
select
  b.id,
  b.created_at,
  b.valuation_id,
  v.client_email,
  v.advisor_id,
  u.tenant,
  v.client_name,
  v.client_last_name,
  v.client_dni as "DNI",
  v.client_phone_number as phone,
  v.contract_type,
  v.new_company,
  v.new_rate as new_rate_name,
  v.new_subrate,
  v.saving_percentage,
  v."CUPS",
  b.pdf_invoice,
  b.source,
  b.deleted
  b.deleted_reason
from
  base b
  left join _valuations_detailed v on v.id = b.valuation_id
  left join users u on u.user_id = v.advisor_id;