-- Script de debug para verificar por qué no aparece la tarifa INDEX 15 de GALP
-- Comparativa ID: 3516574f-ccb0-43a5-a2a5-44fe35ff0b38
-- Usuario: 27ab282c-7049-4e93-af46-9cb0b29d0f46
-- Tarifa esperada: f3d77f0e-fcf1-49b3-a735-2cb040e02ea2 (GALP INDEX 15)

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
  WHERE c30.id = '3516574f-ccb0-43a5-a2a5-44fe35ff0b38'
),
user_data AS (
  SELECT
    user_id,
    tenant,
    email
  FROM users
  WHERE user_id = '27ab282c-7049-4e93-af46-9cb0b29d0f46'
),
target_rate AS (
  SELECT
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    cr.invoice_month,
    cr.invoice_year,
    cr.cif,
    cr.region,
    cr.tenant_id,
    cr.deleted,
    cr.has_permanence
  FROM comparison_rates cr
  WHERE cr.id = 'f3d77f0e-fcf1-49b3-a735-2cb040e02ea2'
)
SELECT
  '=== DATOS DE LA COMPARATIVA ===' AS seccion,
  cd.company AS comp_company,
  cd.invoice_month AS comp_month,
  cd.invoice_year AS comp_year,
  cd.cif AS comp_cif,
  cd.region AS comp_region,
  cd.preferred_subrate AS comp_subrate,
  cd.wants_permanence AS comp_permanence,
  ud.tenant AS user_tenant,

  '=== DATOS DE LA TARIFA ===' AS seccion2,
  tr.company AS rate_company,
  tr.rate_name AS rate_name,
  tr.subrate_name AS rate_subrate,
  tr.rate_mode AS rate_mode,
  tr.invoice_month AS rate_month,
  tr.invoice_year AS rate_year,
  tr.cif AS rate_cif,
  tr.region AS rate_region,
  tr.tenant_id AS rate_tenant_id,
  tr.deleted AS rate_deleted,
  tr.has_permanence AS rate_permanence,

  '=== VALIDACIÓN DE FILTROS ===' AS seccion3,
  -- Filtro 1: type
  CASE WHEN tr.id IS NOT NULL THEN '✓ Tarifa existe' ELSE '✗ Tarifa no existe' END AS filtro_exists,

  -- Filtro 2: company diferente
  CASE WHEN tr.company <> cd.company THEN '✓ Compañía diferente' ELSE '✗ Misma compañía' END AS filtro_company,

  -- Filtro 3: deleted
  CASE WHEN tr.deleted = FALSE THEN '✓ No eliminada' ELSE '✗ Eliminada' END AS filtro_deleted,

  -- Filtro 4: tenant
  CASE
    WHEN tr.tenant_id IS NULL THEN '✓ tenant_id es NULL (válido para todos)'
    WHEN ud.tenant = ANY(tr.tenant_id) THEN '✓ Tenant del usuario está en tenant_id'
    ELSE '✗ Tenant del usuario NO está en tenant_id'
  END AS filtro_tenant,

  -- Filtro 5: mes/año para indexadas
  CASE
    WHEN tr.rate_mode::text <> 'Indexada' THEN '✓ No es indexada (no aplica filtro mes/año)'
    WHEN tr.invoice_month IS NULL AND tr.invoice_year IS NULL THEN '✓ Indexada sin mes/año (válida para todos)'
    WHEN tr.invoice_month = cd.invoice_month AND tr.invoice_year = cd.invoice_year THEN '✓ Mes/año coinciden'
    ELSE '✗ Mes/año NO coinciden'
  END AS filtro_indexada_mes_anio,

  -- Filtro 6: subrate preferida
  CASE
    WHEN cd.preferred_subrate IS NULL THEN '✓ Sin subrate preferida (acepta todas)'
    WHEN cd.preferred_subrate = '' THEN '✓ Subrate vacía (acepta todas)'
    WHEN tr.subrate_name = cd.preferred_subrate THEN '✓ Subrate coincide'
    ELSE '✗ Subrate NO coincide'
  END AS filtro_subrate,

  -- Filtro 7: cif
  CASE
    WHEN tr.cif IS NULL THEN '✓ CIF tarifa es NULL (válido para todos)'
    WHEN tr.cif = cd.cif THEN '✓ CIF coincide'
    ELSE '✗ CIF NO coincide'
  END AS filtro_cif,

  -- Filtro 8: región
  CASE
    WHEN cd.region IS NULL THEN '✓ Sin región en comparativa (acepta todas)'
    WHEN cd.region = ANY(tr.region) THEN '✓ Región coincide'
    ELSE '✗ Región NO coincide'
  END AS filtro_region,

  -- Filtro 9: permanencia (fallback complejo)
  CASE
    WHEN cd.wants_permanence IS NOT TRUE THEN '✓ No pidió permanencia (acepta cualquiera)'
    WHEN tr.has_permanence = TRUE THEN '✓ Pidió permanencia y la tarifa la tiene'
    ELSE '⚠ Pidió permanencia pero tarifa no la tiene (verificar fallback)'
  END AS filtro_permanencia

FROM comparison_data cd
CROSS JOIN user_data ud
CROSS JOIN target_rate tr;
