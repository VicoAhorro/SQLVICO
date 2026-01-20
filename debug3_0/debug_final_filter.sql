-- Debug para analizar el filtrado final de la vista _comparisons_detailed_3_0
-- UUID: 5b9f19c9-ce94-4612-b62b-639fb8f21c6d

-- 1. Verificar el rate_i_want de la comparison
SELECT 
    '=== RATE_I_WANT DE LA COMPARISON ===' as info_section,
    c.id,
    c.rate_i_have,
    c.rate_i_want,
    c.preferred_subrate
FROM comparison_3_0 c
WHERE c.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d';

-- 2. Ver todas las rates que llegan al ranking final (sin filtrar por rate_i_want)
SELECT 
    '=== TODAS LAS RATES ANTES DEL FILTRADO FINAL ===' as info_section,
    rc.id,
    rc.new_rate_id,
    rc.new_company,
    rc.new_rate_name,
    rc.rate_mode,
    rc.rank,
    rc.rank_by_mode,
    rc.savings_yearly,
    rc.ranked_crs
FROM (
    -- Simular el proceso completo hasta ranked_comparisons
    WITH calculated_prices_3_0 AS (
      SELECT
        c30.id,
        c30.created_at,
        c30.client_email,
        c30.advisor_id,
        c30.consumption_p1, c30.consumption_p2, c30.consumption_p3, c30.consumption_p4, c30.consumption_p5, c30.consumption_p6,
        c30.anual_consumption_p1, c30.anual_consumption_p2, c30.anual_consumption_p3, c30.anual_consumption_p4, c30.anual_consumption_p5, c30.anual_consumption_p6,
        c30.autoconsumo_precio,
        c30."precio_kw_P1", c30."precio_kw_P2", c30."precio_kw_P3", c30."precio_kw_P4", c30."precio_kw_P5", c30."precio_kw_P6",
        c30."precio_kwh_P1", c30."precio_kwh_P2", c30."precio_kwh_P3", c30."precio_kwh_P4", c30."precio_kwh_P5", c30."precio_kwh_P6",
        COALESCE(c30.consumption_p1,0::real)+COALESCE(c30.consumption_p2,0::real)+COALESCE(c30.consumption_p3,0::real)+
        COALESCE(c30.consumption_p4,0::real)+COALESCE(c30.consumption_p5,0::real)+COALESCE(c30.consumption_p6,0::real) AS total_consumption,
        COALESCE(c30.anual_consumption_p1,0::real)+COALESCE(c30.anual_consumption_p2,0::real)+COALESCE(c30.anual_consumption_p3,0::real)+
        COALESCE(c30.anual_consumption_p4,0::real)+COALESCE(c30.anual_consumption_p5,0::real)+COALESCE(c30.anual_consumption_p6,0::real) AS total_anual_consumption,
        c30.power_p1, c30.power_p2, c30.power_p3, c30.power_p4, c30.power_p5, c30.power_p6,
        c30.current_total_invoice, c30.surpluses, COALESCE(c30.surpluses,0::real)*COALESCE(cr.price_surpluses,0::real) AS total_surpluses_price,
        c30.power_surpluses, c30."VAT", c30.power_days AS days, c30.pdf_invoice, c30."CUPS", c30.address_id, c30.company, c30.rate_name,
        c30.invoice_month, c30.equipment_rental, c30.selfconsumption, c30.manual_data, c30.reactive, c30.valuation_id, c30.invoice_year,
        0::real AS meter_rental, c30.preferred_subrate, c30.rate_i_have, c30.term_month_i_want,
        cr.company AS new_company, cr.rate_name AS new_rate_name, cr.subrate_name AS new_subrate_name, cr.term_month,
        cr.price_pp1, cr.price_pp2, cr.price_pp3, cr.price_pp4, cr.price_pp5, cr.price_pp6,
        cr.price_cp1, cr.price_cp2, cr.price_cp3, cr.price_cp4, cr.price_cp5, cr.price_cp6, cr.price_surpluses,
        cr.has_permanence, cr.rate_mode, 0::real as total_excedentes_precio,
        ((COALESCE(c30.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
        ((COALESCE(c30.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
        ((COALESCE(c30.power_p3, 0::real) * COALESCE(cr.price_pp3, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
        ((COALESCE(c30.power_p4, 0::real) * COALESCE(cr.price_pp4, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
        ((COALESCE(c30.power_p5, 0::real) * COALESCE(cr.price_pp5, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
        ((COALESCE(c30.power_p6, 0::real) * COALESCE(cr.price_pp6, 0::real))  * COALESCE(c30.power_days, 0)::double precision) AS total_power_price,
        COALESCE(c30.consumption_p1,0::numeric)*COALESCE(cr.price_cp1,0::numeric) + COALESCE(c30.consumption_p2,0::numeric)*COALESCE(cr.price_cp2,0::numeric) +
        COALESCE(c30.consumption_p3,0::numeric)*COALESCE(cr.price_cp3,0::numeric) + COALESCE(c30.consumption_p4,0::numeric)*COALESCE(cr.price_cp4,0::numeric) +
        COALESCE(c30.consumption_p5,0::numeric)*COALESCE(cr.price_cp5,0::numeric) + COALESCE(c30.consumption_p6,0::numeric)*COALESCE(cr.price_cp6,0::numeric) AS total_consumption_price,
        (
          (COALESCE(c30.power_p1,0::real) * COALESCE(cr.price_pp1,0::real) * COALESCE(c30.power_days,0))::double precision +
          (COALESCE(c30.power_p2,0::real) * COALESCE(cr.price_pp2,0::real) * COALESCE(c30.power_days,0))::double precision +
          (COALESCE(c30.power_p3,0::real) * COALESCE(cr.price_pp3,0::real) * COALESCE(c30.power_days,0))::double precision +
          (COALESCE(c30.power_p4,0::real) * COALESCE(cr.price_pp4,0::real) * COALESCE(c30.power_days,0))::double precision +
          (COALESCE(c30.power_p5,0::real) * COALESCE(cr.price_pp5,0::real) * COALESCE(c30.power_days,0))::double precision +
          (COALESCE(c30.power_p6,0::real) * COALESCE(cr.price_pp6,0::real) * COALESCE(c30.power_days,0))::double precision
        ) +
        (
          (COALESCE(c30.consumption_p1,0::real) * COALESCE(cr.price_cp1,0::real))::double precision +
          (COALESCE(c30.consumption_p2,0::real) * COALESCE(cr.price_cp2,0::real))::double precision +
          (COALESCE(c30.consumption_p3,0::real) * COALESCE(cr.price_cp3,0::real))::double precision +
          (COALESCE(c30.consumption_p4,0::real) * COALESCE(cr.price_cp4,0::real))::double precision +
          (COALESCE(c30.consumption_p5,0::real) * COALESCE(cr.price_cp5,0::real))::double precision +
          (COALESCE(c30.consumption_p6,0::real) * COALESCE(cr.price_cp6,0::real))::double precision
        ) + COALESCE(c30.power_surpluses,0::real)::double precision -
        (COALESCE(c30.surpluses,0::real) * COALESCE(cr.price_surpluses,0::real))::double precision AS new_total_price,
        '3_0'::text AS type,
        COALESCE(c30.temp_client_name,'') AS temp_client_name, COALESCE(c30.temp_client_last_name,'') AS temp_client_last_name,
        ARRAY['3_0'::text,'All'::text] AS type_filter, c30.deleted, c30.deleted_reason, c30.deleted_at, cr.id AS new_rate_id,
        COALESCE(c30.max_power,0) AS max_power, 0 AS speed_fiber, 0 AS mobile_lines, 0 AS mobile_total_gb, FALSE AS fijo,
        0 AS new_speed_fiber, 0 AS new_total_mobile_lines, 0 AS new_mobile_total_gb, ''::text AS rate_pack, 0 AS phone_total_anual_price,
        FALSE AS tarifa_plana, c30.cif, c30.region
      FROM comparison_3_0 c30
      LEFT JOIN users u ON u.user_id = c30.advisor_id
      LEFT JOIN LATERAL (
        SELECT cr.*
        FROM comparison_rates cr
        WHERE cr.type = '3_0'
          AND (
            (c30.rate_i_have = 'Fija' AND c30.rate_i_want = 'Indexada' AND cr.id = 'febdbb18-8de5-4f2c-982a-ddfe2e18b3c8')
            OR (
              (c30.rate_i_have IS DISTINCT FROM 'Fija' OR cr.rate_mode IS DISTINCT FROM 'Indexada')
              AND cr.company <> c30.company
              AND (cr.deleted = FALSE)
              AND (cr.tenant_id IS NULL OR u.tenant = ANY (cr.tenant_id))
              AND (
                cr.rate_mode::text <> 'Indexada'
                OR (
                  (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
                  OR (cr.invoice_month = c30.invoice_month AND cr.invoice_year = c30.invoice_year)
                )
              )
              AND (
                c30.preferred_subrate IS NULL
                OR c30.preferred_subrate = ''
                OR cr.subrate_name = c30.preferred_subrate
              )
              AND (
                c30.wants_permanence IS NOT TRUE
                OR cr.has_permanence = TRUE
                OR NOT EXISTS (
                  SELECT 1 FROM comparison_rates crp
                  WHERE crp.type = '3_0' AND crp.company <> c30.company
                    AND (
                      crp.rate_mode::text <> 'Indexada'
                      OR (
                        (crp.invoice_month IS NULL AND crp.invoice_year IS NULL)
                        OR (crp.invoice_month = c30.invoice_month AND crp.invoice_year = c30.invoice_year)
                      )
                    )
                    AND (
                      c30.preferred_subrate IS NULL OR c30.preferred_subrate = '' OR crp.subrate_name = c30.preferred_subrate
                    )
                    AND (c30.region IS NULL OR c30.region = ANY (crp.region))
                    AND crp.has_permanence = TRUE
                )
              )
              AND (cr.cif IS NULL OR cr.cif = c30.cif)
              AND (c30.region IS NULL OR c30.region = ANY (cr.region))
            )
          )
      ) cr ON TRUE
      WHERE (c30.deleted IS NULL OR c30.deleted = FALSE)
    ),
    unified_calculated_prices AS (SELECT * FROM calculated_prices_3_0),
    unified_extended_prices AS (
      SELECT
        ucp.*, crs.id AS crs_id, c30_base.rate_i_want,
        COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(crs.crs_cp1,0::real) + COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(crs.crs_cp2,0::real) +
        COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(crs.crs_cp3,0::real) + COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(crs.crs_cp4,0::real) +
        COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(crs.crs_cp5,0::real) + COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(crs.crs_cp6,0::real) +
        COALESCE(ucp.power_p1,0::real)*COALESCE(crs.crs_pp1,0::real) + COALESCE(ucp.power_p2,0::real)*COALESCE(crs.crs_pp2,0::real) +
        COALESCE(ucp.power_p3,0::real)*COALESCE(crs.crs_pp3,0::real) + COALESCE(ucp.power_p4,0::real)*COALESCE(crs.crs_pp4,0::real) +
        COALESCE(ucp.power_p5,0::real)*COALESCE(crs.crs_pp5,0::real) + COALESCE(ucp.power_p6,0::real)*COALESCE(crs.crs_pp6,0::real) +
        COALESCE(crs.fixed_crs,0) AS total_crs,
        CASE
          WHEN ucp.new_company IS NOT NULL THEN
            CASE
              WHEN c30_base.rate_i_have = 'Indexada' AND ucp.rate_mode = 'Indexada' THEN
                (
                  ((COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(ucp."precio_kwh_P1",0::real) + COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(ucp."precio_kwh_P2",0::real) +
                    COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(ucp."precio_kwh_P3",0::real) + COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(ucp."precio_kwh_P4",0::real) +
                    COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(ucp."precio_kwh_P5",0::real) + COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(ucp."precio_kwh_P6",0::real) +
                    COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real)*COALESCE(ucp."precio_kw_P1",0::real)*365.0 + COALESCE(ucp.power_p2,0::real)*COALESCE(ucp."precio_kw_P2",0::real)*365.0 +
                    COALESCE(ucp.power_p3,0::real)*COALESCE(ucp."precio_kw_P3",0::real)*365.0 + COALESCE(ucp.power_p4,0::real)*COALESCE(ucp."precio_kw_P4",0::real)*365.0 +
                    COALESCE(ucp.power_p5,0::real)*COALESCE(ucp."precio_kw_P5",0::real)*365.0 + COALESCE(ucp.power_p6,0::real)*COALESCE(ucp."precio_kw_P6",0::real)*365.0
                    - COALESCE(ucp.surpluses,0) * (182.5::double precision / NULLIF(ucp.days::numeric,0)) * COALESCE(ucp.autoconsumo_precio,0)) * 1.05113
                ) * (1 + COALESCE(ucp."VAT",0)) -
                ((COALESCE(ucp.total_consumption_price,0) / NULLIF(ucp.total_consumption,0) * COALESCE(ucp.total_anual_consumption,0) +
                  COALESCE(ucp.power_p1,0::real)*COALESCE(ucp.price_pp1,0::real)*365.0 + COALESCE(ucp.power_p2,0::real)*COALESCE(ucp.price_pp2,0::real)*365.0 +
                  COALESCE(ucp.power_p3,0::real)*COALESCE(ucp.price_pp3,0::real)*365.0 + COALESCE(ucp.power_p4,0::real)*COALESCE(ucp.price_pp4,0::real)*365.0 +
                  COALESCE(ucp.power_p5,0::real)*COALESCE(ucp.price_pp5,0::real)*365.0 + COALESCE(ucp.power_p6,0::real)*COALESCE(ucp.price_pp6,0::real)*365.0) * 1.05113 * (1 + COALESCE(ucp."VAT",0))
                )
              WHEN c30_base.rate_i_have = 'Fija' AND ucp.rate_mode = 'Fija' THEN
                (
                  ((COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(ucp."precio_kwh_P1",0::real) + COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(ucp."precio_kwh_P2",0::real) +
                    COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(ucp."precio_kwh_P3",0::real) + COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(ucp."precio_kwh_P4",0::real) +
                    COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(ucp."precio_kwh_P5",0::real) + COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(ucp."precio_kwh_P6",0::real) +
                    COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real)*COALESCE(ucp."precio_kw_P1",0::real)*365.0 + COALESCE(ucp.power_p2,0::real)*COALESCE(ucp."precio_kw_P2",0::real)*365.0 +
                    COALESCE(ucp.power_p3,0::real)*COALESCE(ucp."precio_kw_P3",0::real)*365.0 + COALESCE(ucp.power_p4,0::real)*COALESCE(ucp."precio_kw_P4",0::real)*365.0 +
                    COALESCE(ucp.power_p5,0::real)*COALESCE(ucp."precio_kw_P5",0::real)*365.0 + COALESCE(ucp.power_p6,0::real)*COALESCE(ucp."precio_kw_P6",0::real)*365.0
                    - COALESCE(ucp.surpluses,0) * (182.5::double precision / NULLIF(ucp.days::numeric,0)) * COALESCE(ucp.autoconsumo_precio,0)) * 1.05113
                ) * (1 + COALESCE(ucp."VAT",0)) -
                ((COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(ucp.price_cp1,0::real) + COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(ucp.price_cp2,0::real) +
                  COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(ucp.price_cp3,0::real) + COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(ucp.price_cp4,0::real) +
                  COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(ucp.price_cp5,0::real) + COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(ucp.price_cp6,0::real) +
                  COALESCE(ucp.power_p1,0::real)*COALESCE(ucp.price_pp1,0::real)*365.0 + COALESCE(ucp.power_p2,0::real)*COALESCE(ucp.price_pp2,0::real)*365.0 +
                  COALESCE(ucp.power_p3,0::real)*COALESCE(ucp.price_pp3,0::real)*365.0 + COALESCE(ucp.power_p4,0::real)*COALESCE(ucp.price_pp4,0::real)*365.0 +
                  COALESCE(ucp.power_p5,0::real)*COALESCE(ucp.price_pp5,0::real)*365.0 + COALESCE(ucp.power_p6,0::real)*COALESCE(ucp.price_pp6,0::real)*365.0) * 1.05113 * (1 + COALESCE(ucp."VAT",0))
                )
              WHEN c30_base.rate_i_have = 'Indexada' AND ucp.rate_mode = 'Fija' THEN
                (
                  ((COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(ucp."precio_kwh_P1",0::real) + COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(ucp."precio_kwh_P2",0::real) +
                    COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(ucp."precio_kwh_P3",0::real) + COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(ucp."precio_kwh_P4",0::real) +
                    COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(ucp."precio_kwh_P5",0::real) + COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(ucp."precio_kwh_P6",0::real) +
                    COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real)*COALESCE(ucp."precio_kw_P1",0::real)*365.0 + COALESCE(ucp.power_p2,0::real)*COALESCE(ucp."precio_kw_P2",0::real)*365.0 +
                    COALESCE(ucp.power_p3,0::real)*COALESCE(ucp."precio_kw_P3",0::real)*365.0 + COALESCE(ucp.power_p4,0::real)*COALESCE(ucp."precio_kw_P4",0::real)*365.0 +
                    COALESCE(ucp.power_p5,0::real)*COALESCE(ucp."precio_kw_P5",0::real)*365.0 + COALESCE(ucp.power_p6,0::real)*COALESCE(ucp."precio_kw_P6",0::real)*365.0
                    - COALESCE(ucp.surpluses,0) * (182.5::double precision / NULLIF(ucp.days::numeric,0)) * COALESCE(ucp.autoconsumo_precio,0)) * 1.05113
                ) * (1 + COALESCE(ucp."VAT",0)) -
                ((COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(ucp.price_cp1,0::real) + COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(ucp.price_cp2,0::real) +
                  COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(ucp.price_cp3,0::real) + COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(ucp.price_cp4,0::real) +
                  COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(ucp.price_cp5,0::real) + COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(ucp.price_cp6,0::real) +
                  COALESCE(ucp.power_p1,0::real)*COALESCE(ucp.price_pp1,0::real)*365.0 + COALESCE(ucp.power_p2,0::real)*COALESCE(ucp.price_pp2,0::real)*365.0 +
                  COALESCE(ucp.power_p3,0::real)*COALESCE(ucp.price_pp3,0::real)*365.0 + COALESCE(ucp.power_p4,0::real)*COALESCE(ucp.price_pp4,0::real)*365.0 +
                  COALESCE(ucp.power_p5,0::real)*COALESCE(ucp.price_pp5,0::real)*365.0 + COALESCE(ucp.power_p6,0::real)*COALESCE(ucp.price_pp6,0::real)*365.0) * 1.05113 * (1 + COALESCE(ucp."VAT",0))
                )
              WHEN c30_base.rate_i_have = 'Fija' AND ucp.rate_mode = 'Indexada' THEN
                (
                  ((COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(ucp."precio_kwh_P1",0::real) + COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(ucp."precio_kwh_P2",0::real) +
                    COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(ucp."precio_kwh_P3",0::real) + COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(ucp."precio_kwh_P4",0::real) +
                    COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(ucp."precio_kwh_P5",0::real) + COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(ucp."precio_kwh_P6",0::real) +
                    COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real)*COALESCE(ucp."precio_kw_P1",0::real)*365.0 + COALESCE(ucp.power_p2,0::real)*COALESCE(ucp."precio_kw_P2",0::real)*365.0 +
                    COALESCE(ucp.power_p3,0::real)*COALESCE(ucp."precio_kw_P3",0::real)*365.0 + COALESCE(ucp.power_p4,0::real)*COALESCE(ucp."precio_kw_P4",0::real)*365.0 +
                    COALESCE(ucp.power_p5,0::real)*COALESCE(ucp."precio_kw_P5",0::real)*365.0 + COALESCE(ucp.power_p6,0::real)*COALESCE(ucp."precio_kw_P6",0::real)*365.0
                    - COALESCE(ucp.surpluses,0) * (182.5::double precision / NULLIF(ucp.days::numeric,0)) * COALESCE(ucp.autoconsumo_precio,0)) * 1.05113
                ) * (1 + COALESCE(ucp."VAT",0)) -
                ((COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(ucp.price_cp1,0::real) + COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(ucp.price_cp2,0::real) +
                  COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(ucp.price_cp3,0::real) + COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(ucp.price_cp4,0::real) +
                  COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(ucp.price_cp5,0::real) + COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(ucp.price_cp6,0::real) +
                  COALESCE(ucp.power_p1,0::real)*COALESCE(ucp.price_pp1,0::real)*365.0 + COALESCE(ucp.power_p2,0::real)*COALESCE(ucp.price_pp2,0::real)*365.0 +
                  COALESCE(ucp.power_p3,0::real)*COALESCE(ucp.price_pp3,0::real)*365.0 + COALESCE(ucp.power_p4,0::real)*COALESCE(ucp.price_pp4,0::real)*365.0 +
                  COALESCE(ucp.power_p5,0::real)*COALESCE(ucp.price_pp5,0::real)*365.0 + COALESCE(ucp.power_p6,0::real)*COALESCE(ucp.price_pp6,0::real)*365.0) * 1.05113 * (1 + COALESCE(ucp."VAT",0))
                )
              ELSE 0.0
            END
          ELSE 0.0
        END AS savings_yearly,
        CASE
          WHEN ucp.new_company IS NOT NULL THEN
            COALESCE(ucp.current_total_invoice,0::real) - ((COALESCE(ucp.new_total_price,0::real)::double precision * 1.05113 + COALESCE(ucp.equipment_rental,0::real)) * (1 + COALESCE(ucp."VAT",0::real)))
          ELSE 0.0
        END AS savings
      FROM unified_calculated_prices ucp
      LEFT JOIN comparison_3_0 c30_base ON c30_base.id = ucp.id
      LEFT JOIN comparison_rates_crs crs ON crs.comparison_rate_id = ucp.new_rate_id
       AND (crs.min_kw_anual IS NULL OR ucp.total_anual_consumption >= crs.min_kw_anual)
       AND (crs.max_kw_anual IS NULL OR ucp.total_anual_consumption <  crs.max_kw_anual)
       AND (crs.min_power   IS NULL OR ucp.power_p1 >= crs.min_power)
       AND (crs.max_power   IS NULL OR ucp.power_p1 <  crs.max_power)
    ),
    filtered_prices AS (
      SELECT uep.*, u.tenant, c30.wants_permanence, c30.region AS c30_region, c30.cif AS c30_cif
      FROM unified_extended_prices uep
      LEFT JOIN comparison_3_0 c30 ON c30.id = uep.id
      LEFT JOIN users u ON u.user_id = c30.advisor_id
    ),
    ranked_comparisons AS (
      SELECT
        fp.*,
        CASE
          WHEN fp.new_company IS NOT NULL AND fp.savings_yearly > 0
            THEN fp.savings_yearly + COALESCE(fp.total_crs,0::real) * 4
          ELSE fp.savings_yearly + COALESCE(fp.total_crs,0::real) * 4
        END AS ranked_crs,
        ROW_NUMBER() OVER (PARTITION BY fp.id, fp.rate_mode ORDER BY
          CASE
            WHEN fp.new_company IS NOT NULL AND fp.savings_yearly > 0
              THEN fp.savings_yearly + COALESCE(fp.total_crs,0::real) * 4
            ELSE fp.savings_yearly + COALESCE(fp.total_crs,0::real) * 4
          END DESC) AS rank_by_mode,
        ROW_NUMBER() OVER (PARTITION BY fp.id ORDER BY
          CASE
            WHEN fp.new_company IS NOT NULL AND fp.savings_yearly > 0
              THEN fp.savings_yearly + COALESCE(fp.total_crs,0::real) * 4
            ELSE fp.savings_yearly + COALESCE(fp.total_crs,0::real) * 4
          END DESC) AS rank
      FROM filtered_prices fp
    )
    SELECT * FROM ranked_comparisons
) rc
WHERE rc.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'
  AND (rc.deleted IS NULL OR rc.deleted = FALSE)
ORDER BY rc.rank;

-- 3. Aplicar el filtrado final exacto de la vista
SELECT 
    '=== RESULTADO DESPUÉS DEL FILTRADO FINAL ===' as info_section,
    rc.id,
    rc.new_rate_id,
    rc.new_company,
    rc.new_rate_name,
    rc.rate_mode,
    rc.rate_i_want,
    rc.rank,
    rc.rank_by_mode,
    CASE
        WHEN rc.rate_i_want IS NULL AND rc.rank = 1 THEN 'PASA (rate_i_want NULL + rank=1)'
        WHEN rc.rate_i_want = 'Fija' AND rc.rate_mode = 'Fija' AND rc.rank_by_mode = 1 THEN 'PASA (Fija + rank_by_mode=1)'
        WHEN rc.rate_i_want = 'Indexada' AND rc.rate_mode = 'Indexada' AND rc.rank_by_mode = 1 THEN 'PASA (Indexada + rank_by_mode=1)'
        ELSE 'NO PASA'
    END AS filtro_resultado
FROM (
    -- Misma query anterior pero solo el resultado final
    WITH calculated_prices_3_0 AS ( ... ), -- Acá iría toda la lógica anterior
    unified_calculated_prices AS (SELECT * FROM calculated_prices_3_0),
    unified_extended_prices AS ( ... ), -- Acá iría la lógica de extended prices
    filtered_prices AS ( ... ), -- Acá iría filtered prices
    ranked_comparisons AS ( ... ) -- Acá iría ranked comparisons
    SELECT * FROM ranked_comparisons
) rc
WHERE rc.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'
  AND (rc.deleted IS NULL OR rc.deleted = FALSE)
  AND (
    (rc.rate_i_want IS NULL AND rc.rank = 1)
    OR (rc.rate_i_want = 'Fija' AND rc.rate_mode = 'Fija' AND rc.rank_by_mode = 1)
    OR (rc.rate_i_want = 'Indexada' AND rc.rate_mode = 'Indexada' AND rc.rank_by_mode = 1)
  );

-- 4. Verificar si hay alguna valoración para esta comparison
SELECT 
    '=== VERIFICAR VALORACIÓN ===' as info_section,
    v.id,
    v.comparison_id,
    v.status,
    v.created_at,
    v.updated_at
FROM valuations v
WHERE v.comparison_id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d';
