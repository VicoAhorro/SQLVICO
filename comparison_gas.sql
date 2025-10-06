DROP VIEW IF EXISTS public._comparisons_detailed_gas;

CREATE OR REPLACE VIEW public._comparisons_detailed_gas AS
WITH
-- ====================== BASE GAS ======================
calculated_prices_gas AS (
  SELECT
    cg.id,
    cg.created_at,
    cg.client_email,
    cg.advisor_id,

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

    -- Nueva tarifa (cr)
    cr.company                                   AS new_company,
    cr.rate_name                                 AS new_rate_name,
    cr.subrate_name                              AS new_subrate_name,
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
    cr.has_permanence
  FROM comparison_gas cg
  LEFT JOIN comparison_rates cr
    ON cr.type = 'gas'
   AND cr.company <> cg.company
   AND cr.subrate_name = cg.rate_name
   AND (
        (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
        OR (cr.invoice_month = cg.invoice_month AND cr.invoice_year = cg.invoice_year)
   )
   AND (
        cg.preferred_subrate IS NULL
        OR cg.preferred_subrate = ''
        OR cr.subrate_name = cg.rate_name
   )
  WHERE (cg.deleted IS NULL OR cg.deleted = FALSE)
    AND (cg.region IS NULL OR cg.region = ANY (cr.region))
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
      COALESCE(ucp.power_p2,0::real) AS p2,
      COALESCE(ucp.power_p3,0::real) AS p3,
      COALESCE(ucp.power_p4,0::real) AS p4,
      COALESCE(ucp.power_p5,0::real) AS p5,
      COALESCE(ucp.power_p6,0::real) AS p6
  ) pwr

  CROSS JOIN LATERAL (
    SELECT
      COALESCE(ucp.anual_consumption_p1,0::real) * COALESCE(ucp."precio_kwh_P1",0::real) +
      COALESCE(ucp.anual_consumption_p2,0::real) * COALESCE(ucp."precio_kwh_P2",0::real) +
      COALESCE(ucp.anual_consumption_p3,0::real) * COALESCE(ucp."precio_kwh_P3",0::real) +
      COALESCE(ucp.anual_consumption_p4,0::real) * COALESCE(ucp."precio_kwh_P4",0::real) +
      COALESCE(ucp.anual_consumption_p5,0::real) * COALESCE(ucp."precio_kwh_P5",0::real) +
      COALESCE(ucp.anual_consumption_p6,0::real) * COALESCE(ucp."precio_kwh_P6",0::real)
      AS annual_new_energy_pre_vat
  ) a1

  CROSS JOIN LATERAL (
    SELECT
      COALESCE(ucp.anual_consumption_p1,0::real) * COALESCE(ucp.price_cp1,0::real) +
      COALESCE(ucp.anual_consumption_p2,0::real) * COALESCE(ucp.price_cp2,0::real) +
      COALESCE(ucp.anual_consumption_p3,0::real) * COALESCE(ucp.price_cp3,0::real) +
      COALESCE(ucp.anual_consumption_p4,0::real) * COALESCE(ucp.price_cp4,0::real) +
      COALESCE(ucp.anual_consumption_p5,0::real) * COALESCE(ucp.price_cp5,0::real) +
      COALESCE(ucp.anual_consumption_p6,0::real) * COALESCE(ucp.price_cp6,0::real)
      AS annual_old_energy_pre_vat
  ) a2

  CROSS JOIN LATERAL (
    SELECT
      (pwr.power1_or_1 * COALESCE(ucp."precio_kw_P1",0::real) * 365::double precision) +
      (pwr.p2           * COALESCE(ucp."precio_kw_P2",0::real) * 365::double precision) +
      (pwr.p3           * COALESCE(ucp."precio_kw_P3",0::real) * 365::double precision) +
      (pwr.p4           * COALESCE(ucp."precio_kw_P4",0::real) * 365::double precision) +
      (pwr.p5           * COALESCE(ucp."precio_kw_P5",0::real) * 365::double precision) +
      (pwr.p6           * COALESCE(ucp."precio_kw_P6",0::real) * 365::double precision)
      AS annual_new_power_pre_vat,

      (COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real) * COALESCE(ucp.price_pp1,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p2,0::real) * COALESCE(ucp.price_pp2,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p3,0::real) * COALESCE(ucp.price_pp3,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p4,0::real) * COALESCE(ucp.price_pp4,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p5,0::real) * COALESCE(ucp.price_pp5,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p6,0::real) * COALESCE(ucp.price_pp6,0::real) * 365::double precision)
      AS annual_old_power_pre_vat
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

      -- Mensual nuevo con IVA
      (COALESCE(ucp.new_total_price,0::double precision) + COALESCE(ucp.equipment_rental,0))
        * (1::double precision + COALESCE(ucp."VAT",0::real)) AS monthly_new_with_vat,

      -- Actual mensual anualizado (tarifa plana)
      COALESCE(ucp.current_total_invoice,0) * (365.0 / NULLIF(ucp.days::numeric,0)) AS current_monthly_annualized
  ) v

  CROSS JOIN LATERAL (
    SELECT
      CASE
        WHEN ucp.tarifa_plana = TRUE THEN
          COALESCE(ucp.current_total_invoice,0::real) * (365.0 / NULLIF(ucp.days::numeric,0))::double precision
          -
          (
            COALESCE(ucp.anual_consumption_p1,0::real) * (COALESCE(ucp.price_cp1,0::real) + 0.00234)
            + COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real) * COALESCE(ucp.price_pp1,0::real) * 365::double precision
            + COALESCE(NULLIF(ucp.power_p2,0::double precision),1::real) * COALESCE(ucp.price_pp2,0::real) * 365::double precision
          )
          * (1::double precision + COALESCE(ucp."VAT",0::real))

        WHEN ucp.new_company IS NOT NULL THEN
          v.annual_new_with_vat - v.annual_old_with_vat
        ELSE 0.0::double precision
      END AS savings_yearly
  ) sly
),
-- ====================== RANKING ======================
ranked_comparisons AS (
  SELECT
    uep.*,
    CASE
      WHEN uep.new_company IS NOT NULL AND uep.savings_yearly > 0 THEN
        uep.savings_yearly + COALESCE(uep.total_crs,0) * 4::double precision
      ELSE uep.savings_yearly + COALESCE(uep.total_crs,0) * 4::double precision
    END AS ranked_crs,
    ROW_NUMBER() OVER (
      PARTITION BY uep.id
      ORDER BY
        CASE
          WHEN uep.new_company IS NOT NULL AND uep.savings_yearly > 0 THEN
            uep.savings_yearly + COALESCE(uep.total_crs,0) * 4::double precision
          ELSE uep.savings_yearly + COALESCE(uep.total_crs,0) * 4::double precision
        END DESC
    ) AS rank
  FROM unified_extended_prices uep
),
all_comparisons_ranked AS (
  SELECT * FROM ranked_comparisons
)

