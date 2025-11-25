-- DROP VIEW IF EXISTS public._comparisons_detailed_3_0;

CREATE OR REPLACE VIEW public._comparisons_detailed_3_0 AS
WITH calculated_prices_3_0 AS (
  SELECT
    c30.id,
    c30.created_at,
    c30.client_email,
    c30.advisor_id,

    c30.consumption_p1,
    c30.consumption_p2,
    c30.consumption_p3,
    c30.consumption_p4,
    c30.consumption_p5,
    c30.consumption_p6,

    c30.anual_consumption_p1,
    c30.anual_consumption_p2,
    c30.anual_consumption_p3,
    c30.anual_consumption_p4,
    c30.anual_consumption_p5,
    c30.anual_consumption_p6,

    c30.autoconsumo_precio,

    c30."precio_kw_P1",
    c30."precio_kw_P2",
    c30."precio_kw_P3",
    c30."precio_kw_P4",
    c30."precio_kw_P5",
    c30."precio_kw_P6",

    c30."precio_kwh_P1",
    c30."precio_kwh_P2",
    c30."precio_kwh_P3",
    c30."precio_kwh_P4",
    c30."precio_kwh_P5",
    c30."precio_kwh_P6",

    COALESCE(c30.consumption_p1,0::real)+COALESCE(c30.consumption_p2,0::real)+COALESCE(c30.consumption_p3,0::real)+
    COALESCE(c30.consumption_p4,0::real)+COALESCE(c30.consumption_p5,0::real)+COALESCE(c30.consumption_p6,0::real) AS total_consumption,

    COALESCE(c30.anual_consumption_p1,0::real)+COALESCE(c30.anual_consumption_p2,0::real)+COALESCE(c30.anual_consumption_p3,0::real)+
    COALESCE(c30.anual_consumption_p4,0::real)+COALESCE(c30.anual_consumption_p5,0::real)+COALESCE(c30.anual_consumption_p6,0::real) AS total_anual_consumption,

    c30.power_p1, c30.power_p2, c30.power_p3, c30.power_p4, c30.power_p5, c30.power_p6,

    c30.current_total_invoice,
    c30.surpluses,
    COALESCE(c30.surpluses,0::real)*COALESCE(cr.price_surpluses,0::real) AS total_surpluses_price,
    c30.power_surpluses,
    c30."VAT",
    c30.power_days AS days,
    c30.pdf_invoice,
    c30."CUPS",
    c30.address_id,
    c30.company,
    c30.rate_name,
    c30.invoice_month,
    c30.equipment_rental,
    c30.selfconsumption,
    c30.manual_data,
    c30.reactive,
    c30.valuation_id,
    c30.invoice_year,
    0::real AS meter_rental,
    c30.preferred_subrate,
    c30.rate_i_have,

    cr.company      AS new_company,
    cr.rate_name    AS new_rate_name,
    cr.subrate_name AS new_subrate_name,

    cr.price_pp1, cr.price_pp2, cr.price_pp3, cr.price_pp4, cr.price_pp5, cr.price_pp6,
    cr.price_cp1, cr.price_cp2, cr.price_cp3, cr.price_cp4, cr.price_cp5, cr.price_cp6,
    cr.price_surpluses,
    cr.has_permanence,
    cr.rate_mode,
    0::real as total_excedentes_precio,

-- ================================================================================
-- TOTAL POWER PRICE
-- ================================================================================
  ((COALESCE(c30.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
  ((COALESCE(c30.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
  ((COALESCE(c30.power_p3, 0::real) * COALESCE(cr.price_pp3, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
  ((COALESCE(c30.power_p4, 0::real) * COALESCE(cr.price_pp4, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
  ((COALESCE(c30.power_p5, 0::real) * COALESCE(cr.price_pp5, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
  ((COALESCE(c30.power_p6, 0::real) * COALESCE(cr.price_pp6, 0::real))  * COALESCE(c30.power_days, 0)::double precision) AS total_power_price,
-- ================================================================================
-- TOTAL CONSUMPTION PRICE
-- ================================================================================
    COALESCE(c30.consumption_p1,0::real)*COALESCE(cr.price_cp1,0::real) +
    COALESCE(c30.consumption_p2,0::real)*COALESCE(cr.price_cp2,0::real) +
    COALESCE(c30.consumption_p3,0::real)*COALESCE(cr.price_cp3,0::real) +
    COALESCE(c30.consumption_p4,0::real)*COALESCE(cr.price_cp4,0::real) +
    COALESCE(c30.consumption_p5,0::real)*COALESCE(cr.price_cp5,0::real) +
    COALESCE(c30.consumption_p6,0::real)*COALESCE(cr.price_cp6,0::real) AS total_consumption_price,
-- ================================================================================
-- NEW TOTAL PRICE
-- ================================================================================
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
    ) +
    COALESCE(c30.power_surpluses,0::real)::double precision -
    (COALESCE(c30.surpluses,0::real) * COALESCE(cr.price_surpluses,0::real))::double precision
    AS new_total_price,


    '3_0'::text AS type,

    COALESCE(c30.temp_client_name,'')      AS temp_client_name,
    COALESCE(c30.temp_client_last_name,'') AS temp_client_last_name,
    ARRAY['3_0'::text,'All'::text]         AS type_filter,

    c30.deleted,
    c30.deleted_reason,
    cr.id AS new_rate_id,
    COALESCE(c30.max_power,0) AS max_power,

    0 AS speed_fiber,
    0 AS mobile_lines,
    0 AS mobile_total_gb,
    FALSE AS fijo,
    0 AS new_speed_fiber,
    0 AS new_total_mobile_lines,
    0 AS new_mobile_total_gb,
    ''::text AS rate_pack,
    0 AS phone_total_anual_price,

    FALSE AS tarifa_plana,
    c30.cif,
    c30.region
    
  FROM comparison_3_0 c30
  LEFT JOIN users u
  ON u.user_id = c30.advisor_id
  LEFT JOIN comparison_rates cr
  ON cr.type = '3_0'
    AND cr.company <> c30.company
    AND (cr.deleted = FALSE)
    AND (cr.tenant_id IS NULL OR u.tenant = ANY(cr.tenant_id))
    -- Filtro de mes/año solo si la tarifa es indexada
    AND (
          cr.rate_mode::text <> 'Indexada'
          OR (
              (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
            OR (cr.invoice_month = c30.invoice_month AND cr.invoice_year = c30.invoice_year)
          )
    )
    -- Subrate preferida (si hay)
    AND (
          c30.preferred_subrate IS NULL
          OR c30.preferred_subrate = ''
          OR cr.subrate_name = c30.preferred_subrate
    )
  -- ⬇️ Fallback de permanencia (igual que en GAS):
 AND (
      -- Si NO quiere permanencia → rechazar tarifas con permanencia
      (c30.wants_permanence IS NOT TRUE AND COALESCE(cr.has_permanence, FALSE) = FALSE)
      -- Si SÍ quiere permanencia → aceptar solo con permanencia (o todas si no existe ninguna)
      OR (
           c30.wants_permanence = TRUE
           AND (
                cr.has_permanence = TRUE
                OR NOT EXISTS (
                     SELECT 1
                     FROM comparison_rates crp
                     WHERE crp.type = '3_0'
                       AND crp.company <> c30.company
                       AND (
                            crp.rate_mode::text <> 'Indexada'
                            OR (
                                 (crp.invoice_month IS NULL AND crp.invoice_year IS NULL)
                              OR (crp.invoice_month = c30.invoice_month AND crp.invoice_year = c30.invoice_year)
                            )
                       )
                       AND (
                            c30.preferred_subrate IS NULL
                            OR c30.preferred_subrate = ''
                            OR crp.subrate_name = c30.preferred_subrate
                       )
                       AND (c30.region IS NULL OR c30.region = ANY (crp.region))
                       AND crp.has_permanence = TRUE
                )
           )
      )
 )
 AND (
      cr.cif IS NULL
      OR c30.cif IS NULL
      OR cr.cif = c30.cif
 )
  WHERE (c30.deleted IS NULL OR c30.deleted = FALSE)
    AND (c30.region IS NULL OR c30.region = ANY (cr.region))
),
unified_calculated_prices AS (
  SELECT * FROM calculated_prices_3_0
),
unified_extended_prices AS (
  SELECT
    ucp.*,
    crs.id AS crs_id,

    COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(crs.crs_cp1,0::real) +
    COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(crs.crs_cp2,0::real) +
    COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(crs.crs_cp3,0::real) +
    COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(crs.crs_cp4,0::real) +
    COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(crs.crs_cp5,0::real) +
    COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(crs.crs_cp6,0::real) +
    COALESCE(ucp.power_p1,0::real)*COALESCE(crs.crs_pp1,0::real) +
    COALESCE(ucp.power_p2,0::real)*COALESCE(crs.crs_pp2,0::real) +
    COALESCE(ucp.power_p3,0::real)*COALESCE(crs.crs_pp3,0::real) +
    COALESCE(ucp.power_p4,0::real)*COALESCE(crs.crs_pp4,0::real) +
    COALESCE(ucp.power_p5,0::real)*COALESCE(crs.crs_pp5,0::real) +
    COALESCE(ucp.power_p6,0::real)*COALESCE(crs.crs_pp6,0::real) +
    COALESCE(crs.fixed_crs,0) AS total_crs,

    CASE
      WHEN ucp.new_company IS NOT NULL THEN
        (
          (
            (COALESCE(ucp.anual_consumption_p1,0::real)*COALESCE(ucp."precio_kwh_P1",0::real) +
             COALESCE(ucp.anual_consumption_p2,0::real)*COALESCE(ucp."precio_kwh_P2",0::real) +
             COALESCE(ucp.anual_consumption_p3,0::real)*COALESCE(ucp."precio_kwh_P3",0::real) +
             COALESCE(ucp.anual_consumption_p4,0::real)*COALESCE(ucp."precio_kwh_P4",0::real) +
             COALESCE(ucp.anual_consumption_p5,0::real)*COALESCE(ucp."precio_kwh_P5",0::real) +
             COALESCE(ucp.anual_consumption_p6,0::real)*COALESCE(ucp."precio_kwh_P6",0::real) +
             COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real)*COALESCE(ucp."precio_kw_P1",0::real)*365.0 +
             COALESCE(ucp.power_p2,0::real)*COALESCE(ucp."precio_kw_P2",0::real)*365.0 +
             COALESCE(ucp.power_p3,0::real)*COALESCE(ucp."precio_kw_P3",0::real)*365.0 +
             COALESCE(ucp.power_p4,0::real)*COALESCE(ucp."precio_kw_P4",0::real)*365.0 +
             COALESCE(ucp.power_p5,0::real)*COALESCE(ucp."precio_kw_P5",0::real)*365.0 +
             COALESCE(ucp.power_p6,0::real)*COALESCE(ucp."precio_kw_P6",0::real)*365.0
             - COALESCE(ucp.surpluses,0) * (182.5::double precision / NULLIF(ucp.days::numeric,0)) * COALESCE(ucp.autoconsumo_precio,0)
            )
            * 1.05113
          ) * (1 + COALESCE(ucp."VAT",0))
          -
          (
            COALESCE(ucp.total_consumption_price,0) / NULLIF(ucp.total_consumption,0) * COALESCE(ucp.total_anual_consumption,0) +
            COALESCE(ucp.power_p1,0::real)*COALESCE(ucp.price_pp1,0::real)*365.0 +
            COALESCE(ucp.power_p2,0::real)*COALESCE(ucp.price_pp2,0::real)*365.0 +
            COALESCE(ucp.power_p3,0::real)*COALESCE(ucp.price_pp3,0::real)*365.0 +
            COALESCE(ucp.power_p4,0::real)*COALESCE(ucp.price_pp4,0::real)*365.0 +
            COALESCE(ucp.power_p5,0::real)*COALESCE(ucp.price_pp5,0::real)*365.0 +
            COALESCE(ucp.power_p6,0::real)*COALESCE(ucp.price_pp6,0::real)*365.0
          ) * 1.05113 * (1 + COALESCE(ucp."VAT",0))
        )
      ELSE 0.0
    END AS savings_yearly,

    CASE
      WHEN ucp.new_company IS NOT NULL THEN
        COALESCE(ucp.current_total_invoice,0::real) -
        ((COALESCE(ucp.new_total_price,0::real)::double precision * 1.05113 + COALESCE(ucp.equipment_rental,0::real)) * (1 + COALESCE(ucp."VAT",0::real)))
      ELSE 0.0
    END AS savings
  FROM unified_calculated_prices ucp
  LEFT JOIN comparison_rates_crs crs
    ON crs.comparison_rate_id = ucp.new_rate_id
   AND (crs.min_kw_anual IS NULL OR ucp.total_anual_consumption >= crs.min_kw_anual)
   AND (crs.max_kw_anual IS NULL OR ucp.total_anual_consumption <  crs.max_kw_anual)
   AND (crs.min_power   IS NULL OR ucp.power_p1 >= crs.min_power)
   AND (crs.max_power   IS NULL OR ucp.power_p1 <  crs.max_power)
),
ranked_comparisons AS (
  SELECT
    uep.*,
    CASE
      WHEN uep.new_company IS NOT NULL AND uep.savings_yearly > 0
        THEN uep.savings_yearly + COALESCE(uep.total_crs,0::real) * 4
      ELSE uep.savings_yearly + COALESCE(uep.total_crs,0::real) * 4
    END AS ranked_crs,
    ROW_NUMBER() OVER (
      PARTITION BY uep.id
      ORDER BY
        CASE
          WHEN uep.new_company IS NOT NULL AND uep.savings_yearly > 0
            THEN uep.savings_yearly + COALESCE(uep.total_crs,0::real) * 4
          ELSE uep.savings_yearly + COALESCE(uep.total_crs,0::real) * 4
        END DESC
    ) AS rank
  FROM unified_extended_prices uep
),
all_comparisons_ranked AS (
  SELECT * FROM ranked_comparisons
)

SELECT DISTINCT
  -- ORDEN EXACTO REQUERIDO
  rc.id,
  rc.created_at,
  rc.client_email,
  rc.advisor_id,
  rc.consumption_p1,
  rc.consumption_p2,
  rc.consumption_p3,
  rc.consumption_p4,
  rc.consumption_p5,
  rc.consumption_p6,
  rc.anual_consumption_p1,
  rc.anual_consumption_p2,
  rc.anual_consumption_p3,
  rc.anual_consumption_p4,
  rc.anual_consumption_p5,
  rc.anual_consumption_p6,
  rc.autoconsumo_precio,
  rc."precio_kw_P1",
  rc."precio_kw_P2",
  rc."precio_kw_P3",
  rc."precio_kw_P4",
  rc."precio_kw_P5",
  rc."precio_kw_P6",
  rc."precio_kwh_P1",
  rc."precio_kwh_P2",
  rc."precio_kwh_P3",
  rc."precio_kwh_P4",
  rc."precio_kwh_P5",
  rc."precio_kwh_P6",
  rc.total_consumption,
  rc.total_anual_consumption,
  rc.power_p1,
  rc.power_p2,
  rc.power_p3,
  rc.power_p4,
  rc.power_p5,
  rc.power_p6,
  rc.current_total_invoice,
  rc.surpluses,
  rc.total_surpluses_price,
  rc.power_surpluses,
  rc."VAT",
  rc.days,
  rc.pdf_invoice,
  rc."CUPS",
  rc.address_id,
  rc.company,
  rc.rate_name,
  rc.invoice_month,
  rc.equipment_rental,
  rc.selfconsumption,
  rc.manual_data,
  rc.reactive,
  rc.valuation_id,
  rc.invoice_year,
  rc.meter_rental,
  rc.preferred_subrate,
  rc.new_company,
  rc.new_rate_name,
  rc.new_subrate_name,
  rc.price_pp1,
  rc.price_pp2,
  rc.price_pp3,
  rc.price_pp4,
  rc.price_pp5,
  rc.price_pp6,
  rc.price_cp1,
  rc.price_cp2,
  rc.price_cp3,
  rc.price_cp4,
  rc.price_cp5,
  rc.price_cp6,
  rc.price_surpluses,
  rc.total_power_price,
  rc.total_consumption_price,
  rc.new_total_price,
  rc.type,
  rc.temp_client_name,
  rc.temp_client_last_name,
  rc.type_filter,
  rc.deleted,
  rc.deleted_reason,
  rc.new_rate_id,
  rc.max_power,
  rc.speed_fiber,
  rc.mobile_lines,
  rc.mobile_total_gb,
  rc.fijo,
  rc.new_speed_fiber,
  rc.new_total_mobile_lines,
  rc.new_mobile_total_gb,
  rc.rate_pack,
  rc.phone_total_anual_price,
  rc.crs_id,
  rc.total_crs,
  rc.savings,
  rc.savings_yearly,
  rc.ranked_crs,
  rc.rank,
  rc.tarifa_plana,
-- ================================================================================
-- IEE MONTHLY
-- ================================================================================
  (
    (
        COALESCE(rc.consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) +
        COALESCE(rc.consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) +
        COALESCE(rc.consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) +
        COALESCE(rc.consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) + 
        COALESCE(rc.consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) +
        COALESCE(rc.consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) +
        COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * COALESCE(rc.days, 0)::double precision
      ) * 0.05113::double precision
  ) AS iee_monthly,

  -- iee
  (
    (
      COALESCE(rc.anual_consumption_p1,0::real)*COALESCE(rc.price_cp1,0::real) +
      COALESCE(rc.anual_consumption_p2,0::real)*COALESCE(rc.price_cp2,0::real) +
      COALESCE(rc.anual_consumption_p3,0::real)*COALESCE(rc.price_cp3,0::real) +
      COALESCE(rc.anual_consumption_p4,0::real)*COALESCE(rc.price_cp4,0::real) +
      COALESCE(rc.anual_consumption_p5,0::real)*COALESCE(rc.price_cp5,0::real) +
      COALESCE(rc.anual_consumption_p6,0::real)*COALESCE(rc.price_cp6,0::real) +
      (COALESCE(rc.power_p1,0::real)*COALESCE(rc.price_pp1,0::real) +
       COALESCE(rc.power_p2,0::real)*COALESCE(rc.price_pp2,0::real) +
       COALESCE(rc.power_p3,0::real)*COALESCE(rc.price_pp3,0::real) +
       COALESCE(rc.power_p4,0::real)*COALESCE(rc.price_pp4,0::real) +
       COALESCE(rc.power_p5,0::real)*COALESCE(rc.price_pp5,0::real) +
       COALESCE(rc.power_p6,0::real)*COALESCE(rc.price_pp6,0::real)
      ) * 365::double precision
    ) * 0.05113::double precision
  ) AS iee,

  -- new_total_price_with_vat
  (
    (COALESCE(rc.new_total_price,0::real)::double precision * 1.05113 + COALESCE(rc.equipment_rental,0::real))
    * (1 + COALESCE(rc."VAT",0::real))
  ) AS new_total_price_with_vat,

  -- new_total_yearly_price_with_vat
  -- new_total_yearly_price_with_vat
  (
    (
      COALESCE(rc.anual_consumption_p1,0::real) * COALESCE(rc.price_cp1,0::real) +
      COALESCE(rc.anual_consumption_p2,0::real) * COALESCE(rc.price_cp2,0::real) +
      COALESCE(rc.anual_consumption_p3,0::real) * COALESCE(rc.price_cp3,0::real) +
      COALESCE(rc.anual_consumption_p4,0::real) * COALESCE(rc.price_cp4,0::real) +
      COALESCE(rc.anual_consumption_p5,0::real) * COALESCE(rc.price_cp5,0::real) +
      COALESCE(rc.anual_consumption_p6,0::real) * COALESCE(rc.price_cp6,0::real) +
      COALESCE(rc.power_p1,0::real) * COALESCE(rc.price_pp1,0::real) * 365::double precision +
      COALESCE(rc.power_p2,0::real) * COALESCE(rc.price_pp2,0::real) * 365::double precision +
      COALESCE(rc.power_p3,0::real) * COALESCE(rc.price_pp3,0::real) * 365::double precision +
      COALESCE(rc.power_p4,0::real) * COALESCE(rc.price_pp4,0::real) * 365::double precision +
      COALESCE(rc.power_p5,0::real) * COALESCE(rc.price_pp5,0::real) * 365::double precision +
      COALESCE(rc.power_p6,0::real) * COALESCE(rc.price_pp6,0::real) * 365::double precision
    ) * (1::numeric + 0.05113)::double precision
  ) * (1::double precision + COALESCE(rc."VAT",0::real)) AS new_total_yearly_price_with_vat,

  -- saving_percentage
  (
    (
      (
        COALESCE(rc.anual_consumption_p1,0::real)*COALESCE(rc."precio_kwh_P1",0::real) +
        COALESCE(rc.anual_consumption_p2,0::real)*COALESCE(rc."precio_kwh_P2",0::real) +
        COALESCE(rc.anual_consumption_p3,0::real)*COALESCE(rc."precio_kwh_P3",0::real) +
        COALESCE(rc.anual_consumption_p4,0::real)*COALESCE(rc."precio_kwh_P4",0::real) +
        COALESCE(rc.anual_consumption_p5,0::real)*COALESCE(rc."precio_kwh_P5",0::real) +
        COALESCE(rc.anual_consumption_p6,0::real)*COALESCE(rc."precio_kwh_P6",0::real) +
        COALESCE(NULLIF(rc.power_p1,0::double precision),1::real)*COALESCE(rc."precio_kw_P1",0::real)*365.0 +
        COALESCE(rc.power_p2,0::real)*COALESCE(rc."precio_kw_P2",0::real)*365.0 +
        COALESCE(rc.power_p3,0::real)*COALESCE(rc."precio_kw_P3",0::real)*365.0 +
        COALESCE(rc.power_p4,0::real)*COALESCE(rc."precio_kw_P4",0::real)*365.0 +
        COALESCE(rc.power_p5,0::real)*COALESCE(rc."precio_kw_P5",0::real)*365.0 +
        COALESCE(rc.power_p6,0::real)*COALESCE(rc."precio_kw_P6",0::real)*365.0
        - COALESCE(rc.surpluses,0) * (182.5::double precision / NULLIF(rc.days::numeric,0)) * COALESCE(rc.autoconsumo_precio,0)
      ) * 1.05113 * (1 + COALESCE(rc."VAT",0))
      -
      (
        COALESCE(rc.total_consumption_price,0::real) / NULLIF(rc.total_consumption,0::real) * COALESCE(rc.total_anual_consumption,0::real) +
        COALESCE(rc.power_p1,0::real)*COALESCE(rc.price_pp1,0::real)*365.0 +
        COALESCE(rc.power_p2,0::real)*COALESCE(rc.price_pp2,0::real)*365.0 +
        COALESCE(rc.power_p3,0::real)*COALESCE(rc.price_pp3,0::real)*365.0 +
        COALESCE(rc.power_p4,0::real)*COALESCE(rc.price_pp4,0::real)*365.0 +
        COALESCE(rc.power_p5,0::real)*COALESCE(rc.price_pp5,0::real)*365.0 +
        COALESCE(rc.power_p6,0)*COALESCE(rc.price_pp6,0)*365.0
      ) * 1.05113 * (1 + COALESCE(rc."VAT",0))
    ) / NULLIF(
      (
        COALESCE(rc.anual_consumption_p1,0::real)*COALESCE(rc."precio_kwh_P1",0::real) +
        COALESCE(rc.anual_consumption_p2,0::real)*COALESCE(rc."precio_kwh_P2",0::real) +
        COALESCE(rc.anual_consumption_p3,0::real)*COALESCE(rc."precio_kwh_P3",0::real) +
        COALESCE(rc.anual_consumption_p4,0::real)*COALESCE(rc."precio_kwh_P4",0::real) +
        COALESCE(rc.anual_consumption_p5,0::real)*COALESCE(rc."precio_kwh_P5",0::real) +
        COALESCE(rc.anual_consumption_p6,0::real)*COALESCE(rc."precio_kwh_P6",0::real) +
        COALESCE(NULLIF(rc.power_p1,0::double precision),1::real)*COALESCE(rc."precio_kw_P1",0::real)*365.0 +
        COALESCE(rc.power_p2,0::real)*COALESCE(rc."precio_kw_P2",0::real)*365.0 +
        COALESCE(rc.power_p3,0::real)*COALESCE(rc."precio_kw_P3",0::real)*365.0 +
        COALESCE(rc.power_p4,0::real)*COALESCE(rc."precio_kw_P4",0::real)*365.0 +
        COALESCE(rc.power_p5,0::real)*COALESCE(rc."precio_kw_P5",0::real)*365.0 +
        COALESCE(rc.power_p6,0::real)*COALESCE(rc."precio_kw_P6",0::real)*365.0
        - COALESCE(rc.surpluses,0) * (182.5::double precision / NULLIF(rc.days::numeric,0)) * COALESCE(rc.autoconsumo_precio,0)
      ) * 1.05113 * (1 + COALESCE(rc."VAT",0)),
      0::double precision
    )
  ) AS saving_percentage,

  -- supervisors, client/advisor info, filtros y búsqueda
  us.supervisors,
  COALESCE(rc.temp_client_name,'')      AS client_name,
  COALESCE(rc.temp_client_last_name,'') AS client_last_name,
  u.email                               AS advisor_email,
  u.name                                AS advisor_display_name,
  ARRAY[COALESCE(u.email,''::text),'All'] AS advisor_filter,
  EXTRACT(MONTH FROM rc.created_at)::text AS created_month,
  EXTRACT(YEAR  FROM rc.created_at)::text AS created_year,
  LOWER(
    COALESCE(rc."CUPS",'') || ' ' ||
    COALESCE(rc.client_email,'') || ' ' ||
    COALESCE(rc.company,'') || ' ' ||
    COALESCE(rc.rate_name,'') || ' ' ||
    COALESCE(rc.temp_client_name,'') || ' ' ||
    COALESCE(rc.temp_client_last_name,'')
  ) AS search,
  ARRAY[COALESCE(rc.company,''::text),'All'] AS company_filter,
  rc.cif,
  rc.region,

  0.0::numeric(8,2) AS daily_maintenance_with_vat,
  rc.has_permanence,
  rc.rate_mode,
  rc.total_excedentes_precio,
  rc.rate_i_have

FROM all_comparisons_ranked rc
LEFT JOIN _users_supervisors us ON rc.advisor_id = us.user_id
LEFT JOIN users u               ON u.user_id     = rc.advisor_id
WHERE rc.rank = 1
  AND (rc.deleted IS NULL OR rc.deleted = FALSE);