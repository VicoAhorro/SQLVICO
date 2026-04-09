-- Debug funnel para comparativas 3_0.
-- Uso:
--   1. Sustituye target_id por el UUID de comparison_3_0 que quieras analizar.
--   2. Ejecuta el script completo.
--
-- Devuelve:
--   - Los datos base de la comparativa.
--   - Un conteo por etapa para ver en qué filtro se quedan fuera las tarifas.
--   - El detalle final de las tarifas que sobreviven.

WITH params AS (
  SELECT '5b9f19c9-ce94-4612-b62b-639fb8f21c6d'::uuid AS target_id
),
base AS (
  SELECT
    c30.*,
    u.email AS advisor_email,
    u.tenant
  FROM comparison_3_0 c30
  LEFT JOIN users u ON u.user_id = c30.advisor_id
  JOIN params p ON p.target_id = c30.id
),
all_rates AS (
  SELECT cr.*
  FROM comparison_rates cr
  WHERE cr.type = '3_0'
),
step_type AS (
  SELECT ar.*, b.id AS comparison_id
  FROM all_rates ar
  CROSS JOIN base b
),
step_forced_or_regular AS (
  SELECT s.*
  FROM step_type s
  CROSS JOIN base b
  WHERE
    (
      b.rate_i_have = 'Fija'
      AND b.rate_i_want = 'Indexada'
      AND s.id = 'febdbb18-8de5-4f2c-982a-ddfe2e18b3c8'
    )
    OR (
      (b.rate_i_have IS DISTINCT FROM 'Fija' OR s.rate_mode IS DISTINCT FROM 'Indexada')
      AND s.company <> b.company
      AND s.deleted = FALSE
      AND (s.tenant_id IS NULL OR b.tenant = ANY (s.tenant_id))
      AND (
        s.rate_mode::text <> 'Indexada'
        OR (
          (s.invoice_month IS NULL AND s.invoice_year IS NULL)
          OR (s.invoice_month = b.invoice_month AND s.invoice_year = b.invoice_year)
        )
      )
      AND (
        b.preferred_subrate IS NULL
        OR b.preferred_subrate = ''
        OR s.subrate_name = b.preferred_subrate
      )
      AND (
        b.ssaa_preference IS NULL
        OR b.ssaa_preference = ''
        OR (b.ssaa_preference = '12' AND COALESCE(s.ssaa, '') IN ('12', '18', 'incluidos'))
        OR (b.ssaa_preference = '18' AND COALESCE(s.ssaa, '') IN ('18', 'incluidos'))
        OR (b.ssaa_preference = 'incluidos' AND COALESCE(s.ssaa, '') = 'incluidos')
      )
      AND (
        (b.wants_permanence IS TRUE AND (
          s.has_permanence = TRUE
          OR NOT EXISTS (
            SELECT 1
            FROM comparison_rates crp
            WHERE crp.type = '3_0'
              AND crp.company <> b.company
              AND (
                crp.rate_mode::text <> 'Indexada'
                OR (
                  (crp.invoice_month IS NULL AND crp.invoice_year IS NULL)
                  OR (crp.invoice_month = b.invoice_month AND crp.invoice_year = b.invoice_year)
                )
              )
              AND (
                b.preferred_subrate IS NULL
                OR b.preferred_subrate = ''
                OR crp.subrate_name = b.preferred_subrate
              )
              AND (
                b.ssaa_preference IS NULL
                OR b.ssaa_preference = ''
                OR (b.ssaa_preference = '12' AND COALESCE(crp.ssaa, '') IN ('12', '18', 'incluidos'))
                OR (b.ssaa_preference = '18' AND COALESCE(crp.ssaa, '') IN ('18', 'incluidos'))
                OR (b.ssaa_preference = 'incluidos' AND COALESCE(crp.ssaa, '') = 'incluidos')
              )
              AND (b.region IS NULL OR b.region = ANY (crp.region))
              AND crp.has_permanence = TRUE
              AND (b.wants_gdo = FALSE OR crp.has_gdo = TRUE)
          )
        ))
        OR (b.wants_permanence IS FALSE AND COALESCE(s.has_permanence, FALSE) = FALSE)
        OR (b.wants_permanence IS NULL)
      )
      AND (s.cif IS NULL OR s.cif = b.cif)
      AND (b.region IS NULL OR b.region = ANY (s.region))
      AND (b.wants_gdo = FALSE OR s.has_gdo = TRUE)
      AND (
        b.excluded_company_ids IS NULL
        OR NOT (
          s.company IN (
            SELECT c_ex.name
            FROM companies c_ex
            WHERE c_ex.id = ANY (b.excluded_company_ids)
          )
        )
      )
      AND (
        b.wants_permanence IS NOT TRUE
        OR b.term_month_i_want IS NULL
        OR (s.term_month <= b.term_month_i_want AND s.term_month > (b.term_month_i_want - 12))
      )
    )
),
ranked AS (
  SELECT
    s.*,
    ROW_NUMBER() OVER (PARTITION BY s.comparison_id, s.rate_mode ORDER BY s.company, s.rate_name, s.id) AS rank_by_mode,
    ROW_NUMBER() OVER (PARTITION BY s.comparison_id ORDER BY s.company, s.rate_name, s.id) AS rank_global
  FROM step_forced_or_regular s
),
final_selection AS (
  SELECT r.*
  FROM ranked r
  CROSS JOIN base b
  WHERE
    (b.rate_i_want IS NULL AND r.rank_global = 1)
    OR (b.rate_i_want = 'Fija' AND r.rate_mode = 'Fija' AND r.rank_by_mode = 1)
    OR (b.rate_i_want = 'Indexada' AND r.rate_mode = 'Indexada' AND r.rank_by_mode = 1)
)

