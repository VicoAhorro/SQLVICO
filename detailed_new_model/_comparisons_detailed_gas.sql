-- DROP VIEW IF EXISTS public._comparisons_detailed_gas;

CREATE OR REPLACE VIEW public._comparisons_detailed_gas AS
WITH
-- ====================== BASE GAS ======================
calculated_prices_gas AS (
  SELECT
    cg.id,
    cg.created_at,
    cg.client_email,
    cg.advisor_id,

    -- Segmento desde tabla comparisons
    cmp.client_type,

    -- Consumos y anual
    cg.consumption                               AS consumption_p1,
    0                                            AS consumption_p2,
    0                                            AS consumption_p3,
    0                                            AS consumption_p4,
    0                                            AS consumption_p5,
    0                                            AS consumption_p6,
    cg.anual_consumption                         AS anual_consumption_p1,
    0                                            AS anual_consumption_p2,
    0                                            AS anual_consumption_p3,
    0                                            AS anual_consumption_p4,
    0                                            AS anual_consumption_p5,
    0                                            AS anual_consumption_p6,

    0                                            AS autoconsumo_precio,

    -- Precios kWh actuales (solo P1 en gas)
    cg."precio actual kw"::real                  AS "precio_kwh_P1",
    0                                            AS "precio_kwh_P2",
    0                                            AS "precio_kwh_P3",
    0                                            AS "precio_kwh_P4",
    0                                            AS "precio_kwh_P5",
    0                                            AS "precio_kwh_P6",

    -- Precio fijo/día actual (asimilado a potencia)
    cg."precio fijo actual dia"                  AS "precio_kw_P1",
    0                                            AS "precio_kw_P2",
    0                                            AS "precio_kw_P3",
    0                                            AS "precio_kw_P4",
    0                                            AS "precio_kw_P5",
    0                                            AS "precio_kw_P6",

    -- Totales base
    cg.consumption                               AS total_consumption,
    cg.anual_consumption                         AS total_anual_consumption,
    0                                            AS power_p1,
    0                                            AS power_p2,
    0                                            AS power_p3,
    0                                            AS power_p4,
    0                                            AS power_p5,
    0                                            AS power_p6,

    cg.current_total_invoice,
    0                                            AS surpluses,
    0                                            AS total_surpluses_price,
    0                                            AS power_surpluses,
    cg."VAT",
    cg.days,
    cg.pdf_invoice,
    cg."CUPS",
    cg.address_id,
    cg.company,
    cg.rate_name,
    cg.invoice_month,
    cg.equipment_rental,
    FALSE                                        AS selfconsumption,
    cg.manual_data,
    0                                            AS reactive,
    cg.valuation_id,
    cg.invoice_year,
    cg.meter_rental,
    cg.preferred_subrate,
    cg.wants_permanence,
    cg.term_month_i_want,
    cg.excluded_company_ids,
    cg.wants_gdo,
    cg.temp_client_phone,
    cg.comparison_id,

    -- Nueva tarifa (cr)
    cr.company                                   AS new_company,
    cr.rate_name                                 AS new_rate_name,
    cr.subrate_name                              AS new_subrate_name,
    cr.term_month,
    cr.price_pp1,
    cr.price_pp2,
    cr.price_pp3,
    cr.price_pp4,
    cr.price_pp5,
    cr.price_pp6,
    cr.price_cp1,
    cr.price_cp2,
    cr.price_cp3,
    cr.price_cp4,
    cr.price_cp5,
    cr.price_cp6,
    cr.price_surpluses,

    -- Cálculos GAS (mensual base nuevo pre-IVA)
    (COALESCE(cg.days::real, 0::real) * COALESCE(cr.price_pp1, 0::real))::double precision AS total_power_price,
    COALESCE(cg.consumption, 0::real) * COALESCE(cr.price_cp1, 0::real)                    AS total_consumption_price,
    COALESCE(cg.days::real, 0::real) * COALESCE(cr.price_pp1, 0::real) +
    COALESCE(cg.consumption, 0::real) * (COALESCE(cr.price_cp1, 0::real) + 0.00234::double precision)
                                                                                           AS new_total_price,

    'gas'::text                                     AS type,
    COALESCE(cg.temp_client_name, ''::text)         AS temp_client_name,
    COALESCE(cg.temp_client_last_name, ''::text)    AS temp_client_last_name,
    ARRAY['gas'::text, 'All'::text]                 AS type_filter,

    cg.deleted,
    cg.deleted_reason,
    cg.deleted_at,
    cr.id                                          AS new_rate_id,
    0                                             AS max_power,
    0                                             AS speed_fiber,
    0                                             AS mobile_lines,
    0                                             AS mobile_total_gb,
    FALSE                                         AS fijo,
    0                                             AS new_speed_fiber,
    0                                             AS new_total_mobile_lines,
    0                                             AS new_mobile_total_gb,
    ''::text                                      AS rate_pack,
    0                                             AS phone_total_anual_price,
    cg.tarifa_plana,
    cg.cif,
    cg.region,
    cr.has_permanence,
    cr.has_gdo,
    cr.rate_mode,
    0                                             AS total_excedentes_precio

  FROM (SELECT * FROM comparison_gas WHERE valuation_id IS NULL AND deleted = false) cg
  LEFT JOIN public.comparisons cmp ON cg.comparison_id = cmp.id
  LEFT JOIN users u 
  ON u.user_id = cg.advisor_id
  LEFT JOIN comparison_rates cr
  ON cr.type = 'gas'
 AND cr.company <> cg.company
 AND (cr.deleted = FALSE)
 AND (cr.tenant_id IS NULL OR u.tenant = ANY(cr.tenant_id))
 AND cr.subrate_name = cg.rate_name
 AND (
      (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
      OR (cr.invoice_month = cg.invoice_month AND cr.invoice_year = cg.invoice_year)
 )
 AND (cr.cif IS NULL OR cr.cif = cg.cif)
 AND (
      cg.preferred_subrate IS NULL
      OR cg.preferred_subrate = ''
      OR cr.subrate_name = cg.rate_name
 )
 AND (
      cg.prefered_rate_type IS NULL 
      OR cr.rate_mode = cg.prefered_rate_type
      OR (cg.prefered_rate_type = 'Indexada' AND cr.rate_mode IS NULL)
      OR NOT EXISTS (
          SELECT 1
          FROM comparison_rates cr2
          WHERE cr2.type = 'gas'
            AND cr2.company <> cg.company
            AND cr2.subrate_name = cg.rate_name
            AND (cr2.deleted = FALSE)
            AND (cr2.tenant_id IS NULL OR u.tenant = ANY(cr2.tenant_id))
            AND (
                 (cr2.invoice_month IS NULL AND cr2.invoice_year IS NULL)
                 OR (cr2.invoice_month = cg.invoice_month AND cr2.invoice_year = cg.invoice_year)
            )
            AND (cr2.cif IS NULL OR cr2.cif = cg.cif)
            AND (
                 cg.preferred_subrate IS NULL
                 OR cg.preferred_subrate = ''
                 OR cr2.subrate_name = cg.rate_name
            )
            AND (
                 cr2.rate_mode = cg.prefered_rate_type
                 OR (cg.prefered_rate_type = 'Indexada' AND cr2.rate_mode IS NULL)
            )
      )
 )
  AND (
       (cg.wants_permanence IS TRUE AND (cr.has_permanence = TRUE OR NOT EXISTS (
        SELECT 1
        FROM comparison_rates crp
        WHERE crp.type = 'gas'
          AND crp.company <> cg.company
          AND crp.subrate_name = cg.rate_name
          AND (
               (crp.invoice_month IS NULL AND crp.invoice_year IS NULL)
               OR (crp.invoice_month = cg.invoice_month AND crp.invoice_year = cg.invoice_year)
          )
          AND (cg.region IS NULL OR cg.region = ANY (crp.region))
          AND (
               cg.preferred_subrate IS NULL
               OR cg.preferred_subrate = ''
               OR crp.subrate_name = cg.rate_name
          )
          AND crp.has_permanence = TRUE
       )))
       OR (cg.wants_permanence IS FALSE AND COALESCE(cr.has_permanence, false) = false)
       OR (cg.wants_permanence IS NULL)
  )
 AND (cg.region IS NULL OR cg.region = ANY (cr.region))
 AND (cg.excluded_company_ids IS NULL OR NOT (cr.company IN (SELECT c_ex.name FROM companies c_ex WHERE c_ex.id = ANY (cg.excluded_company_ids))))

),
unified_calculated_prices AS (
  SELECT * FROM calculated_prices_gas
),
-- ====================== CRS Y FÓRMULAS ======================
unified_extended_prices AS (
  SELECT
    ucp.*,
    crs.id AS crs_id,

    -- CRS total
    COALESCE(ucp.anual_consumption_p1,0::real) * COALESCE(crs.crs_cp1,0::real) +
    COALESCE(ucp.anual_consumption_p2,0::real) * COALESCE(crs.crs_cp2,0::real) +
    COALESCE(ucp.anual_consumption_p3,0::real) * COALESCE(crs.crs_cp3,0::real) +
    COALESCE(ucp.anual_consumption_p4,0::real) * COALESCE(crs.crs_cp4,0::real) +
    COALESCE(ucp.anual_consumption_p5,0::real) * COALESCE(crs.crs_cp5,0::real) +
    COALESCE(ucp.anual_consumption_p6,0::real) * COALESCE(crs.crs_cp6,0::real) +
    COALESCE(ucp.power_p1,0::real) * COALESCE(crs.crs_pp1,0::real) +
    COALESCE(ucp.power_p2,0::real) * COALESCE(crs.crs_pp2,0::real) +
    COALESCE(ucp.power_p3,0::real) * COALESCE(crs.crs_pp3,0::real) +
    COALESCE(ucp.power_p4,0::real) * COALESCE(crs.crs_pp4,0::real) +
    COALESCE(ucp.power_p5,0::real) * COALESCE(crs.crs_pp5,0::real) +
    COALESCE(ucp.power_p6,0::real) * COALESCE(crs.crs_pp6,0::real) +
    COALESCE(crs.fixed_crs,0::real) AS total_crs,

    -- Auxiliares
    v.*,
    sly.savings_yearly
  FROM unified_calculated_prices ucp
  LEFT JOIN comparison_rates_crs crs
    ON crs.comparison_rate_id = ucp.new_rate_id
   AND (crs.min_kw_anual IS NULL OR ucp.total_anual_consumption >= crs.min_kw_anual)
   AND (crs.max_kw_anual IS NULL OR ucp.total_anual_consumption <  crs.max_kw_anual)
   AND (crs.min_power   IS NULL OR ucp.power_p1 >= crs.min_power)
   AND (crs.max_power   IS NULL OR ucp.power_p1 <  crs.max_power)

  CROSS JOIN LATERAL (
    SELECT
      COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real) AS power1_or_1,
      0::real AS p2, 0::real AS p3, 0::real AS p4, 0::real AS p5, 0::real AS p6
  ) pwr

  CROSS JOIN LATERAL (
    SELECT
      COALESCE(ucp.anual_consumption_p1,0::real) * COALESCE(ucp."precio_kwh_P1",0::real) AS annual_new_energy_pre_vat
  ) a1

  CROSS JOIN LATERAL (
    SELECT
      COALESCE(ucp.anual_consumption_p1,0::real) * (COALESCE(ucp.price_cp1,0::real) + 0.00234) AS annual_old_energy_pre_vat
  ) a2

  CROSS JOIN LATERAL (
    SELECT
      (pwr.power1_or_1 * COALESCE(ucp."precio_kw_P1",0::real) * 365::double precision) AS annual_new_power_pre_vat,
      (COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real) * COALESCE(ucp.price_pp1,0::real) * 365::double precision) AS annual_old_power_pre_vat
  ) pwr_year

  CROSS JOIN LATERAL (
    SELECT
      (a1.annual_new_energy_pre_vat + pwr_year.annual_new_power_pre_vat) AS annual_new_pre_vat,
      (a2.annual_old_energy_pre_vat + pwr_year.annual_old_power_pre_vat) AS annual_old_pre_vat
  ) base

  CROSS JOIN LATERAL (
    SELECT
      base.annual_new_pre_vat * (1::double precision + COALESCE(ucp."VAT",0::real)) AS annual_new_with_vat,
      base.annual_old_pre_vat * (1::double precision + COALESCE(ucp."VAT",0::real)) AS annual_old_with_vat,
      (COALESCE(ucp.new_total_price,0::double precision) + COALESCE(ucp.equipment_rental,0)) * (1::double precision + COALESCE(ucp."VAT",0::real)) AS monthly_new_with_vat,
      COALESCE(ucp.current_total_invoice,0) * (365.0 / NULLIF(ucp.days::numeric,0)) AS current_monthly_annualized
  ) v

  CROSS JOIN LATERAL (
    SELECT
      CASE
        WHEN ucp.tarifa_plana = TRUE THEN
          COALESCE(ucp.current_total_invoice,0::real) * (365.0 / NULLIF(ucp.days::numeric,0))::double precision
          - (COALESCE(ucp.anual_consumption_p1,0::real) * (COALESCE(ucp.price_cp1,0::real) + 0.00234) + COALESCE(ucp.price_pp1,0::real) * 365) * (1::double precision + COALESCE(ucp."VAT",0::real))
        WHEN ucp.new_company IS NOT NULL THEN
          v.annual_old_with_vat - v.annual_new_with_vat -- IMPORTANTE: El signo original parece invertido en el SQL base o depende de como se use. Usaremos anual_old - anual_new para ahorro positivo.
        ELSE 0.0::double precision
      END AS savings_yearly
  ) sly
),

