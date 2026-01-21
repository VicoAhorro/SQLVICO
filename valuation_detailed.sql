create or replace view public._valuations_detailed as
select distinct
  on (v.id) v.id,
  v.created_at,
  v.client_email,
  v.contract_type,
  v.advisor_id,
  v.pdf_proposal,
  v.status,
  v.proposal_date,
  v.signature,
  v.signature_date,
  v."CUPS",
  v.new_company,
  v.bank_ownership,
  v.saving_percentage,
  v.temp_client_name,
  v.temp_client_last_name,
  v.deleted,
  v.deleted_reason,
  v.contract_id,
  v.pdf_invoice,
  v.temp_account_number,
  v.temp_dni,
  v.crs,
  v.temp_pdf_dni,
  v.temp_mobile_number,
  v.temp_ownership_change,
  v.temp_ownership_change_pdf,
  v.temp_power_change,
  v.temp_power_change_new_value,
  v.temp_paper_invoices,
  v.temp_new_registration,
  v.temp_account_ownership_pdf,
  v.temp_delegated_signature,
  v.temp_delegated_signature_email,
  v.temp_selfconsumption,
  v.max_power,
  v.new_rate,
  v.new_subrate,
  case
    when (
      (
        select
          u2.racc
        from
          users u2
        where
          u2.user_id = v.advisor_id
        limit
          1
      )
    ) = true then (
      select
        array_cat(us.supervisors, array_agg(ur.user_id)) as array_cat
      from
        users_racc ur
    )
    else us.supervisors
  end as supervisors,
  u.email as advisor_email,
  r.role as advisor_role,
  COALESCE(cl.name, v.temp_client_name) as client_name,
  COALESCE(cl.last_name, v.temp_client_last_name) as client_last_name,
  COALESCE(cl."DNI", v.temp_dni) as client_dni,
  COALESCE(cl."DNI_pdf", v.temp_pdf_dni) as client_pdf_dni,
  COALESCE(cl.phone_number, v.temp_mobile_number) as client_phone_number,
  array[v.contract_type, 'All'::text] as contract_type_filter,
  array[v.advisor_id::text, 'All'::text] as advisor_filter,
  concat_ws(
    ' '::text,
    v.client_email,
    v.temp_client_name,
    v.temp_client_last_name,
    v.contract_type,
    u.email,
    r.role,
    v."CUPS",
    cl.name,
    cl.last_name,
    cl."DNI",
    cl.phone_number,
    v.temp_mobile_number
  ) as search,
  to_char(v.created_at, 'MM'::text) as created_month,
  to_char(v.created_at, 'YYYY'::text) as created_year,
  v.idioma,
  array[v.new_company, 'All'::text] as new_company_filter,
  comp.cif,
  comp.region,
  v.notificaciones,
  COALESCE(cr.has_permanence, false) as wants_permanence,
  comp.wants_permanence as original_wants_permanence,
  v.deleted_at,
  v.temp_client_phone
from
  clients_valuations v
  left join _users_supervisors us on v.advisor_id = us.user_id
  left join clients cl on lower(cl.email) = NULLIF(lower(btrim(v.client_email)), ''::text)
  left join lateral (
    select
      c.cif,
      c.region,
      c.wants_permanence,
      c.rate_name
    from
      (
        select
          comparison_light.valuation_id,
          comparison_light.cif,
          comparison_light.region,
          comparison_light.wants_permanence,
          comparison_light.rate_name
        from
          comparison_light
        union
        select
          comparison_gas.valuation_id,
          comparison_gas.cif,
          comparison_gas.region,
          comparison_gas.wants_permanence,
          comparison_gas.rate_name
        from
          comparison_gas
        union
        select
          comparison_3_0.valuation_id,
          comparison_3_0.cif,
          comparison_3_0.region,
          comparison_3_0.wants_permanence,
          comparison_3_0.rate_name
        from
          comparison_3_0
      ) c
    where
      c.valuation_id = v.id
    limit
      1
  ) comp on true
  left join comparison_rates_old cr on comp.rate_name = cr.rate_name
  join users u on v.advisor_id = u.user_id
  join roles r on u.role_id = r.id;