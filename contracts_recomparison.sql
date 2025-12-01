CREATE OR REPLACE VIEW public._contracts_recomparison AS
WITH contracts AS (
  SELECT
    c.id AS contract_id,
    c.contract_type,
    COALESCE(c.region, 'PENINSULA'::text) AS region,
    GREATEST(
      LEAST(COALESCE(c.saving_percentage, 0::real)::numeric, 1::numeric),
      0::numeric
    ) AS saving_percentage_actual,

    -- Consumos y potencias actuales (anuales)
    COALESCE(c.consumoanualp1, 0::real)::numeric AS anual_consumption_p1,
    COALESCE(c.consumoanualp2, 0::real)::numeric AS anual_consumption_p2,
    COALESCE(c.consumoanualp3, 0::real)::numeric AS anual_consumption_p3,
    COALESCE(c.consumoanualp4, 0::real)::numeric AS anual_consumption_p4,
    COALESCE(c.consumoanualp5, 0::real)::numeric AS anual_consumption_p5,
    COALESCE(c.consumoanualp6, 0::real)::numeric AS anual_consumption_p6,

    COALESCE(c.potenciacontratadap1, 0::real)::numeric AS power_p1,
    COALESCE(c.potenciacontratadap2, 0::real)::numeric AS power_p2,
    COALESCE(c.potenciacontratadap3, 0::real)::numeric AS power_p3,
    COALESCE(c.potenciacontratadap4, 0::real)::numeric AS power_p4,
    COALESCE(c.potenciacontratadap5, 0::real)::numeric AS power_p5,
    COALESCE(c.potenciacontratadap6, 0::real)::numeric AS power_p6,

    COALESCE(c.precioconsumop1, 0::real)::numeric AS current_cp1,
    COALESCE(c.precioconsumop2, 0::real)::numeric AS current_cp2,
    COALESCE(c.precioconsumop3, 0::real)::numeric AS current_cp3,
    COALESCE(c.precioconsumop4, 0::real)::numeric AS current_cp4,
    COALESCE(c.precioconsumop5, 0::real)::numeric AS current_cp5,
    COALESCE(c.precioconsumop6, 0::real)::numeric AS current_cp6,

    COALESCE(c.preciopotencia1, 0::real)::numeric AS current_pp1,
    COALESCE(c.preciopotencia2, 0::real)::numeric AS current_pp2,
    COALESCE(c.preciopotencia3, 0::real)::numeric AS current_pp3,
    COALESCE(c.preciopotencia4, 0::real)::numeric AS current_pp4,
    COALESCE(c.preciopotencia5, 0::real)::numeric AS current_pp5,
    COALESCE(c.preciopotencia6, 0::real)::numeric AS current_pp6
  FROM clients_contracts c
  WHERE COALESCE(c.deleted, FALSE) = FALSE
    AND c.contract_type = ANY (ARRAY['light'::text, 'gas'::text, '3_0'::text])
),
contracts_costs AS (
  SELECT
    con.*,
    (
      con.anual_consumption_p1 * con.current_cp1 +
      con.anual_consumption_p2 * con.current_cp2 +
      con.anual_consumption_p3 * con.current_cp3 +
      con.anual_consumption_p4 * con.current_cp4 +
      con.anual_consumption_p5 * con.current_cp5 +
      con.anual_consumption_p6 * con.current_cp6
    ) AS energy_cost_year_curr,
    (
      (
        con.power_p1 * con.current_pp1 +
        con.power_p2 * con.current_pp2 +
        con.power_p3 * con.current_pp3 +
        con.power_p4 * con.current_pp4 +
        con.power_p5 * con.current_pp5 +
        con.power_p6 * con.current_pp6
      ) * 365::numeric
    ) AS power_cost_year_curr,
    (
      con.anual_consumption_p1 +
      con.anual_consumption_p2 +
      con.anual_consumption_p3 +
      con.anual_consumption_p4 +
      con.anual_consumption_p5 +
      con.anual_consumption_p6
    ) AS total_anual_consumption,
    CASE
      WHEN con.contract_type = ANY (ARRAY['light'::text, '3_0'::text]) THEN
        ((
          con.anual_consumption_p1 * con.current_cp1 +
          con.anual_consumption_p2 * con.current_cp2 +
          con.anual_consumption_p3 * con.current_cp3 +
          con.anual_consumption_p4 * con.current_cp4 +
          con.anual_consumption_p5 * con.current_cp5 +
          con.anual_consumption_p6 * con.current_cp6
        ) + (
          (
            con.power_p1 * con.current_pp1 +
            con.power_p2 * con.current_pp2 +
            con.power_p3 * con.current_pp3 +
            con.power_p4 * con.current_pp4 +
            con.power_p5 * con.current_pp5 +
            con.power_p6 * con.current_pp6
          ) * 365::numeric
        )) * 1.05113::numeric
      ELSE
        (
          con.anual_consumption_p1 * con.current_cp1 +
          con.anual_consumption_p2 * con.current_cp2 +
          con.anual_consumption_p3 * con.current_cp3 +
          con.anual_consumption_p4 * con.current_cp4 +
          con.anual_consumption_p5 * con.current_cp5 +
          con.anual_consumption_p6 * con.current_cp6
        ) + (
          (
            con.power_p1 * con.current_pp1 +
            con.power_p2 * con.current_pp2 +
            con.power_p3 * con.current_pp3 +
            con.power_p4 * con.current_pp4 +
            con.power_p5 * con.current_pp5 +
            con.power_p6 * con.current_pp6
          ) * 365::numeric
        )
    END AS current_year_cost_iee
  FROM contracts con
),
payments AS (
  SELECT contract_id, COALESCE(SUM(p."crs cobrado"), 0) AS total_cobrado
  FROM public.clients_contracts_payments p
  GROUP BY contract_id
),
contracts_decomision AS (
  SELECT
    c.id AS contract_id,
    UPPER(TRIM(COALESCE(c.new_company, ''))) AS new_company,
    COALESCE(c.crs, 0) AS crs_base,
    c.activation_date::date AS activation_date,
    COALESCE(p.total_cobrado, 0) AS total_cobrado,
    CASE
      WHEN UPPER(TRIM(COALESCE(c.new_company, ''))) IN ('BASSOLS','IMAGINA','LOGOS','PLENITUDE','CYE','GALP','ELEIA')
           AND c.activation_date IS NOT NULL
        THEN GREATEST(0, LEAST((CURRENT_DATE - c.activation_date::date) / 365.0, 1.0))
      ELSE 1.0
    END AS porcentaje
  FROM public.clients_contracts c
  LEFT JOIN payments p ON p.contract_id = c.id
  WHERE COALESCE(c.deleted, FALSE) = FALSE
),
candidates AS (
  SELECT
    cc.contract_id,
    cc.contract_type,
    cc.region,
    cc.saving_percentage_actual,
    cc.energy_cost_year_curr,
    cc.power_cost_year_curr,
    cc.total_anual_consumption,
    cc.current_year_cost_iee,

    cc.anual_consumption_p1,
    cc.anual_consumption_p2,
    cc.anual_consumption_p3,
    cc.anual_consumption_p4,
    cc.anual_consumption_p5,
    cc.anual_consumption_p6,

    cc.power_p1,
    cc.power_p2,
    cc.power_p3,
    cc.power_p4,
    cc.power_p5,
    cc.power_p6,

    cr.id AS new_rate_id,
    cr.company AS new_company,
    cr.rate_name AS new_rate_name,
    cr.subrate_name AS new_subrate_name,
    cr.rate_mode,
    cr.has_permanence,
    cr.has_maintenance,
    cr.daily_maintenance_with_vat,

    CASE
      WHEN cc.contract_type = 'gas'::text THEN
        365::numeric * COALESCE(cr.price_pp1, 0::real)::numeric +
        cc.anual_consumption_p1 * (COALESCE(cr.price_cp1, 0::real)::numeric + 0.00234)
      WHEN cc.contract_type = ANY (ARRAY['light'::text, '3_0'::text]) THEN
        (
          cc.anual_consumption_p1 * COALESCE(cr.price_cp1, 0::real)::numeric +
          cc.anual_consumption_p2 * COALESCE(cr.price_cp2, 0::real)::numeric +
          cc.anual_consumption_p3 * COALESCE(cr.price_cp3, 0::real)::numeric +
          cc.anual_consumption_p4 * COALESCE(cr.price_cp4, 0::real)::numeric +
          cc.anual_consumption_p5 * COALESCE(cr.price_cp5, 0::real)::numeric +
          cc.anual_consumption_p6 * COALESCE(cr.price_cp6, 0::real)::numeric +
          (
            (
              cc.power_p1 * COALESCE(cr.price_pp1, 0::real)::numeric +
              cc.power_p2 * COALESCE(cr.price_pp2, 0::real)::numeric +
              cc.power_p3 * COALESCE(cr.price_pp3, 0::real)::numeric +
              cc.power_p4 * COALESCE(cr.price_pp4, 0::real)::numeric +
              cc.power_p5 * COALESCE(cr.price_pp5, 0::real)::numeric +
              cc.power_p6 * COALESCE(cr.price_pp6, 0::real)::numeric
            ) * 365::numeric
          )
        ) * 1.05113::numeric
      ELSE NULL::numeric
    END
    + COALESCE(cr.daily_maintenance_with_vat, 0::real)::numeric * 365::numeric AS new_year_cost
  FROM contracts_costs cc
  JOIN comparison_rates cr
    ON cr.type = cc.contract_type
   AND COALESCE(cr.deleted, FALSE) = FALSE
   AND (
     cc.region IS NULL
     OR cr.region IS NULL
     OR cc.region = ANY (cr.region)
   )
),
candidates_with_crs AS (
  SELECT
    c.*,
    crs.id AS crs_id,
    (
      c.anual_consumption_p1 * COALESCE(crs.crs_cp1, 0::real)::numeric +
      c.anual_consumption_p2 * COALESCE(crs.crs_cp2, 0::real)::numeric +
      c.anual_consumption_p3 * COALESCE(crs.crs_cp3, 0::real)::numeric +
      c.anual_consumption_p4 * COALESCE(crs.crs_cp4, 0::real)::numeric +
      c.anual_consumption_p5 * COALESCE(crs.crs_cp5, 0::real)::numeric +
      c.anual_consumption_p6 * COALESCE(crs.crs_cp6, 0::real)::numeric +
      c.power_p1 * COALESCE(crs.crs_pp1, 0::real)::numeric +
      c.power_p2 * COALESCE(crs.crs_pp2, 0::real)::numeric +
      c.power_p3 * COALESCE(crs.crs_pp3, 0::real)::numeric +
      c.power_p4 * COALESCE(crs.crs_pp4, 0::real)::numeric +
      c.power_p5 * COALESCE(crs.crs_pp5, 0::real)::numeric +
      c.power_p6 * COALESCE(crs.crs_pp6, 0::real)::numeric +
      COALESCE(crs.fixed_crs, 0::real)::numeric
    ) AS total_crs
  FROM candidates c
  LEFT JOIN comparison_rates_crs crs
    ON crs.comparison_rate_id = c.new_rate_id
   AND (crs.min_kw_anual IS NULL OR c.total_anual_consumption >= crs.min_kw_anual)
   AND (crs.max_kw_anual IS NULL OR c.total_anual_consumption <  crs.max_kw_anual)
   AND (crs.min_power   IS NULL OR c.power_p1 >= crs.min_power)
   AND (crs.max_power   IS NULL OR c.power_p1 <  crs.max_power)
),
ranked AS (
  SELECT
    cwc.*,
    savings.calc_new_savings AS savings_yearly,
    savings.calc_new_savings / NULLIF(cwc.current_year_cost_iee, 0::numeric) AS new_saving_percentage,
    savings.calc_new_savings + COALESCE(cwc.total_crs, 0::numeric) * 4::numeric AS ranked_crs,
    ROW_NUMBER() OVER (
      PARTITION BY cwc.contract_id
      ORDER BY savings.calc_new_savings + COALESCE(cwc.total_crs, 0::numeric) * 4::numeric DESC
    ) AS rank
  FROM candidates_with_crs cwc
  CROSS JOIN LATERAL (
    SELECT GREATEST(cwc.current_year_cost_iee - COALESCE(cwc.new_year_cost, cwc.current_year_cost_iee), 0::numeric) AS calc_new_savings
  ) savings
)
SELECT
  r.contract_id,
  r.contract_type,
  r.region,
  r.energy_cost_year_curr,
  r.power_cost_year_curr,
  r.current_year_cost_iee,
  r.saving_percentage_actual,

  r.new_company,
  r.new_rate_name,
  r.new_subrate_name,
  r.new_rate_id,
  r.new_year_cost,
  r.has_maintenance,
  r.daily_maintenance_with_vat,

  r.savings_yearly,
  r.new_saving_percentage,
  r.new_saving_percentage - r.saving_percentage_actual AS delta_vs_recorded_saving,

  r.crs_id,
  r.total_crs,
  r.ranked_crs,
  r.rank,

  -- Decomisión
  ROUND(cd.crs_base::numeric, 2) AS decomision_base,
  ROUND((cd.porcentaje * 100)::numeric, 2) AS porcentaje_por_dias,
  ROUND((CASE WHEN cd.crs_base <= 0 THEN 0 ELSE cd.crs_base * cd.porcentaje END)::numeric, 2) AS decomision,
  cd.total_cobrado,
  ROUND((CASE WHEN cd.crs_base <= 0 THEN 0 ELSE cd.crs_base * cd.porcentaje END - cd.total_cobrado)::numeric, 2) AS decomision_pendiente
FROM ranked r
LEFT JOIN contracts_decomision cd ON cd.contract_id = r.contract_id
WHERE r.rank = 1
  AND COALESCE(r.new_saving_percentage, 0) > 0.05;
