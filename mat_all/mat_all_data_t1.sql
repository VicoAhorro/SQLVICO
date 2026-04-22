create materialized view public.mat_all_data_t1 as
with
  latest_val as (
    select distinct
      on (
        _valuations_detailed.client_email,
        _valuations_detailed.advisor_id
      ) _valuations_detailed.client_email,
      _valuations_detailed.advisor_id,
      _valuations_detailed.id as valuation_id,
      _valuations_detailed.created_at as valuation_created_at,
      _valuations_detailed.pdf_proposal
    from
      _valuations_detailed
    order by
      _valuations_detailed.client_email,
      _valuations_detailed.advisor_id,
      _valuations_detailed.created_at desc
  ),
  latest_val_by_contract as (
    select distinct
      on (_valuations_detailed.contract_id) _valuations_detailed.contract_id,
      _valuations_detailed.id as valuation_id,
      _valuations_detailed.created_at as valuation_created_at,
      _valuations_detailed.pdf_proposal,
      _valuations_detailed.rate_type
    from
      _valuations_detailed
    where
      _valuations_detailed.contract_id is not null
    order by
      _valuations_detailed.contract_id,
      _valuations_detailed.created_at desc
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
  )
select
  'contract'::text as source,
  c.id,
  c.created_at,
  c.activation_date,
  c.client_email,
  c.advisor_id,
  u.email as advisor_email,
  c.client_name as name,
  c.client_last_name as last_name,
  c."DNI",
  c.client_address as address,
  c.phone_number as phone,
  c.client_type,
  c.contract_type,
  c.new_company,
  c.new_rate as new_rate_name,
  c.new_subrate,
  c.saving_percentage,
  c.pdf_invoice,
  c.total_savings,
  c."CUPS",
  c.status,
  null::text as subestadocompanias,
  c.last_update,
  c.fecha_baja,
  c.baja_firma_delegada,
  c.firma_date,
  lvc.valuation_id,
  lvc.valuation_created_at,
  lvc.pdf_proposal,
  lcc.comparison_id,
  lcc.comparison_created_at,
  c.deleted,
  null::text as deleted_reason,
  null::timestamp without time zone as deleted_at,
  null::timestamp without time zone as incident_date,
  null::text as incident_type,
  lvc.rate_type,
  null::text as rejected_type,
  null::text as proposed_company,
  null::text as proposed_rate_type,
  null::uuid as changed_by,
  u.email as changed_by_email
from
  _contracts_detailed c
  join users u on u.user_id = c.advisor_id
  left join latest_val_by_contract lvc on lvc.contract_id = c.id
  left join latest_cmp lcc on lcc.valuation_id = lvc.valuation_id
where
  u.tenant = 1
union all
select
  'comparison'::text as source,
  c.id,
  c.created_at,
  null::timestamp without time zone as activation_date,
  c.client_email,
  c.advisor_id,
  u.email as advisor_email,
  c.client_name as name,
  c.client_last_name as last_name,
  c."DNI",
  null::text as address,
  c.phone,
  null::text as client_type,
  c.contract_type,
  c.new_company,
  c.new_rate_name,
  c.new_subrate,
  c.saving_percentage,
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
  c.created_at as comparison_created_at,
  c.deleted,
  null::text as deleted_reason,
  null::timestamp without time zone as deleted_at,
  null::timestamp without time zone as incident_date,
  null::text as incident_type,
  null::rate_mode_type as rate_type,
  null::text as rejected_type,
  null::text as proposed_company,
  null::text as proposed_rate_type,
  c.advisor_id as changed_by,
  u.email as changed_by_email
from
  mat_comparisons_historic c
  left join _valuations_detailed v on v.id = c.valuation_id
  left join users u on u.user_id = c.advisor_id
where
  c.tenant = 1
