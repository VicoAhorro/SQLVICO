CREATE OR REPLACE VIEW public._comparisons_detailed_insurance AS
SELECT
  cs.id,
  cs.created_at::timestamp without time zone AS created_at,
  cs.client_email,
  cs.advisor_id,

  0::real AS consumption_p1,
  0::real AS consumption_p2,
  0::real AS consumption_p3,
  0::real AS consumption_p4,
  0::real AS consumption_p5,
  0::real AS consumption_p6,

  0::real AS anual_consumption_p1,
  0::real AS anual_consumption_p2,
  0::real AS anual_consumption_p3,
  0::real AS anual_consumption_p4,
  0::real AS anual_consumption_p5,
  0::real AS anual_consumption_p6,

  0::real AS autoconsumo_precio,

  0::real AS "precio_kw_P1",
  0::real AS "precio_kw_P2",
  0::real AS "precio_kw_P3",
  0::real AS "precio_kw_P4",
  0::real AS "precio_kw_P5",
  0::real AS "precio_kw_P6",

  0::real AS "precio_kwh_P1",
  0::real AS "precio_kwh_P2",
  0::real AS "precio_kwh_P3",
  0::real AS "precio_kwh_P4",
  0::real AS "precio_kwh_P5",
  0::real AS "precio_kwh_P6",

  0::real AS total_consumption,
  0::real AS total_anual_consumption,

  0::real AS power_p1,
  0::real AS power_p2,
  0::real AS power_p3,
  0::real AS power_p4,
  0::real AS power_p5,
  0::real AS power_p6,

  COALESCE(cs.current_total_invoice, 0)::numeric AS current_total_invoice,
  0::real AS surpluses,
  0::double precision AS total_surpluses_price,
  0::real AS power_surpluses,
  0::real AS "VAT",
  0::integer AS days,
  cs.pdf_poliza AS pdf_invoice,
  COALESCE(
    cs.quote_result -> 'quote_inputs' ->> 'previousPolicyNumber',
    cs.quote_result -> 'quote_inputs' ->> 'previous_policy_number',
    ''
  )::text AS "CUPS",
  null::uuid AS address_id,
  cs.company,
  COALESCE(it.name, cs.quote_result ->> 'insurance_type_name', 'Seguro')::text AS rate_name,
  null::integer AS invoice_month,
  0::real AS equipment_rental,
  false AS selfconsumption,
  true AS manual_data,
  0::real AS reactive,
  cs.valuation_id,
  null::integer AS invoice_year,
  0::real AS meter_rental,
  null::text AS preferred_subrate,
  cs.new_company,
  cs.new_product_name AS new_rate_name,
  cs.new_product_type AS new_subrate_name,

  0::real AS price_pp1,
  0::real AS price_pp2,
  0::real AS price_pp3,
  0::real AS price_pp4,
  0::real AS price_pp5,
  0::real AS price_pp6,

  0::real AS price_cp1,
  0::real AS price_cp2,
  0::real AS price_cp3,
  0::real AS price_cp4,
  0::real AS price_cp5,
  0::real AS price_cp6,

  0::real AS price_surpluses,
  0::double precision AS total_power_price,
  0::double precision AS total_consumption_price,
  COALESCE(cs.new_annual_price, 0)::double precision AS new_total_price,
  'seguros'::text AS type,
  COALESCE(cs.temp_client_name, ''::text) AS temp_client_name,
  COALESCE(cs.temp_client_last_name, ''::text) AS temp_client_last_name,
  ARRAY['seguros'::text, 'All'::text] AS type_filter,
  COALESCE(cs.deleted, false) AS deleted,
  cs.deleted_reason,
  null::timestamp without time zone AS deleted_at,
  null::uuid AS new_rate_id,
  0::real AS max_power,

  0::integer AS speed_fiber,
  0::integer AS mobile_lines,
  0::integer AS mobile_total_gb,
  false AS fijo,
  0::integer AS new_speed_fiber,
  0::integer AS new_total_mobile_lines,
  0::integer AS new_mobile_total_gb,
  ''::text AS rate_pack,
  0::integer AS phone_total_anual_price,
  null::uuid AS crs_id,
  COALESCE(cs.estimated_saving, 0)::double precision AS total_crs,
  CASE
    WHEN cs.current_total_invoice IS NOT NULL AND cs.new_annual_price IS NOT NULL
      THEN (cs.current_total_invoice - cs.new_annual_price)::double precision / 12::double precision
    WHEN cs.estimated_saving IS NOT NULL
      THEN cs.estimated_saving::double precision / 12::double precision
    ELSE null::double precision
  END AS savings,
  CASE
    WHEN cs.current_total_invoice IS NOT NULL AND cs.new_annual_price IS NOT NULL
      THEN (cs.current_total_invoice - cs.new_annual_price)::double precision
    WHEN cs.estimated_saving IS NOT NULL
      THEN cs.estimated_saving::double precision
    ELSE null::double precision
  END AS savings_yearly,
  null::double precision AS ranked_crs,
  null::integer AS rank,
  false AS tarifa_plana,
  0.0::double precision AS iee_monthly,
  0.0::double precision AS iee,
  COALESCE(cs.new_annual_price, 0)::double precision AS new_total_price_with_vat,
  COALESCE(cs.new_annual_price, 0)::double precision AS new_total_yearly_price_with_vat,
  CASE
    WHEN COALESCE(cs.current_total_invoice, 0) > 0 AND cs.new_annual_price IS NOT NULL
      THEN ((cs.current_total_invoice - cs.new_annual_price)::double precision / cs.current_total_invoice::double precision)
    WHEN COALESCE(cs.current_total_invoice, 0) > 0 AND cs.estimated_saving IS NOT NULL
      THEN (cs.estimated_saving::double precision / cs.current_total_invoice::double precision)
    ELSE 0.0::double precision
  END AS saving_percentage,
  us.supervisors,
  COALESCE(cs.temp_client_name, ''::text) AS client_name,
  COALESCE(cs.temp_client_last_name, ''::text) AS client_last_name,
  us.email AS advisor_email,
  us.display_name AS advisor_display_name,
  ARRAY[COALESCE(us.email, ''::text), 'All'::text] AS advisor_filter,
  EXTRACT(month FROM cs.created_at)::text AS created_month,
  EXTRACT(year FROM cs.created_at)::text AS created_year,
  concat_ws(
    ', '::text,
    cs.client_email,
    COALESCE(cs.quote_result -> 'quote_inputs' ->> 'previousPolicyNumber', cs.quote_result -> 'quote_inputs' ->> 'previous_policy_number', ''),
    COALESCE(it.name, cs.quote_result ->> 'insurance_type_name', 'Seguro')
  ) AS search,
  ARRAY[COALESCE(cs.company, ''::text), 'All'::text] AS company_filter,
  false AS cif,
  null::text AS region,
  0.0::numeric(8, 2) AS daily_maintenance_with_vat,
  false AS has_permanence,
  null::rate_mode_type AS rate_mode,
  0::real AS total_excedentes_precio,
  null::rate_mode_type AS rate_i_have,
  null::integer AS term_month,
  null::integer AS term_month_i_want,
  null::uuid[] AS excluded_company_ids,
  false AS wants_gdo,
  null::text AS temp_client_phone,
  cs.comparison_id,
  false AS wants_permanence,
  null::text AS ssaa_preference,
  null::text AS new_ssaa
FROM public.comparison_seguros cs
LEFT JOIN public.insurance_types it
  ON it.id = cs.insurance_type_id
LEFT JOIN public.users us
  ON us.user_id = cs.advisor_id
WHERE cs.valuation_id IS NULL
  AND COALESCE(cs.deleted, false) = false;
