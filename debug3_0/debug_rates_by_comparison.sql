-- Debug script para analizar qué rates son válidas para una comparison_id específica
-- Cambia el valor de @comparison_id para analizar diferentes casos

-- Parámetro: UUID de la comparison a analizar
-- 5b9f19c9-ce94-4612-b62b-639fb8f21c6d

-- 1. Información básica de la comparison
SELECT 
    '=== INFORMACIÓN BÁSICA DE LA COMPARISON ===' as info_section,
    c.id,
    c.created_at,
    c.client_email,
    c.company,
    c.rate_name as current_rate,
    c.rate_i_have,
    c.rate_i_want,
    c.preferred_subrate,
    c.region,
    c.cif,
    c.wants_permanence,
    c.invoice_month,
    c.invoice_year,
    c.advisor_id,
    u.email as advisor_email,
    u.tenant
FROM comparison_3_0 c
LEFT JOIN users u ON u.user_id = c.advisor_id
WHERE c.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d';

-- 2. Todas las rates disponibles tipo 3_0
SELECT 
    '=== TODAS LAS RATES 3_0 DISPONIBLES ===' as info_section,
    COUNT(*) as total_rates_3_0
FROM comparison_rates cr 
WHERE cr.type = '3_0' AND cr.deleted = FALSE;

-- 3. Rates que pasan los filtros básicos (sin tenant)
SELECT 
    '=== RATES QUE PASAN FILTROS BÁSICOS ===' as info_section,
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    cr.has_permanence,
    cr.region,
    cr.cif,
    cr.invoice_month,
    cr.invoice_year,
    cr.tenant_id
