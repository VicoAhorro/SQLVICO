--DROP VIEW IF EXISTS public._comparisons_detailed_phone;

CREATE OR REPLACE VIEW public._comparisons_detailed_phone AS
WITH RECURSIVE
base_rates AS (
  SELECT
    crp.id              AS rate_id,
    crp.company         AS rate_company,
    crp.rate            AS rate_name,
    crp.fibra_mb,
    crp.mobile_lines    AS total_lines,
    crp.total_gb_mobile AS total_gb,
    crp.price           AS total_price,
    crp.anual_price     AS total_anual_price,
    crp.crs             AS total_crs,
    crp.crs_calculation,
    crp.excluded_companies,
    crp.rate            AS rate_pack,
    crp.type            AS rate_type,
    crp.allow_landline
  FROM comparison_rates_phone crp
  WHERE crp.type <> 'Adicional'
),
recursive_combinations AS (
  SELECT * FROM base_rates
  UNION ALL
  SELECT
    rc_1.rate_id,
    rc_1.rate_company,
    rc_1.rate_name,
    rc_1.fibra_mb,
    rc_1.total_lines + al.mobile_lines,
    rc_1.total_gb    + al.total_gb_mobile,
    rc_1.total_price + al.price,
    rc_1.total_anual_price + al.anual_price,
    rc_1.total_crs   + al.crs,
    rc_1.crs_calculation + al.crs_calculation,
    rc_1.excluded_companies,
    concat_ws(', ', rc_1.rate_pack, al.rate) AS rate_pack,
    rc_1.rate_type,
    rc_1.allow_landline
  FROM recursive_combinations rc_1
  JOIN comparison_rates_phone al
    ON al.type = 'Adicional'
   AND al.company = rc_1.rate_company
   AND (al.is_unique = FALSE OR NOT (al.rate = ANY(string_to_array(rc_1.rate_pack, ', '))))
   AND rc_1.total_lines < (SELECT max(cp.mobile_lines + 2) FROM comparison_phone cp)
),
ranked_phone AS (
  SELECT
    cp.id,
    cp.created_at,
    cp.client_email,
    cp.advisor_id,

    -- normalizados (no aplican en phone)
    0 AS consumption_p1, 0 AS consumption_p2, 0 AS consumption_p3, 0 AS consumption_p4, 0 AS consumption_p5, 0 AS consumption_p6,
    0 AS anual_consumption_p1, 0 AS anual_consumption_p2, 0 AS anual_consumption_p3, 0 AS anual_consumption_p4, 0 AS anual_consumption_p5, 0 AS anual_consumption_p6,
    0 AS autoconsumo_precio,
    0 AS "precio_kw_P1", 0 AS "precio_kw_P2", 0 AS "precio_kw_P3", 0 AS "precio_kw_P4", 0 AS "precio_kw_P5", 0 AS "precio_kw_P6",
    0 AS "precio_kwh_P1", 0 AS "precio_kwh_P2", 0 AS "precio_kwh_P3", 0 AS "precio_kwh_P4", 0 AS "precio_kwh_P5", 0 AS "precio_kwh_P6",
    0 AS total_consumption,
    0 AS total_anual_consumption,
    0 AS power_p1, 0 AS power_p2, 0 AS power_p3, 0 AS power_p4, 0 AS power_p5, 0 AS power_p6,

    cp.current_total_invoice,
    0 AS surpluses,
    0 AS total_surpluses_price,
    0 AS power_surpluses,
    0::real AS "VAT",
    0 AS days,
    cp.pdf_invoice,
    ''::text AS cups,
    NULL::uuid AS address_id,
    cp.company,
    ''::text AS rate_name,
    0 AS invoice_month,
    0 AS equipment_rental,
    FALSE AS selfconsumption,
    TRUE  AS manual_data,
    0 AS reactive,
    cp.valuation_id,
    0 AS invoice_year,
    0 AS meter_rental,
    ''::text AS preferred_subrate,

    -- Nueva “tarifa” (pack)
    rc_1.rate_company AS new_company,
    rc_1.rate_name    AS new_rate_name,
    ''::text          AS new_subrate_name,
    0 AS price_pp1, 0 AS price_pp2, 0 AS price_pp3, 0 AS price_pp4, 0 AS price_pp5, 0 AS price_pp6,
    0 AS price_cp1, 0 AS price_cp2, 0 AS price_cp3, 0 AS price_cp4, 0 AS price_cp5, 0 AS price_cp6,
    0 AS price_surpluses,
    0 AS total_power_price,
    0 AS total_consumption_price,

    rc_1.total_price AS new_total_price,
    'phone'::text    AS type,
    COALESCE(cp.temp_client_name,'')      AS temp_client_name,
    COALESCE(cp.temp_client_last_name,'') AS temp_client_last_name,
    ARRAY['phone','All']                  AS type_filter,
    cp.deleted,
    cp.deleted_reason,
    rc_1.rate_id     AS new_rate_id,
    0 AS max_power,

    -- datos telco
    cp.speed_fiber,
    cp.mobile_lines,
    cp.mobile_total_gb,
    cp.landline        AS fijo,
    rc_1.fibra_mb      AS new_speed_fiber,
    rc_1.total_lines   AS new_total_mobile_lines,
    rc_1.total_gb      AS new_mobile_total_gb,
    rc_1.rate_pack     AS rate_pack,
    rc_1.total_anual_price AS phone_total_anual_price,

    -- CRS / ahorro
    rc_1.rate_id AS crs_id,
    rc_1.total_crs,
    (cp.current_total_invoice::double precision - rc_1.total_price)            AS savings,
    ((cp.current_total_invoice*12)::double precision - rc_1.total_anual_price) AS savings_yearly,

    ((cp.current_total_invoice*12)::double precision - rc_1.total_anual_price) + rc_1.total_crs*4 AS ranked_crs,
    ROW_NUMBER() OVER (
      PARTITION BY cp.id
      ORDER BY ((cp.current_total_invoice*12)::double precision - rc_1.total_anual_price) + rc_1.total_crs*4 DESC
    ) AS rank
  FROM comparison_phone cp
  JOIN recursive_combinations rc_1
    ON rc_1.fibra_mb   >= cp.speed_fiber
   AND rc_1.total_lines BETWEEN cp.mobile_lines AND (cp.mobile_lines + 2)
   AND rc_1.rate_type   = cp.rate_type
   AND rc_1.total_gb   >= cp.mobile_total_gb
   AND (rc_1.excluded_companies IS NULL
        OR NOT EXISTS (
          SELECT 1
          FROM unnest(rc_1.excluded_companies) ex(ex)
          WHERE ex.ex = cp.company
        ))
   AND (cp.landline = FALSE OR rc_1.allow_landline = TRUE)
   AND (cp.deleted IS NULL OR cp.deleted = FALSE)
)