union all
select
  'valuation'::text as source,
  v.id,
  v.created_at,
  null::timestamp without time zone as activation_date,
  v.client_email,
  v.advisor_id,
  u.email as advisor_email,
  v.client_name as name,
  v.client_last_name as last_name,
  v.client_dni as "DNI",
  null::text as address,
  v.client_phone_number as phone,
  null::text as client_type,
  v.contract_type,
  v.new_company,
  v.new_rate as new_rate_name,
  v.new_subrate,
  v.saving_percentage,
  v.pdf_invoice,
  null::double precision as total_savings,
  v."CUPS",
  null::text as status,
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
  null::timestamp without time zone as deleted_at,
  null::timestamp without time zone as incident_date,
  null::text as incident_type,
  v.rate_type,
  null::text as rejected_type,
  null::text as proposed_company,
  null::text as proposed_rate_type,
  v.advisor_id as changed_by,
  u.email as changed_by_email
from
  _valuations_detailed v
  left join users u on u.user_id = v.advisor_id
where
  u.tenant = 1
union all
select
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
  cl.total_savings,
  null::text as "CUPS",
  null::text as status,
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
  null::boolean as deleted,
  null::text as deleted_reason,
  null::timestamp without time zone as deleted_at,
  null::timestamp without time zone as incident_date,
  null::text as incident_type,
  null::rate_mode_type as rate_type,
  null::text as rejected_type,
  null::text as proposed_company,
  null::text as proposed_rate_type,
  cl.advisor_id as changed_by,
  u.email as changed_by_email
from
  _clients_detailed cl
  left join users u on u.user_id = cl.advisor_id
  left join latest_val lv on lv.client_email = cl.email
  and lv.advisor_id = cl.advisor_id
  left join latest_cmp lc on lc.valuation_id = lv.valuation_id
where
  u.tenant = 1
union all
select
  'renewals'::text as source,
  r.id,
  r.created_at,
  r.sign_date as activation_date,
  r.email as client_email,
  r.changed_by as advisor_id,
  u.email as advisor_email,
  r.first_name as name,
  r.last_name as last_name,
  r.document_identity as "DNI",
  null::text as address,
  r.phone,
  r.client_type,
  r.energy_type as contract_type,
  r.proposed_company as new_company,
  r.proposed_rate_type as new_rate_name,
  null::text as new_subrate,
  r.proposed_savings_percentage::double precision as saving_percentage,
  null::text as pdf_invoice,
  r.proposed_savings_yearly::double precision as total_savings,
  r.cups as "CUPS",
  r.status::text as status,
  null::text as subestadocompanias,
  r.updated_at as last_update,
  null::timestamp without time zone as fecha_baja,
  null::timestamp without time zone as baja_firma_delegada,
  r.sign_date as firma_date,
  null::uuid as valuation_id,
  null::timestamp without time zone as valuation_created_at,
  null::text as pdf_proposal,
  null::uuid as comparison_id,
  null::timestamp without time zone as comparison_created_at,
  false as deleted,
  null::text as deleted_reason,
  null::timestamp without time zone as deleted_at,
  null::timestamp without time zone as incident_date,
  null::text as incident_type,
  r.current_rate_type::rate_mode_type as rate_type,
  r.rejected_type,
  r.proposed_company,
  r.proposed_rate_type,
  r.changed_by,
  u.email as changed_by_email
from
  renewals_racc r
  left join users u on u.user_id = r.changed_by
where
  coalesce(u.tenant, 1) = 1;

-- Índices para mat_all_data_t1
CREATE UNIQUE INDEX IF NOT EXISTS mat_all_data_t1_unique_idx ON public.mat_all_data_t1 (source, id);
CREATE INDEX IF NOT EXISTS mat_all_data_t1_cups_idx ON public.mat_all_data_t1 ("CUPS");
CREATE INDEX IF NOT EXISTS mat_all_data_t1_email_idx ON public.mat_all_data_t1 (client_email);
CREATE INDEX IF NOT EXISTS mat_all_data_t1_dni_idx ON public.mat_all_data_t1 ("DNI");
CREATE INDEX IF NOT EXISTS mat_all_data_t1_advisor_idx ON public.mat_all_data_t1 (advisor_id);
CREATE INDEX IF NOT EXISTS mat_all_data_t1_status_idx ON public.mat_all_data_t1 (status);
CREATE INDEX IF NOT EXISTS mat_all_data_t1_created_at_idx ON public.mat_all_data_t1 (created_at DESC);
CREATE INDEX IF NOT EXISTS mat_all_data_t1_valuation_id_idx ON public.mat_all_data_t1 (valuation_id);
