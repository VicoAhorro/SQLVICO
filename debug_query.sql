
-- Verificar tarifas que cumplen TODOS los criterios para este cliente
SELECT 
  cr.company,
  cr.rate_name,
  cr.subrate_name,
  cr.selfconsumption,
  cr.invoice_month,
  cr.invoice_year,
  cr.rate_mode,
  cr.region
FROM comparison_rates cr
WHERE cr.type = 'light'
AND cr.company <> 'BASSOLS'
AND cr.deleted = FALSE
AND cr.selfconsumption = TRUE
AND LOWER(cr.subrate_name) = LOWER('Fija')
AND (cr.invoice_month = 12 AND cr.invoice_year = 2025 OR (cr.invoice_month IS NULL AND cr.invoice_year IS NULL))
AND ('PENINSULA' IS NULL OR 'PENINSULA' = ANY (cr.region))
ORDER BY cr.company, cr.rate_name
LIMIT 10;

