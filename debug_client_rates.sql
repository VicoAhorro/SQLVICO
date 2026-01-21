-- Debug para ver qué tarifas disponibles podría coincidir con el cliente
-- ID: 766f8403-54ec-4c76-8fd4-fe701a6250dd

SELECT 
    cr.id,
    cr.company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    cr.invoice_month,
    cr.invoice_year,
    cr.region,
    cr.selfconsumption,
    cr.has_permanence,
    cr.cif,
    cr.has_gdo,
    cr.deleted,
    
    -- Verificación de filtros clave
    CASE 
        WHEN cr.company = 'BASSOLS' THEN '[NO] Misma compañía'
        WHEN cr.deleted = TRUE THEN '[NO] Tarifa eliminada'
        WHEN cr.selfconsumption IS DISTINCT FROM TRUE THEN '[NO] Sin autoconsumo'
        WHEN NOT ('PENINSULA' = ANY(cr.region) OR cr.region IS NULL) THEN '[NO] No cubre PENINSULA'
        WHEN cr.invoice_month IS NOT NULL AND cr.invoice_year IS NOT NULL 
             AND NOT (cr.invoice_month = 12 AND cr.invoice_year = 2025) 
             AND cr.rate_mode <> 'Indexada' THEN '[NO] Periodo incorrecto'
        ELSE '[OK] Posible candidata'
    END AS filter_status,
    
    -- Detalle de verificación de región
    CASE 
        WHEN cr.region IS NULL THEN 'Región: NULL (permite todo)'
        WHEN 'PENINSULA' = ANY(cr.region) THEN 'Región: OK - incluye PENINSULA'
        ELSE 'Región: NO - ' || array_to_string(cr.region, ', ')
    END AS region_detail,
    
    -- Detalle de autoconsumo
    CASE 
        WHEN cr.selfconsumption IS TRUE THEN 'Autoconsumo: OK'
        WHEN cr.selfconsumption IS FALSE THEN 'Autoconsumo: NO'
        ELSE 'Autoconsumo: NULL'
    END AS selfconsumption_detail

FROM comparison_rates cr
WHERE cr.type = 'light'
  AND cr.company <> 'BASSOLS'
  AND cr.deleted = FALSE
ORDER BY 
    filter_status,
    cr.company,
    cr.rate_name,
    cr.subrate_name;
