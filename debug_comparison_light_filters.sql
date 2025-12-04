-- Debug: candidatos de light con estado de cada filtro.
-- Cambia el id en la CTE `target` para el caso que quieras revisar.
WITH target AS (
  SELECT
    cl.*,
    u.tenant AS advisor_tenant
  FROM comparison_light cl
  LEFT JOIN users u ON u.user_id = cl.advisor_id
  WHERE cl.id = '03c8b391-23dc-47b2-b5ba-19ef7471ffc3'
),
candidates AS (
  SELECT
    t.id AS comparison_id,
    t.company AS comparison_company,
    t.rate_name AS comparison_rate_name,
    t.invoice_month AS comparison_invoice_month,
    t.invoice_year AS comparison_invoice_year,
    t.preferred_subrate,
    t.region AS comparison_region,
    t.selfconsumption AS comparison_selfconsumption,
    t.cif AS comparison_cif,
    t.wants_permanence AS comparison_wants_permanence,
    t.advisor_tenant,

    cr.id AS rate_id,
    cr.company AS rate_company,
    cr.rate_name,
    cr.subrate_name,
    cr.invoice_month AS rate_invoice_month,
    cr.invoice_year AS rate_invoice_year,
    cr.region AS rate_region,
    cr.selfconsumption AS rate_selfconsumption,
    cr.cif AS rate_cif,
    cr.has_permanence,
    cr.rate_mode,

    -- Filtros de periodo/subrate (mismo orden que la vista principal)
    (cr.invoice_month = t.invoice_month AND cr.invoice_year = t.invoice_year
      AND (
        t.preferred_subrate IS NULL
        OR t.preferred_subrate = ''
        OR LOWER(cr.subrate_name::text) = LOWER(t.preferred_subrate::text)
      )
    ) AS f_exact_period,

    (cr.invoice_month IS NULL AND cr.invoice_year IS NULL) AS f_generic_period,

    (
      cr.invoice_month = t.invoice_month
      AND cr.invoice_year = t.invoice_year
      AND NOT EXISTS (
        SELECT 1
        FROM comparison_rates_v2 crs
        WHERE crs.type = 'light'
          AND crs.company <> t.company
          AND crs.invoice_month = t.invoice_month
          AND crs.invoice_year = t.invoice_year
          AND LOWER(crs.subrate_name::text) = LOWER(t.preferred_subrate::text)
      )
    ) AS f_fallback_no_preferred_match,

    (
      cr.invoice_year = t.invoice_year
      AND NOT EXISTS (
        SELECT 1
        FROM comparison_rates_v2 cry
        WHERE cry.type = 'light'
          AND cry.company <> t.company
          AND cry.invoice_month = t.invoice_month
          AND cry.invoice_year = t.invoice_year
      )
    ) AS f_fallback_same_year,

    -- Otros filtros
    (t.region IS NULL OR t.region = ANY (cr.region)) AS f_region,
    (
      (t.selfconsumption = TRUE AND COALESCE(cr.selfconsumption, FALSE) = TRUE)
      OR (t.selfconsumption IS DISTINCT FROM TRUE AND cr.selfconsumption IS DISTINCT FROM TRUE)
    ) AS f_selfconsumption,
    (cr.cif IS NULL OR cr.cif = t.cif) AS f_cif,
    (
      t.wants_permanence IS NOT TRUE
      OR cr.has_permanence = TRUE
      OR NOT EXISTS (
        SELECT 1
        FROM comparison_rates_v2 crp
        WHERE crp.type = 'light'
          AND crp.company <> t.company
          AND (
                (crp.invoice_month IS NULL AND crp.invoice_year IS NULL)
             OR (crp.invoice_month = t.invoice_month AND crp.invoice_year = t.invoice_year)
          )
          AND (t.region IS NULL OR t.region = ANY (crp.region))
          AND (
                (t.selfconsumption = TRUE AND COALESCE(crp.selfconsumption, FALSE) = TRUE)
                OR (t.selfconsumption IS DISTINCT FROM TRUE AND crp.selfconsumption IS DISTINCT FROM TRUE)
              )
          AND (crp.cif IS NULL OR crp.cif = t.cif)
          AND crp.has_permanence = TRUE
      )
    ) AS f_permanence,

    -- Resultado global
    (
      (
        (cr.invoice_month = t.invoice_month AND cr.invoice_year = t.invoice_year
          AND (
            t.preferred_subrate IS NULL
            OR t.preferred_subrate = ''
            OR LOWER(cr.subrate_name::text) = LOWER(t.preferred_subrate::text)
          )
        )
        OR (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
        OR (
          cr.invoice_month = t.invoice_month
          AND cr.invoice_year = t.invoice_year
          AND NOT EXISTS (
            SELECT 1
            FROM comparison_rates_v2 crs
            WHERE crs.type = 'light'
              AND crs.company <> t.company
              AND crs.invoice_month = t.invoice_month
              AND crs.invoice_year = t.invoice_year
              AND LOWER(crs.subrate_name::text) = LOWER(t.preferred_subrate::text)
          )
        )
        OR (
          cr.invoice_year = t.invoice_year
          AND NOT EXISTS (
            SELECT 1
            FROM comparison_rates_v2 cry
            WHERE cry.type = 'light'
              AND cry.company <> t.company
              AND cry.invoice_month = t.invoice_month
              AND cry.invoice_year = t.invoice_year
          )
        )
      )
      AND (t.region IS NULL OR t.region = ANY (cr.region))
      AND (
        (t.selfconsumption = TRUE AND COALESCE(cr.selfconsumption, FALSE) = TRUE)
        OR (t.selfconsumption IS DISTINCT FROM TRUE AND cr.selfconsumption IS DISTINCT FROM TRUE)
      )
      AND (cr.cif IS NULL OR cr.cif = t.cif)
      AND (
        t.wants_permanence IS NOT TRUE
        OR cr.has_permanence = TRUE
        OR NOT EXISTS (
          SELECT 1
          FROM comparison_rates_v2 crp
          WHERE crp.type = 'light'
            AND crp.company <> t.company
            AND (
                  (crp.invoice_month IS NULL AND crp.invoice_year IS NULL)
               OR (crp.invoice_month = t.invoice_month AND crp.invoice_year = t.invoice_year)
            )
            AND (t.region IS NULL OR t.region = ANY (crp.region))
            AND (
                  (t.selfconsumption = TRUE AND COALESCE(crp.selfconsumption, FALSE) = TRUE)
                  OR (t.selfconsumption IS DISTINCT FROM TRUE AND crp.selfconsumption IS DISTINCT FROM TRUE)
                )
            AND (crp.cif IS NULL OR crp.cif = t.cif)
            AND crp.has_permanence = TRUE
        )
      )
    ) AS passes_all_filters

  FROM target t
  JOIN comparison_rates_v2 cr
    ON cr.type = 'light'
   AND cr.company <> t.company
   AND cr.deleted = FALSE
   AND (cr.tenant_id IS NULL OR t.advisor_tenant = ANY (cr.tenant_id))
)
SELECT
  c.comparison_id,
  c.rate_company,
  c.rate_name,
  c.subrate_name,
  c.has_permanence,
  c.rate_mode,
  f.filter_name,
  f.passes AS filter_passes,
  CASE WHEN f.passes THEN '[OK]' ELSE '[NO]' END AS checkmark,
  c.passes_all_filters
FROM candidates c
CROSS JOIN LATERAL (
  VALUES
    ('f_exact_period', c.f_exact_period),
    ('f_generic_period', c.f_generic_period),
    ('f_fallback_no_preferred_match', c.f_fallback_no_preferred_match),
    ('f_fallback_same_year', c.f_fallback_same_year),
    ('f_region', c.f_region),
    ('f_selfconsumption', c.f_selfconsumption),
    ('f_cif', c.f_cif),
    ('f_permanence', c.f_permanence)
) AS f(filter_name, passes)
ORDER BY c.passes_all_filters DESC, c.rate_company, c.rate_name, c.subrate_name, f.filter_name;
