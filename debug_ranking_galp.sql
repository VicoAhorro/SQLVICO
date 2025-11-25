-- Ver todas las tarifas que se están comparando y su ranking
-- para la comparativa 3516574f-ccb0-43a5-a2a5-44fe35ff0b38

WITH calculated_prices_3_0 AS (
  SELECT
    c30.id,
    c30.invoice_month,
    c30.invoice_year,
    c30.consumption_p1, c30.consumption_p2, c30.consumption_p3,
    c30.consumption_p4, c30.consumption_p5, c30.consumption_p6,
    c30.anual_consumption_p1, c30.anual_consumption_p2, c30.anual_consumption_p3,
    c30.anual_consumption_p4, c30.anual_consumption_p5, c30.anual_consumption_p6,
    c30.power_p1, c30.power_p2, c30.power_p3, c30.power_p4, c30.power_p5, c30.power_p6,
    c30.power_days,
    c30.surpluses,
    c30."VAT",
    c30.advisor_id,
    c30.company,
    c30.preferred_subrate,
    c30.wants_permanence,
    c30.cif,
    c30.region,
    c30.current_total_invoice,
    c30.equipment_rental,
    c30."precio_kwh_P1", c30."precio_kwh_P2", c30."precio_kwh_P3",
    c30."precio_kwh_P4", c30."precio_kwh_P5", c30."precio_kwh_P6",
    c30."precio_kw_P1", c30."precio_kw_P2", c30."precio_kw_P3",
    c30."precio_kw_P4", c30."precio_kw_P5", c30."precio_kw_P6",
    c30.autoconsumo_precio,

    COALESCE(c30.consumption_p1,0::real)+COALESCE(c30.consumption_p2,0::real)+COALESCE(c30.consumption_p3,0::real)+
    COALESCE(c30.consumption_p4,0::real)+COALESCE(c30.consumption_p5,0::real)+COALESCE(c30.consumption_p6,0::real) AS total_consumption,

    COALESCE(c30.anual_consumption_p1,0::real)+COALESCE(c30.anual_consumption_p2,0::real)+COALESCE(c30.anual_consumption_p3,0::real)+
    COALESCE(c30.anual_consumption_p4,0::real)+COALESCE(c30.anual_consumption_p5,0::real)+COALESCE(c30.anual_consumption_p6,0::real) AS total_anual_consumption,

    cr.id AS new_rate_id,
    cr.company AS new_company,
    cr.rate_name AS new_rate_name,
    cr.subrate_name AS new_subrate_name,
    cr.rate_mode,
    cr.price_pp1, cr.price_pp2, cr.price_pp3, cr.price_pp4, cr.price_pp5, cr.price_pp6,
    cr.price_cp1, cr.price_cp2, cr.price_cp3, cr.price_cp4, cr.price_cp5, cr.price_cp6,
    cr.price_surpluses,

    -- TOTAL POWER PRICE
    ((COALESCE(c30.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
    ((COALESCE(c30.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
    ((COALESCE(c30.power_p3, 0::real) * COALESCE(cr.price_pp3, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
    ((COALESCE(c30.power_p4, 0::real) * COALESCE(cr.price_pp4, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
    ((COALESCE(c30.power_p5, 0::real) * COALESCE(cr.price_pp5, 0::real))  * COALESCE(c30.power_days, 0)::double precision) +
    ((COALESCE(c30.power_p6, 0::real) * COALESCE(cr.price_pp6, 0::real))  * COALESCE(c30.power_days, 0)::double precision) AS total_power_price,

    -- TOTAL CONSUMPTION PRICE
    COALESCE(c30.consumption_p1,0::real)*COALESCE(cr.price_cp1,0::real) +
    COALESCE(c30.consumption_p2,0::real)*COALESCE(cr.price_cp2,0::real) +
    COALESCE(c30.consumption_p3,0::real)*COALESCE(cr.price_cp3,0::real) +
    COALESCE(c30.consumption_p4,0::real)*COALESCE(cr.price_cp4,0::real) +
    COALESCE(c30.consumption_p5,0::real)*COALESCE(cr.price_cp5,0::real) +
    COALESCE(c30.consumption_p6,0::real)*COALESCE(cr.price_cp6,0::real) AS total_consumption_price,

    -- NEW TOTAL PRICE
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
    AS new_total_price

  FROM comparison_3_0 c30
  LEFT JOIN users u ON u.user_id = c30.advisor_id
  LEFT JOIN comparison_rates cr
    ON cr.type = '3_0'
    AND cr.company <> c30.company
    AND (cr.deleted = FALSE)
    AND (cr.tenant_id IS NULL OR u.tenant = ANY(cr.tenant_id))
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
  WHERE c30.id = '3516574f-ccb0-43a5-a2a5-44fe35ff0b38'
    AND (c30.deleted IS NULL OR c30.deleted = FALSE)
    AND (c30.region IS NULL OR c30.region = ANY (cr.region))
),
with_savings AS (
  SELECT
    cp.*,
    -- savings_yearly calculation
    CASE
      WHEN cp.new_company IS NOT NULL THEN
        (
          (
            (COALESCE(cp.anual_consumption_p1,0::real)*COALESCE(cp."precio_kwh_P1",0::real) +
             COALESCE(cp.anual_consumption_p2,0::real)*COALESCE(cp."precio_kwh_P2",0::real) +
             COALESCE(cp.anual_consumption_p3,0::real)*COALESCE(cp."precio_kwh_P3",0::real) +
             COALESCE(cp.anual_consumption_p4,0::real)*COALESCE(cp."precio_kwh_P4",0::real) +
             COALESCE(cp.anual_consumption_p5,0::real)*COALESCE(cp."precio_kwh_P5",0::real) +
             COALESCE(cp.anual_consumption_p6,0::real)*COALESCE(cp."precio_kwh_P6",0::real) +
             COALESCE(NULLIF(cp.power_p1,0::double precision),1::real)*COALESCE(cp."precio_kw_P1",0::real)*365.0 +
             COALESCE(cp.power_p2,0::real)*COALESCE(cp."precio_kw_P2",0::real)*365.0 +
             COALESCE(cp.power_p3,0::real)*COALESCE(cp."precio_kw_P3",0::real)*365.0 +
             COALESCE(cp.power_p4,0::real)*COALESCE(cp."precio_kw_P4",0::real)*365.0 +
             COALESCE(cp.power_p5,0::real)*COALESCE(cp."precio_kw_P5",0::real)*365.0 +
             COALESCE(cp.power_p6,0::real)*COALESCE(cp."precio_kw_P6",0::real)*365.0
             - COALESCE(cp.surpluses,0) * (182.5::double precision / NULLIF(cp.power_days::numeric,0)) * COALESCE(cp.autoconsumo_precio,0)
            )
            * 1.05113
          ) * (1 + COALESCE(cp."VAT",0))
          -
          (
            COALESCE(cp.total_consumption_price,0) / NULLIF(cp.total_consumption,0) * COALESCE(cp.total_anual_consumption,0) +
            COALESCE(cp.power_p1,0::real)*COALESCE(cp.price_pp1,0::real)*365.0 +
            COALESCE(cp.power_p2,0::real)*COALESCE(cp.price_pp2,0::real)*365.0 +
            COALESCE(cp.power_p3,0::real)*COALESCE(cp.price_pp3,0::real)*365.0 +
            COALESCE(cp.power_p4,0::real)*COALESCE(cp.price_pp4,0::real)*365.0 +
            COALESCE(cp.power_p5,0::real)*COALESCE(cp.price_pp5,0::real)*365.0 +
            COALESCE(cp.power_p6,0::real)*COALESCE(cp.price_pp6,0::real)*365.0
          ) * 1.05113 * (1 + COALESCE(cp."VAT",0))
        )
      ELSE 0.0
    END AS savings_yearly
  FROM calculated_prices_3_0 cp
)
SELECT
  new_company,
  new_rate_name,
  rate_mode,
  savings_yearly,
  new_total_price,
  ROW_NUMBER() OVER (ORDER BY savings_yearly DESC) AS rank
FROM with_savings
WHERE new_company IS NOT NULL
ORDER BY savings_yearly DESC
LIMIT 20;
