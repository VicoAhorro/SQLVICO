create or replace view public._contracts_detailed as
with
  -- 1. Pre-agregación de facturas para evitar el GROUP BY masivo en la vista principal
  invoice_stats as (
    select
      "CUPS",
      sum(total_invoice) as total_invoice_cups,
      count(*) as invoice_count
    from
      clients_invoices
    group by
      "CUPS"
  ),
  -- 2. Obtener la última factura de cada CUPS de forma eficiente
  last_invoices as (
    select distinct on ("CUPS")
      "CUPS",
      total_invoice
    from
      clients_invoices
    order by
      "CUPS",
      invoice_year desc,
      invoice_month desc
  )
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
  -- Limpieza de CUPS centralizada
  case
    when length(trim(both from c."CUPS")) = 22 then left(trim(both from c."CUPS"), 20)
    else trim(both from c."CUPS")
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
  -- Usamos la lógica ya calculada en la vista maestra de supervisores
  us.supervisors,
  us.email as advisor_email,
  r.role as advisor_role,
  -- Ahorro calculado a partir de la pre-agregación
  COALESCE((ist.total_invoice_cups * c.saving_percentage), 0)::double precision as total_savings,
  array[c.contract_type, 'All'::text] as contract_type_filter,
  array[c.advisor_id::text, 'All'::text] as advisor_filter,
  array[c.client_address_id::text, 'All'::text] as address_filter,
  cl.name as client_name,
  cl.last_name as client_last_name,
  ca.address as client_address,
  ca.alias as client_address_alias,
  li.total_invoice as last_invoice_amount,
  -- Buscador optimizado
  concat_ws(
    ' ',
    c.id,
    c.client_email,
    c."CUPS",
    us.email,
    cl.name,
    cl.last_name,
    ca.address,
    c.comentario_tarifa
  ) as search,
  to_char(c.created_at, 'MM') as created_month,
  to_char(c.created_at, 'YYYY') as created_year,
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
  COALESCE(us.racc, false) as is_racc,
  c.comentario_tarifa,
  v.notificaciones,
  c.baja_firma_delegada,
  c.firma_date,
  c.deleted,
  (c.activation_date + '1 year'::interval)::date as fecha_prevista_renovacion,
  array[c.new_company, 'All'::text] as new_company_filter,
  c.insurance_type,
  c.cif as is_cif,
  c.region as valuation_region,
  c.is_carga_contrato,
  c.has_permanence,
  cl.apellido_representante,
  c.deleted_at,
  c.deleted_reason
from
  public.clients_contracts c
  left join public.clients cl on c.client_id = cl.id
  -- Usamos la vista maestra optimizada
  left join public._users_supervisors_all us on c.advisor_id = us.user_id
  left join public.users u on c.advisor_id = u.user_id
  left join public.roles r on u.role_id = r.id
  left join public.clients_addresses ca on c.client_address_id = ca.id
  -- Joins con pre-agregaciones
  left join invoice_stats ist on c."CUPS" = ist."CUPS"
  left join last_invoices li on c."CUPS" = li."CUPS"
  left join public.clients_valuations v on v.contract_id = c.id;