SELECT
  'base_comparison' AS section,
  b.id::text AS comparison_id,
  b.company,
  b.rate_i_have::text AS rate_i_have,
  b.rate_i_want::text AS rate_i_want,
  b.preferred_subrate,
  b.ssaa_preference,
  b.region,
  b.cif::text AS cif,
  b.wants_permanence::text AS wants_permanence,
  b.term_month_i_want::text AS term_month_i_want,
  b.wants_gdo::text AS wants_gdo,
  b.invoice_month::text AS invoice_month,
  b.invoice_year::text AS invoice_year,
  b.advisor_email
FROM base b

UNION ALL

SELECT
  'count_all_rates',
  COUNT(*)::text,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM all_rates

UNION ALL

SELECT
  'count_after_full_filter',
  COUNT(*)::text,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM step_forced_or_regular

UNION ALL

SELECT
  'count_fixed_after_full_filter',
  COUNT(*)::text,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM step_forced_or_regular
WHERE rate_mode = 'Fija'

UNION ALL

SELECT
  'count_indexed_after_full_filter',
  COUNT(*)::text,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM step_forced_or_regular
WHERE rate_mode = 'Indexada'

UNION ALL

SELECT
  'count_final_selection',
  COUNT(*)::text,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM final_selection
;

SELECT
  r.id,
  r.company,
  r.rate_name,
  r.subrate_name,
  r.rate_mode,
  r.invoice_month,
  r.invoice_year,
  r.has_permanence,
  r.term_month,
  r.has_gdo,
  r.ssaa,
  r.rank_by_mode,
  r.rank_global
FROM ranked r
ORDER BY r.rate_mode, r.rank_by_mode, r.company, r.rate_name;

SELECT
  f.id,
  f.company,
  f.rate_name,
  f.subrate_name,
  f.rate_mode,
  f.invoice_month,
  f.invoice_year,
  f.has_permanence,
  f.term_month,
  f.has_gdo,
  f.ssaa
FROM final_selection f
ORDER BY f.company, f.rate_name;
