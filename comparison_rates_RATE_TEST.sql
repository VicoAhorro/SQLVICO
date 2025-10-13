WITH cg AS (
  SELECT
    id,
    company,
    rate_name,
    region,
    invoice_month,
    invoice_year,
    preferred_subrate,
    wants_permanence,
    cif
  FROM comparison_gas
  WHERE id = 'c811fa22-bfed-4974-a266-7f700f8d4620'
),
candidates AS (
  SELECT cr.*
  FROM comparison_rates cr
  JOIN cg
    ON cr.type = 'gas'
   AND cr.company <> cg.company
   -- subrate_name ESTRICTO = rate_name
   AND cr.subrate_name = cg.rate_name
   -- periodo: mismo mes/año o tarifa sin periodo
   AND (
         (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
      OR (cr.invoice_month = cg.invoice_month AND cr.invoice_year = cg.invoice_year)
   )
   -- preferred_subrate (redundante aquí, pero no estorba)
   AND (
        cg.preferred_subrate IS NULL
        OR cg.preferred_subrate = ''
        OR cr.subrate_name = cg.rate_name
   )
   -- región (SIN comodín: si quieres comodín, añade "OR cr.region IS NULL")
   AND (cg.region IS NULL OR cg.region = ANY (cr.region))
   -- CIF (cg.cif nunca NULL) ⇒ admite cr.cif = cg.cif o NULL
   AND (cr.cif IS NULL OR cr.cif = cg.cif)
   -- Permanencia con fallback
   AND (
        cg.wants_permanence IS NOT TRUE
        OR cr.has_permanence = TRUE
        OR NOT EXISTS (
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
               -- misma regla de CIF en el fallback
               AND (crp.cif IS NULL OR crp.cif = cg.cif)
               AND crp.has_permanence = TRUE
        )
   )
)
SELECT
  id, company, rate_name, subrate_name,
  cif, region, has_permanence, rate_mode,
  price_pp1, price_cp1, price_surpluses
FROM candidates
ORDER BY company, rate_name, subrate_name;