SELECT DISTINCT
  -- ORDEN EXACTO
  rp.id,
  rp.created_at,
  rp.client_email,
  rp.advisor_id,
  rp.consumption_p1,
  rp.consumption_p2,
  rp.consumption_p3,
  rp.consumption_p4,
  rp.consumption_p5,
  rp.consumption_p6,
  rp.anual_consumption_p1,
  rp.anual_consumption_p2,
  rp.anual_consumption_p3,
  rp.anual_consumption_p4,
  rp.anual_consumption_p5,
  rp.anual_consumption_p6,
  rp.autoconsumo_precio,
  rp."precio_kw_P1",
  rp."precio_kw_P2",
  rp."precio_kw_P3",
  rp."precio_kw_P4",
  rp."precio_kw_P5",
  rp."precio_kw_P6",
  rp."precio_kwh_P1",
  rp."precio_kwh_P2",
  rp."precio_kwh_P3",
  rp."precio_kwh_P4",
  rp."precio_kwh_P5",
  rp."precio_kwh_P6",
  rp.total_consumption,
  rp.total_anual_consumption,
  rp.power_p1,
  rp.power_p2,
  rp.power_p3,
  rp.power_p4,
  rp.power_p5,
  rp.power_p6,
  rp.current_total_invoice,
  rp.surpluses,
  rp.total_surpluses_price,
  rp.power_surpluses,
  rp."VAT",
  rp.days,
  rp.pdf_invoice,
  rp.cups AS "CUPS",
  rp.address_id,
  rp.company,
  rp.rate_name,
  rp.invoice_month,
  rp.equipment_rental,
  rp.selfconsumption,
  rp.manual_data,
  rp.reactive,
  rp.valuation_id,
  rp.invoice_year,
  rp.meter_rental,
  rp.preferred_subrate,
  rp.new_company,
  rp.new_rate_name,
  rp.new_subrate_name,
  rp.price_pp1,
  rp.price_pp2,
  rp.price_pp3,
  rp.price_pp4,
  rp.price_pp5,
  rp.price_pp6,
  rp.price_cp1,
  rp.price_cp2,
  rp.price_cp3,
  rp.price_cp4,
  rp.price_cp5,
  rp.price_cp6,
  rp.price_surpluses,
  rp.total_power_price,
  rp.total_consumption_price,
  rp.new_total_price,
  rp.type,
  rp.temp_client_name,
  rp.temp_client_last_name,
  rp.type_filter,
  rp.deleted,
  rp.deleted_reason,
  rp.new_rate_id,
  rp.max_power,
  rp.speed_fiber,
  rp.mobile_lines,
  rp.mobile_total_gb,
  rp.fijo,
  rp.new_speed_fiber,
  rp.new_total_mobile_lines,
  rp.new_mobile_total_gb,
  rp.rate_pack,
  rp.phone_total_anual_price,
  rp.crs_id,
  rp.total_crs,
  rp.savings,
  rp.savings_yearly,
  rp.ranked_crs,
  rp.rank,
  FALSE AS tarifa_plana,
  0.0::double precision AS iee_monthly,
  0.0::double precision AS iee,
  rp.new_total_price AS new_total_price_with_vat,
  COALESCE(rp.phone_total_anual_price, (rp.new_total_price*12)::double precision)
    AS new_total_yearly_price_with_vat,
  CASE
    WHEN rp.current_total_invoice > 0
      THEN (rp.current_total_invoice*12 - COALESCE(rp.phone_total_anual_price,0)::double precision)
           / NULLIF(rp.current_total_invoice*12,0)::double precision
    ELSE 0.0
  END AS saving_percentage,
  us.supervisors,
  COALESCE(rp.temp_client_name,'')      AS client_name,
  COALESCE(rp.temp_client_last_name,'') AS client_last_name,
  u.email                               AS advisor_email,
  u.name                        AS advisor_display_name,
  ARRAY[COALESCE(u.email,''::text),'All'] AS advisor_filter,
  EXTRACT(MONTH FROM rp.created_at)::text AS created_month,
  EXTRACT(YEAR  FROM rp.created_at)::text AS created_year,
  concat_ws(', ', rp.client_email, rp.cups) AS search,
  ARRAY[rp.company, 'All'] AS company_filter,
  FALSE AS cif,       
  NULL::text AS region,  -- texto (si en las otras es text),

    -- NUEVO: Al final del SELECT
  0.0::numeric(8,2) AS daily_maintenance_with_vat,
  false as has_permanence
  
FROM ranked_phone rp
LEFT JOIN _users_supervisors us ON rp.advisor_id = us.user_id
LEFT JOIN users u               ON u.user_id     = rp.advisor_id
WHERE rp.rank = 1
  AND (rp.deleted IS NULL OR rp.deleted = FALSE);