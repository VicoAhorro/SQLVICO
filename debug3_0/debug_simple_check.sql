-- Verificación simple para la comparison 5b9f19c9-ce94-4612-b62b-639fb8f21c6d

-- 1. Verificar datos básicos de la comparison
SELECT 
    '=== DATOS DE LA COMPARISON ===' as info,
    id,
    rate_i_have,
    rate_i_want,
    company,
    preferred_subrate,
    region
FROM comparison_3_0 
WHERE id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d';

-- 2. Ver si hay rates indexadas disponibles para esta comparison
SELECT 
    '=== RATES INDEXADAS DISPONIBLES ===' as info,
    cr.id,
    cr.company,
    cr.rate_name,
    cr.rate_mode,
    cr.subrate_name,
    cr.has_permanence,
    cr.region
FROM comparison_rates cr
WHERE cr.type = '3_0'
  AND cr.deleted = FALSE
  AND cr.company <> 'GALP'
  AND cr.rate_mode = 'Indexada'
  AND (cr.region IS NULL OR 'PENINSULA' = ANY (cr.region))
ORDER BY cr.company, cr.rate_name
LIMIT 10;

-- 3. Verificar si alguna rate indexada tiene CRS válido
SELECT 
    '=== RATES INDEXADAS CON CRS ===' as info,
    cr.id,
    cr.company,
    cr.rate_name,
    cr.rate_mode,
    crs.id as crs_id,
    crs.min_kw_anual,
    crs.max_kw_anual,
    (4437+5262+4287+4079+1576+27853) as total_anual_consumption
FROM comparison_rates cr
LEFT JOIN comparison_rates_crs crs ON crs.comparison_rate_id = cr.id
WHERE cr.type = '3_0'
  AND cr.deleted = FALSE
  AND cr.company <> 'GALP'
  AND cr.rate_mode = 'Indexada'
  AND (cr.region IS NULL OR 'PENINSULA' = ANY (cr.region))
  AND (crs.min_kw_anual IS NULL OR (4437+5262+4287+4079+1576+27853) >= crs.min_kw_anual)
  AND (crs.max_kw_anual IS NULL OR (4437+5262+4287+4079+1576+27853) < crs.max_kw_anual)
ORDER BY cr.company, cr.rate_name
LIMIT 10;

-- 4. Verificar rankings de rates indexadas (simulando el proceso)
WITH filtered_rates AS (
  SELECT 
    cr.*,
    ROW_NUMBER() OVER (
      PARTITION BY cr.id, cr.rate_mode
      ORDER BY cr.company, cr.rate_name
    ) AS rank_by_mode,
    ROW_NUMBER() OVER (
      PARTITION BY cr.id
      ORDER BY cr.company, cr.rate_name
    ) AS rank
  FROM comparison_rates cr
  WHERE cr.type = '3_0'
    AND cr.deleted = FALSE
    AND cr.company <> 'GALP'
    AND cr.rate_mode = 'Indexada'
    AND (cr.region IS NULL OR 'PENINSULA' = ANY (cr.region))
    AND EXISTS (
      SELECT 1 FROM comparison_rates_crs crs
      WHERE crs.comparison_rate_id = cr.id
        AND (crs.min_kw_anual IS NULL OR (4437+5262+4287+4079+1576+27853) >= crs.min_kw_anual)
        AND (crs.max_kw_anual IS NULL OR (4437+5262+4287+4079+1576+27853) < crs.max_kw_anual)
    )
)
SELECT 
    '=== RANKINGS DE RATES INDEXADAS ===' as info,
    id,
    company,
    rate_name,
    rate_mode,
    rank_by_mode,
    rank,
    CASE 
        WHEN rank_by_mode = 1 THEN 'ESTA SERÍA LA SELECCIONADA'
        ELSE 'No seleccionada'
    END as seleccion
FROM filtered_rates
ORDER BY rank_by_mode;

-- 5. Verificar si hay valoración creada
SELECT 
    '=== VALORACIÓN ===' as info,
    id,
    status,
    created_at
FROM valuations 
WHERE comparison_id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d';