-- ====== AHORRO % PARA LOGICA K ======
with_saving_pct AS (
    SELECT
        uep.*,
        CASE
            WHEN uep.tarifa_plana = TRUE AND uep.days > 0 THEN (uep.current_monthly_annualized - uep.annual_new_with_vat) / NULLIF(uep.current_monthly_annualized, 0)
            WHEN uep.new_company IS NOT NULL AND uep.annual_old_with_vat <> 0 THEN (uep.annual_old_with_vat - uep.annual_new_with_vat) / uep.annual_old_with_vat
            ELSE 0.0::double precision
        END AS saving_percentage
    FROM unified_extended_prices uep
),

-- ====== FILTRO NP > Y ======
filtered_np AS (
    SELECT * FROM with_saving_pct
    WHERE (
        -- Gas B2C (Particular): NP > 20
        (COALESCE(client_type::text, 'Particular') = 'Particular' AND total_crs > 20)
        OR
        -- Gas B2B (Empresa): NP > 100
        (client_type::text = 'Empresa' AND total_crs > 100)
    )
),

-- ====================== RANKING ======================
ranked_comparisons AS (
  SELECT
    f.*,
    CASE 
        WHEN f.saving_percentage <= 0.10 THEN 0
        WHEN f.rate_mode = 'Indexada' THEN 500
        ELSE 1000
    END AS k_factor,
    ROW_NUMBER() OVER (
      PARTITION BY f.id
      ORDER BY
        f.savings_yearly + (CASE WHEN f.saving_percentage <= 0.10 THEN 0 WHEN f.rate_mode = 'Indexada' THEN 500 ELSE 1000 END * f.total_crs) DESC
    ) AS rank,
    f.savings_yearly + (CASE WHEN f.saving_percentage <= 0.10 THEN 0 WHEN f.rate_mode = 'Indexada' THEN 500 ELSE 1000 END * f.total_crs) AS ranked_crs
  FROM filtered_np f
)

