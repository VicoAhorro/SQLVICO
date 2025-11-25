-- Análisis detallado de tarifas por CIF y subrate para comparativa b94b634e-728f-4e51-9a9d-fb3d158090db

-- Comparativa tiene:
-- cif = false
-- preferred_subrate = "3.0"
-- invoice_month = 9
-- invoice_year = 2025
-- region = PENINSULA
-- wants_permanence = null

WITH comparison_data AS (
  SELECT * FROM comparison_3_0
  WHERE id = 'b94b634e-728f-4e51-9a9d-fb3d158090db'
),
user_data AS (
  SELECT user_id, tenant
  FROM users
  WHERE user_id = '0f317d06-93a8-4b2d-b18d-9a0264e1d288'
)
SELECT
  '=== ANÁLISIS POR FILTRO ===' AS seccion,
  cr.company,
  cr.rate_name,
  cr.subrate_name,
  cr.rate_mode,
  cr.invoice_month,
  cr.invoice_year,
  cr.cif,
  cr.has_permanence,
  cr.region,
  -- Validar cada filtro individualmente
  CASE WHEN cr.type = '3_0' THEN '✓' ELSE '✗' END AS f1_tipo,
  CASE WHEN cr.company <> cd.company THEN '✓' ELSE '✗' END AS f2_company,
  CASE WHEN cr.deleted = FALSE THEN '✓' ELSE '✗' END AS f3_deleted,
  CASE WHEN (cr.tenant_id IS NULL OR ud.tenant = ANY(cr.tenant_id)) THEN '✓' ELSE '✗' END AS f4_tenant,
  CASE WHEN (
    cr.rate_mode::text <> 'Indexada'
    OR (
        (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
      OR (cr.invoice_month = cd.invoice_month AND cr.invoice_year = cd.invoice_year)
    )
  ) THEN '✓' ELSE '✗' END AS f5_mes_anio,
  CASE WHEN (
    cd.preferred_subrate IS NULL
    OR cd.preferred_subrate = ''
    OR cr.subrate_name = cd.preferred_subrate
  ) THEN '✓' ELSE '✗' END AS f6_subrate,
  CASE WHEN (
    (cd.wants_permanence IS NOT TRUE AND COALESCE(cr.has_permanence, FALSE) = FALSE)
    OR (cd.wants_permanence = TRUE AND cr.has_permanence = TRUE)
  ) THEN '✓' ELSE '✗' END AS f7_permanencia,
  CASE WHEN (cr.cif IS NULL OR cr.cif = cd.cif) THEN '✓' ELSE '✗' END AS f8_cif,
  CASE WHEN (cd.region IS NULL OR cd.region = ANY(cr.region)) THEN '✓' ELSE '✗' END AS f9_region,
  -- Resultado final
  CASE WHEN (
    cr.type = '3_0'
    AND cr.company <> cd.company
    AND cr.deleted = FALSE
    AND (cr.tenant_id IS NULL OR ud.tenant = ANY(cr.tenant_id))
    AND (
      cr.rate_mode::text <> 'Indexada'
      OR (
          (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
        OR (cr.invoice_month = cd.invoice_month AND cr.invoice_year = cd.invoice_year)
      )
    )
    AND (
      cd.preferred_subrate IS NULL
      OR cd.preferred_subrate = ''
      OR cr.subrate_name = cd.preferred_subrate
    )
    AND (
      (cd.wants_permanence IS NOT TRUE AND COALESCE(cr.has_permanence, FALSE) = FALSE)
      OR (cd.wants_permanence = TRUE AND cr.has_permanence = TRUE)
    )
    AND (cr.cif IS NULL OR cr.cif = cd.cif)
    AND (cd.region IS NULL OR cd.region = ANY(cr.region))
  ) THEN '✓ PASA TODO' ELSE '✗ FALLA' END AS resultado
FROM comparison_rates cr
CROSS JOIN comparison_data cd
CROSS JOIN user_data ud
WHERE cr.type = '3_0'
  AND cr.deleted = FALSE
  -- Solo mostrar tarifas que cumplan con subrate 3.0 o cif compatible
  AND (
    cr.subrate_name = '3.0'
    OR cr.cif IS NULL
    OR cr.cif = false
  )
ORDER BY
  CASE WHEN cr.subrate_name = '3.0' THEN 0 ELSE 1 END,
  CASE WHEN cr.cif IS NULL THEN 0 WHEN cr.cif = false THEN 1 ELSE 2 END,
  cr.company,
  cr.rate_name
LIMIT 100;
