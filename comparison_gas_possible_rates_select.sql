/*
  Consulta manual: sustituye el valor de `comparison_id` por la comparación deseada.
  Devuelve cada tarifa candidata válida junto con los filtros claves que se aplican.
*/
WITH comparison AS (
  SELECT
    cg.*,
    u.tenant,
    EXISTS (
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
    ) AS has_preferred_rate_type_available,
    EXISTS (
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
    ) AS has_permanence_option
  FROM comparison_gas cg
  LEFT JOIN users u
    ON u.user_id = cg.advisor_id
  WHERE cg.id = '<insert comparison id>'
)
SELECT
  c.id                                  AS comparison_id,
  c.created_at,
  c.company                              AS market_company,
  c.rate_name,
  c.preferred_subrate,
  c.prefered_rate_type,
  c.wants_permanence,
  c.region,
  c.cif,

  cr.id                                   AS rate_id,
  cr.company,
  cr.rate_name                            AS rate_label,
  cr.subrate_name,
  cr.rate_mode,
  cr.has_permanence,
  cr.region                               AS rate_region,
  cr.invoice_month,
  cr.invoice_year,
  cr.cif                                  AS rate_cif,
  cr.deleted,
  cr.tenant_id,

  (cr.company <> c.company)              AS filter_company_ok,
  (cr.tenant_id IS NULL OR c.tenant = ANY(cr.tenant_id)) AS filter_tenant_ok,
  (
    (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
    OR (cr.invoice_month = c.invoice_month AND cr.invoice_year = c.invoice_year)
  )                                      AS filter_period_ok,
  (cr.cif IS NULL OR cr.cif = c.cif)      AS filter_cif_ok,
  (
    c.preferred_subrate IS NULL
    OR c.preferred_subrate = ''
    OR cr.subrate_name = c.rate_name
  )                                      AS filter_preferred_subrate_ok,
  (c.region IS NULL OR c.region = ANY(cr.region)) AS filter_region_ok,
  (
    c.prefered_rate_type IS NULL
    OR cr.rate_mode = c.prefered_rate_type
    OR (c.prefered_rate_type = 'Indexada' AND cr.rate_mode IS NULL)
    OR NOT c.has_preferred_rate_type_available
  )                                      AS filter_preferred_rate_type_ok,
  (
    c.wants_permanence IS NOT TRUE
    OR cr.has_permanence = TRUE
    OR NOT c.has_permanence_option
  )                                      AS filter_permanence_ok,

  c.has_preferred_rate_type_available,
  c.has_permanence_option
FROM comparison c
JOIN comparison_rates cr ON TRUE
WHERE cr.type = 'gas'
  AND cr.company <> c.company
  AND (cr.deleted = FALSE)
  AND (cr.tenant_id IS NULL OR c.tenant = ANY(cr.tenant_id))
  AND cr.subrate_name = c.rate_name
  AND (
    (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
    OR (cr.invoice_month = c.invoice_month AND cr.invoice_year = c.invoice_year)
  )
  AND (cr.cif IS NULL OR cr.cif = c.cif)
  AND (
    c.preferred_subrate IS NULL
    OR c.preferred_subrate = ''
    OR cr.subrate_name = c.rate_name
  )
  AND (
    c.prefered_rate_type IS NULL
    OR cr.rate_mode = c.prefered_rate_type
    OR (c.prefered_rate_type = 'Indexada' AND cr.rate_mode IS NULL)
    OR NOT c.has_preferred_rate_type_available
  )
  AND (
    c.wants_permanence IS NOT TRUE
    OR cr.has_permanence = TRUE
    OR NOT c.has_permanence_option
  )
  AND (c.region IS NULL OR c.region = ANY (cr.region))
ORDER BY cr.company, cr.rate_name, cr.subrate_name;