FROM comparison_rates cr
WHERE cr.type = '3_0'
  AND cr.deleted = FALSE
  AND cr.company <> (SELECT company FROM comparison_3_0 WHERE id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d')
  AND (
    cr.rate_mode::text <> 'Indexada'
    OR (
      (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
      OR (cr.invoice_month = (SELECT invoice_month FROM comparison_3_0 WHERE id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d')
          AND cr.invoice_year = (SELECT invoice_year FROM comparison_3_0 WHERE id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'))
    )
  )
ORDER BY cr.company, cr.rate_name;

-- 4. Rates que pasan filtros completos (incluyendo tenant)
SELECT 
    '=== RATES QUE PASAN FILTROS COMPLETOS ===' as info_section,
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    cr.has_permanence,
    cr.region,
    cr.cif,
    cr.invoice_month,
    cr.invoice_year,
    cr.tenant_id
FROM comparison_3_0 c30
LEFT JOIN users u ON u.user_id = c30.advisor_id
LEFT JOIN comparison_rates cr ON TRUE
WHERE c30.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'
  AND cr.type = '3_0'
  AND cr.deleted = FALSE
  AND cr.company <> c30.company
  AND (cr.tenant_id IS NULL OR u.tenant = ANY (cr.tenant_id))
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
    c30.wants_permanence IS NOT TRUE
    OR cr.has_permanence = TRUE
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
  AND (cr.cif IS NULL OR cr.cif = c30.cif)
  AND (c30.region IS NULL OR c30.region = ANY (cr.region))
ORDER BY cr.company, cr.rate_name;

-- 5. Caso especial: Fija -> Indexada
SELECT 
    '=== CASO ESPECIAL: FIJA -> INDEXADA ===' as info_section,
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    'Rate forzada para Fija->Indexada' as description
FROM comparison_3_0 c30
LEFT JOIN comparison_rates cr ON cr.id = 'febdbb18-8de5-4f2c-982a-ddfe2e18b3c8'
WHERE c30.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'
  AND c30.rate_i_have = 'Fija'
  AND c30.rate_i_want = 'Indexada'
  AND cr.id = 'febdbb18-8de5-4f2c-982a-ddfe2e18b3c8';

-- 6. Rates con CRS válidos para esta comparison
SELECT 
    '=== RATES CON CRS VÁLIDOS ===' as info_section,
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    crs.id as crs_id,
    crs.min_kw_anual,
    crs.max_kw_anual,
    crs.min_power,
    crs.max_power,
    COALESCE(c30.anual_consumption_p1,0::real)+COALESCE(c30.anual_consumption_p2,0::real)+COALESCE(c30.anual_consumption_p3,0::real)+
    COALESCE(c30.anual_consumption_p4,0::real)+COALESCE(c30.anual_consumption_p5,0::real)+COALESCE(c30.anual_consumption_p6,0::real) AS total_anual_consumption,
    c30.power_p1
FROM comparison_3_0 c30
LEFT JOIN users u ON u.user_id = c30.advisor_id
LEFT JOIN LATERAL (
    SELECT cr.*
    FROM comparison_rates cr
    WHERE cr.type = '3_0'
      AND (
        -- Caso forzado
        (c30.rate_i_have = 'Fija' AND c30.rate_i_want = 'Indexada' AND cr.id = 'febdbb18-8de5-4f2c-982a-ddfe2e18b3c8')
        -- Resto de casos
        OR (
          (c30.rate_i_have IS DISTINCT FROM 'Fija' OR cr.rate_mode IS DISTINCT FROM 'Indexada')
          AND cr.company <> c30.company
          AND (cr.deleted = FALSE)
          AND (cr.tenant_id IS NULL OR u.tenant = ANY (cr.tenant_id))
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
            c30.wants_permanence IS NOT TRUE
            OR cr.has_permanence = TRUE
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
          AND (cr.cif IS NULL OR cr.cif = c30.cif)
          AND (c30.region IS NULL OR c30.region = ANY (cr.region))
        )
      )
) cr ON TRUE
LEFT JOIN comparison_rates_crs crs
  ON crs.comparison_rate_id = cr.id
 AND (crs.min_kw_anual IS NULL OR (COALESCE(c30.anual_consumption_p1,0::real)+COALESCE(c30.anual_consumption_p2,0::real)+COALESCE(c30.anual_consumption_p3,0::real)+
    COALESCE(c30.anual_consumption_p4,0::real)+COALESCE(c30.anual_consumption_p5,0::real)+COALESCE(c30.anual_consumption_p6,0::real)) >= crs.min_kw_anual)
 AND (crs.max_kw_anual IS NULL OR (COALESCE(c30.anual_consumption_p1,0::real)+COALESCE(c30.anual_consumption_p2,0::real)+COALESCE(c30.anual_consumption_p3,0::real)+
    COALESCE(c30.anual_consumption_p4,0::real)+COALESCE(c30.anual_consumption_p5,0::real)+COALESCE(c30.anual_consumption_p6,0::real)) <  crs.max_kw_anual)
 AND (crs.min_power   IS NULL OR c30.power_p1 >= crs.min_power)
 AND (crs.max_power   IS NULL OR c30.power_p1 <  crs.max_power)
WHERE c30.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'
  AND (c30.deleted IS NULL OR c30.deleted = FALSE)
ORDER BY cr.company, cr.rate_name;

-- 7. Resumen final
SELECT 
    '=== RESUMEN FINAL ===' as info_section,
    (SELECT COUNT(*) FROM comparison_rates cr WHERE cr.type = '3_0' AND cr.deleted = FALSE) as total_rates_3_0,
    (SELECT COUNT(*) 
     FROM comparison_3_0 c30
     LEFT JOIN users u ON u.user_id = c30.advisor_id
     LEFT JOIN comparison_rates cr ON TRUE
     WHERE c30.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'
       AND cr.type = '3_0'
       AND cr.deleted = FALSE
       AND cr.company <> c30.company
       AND (cr.tenant_id IS NULL OR u.tenant = ANY (cr.tenant_id))
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
         c30.wants_permanence IS NOT TRUE
         OR cr.has_permanence = TRUE
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
       AND (cr.cif IS NULL OR cr.cif = c30.cif)
       AND (c30.region IS NULL OR c30.region = ANY (cr.region))
    ) as rates_que_pasan_filtros,
    (SELECT COUNT(*)
     FROM comparison_3_0 c30
     LEFT JOIN users u ON u.user_id = c30.advisor_id
     LEFT JOIN LATERAL (
       SELECT cr.*
       FROM comparison_rates cr
       WHERE cr.type = '3_0'
         AND (
           (c30.rate_i_have = 'Fija' AND c30.rate_i_want = 'Indexada' AND cr.id = 'febdbb18-8de5-4f2c-982a-ddfe2e18b3c8')
           OR (
             (c30.rate_i_have IS DISTINCT FROM 'Fija' OR cr.rate_mode IS DISTINCT FROM 'Indexada')
             AND cr.company <> c30.company
             AND (cr.deleted = FALSE)
             AND (cr.tenant_id IS NULL OR u.tenant = ANY (cr.tenant_id))
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
               c30.wants_permanence IS NOT TRUE
               OR cr.has_permanence = TRUE
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
             AND (cr.cif IS NULL OR cr.cif = c30.cif)
             AND (c30.region IS NULL OR c30.region = ANY (cr.region))
           )
         )
     ) cr ON TRUE
     LEFT JOIN comparison_rates_crs crs
       ON crs.comparison_rate_id = cr.id
      AND (crs.min_kw_anual IS NULL OR (COALESCE(c30.anual_consumption_p1,0::real)+COALESCE(c30.anual_consumption_p2,0::real)+COALESCE(c30.anual_consumption_p3,0::real)+
        COALESCE(c30.anual_consumption_p4,0::real)+COALESCE(c30.anual_consumption_p5,0::real)+COALESCE(c30.anual_consumption_p6,0::real)) >= crs.min_kw_anual)
      AND (crs.max_kw_anual IS NULL OR (COALESCE(c30.anual_consumption_p1,0::real)+COALESCE(c30.anual_consumption_p2,0::real)+COALESCE(c30.anual_consumption_p3,0::real)+
        COALESCE(c30.anual_consumption_p4,0::real)+COALESCE(c30.anual_consumption_p5,0::real)+COALESCE(c30.anual_consumption_p6,0::real)) <  crs.max_kw_anual)
      AND (crs.min_power   IS NULL OR c30.power_p1 >= crs.min_power)
      AND (crs.max_power   IS NULL OR c30.power_p1 <  crs.max_power)
     WHERE c30.id = '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'
       AND (c30.deleted IS NULL OR c30.deleted = FALSE)
    ) as rates_con_crs_validos;

-- Instrucciones de uso:
-- 1. El UUID ya está hardcoded: 5b9f19c9-ce94-4612-b62b-639fb8f21c6d
-- 2. Ejecuta este script en PostgreSQL
-- 3. Revisa cada sección para entender por qué algunas rates son filtradas
-- 4. La sección "RESUMEN FINAL" te da el conteo final de rates válidas
