create or replace view public._contracts_detailed as
select
  c.id,
  c.created_at,
  c.business_id,
  c.client_email,
  c.client_id,
  c.advisor_id,
  c.contract_type,
  c.status,
  c.activation_date,
  c.last_update,
  c.payment_date,
  c.firma_date as welcome_date,
  case
    when length(
      TRIM(
        both
        from
          c."CUPS"
      )
    ) = 22 then "left" (
      TRIM(
        both
        from
          c."CUPS"
      ),
      20
    )
    else TRIM(
      both
      from
        c."CUPS"
    )
  end as "CUPS",
  c.saving_percentage,
  c.client_address_id,
  c.selfconsumption,
  c.ownership_change,
  c.ownership_change_pdf,
  c.power_change,
  c.power_change_new_value,
  c.paper_invoices,
  c.new_registration,
  c.account_number,
  c.account_ownership_pdf,
  c.new_company,
  c.in_process_substatus,
  c.incident_reason,
  c.delegated_signature,
  c.delegated_signature_email,
  c.pdf_contract,
  c.max_power,
  c.crs,
  case
    when (
      (
        select
          u2.racc
        from
          users u2
        where
          u2.user_id = c.advisor_id
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
  COALESCE(
    sum(ci.total_invoice * c.saving_percentage)::double precision,
    0::double precision
  ) as total_savings,
  array[c.contract_type, 'All'::text] as contract_type_filter,
  array[c.advisor_id::text, 'All'::text] as advisor_filter,
  array[c.client_address_id::text, 'All'::text] as address_filter,
  cl.name as client_name,
  cl.last_name as client_last_name,
  ca.address as client_address,
  ca.alias as client_address_alias,
  last_invoice.total_invoice as last_invoice_amount,
  concat_ws(
    ' '::text,
    c.id,
    c.created_at,
    c.business_id,
    c.client_email,
    c.client_id,
    c.advisor_id,
    c.contract_type,
    c.status,
    c.activation_date,
    c.last_update,
    c.payment_date,
    c.firma_date,
    case
      when length(
        TRIM(
          both
          from
            c."CUPS"
        )
      ) = 22 then "left" (
        TRIM(
          both
          from
            c."CUPS"
        ),
        20
      )
      else TRIM(
        both
        from
          c."CUPS"
      )
    end,
    u.email,
    us.supervisors,
    r.role,
    c.saving_percentage,
    c.has_permanence,
    cl.name,
    cl.last_name,
    ca.address,
    ca.alias,
    last_invoice.total_invoice,
    c.comentario_tarifa
  ) as search,
  to_char(c.created_at, 'MM'::text) as created_month,
  to_char(c.created_at, 'YYYY'::text) as created_year,
  c.pdf_invoice,
  cl."DNI",
  cl."DNI_pdf",
  cl.dni_repre as cif,
  cl.cif_pdf,
  cl.nombre_representante as business_name,
  cl.client_type,
  cl.phone_number,
  c.new_rate,
  c.new_subrate,
  c.subestadocompanias as subestado_companias,
  c.motivo_rechazo,
  c."contratoreprePDF" as contratorepre_pdf_extra,
  c.payment_date as payment_date_extra,
  c.activation_date as activation_date_extra,
  c.fecha_baja,
  v.created_at as fecha_valuation,
  c.iddocusign as iddocu,
  cl.idioma as client_language,
  u.racc as is_racc,
  c.comentario_tarifa,
  v.notificaciones,
  c.baja_firma_delegada,
  c.firma_date,
  c.deleted,
  (c.activation_date + '1 year'::interval)::date as fecha_prevista_renovacion,
  array[c.new_company, 'All'::text] as new_company_filter,
  c.cif as is_cif,
  c.region as valuation_region,
  c.is_carga_contrato,
  c.has_permanence,
  cl.apellido_representante,
  c.deleted_at,
  c.deleted_reason
from
  clients_contracts c
  left join clients cl on c.client_id = cl.id
  left join _users_supervisors us on c.advisor_id = us.user_id
  left join users u on c.advisor_id = u.user_id
  left join roles r on u.role_id = r.id
  left join clients_addresses ca on c.client_address_id = ca.id
  left join clients_invoices ci on c."CUPS" = ci."CUPS"
  left join lateral (
    select
      ci2.total_invoice
    from
      clients_invoices ci2
    where
      ci2."CUPS" = c."CUPS"
    order by
      ci2.invoice_year desc,
      ci2.invoice_month desc
    limit
      1
  ) last_invoice on true
  left join clients_valuations v on v.contract_id = c.id
group by
  c.id,
  c.created_at,
  c.business_id,
  c.client_email,
  c.client_id,
  c.advisor_id,
  c.contract_type,
  c.status,
  c.activation_date,
  c.last_update,
  c.payment_date,
  c.firma_date,
  c."CUPS",
  u.email,
  us.supervisors,
  r.role,
  c.saving_percentage,
  cl.name,
  cl.last_name,
  ca.address,
  ca.alias,
  last_invoice.total_invoice,
  cl."DNI",
  cl."DNI_pdf",
  cl.dni_repre,
  cl.cif_pdf,
  cl.nombre_representante,
  cl.client_type,
  cl.phone_number,
  c.new_rate,
  c.new_subrate,
  c.subestadocompanias,
  c.motivo_rechazo,
  c."contratoreprePDF",
  c.fecha_baja,
  v.created_at,
  c.iddocusign,
  cl.idioma,
  u.racc,
  c.comentario_tarifa,
  v.notificaciones,
  c.deleted,
  c.has_permanence,
  cl.apellido_representante,
  c.deleted_at,
  c.deleted_reason;