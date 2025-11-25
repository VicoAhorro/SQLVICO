-- Query de diagnóstico para la comparación 3516574f-ccb0-43a5-a2a5-44fe35ff0b38

-- 1. Verificar datos de la comparación
SELECT
    id,
    company,
    rate_i_want,
    rate_i_have,
    preferred_subrate,
    region,
    cif,
    invoice_month,
    invoice_year,
    wants_permanence
FROM comparison_3_0
WHERE id = '3516574f-ccb0-43a5-a2a5-44fe35ff0b38';

-- 2. Ver tarifas disponibles que podrían hacer match
SELECT
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    cr.has_permanence,
    cr.invoice_month,
    cr.invoice_year,
    cr.region,
    cr.cif,
    cr.deleted
FROM comparison_rates cr
WHERE cr.type = '3_0'
    AND cr.deleted = FALSE
    AND cr.rate_mode = 'Indexada'
ORDER BY cr.company, cr.rate_name;

-- 3. Ver si hay alguna tarifa que no sea de la misma compañía
SELECT
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    cr.has_permanence,
    cr.invoice_month,
    cr.invoice_year
FROM comparison_rates cr
WHERE cr.type = '3_0'
    AND cr.company <> 'OTRO'
    AND cr.deleted = FALSE
    AND cr.rate_mode = 'Indexada'
    AND (cr.invoice_month IS NULL OR cr.invoice_month = 10)
    AND (cr.invoice_year IS NULL OR cr.invoice_year = 2025)
    AND (cr.subrate_name = '3.0' OR cr.subrate_name IS NULL)
    AND ('PENINSULA' = ANY(cr.region) OR cr.region IS NULL)
    AND (cr.cif IS NULL OR cr.cif = true)
ORDER BY cr.company, cr.rate_name;

-- 4. Verificar todas las condiciones del JOIN paso a paso
WITH c30_data AS (
    SELECT * FROM comparison_3_0
    WHERE id = '3516574f-ccb0-43a5-a2a5-44fe35ff0b38'
)
SELECT
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    CASE WHEN cr.company <> c30.company THEN '✓' ELSE '✗' END as diff_company,
    CASE WHEN cr.deleted = FALSE THEN '✓' ELSE '✗' END as not_deleted,
    CASE WHEN (cr.rate_mode::text <> 'Indexada' OR
               ((cr.invoice_month IS NULL AND cr.invoice_year IS NULL) OR
                (cr.invoice_month = c30.invoice_month AND cr.invoice_year = c30.invoice_year)))
         THEN '✓' ELSE '✗' END as month_year_check,
    CASE WHEN (c30.preferred_subrate IS NULL OR c30.preferred_subrate = '' OR cr.subrate_name = c30.preferred_subrate)
         THEN '✓' ELSE '✗' END as subrate_check,
    CASE WHEN (c30.rate_i_want IS NULL OR cr.rate_mode = c30.rate_i_want)
         THEN '✓' ELSE '✗' END as rate_mode_check,
    CASE WHEN (c30.region IS NULL OR c30.region = ANY(cr.region))
         THEN '✓' ELSE '✗' END as region_check,
    CASE WHEN (cr.cif IS NULL OR cr.cif = c30.cif)
         THEN '✓' ELSE '✗' END as cif_check
FROM comparison_rates cr
CROSS JOIN c30_data c30
WHERE cr.type = '3_0'
ORDER BY
    diff_company DESC,
    not_deleted DESC,
    month_year_check DESC,
    subrate_check DESC,
    rate_mode_check DESC,
    region_check DESC,
    cif_check DESC;
