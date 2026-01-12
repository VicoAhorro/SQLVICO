-- Ver todas las tarifas indexadas de light
SELECT 
    company,
    rate_name,
    subrate_name,
    rate_mode,
    invoice_month,
    invoice_year,
    deleted
FROM comparison_rates 
WHERE type = 'light' 
  AND rate_mode = 'Indexada' 
  AND deleted = FALSE
  AND company <> 'BASSOLS'  -- Excluir BASSOLS para el cliente
ORDER BY company, rate_name;