-- ====================== SELECT FINAL (orden exacto de columnas) ======================
SELECT
  -- (1) Basales + consumos
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

  -- (2) Precios potencia
  rc."precio_kw_P1",
  rc."precio_kw_P2",
  rc."precio_kw_P3",
  rc."precio_kw_P4",
  rc."precio_kw_P5",
  rc."precio_kw_P6",

  -- (3) Precios energía
  rc."precio_kwh_P1",
  rc."precio_kwh_P2",
  rc."precio_kwh_P3",
  rc."precio_kwh_P4",
  rc."precio_kwh_P5",
  rc."precio_kwh_P6",

  -- (4) Totales y potencias
  rc.total_consumption,
  rc.total_anual_consumption,
  rc.power_p1,
  rc.power_p2,
  rc.power_p3,
  rc.power_p4,
  rc.power_p5,
  rc.power_p6,

  -- (5) Facturación actual y excedentes
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

  -- (6) Nueva tarifa
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

  -- (7) Metas / filtros / flags
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

  -- (8) CRS / ahorros / ranking
  rc.crs_id,
  rc.total_crs,
  -- savings (mensual) para GAS:
  CASE
    WHEN rc.new_company IS NOT NULL THEN COALESCE(rc.current_total_invoice,0) - rc.monthly_new_with_vat
    ELSE 0.0::double precision
  END AS savings,
  rc.savings_yearly,
  rc.ranked_crs,
  rc.rank,
  rc.tarifa_plana,
  0.0::double precision AS iee_monthly, -- GAS = 0
  0.0::double precision AS iee,         -- GAS = 0

  -- (9) Nuevos importes con IVA y % ahorro
    -- importes con IVA directos
  (
    (
      (COALESCE(rc.days::real, 0) * COALESCE(rc.price_pp1, 0::real))
      + (COALESCE(rc.consumption_p1, 0::real) * (COALESCE(rc.price_cp1, 0::real) + 0.00234))
    )::double precision
    + COALESCE(rc.equipment_rental, 0::double precision)
  ) * (1::double precision + COALESCE(rc."VAT", 0::real)) AS new_total_price_with_vat,

  (
    COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real)
  ) * (1::double precision + COALESCE(rc."VAT", 0::real)) AS new_total_yearly_price_with_vat,

  CASE
    when rc.type = 'phone'::text then (
      rc.current_total_invoice * 12::double precision - COALESCE(
        rc.phone_total_anual_price::double precision,
        0.0::double precision
      )
    ) / NULLIF(
      rc.current_total_invoice * 12::double precision,
      0.0::double precision
    )
    WHEN rc.tarifa_plana = TRUE and rc.type = 'light' THEN
     (
      (rc.current_total_invoice * (365.0 / rc.days)) -
      ( (
            (COALESCE(rc.anual_consumption_p1, 0) * COALESCE(rc.price_cp1, 0)) +
            (COALESCE(rc.anual_consumption_p2, 0) * COALESCE(rc.price_cp2, 0)) +
            (COALESCE(rc.anual_consumption_p3, 0) * COALESCE(rc.price_cp3, 0)) +
            (COALESCE(rc.power_p1, 0) * COALESCE(rc.price_pp1, 0) * 365) +
            (COALESCE(rc.power_p2, 0) * COALESCE(rc.price_pp2, 0) * 365)
          ) * 1.05113) 
      * (1 + COALESCE(rc."VAT", 0.0))
    ) / (rc.current_total_invoice * (365.0 / rc.days))

    WHEN rc.tarifa_plana = TRUE and rc.type = 'gas' THEN
     (
      (rc.current_total_invoice * (365.0 / rc.days)) -
      ( (
            (COALESCE(rc.anual_consumption_p1, 0) * (COALESCE(rc.price_cp1, 0))+0.00234) +
            (COALESCE(rc.price_pp1, 0) * 365)) * (1 + COALESCE(rc."VAT", 0.0))
    )) / (rc.current_total_invoice * (365.0 / rc.days))

    when rc.new_company is not null and rc.type <> '3_0'::text then 
    (
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) +
        COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) +
        COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) +
        COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) +
        COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) +
        COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) +
        COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365::double precision +
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365::double precision +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365::double precision 
            - 
        COALESCE(rc.surpluses, 0::real) * 182.5::double precision / case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.autoconsumo_precio, 0::real)
      ) 
      * case
        when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
        else 1.0::double precision
      end 
      * (1::double precision + COALESCE(rc."VAT", 0::real)) 
      - 
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) +
        COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) +
        COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) +
        COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) +
        COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) +
        COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) +
        COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc.price_pp1, 0::real) * 365::double precision +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * 365::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * 365::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * 365::double precision +
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * 365::double precision +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * 365::double precision 
        - COALESCE(rc.surpluses, 0::real) * 182.5::double precision 
        / 
        case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.price_surpluses, 0::real)
      ) 
      *
        case
          when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
        else 1.0::double precision
      end 
      * (1::double precision + COALESCE(rc."VAT", 0::real))
    ) / NULLIF(
                (
                  COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) +
                  COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) +
                  COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) + 
                  COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) + 
                  COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) + 
                  COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) + 
                  COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision + 
                  COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365::double precision +
                  COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365::double precision + 
                  COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365::double precision +
                  COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365::double precision +
                  COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365::double precision - 
                  COALESCE(rc.surpluses, 0::real) * 182.5::double precision 
                  /
                  case
                  when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
                    else rc.days::numeric
                  end::double precision 
                  * COALESCE(rc.autoconsumo_precio, 0::real)
                )
                * 
                case
                  when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
                  else 1.0::double precision
                end 
                * (1::double precision + COALESCE(rc."VAT", 0::real)), 0::double precision
              )
    when rc.new_company is not null and rc.type = '3_0'::text then 
    (
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) +
        COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) +
        COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) +
        COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) +
        COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) +
        COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) +
        COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365::double precision +
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365::double precision +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365::double precision -
        COALESCE(rc.surpluses, 0::real) * 182.5::double precision 
        / 
        case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.autoconsumo_precio, 0::real)
      ) 
      * case
         when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
        else 1.0::double precision
      end * (1::double precision + COALESCE(rc."VAT", 0::real)) - 
        (
          COALESCE(rc.total_consumption_price, 0::real) / COALESCE(rc.total_consumption, 0::real) * COALESCE(rc.total_anual_consumption, 0::real) + 
          COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) * 365::double precision +
          COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * 365::double precision +
          COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * 365::double precision + 
          COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * 365::double precision +
          COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * 365::double precision + 
          COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * 365::double precision
        ) * 1.05113::double precision * (1::double precision + COALESCE(rc."VAT", 0::real))
    ) 
    / 
    NULLIF(
            (
              COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) +
              COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) +
              COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) +
              COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) +
              COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) +
              COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) +
              COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision +
              COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365::double precision +
              COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365::double precision +
              COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365::double precision +
              COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365::double precision + 
              COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365::double precision - 
              COALESCE(rc.surpluses, 0::real) * 182.5::double precision 
              / 
              case
                when COALESCE(rc.days::real, 0::real) = 1::double precision then 182.5
                else rc.days::numeric
              end::double precision
               * COALESCE(rc.autoconsumo_precio, 0::real)
            ) * case
              when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
                else 1.0::double precision
              end * (1::double precision + COALESCE(rc."VAT", 0::real)),
            0::double precision
          )
    else 0.0::double precision
  end as saving_percentage,


  -- (10) Info personas / filtros auxiliares
  us.supervisors,
  COALESCE(rc.temp_client_name, ''::text)      AS client_name,
  COALESCE(rc.temp_client_last_name, ''::text) AS client_last_name,
  u.email                                      AS advisor_email,
  u.name                               AS advisor_display_name,
  ARRAY[COALESCE(u.email,''::text), 'All']     AS advisor_filter,

  -- (11) Derivados fecha y búsquedas
  EXTRACT(MONTH FROM rc.created_at)::text       AS created_month,
  EXTRACT(YEAR  FROM rc.created_at)::text       AS created_year,
  LOWER(
    COALESCE(rc."CUPS",'') || ' ' ||
    COALESCE(rc.client_email,'') || ' ' ||
    COALESCE(rc.company,'') || ' ' ||
    COALESCE(rc.rate_name,'') || ' ' ||
    COALESCE(rc.temp_client_name,'') || ' ' ||
    COALESCE(rc.temp_client_last_name,'')
  )                                           AS search,
  ARRAY[COALESCE(rc.company,''::text), 'All'] AS company_filter,
  rc.cif,
  rc.region,

    -- NUEVO: Al final del SELECT
  0.0::numeric(8,2) AS daily_maintenance_with_vat,
  rc.has_permanence

FROM all_comparisons_ranked rc
LEFT JOIN _users_supervisors us ON rc.advisor_id = us.user_id
LEFT JOIN users u             ON u.user_id = rc.advisor_id
WHERE rc.rank = 1
  AND (rc.deleted IS NULL OR rc.deleted = FALSE)
  AND rc.type = 'gas';