-- ====================== SELECT FINAL ======================
SELECT
  rc.id, rc.created_at, rc.client_email, rc.advisor_id,
  rc.consumption_p1, rc.consumption_p2, rc.consumption_p3, rc.consumption_p4, rc.consumption_p5, rc.consumption_p6,
  rc.anual_consumption_p1, rc.anual_consumption_p2, rc.anual_consumption_p3, rc.anual_consumption_p4, rc.anual_consumption_p5, rc.anual_consumption_p6,
  rc.autoconsumo_precio,
  rc."precio_kw_P1", rc."precio_kw_P2", rc."precio_kw_P3", rc."precio_kw_P4", rc."precio_kw_P5", rc."precio_kw_P6",
  rc."precio_kwh_P1", rc."precio_kwh_P2", rc."precio_kwh_P3", rc."precio_kwh_P4", rc."precio_kwh_P5", rc."precio_kwh_P6",
  rc.total_consumption, rc.total_anual_consumption, rc.power_p1, rc.power_p2, rc.power_p3, rc.power_p4, rc.power_p5, rc.power_p6,
  rc.current_total_invoice, rc.surpluses, rc.total_surpluses_price, rc.power_surpluses, rc."VAT", rc.days, rc.pdf_invoice, rc."CUPS", rc.address_id, rc.company, rc.rate_name, rc.invoice_month, rc.equipment_rental, rc.selfconsumption, rc.manual_data, rc.reactive, rc.valuation_id, rc.invoice_year, rc.meter_rental, rc.preferred_subrate,
  rc.new_company, rc.new_rate_name, rc.new_subrate_name,
  rc.price_pp1, rc.price_pp2, rc.price_pp3, rc.price_pp4, rc.price_pp5, rc.price_pp6,
  rc.price_cp1, rc.price_cp2, rc.price_cp3, rc.price_cp4, rc.price_cp5, rc.price_cp6,
  rc.price_surpluses, rc.total_power_price, rc.total_consumption_price, rc.new_total_price,
  rc.type, rc.temp_client_name, rc.temp_client_last_name, rc.type_filter, rc.deleted, rc.deleted_reason, rc.deleted_at, rc.new_rate_id, rc.max_power, rc.speed_fiber, rc.mobile_lines, rc.mobile_total_gb, rc.fijo, rc.new_speed_fiber, rc.new_total_mobile_lines, rc.new_mobile_total_gb, rc.rate_pack, rc.phone_total_anual_price,
  rc.crs_id, rc.total_crs, 
  CASE WHEN rc.new_company IS NOT NULL THEN rc.current_total_invoice - rc.monthly_new_with_vat ELSE 0.0::double precision END AS savings,
  rc.savings_yearly, rc.ranked_crs, rc.rank, rc.tarifa_plana, 0.0::double precision AS iee_monthly, 0.0::double precision AS iee,
  (( (COALESCE(rc.days::real, 0) * COALESCE(rc.price_pp1, 0::real)) + (COALESCE(rc.consumption_p1, 0::real) * (COALESCE(rc.price_cp1, 0::real) + 0.00234)) )::double precision + COALESCE(rc.equipment_rental, 0::double precision)) * (1 + COALESCE(rc."VAT", 0::real)) AS new_total_price_with_vat,
  (COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real)) * (1 + COALESCE(rc."VAT", 0::real)) AS new_total_yearly_price_with_vat,
  rc.saving_percentage,
  us.supervisors, COALESCE(rc.temp_client_name, ''::text) AS client_name, COALESCE(rc.temp_client_last_name, ''::text) AS client_last_name, us.email AS advisor_email, us.display_name AS advisor_display_name, ARRAY[COALESCE(us.email,''::text), 'All'] AS advisor_filter,
  EXTRACT(MONTH FROM rc.created_at)::text AS created_month, EXTRACT(YEAR  FROM rc.created_at)::text AS created_year,
  COALESCE(rc."CUPS",'') || ' ' || COALESCE(us.display_name,'') || ' ' || COALESCE(us.email,'') || ' ' || LOWER(COALESCE(rc.client_email,'') || ' ' || COALESCE(rc.company,'') || ' ' || COALESCE(rc.rate_name,'') || ' ' || COALESCE(rc.temp_client_name,'') || ' ' || COALESCE(rc.temp_client_last_name,'')) AS search,
  ARRAY[COALESCE(rc.company,''::text), 'All'] AS company_filter,
  rc.cif, rc.region, 0.0::numeric(8,2) AS daily_maintenance_with_vat, rc.has_permanence, rc.rate_mode, rc.total_excedentes_precio, NULL::rate_mode_type AS rate_i_have, rc.term_month, rc.term_month_i_want, rc.excluded_company_ids, rc.wants_gdo, rc.temp_client_phone, rc.comparison_id, rc.wants_permanence, null::text AS ssaa_preference, null::text AS new_ssaa, rc.has_gdo

FROM ranked_comparisons rc
LEFT JOIN _users_supervisors_all us ON rc.advisor_id = us.user_id
WHERE rc.rank = 1 AND rc.type = 'gas';
