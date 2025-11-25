-- Debug para comparativa Maria Ascension Rivas Peleteiro
-- ID: b94b634e-728f-4e51-9a9d-fb3d158090db
-- Usuario: 0f317d06-93a8-4b2d-b18d-9a0264e1d288
-- Compañía actual: OTRO
-- Mes/Año: 9/2025
-- rate_i_have: Fija
-- wants_permanence: null

-- 1. Verificar que la comparativa existe
SELECT
  '=== DATOS COMPARATIVA ===' AS seccion,
  id,
  company,
  invoice_month,
  invoice_year,
  cif,
  region,
  preferred_subrate,
  wants_permanence,
  rate_i_have,
  rate_i_want,
  advisor_id
FROM comparison_3_0
WHERE id = 'b94b634e-728f-4e51-9a9d-fb3d158090db';

-- 2. Verificar tenant del usuario
SELECT
  '=== TENANT USUARIO ===' AS seccion,
  user_id,
  tenant,
  email,
  name
FROM users
WHERE user_id = '0f317d06-93a8-4b2d-b18d-9a0264e1d288';

-- 3. Ver TODAS las tarifas disponibles para mes/año 9/2025 (indexadas y fijas)
SELECT
  '=== TARIFAS DISPONIBLES 9/2025 ===' AS seccion,
  id,
  company,
  rate_name,
  subrate_name,
  rate_mode,
  invoice_month,
  invoice_year,
  cif,
  region,
  tenant_id,
  has_permanence,
  deleted
FROM comparison_rates
WHERE type = '3_0'
  AND (
    (rate_mode = 'Indexada' AND invoice_month = 9 AND invoice_year = 2025)
    OR rate_mode <> 'Indexada'
  )
  AND deleted = FALSE
  AND company <> 'OTRO'
ORDER BY rate_mode, company, rate_name
LIMIT 50;

-- 4. Test del filtro de permanencia con wants_permanence = NULL
WITH test_data AS (
  SELECT
    NULL::boolean AS wants_permanence,
    false AS has_permanence_1,
    true AS has_permanence_2,
    NULL::boolean AS has_permanence_3
)
SELECT
  '=== TEST FILTRO PERMANENCIA ===' AS seccion,
  wants_permanence,
  has_permanence_1,
  has_permanence_2,
  has_permanence_3,
  -- Aplicar la lógica del filtro
  CASE
    WHEN (wants_permanence IS NOT TRUE AND COALESCE(has_permanence_1, FALSE) = FALSE) THEN 'PASA'
    ELSE 'NO PASA'
  END AS test_has_perm_false,
  CASE
    WHEN (wants_permanence IS NOT TRUE AND COALESCE(has_permanence_2, FALSE) = FALSE) THEN 'PASA'
    ELSE 'NO PASA'
  END AS test_has_perm_true,
  CASE
    WHEN (wants_permanence IS NOT TRUE AND COALESCE(has_permanence_3, FALSE) = FALSE) THEN 'PASA'
    ELSE 'NO PASA'
  END AS test_has_perm_null
FROM test_data;

-- 5. Contar cuántas tarifas pasan cada filtro
WITH comparison_data AS (
  SELECT
    c30.id,
    c30.company,
    c30.invoice_month,
    c30.invoice_year,
    c30.cif,
    c30.region,
    c30.preferred_subrate,
    c30.wants_permanence,
    c30.advisor_id
  FROM comparison_3_0 c30
  WHERE c30.id = 'b94b634e-728f-4e51-9a9d-fb3d158090db'
),
user_data AS (
  SELECT user_id, tenant
  FROM users
  WHERE user_id = '0f317d06-93a8-4b2d-b18d-9a0264e1d288'
)
SELECT
  '=== RESUMEN FILTROS ===' AS seccion,
  COUNT(*) AS total_tarifas,
  COUNT(*) FILTER (WHERE cr.type = '3_0') AS total_tipo_3_0,
  COUNT(*) FILTER (WHERE cr.company <> cd.company) AS pasa_company,
  COUNT(*) FILTER (WHERE cr.deleted = FALSE) AS pasa_deleted,
  COUNT(*) FILTER (WHERE cr.tenant_id IS NULL OR ud.tenant = ANY(cr.tenant_id)) AS pasa_tenant,
  COUNT(*) FILTER (WHERE
    cr.rate_mode::text <> 'Indexada'
    OR (
        (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
      OR (cr.invoice_month = cd.invoice_month AND cr.invoice_year = cd.invoice_year)
    )
  ) AS pasa_mes_anio,
  COUNT(*) FILTER (WHERE
    cd.preferred_subrate IS NULL
    OR cd.preferred_subrate = ''
    OR cr.subrate_name = cd.preferred_subrate
  ) AS pasa_subrate,
  COUNT(*) FILTER (WHERE cr.cif IS NULL OR cr.cif = cd.cif) AS pasa_cif,
  COUNT(*) FILTER (WHERE cd.region IS NULL OR cd.region = ANY(cr.region)) AS pasa_region,
  COUNT(*) FILTER (WHERE
    (cd.wants_permanence IS NOT TRUE AND COALESCE(cr.has_permanence, FALSE) = FALSE)
    OR (cd.wants_permanence = TRUE AND cr.has_permanence = TRUE)
  ) AS pasa_permanencia,
  COUNT(*) FILTER (WHERE
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
  ) AS pasa_todos_filtros
FROM comparison_rates cr
CROSS JOIN comparison_data cd
CROSS JOIN user_data ud;

-- 6. Listar las tarifas que pasan TODOS los filtros
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
  '=== TARIFAS QUE PASAN TODOS LOS FILTROS ===' AS seccion,
  cr.id,
  cr.company,
  cr.rate_name,
  cr.subrate_name,
  cr.rate_mode,
  cr.invoice_month,
  cr.invoice_year,
  cr.has_permanence,
  cr.cif,
  cr.region,
  cr.tenant_id
FROM comparison_rates cr
CROSS JOIN comparison_data cd
CROSS JOIN user_data ud
WHERE cr.type = '3_0'
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
ORDER BY cr.rate_mode, cr.company, cr.rate_name
LIMIT 50;
