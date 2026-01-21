-- Debug específico para el cliente 766f8403-54ec-4c76-8fd4-fe701a6250dd
-- Verificar por qué las 3 tarifas con autoconsumo no aparecen

WITH target AS (
  SELECT
    cl.*,
    u.tenant AS advisor_tenant
  FROM comparison_light cl
  LEFT JOIN users u ON u.user_id = cl.advisor_id
  WHERE cl.id = '766f8403-54ec-4c76-8fd4-fe701a6250dd'
),
candidates AS (
  SELECT
    t.id AS comparison_id,
    t.company AS comparison_company,
    t.advisor_tenant,
    
    cr.id AS rate_id,
    cr.company AS rate_company,
    cr.rate_name,
    cr.subrate_name,
    cr.rate_mode,
    cr.region,
    cr.selfconsumption,
    cr.has_permanence,
    cr.cif,
    cr.has_gdo,
    cr.tenant_id,
    cr.deleted,

    -- Verificación de cada filtro individual
    (cr.company <> t.company) AS f_different_company,
    (cr.deleted = FALSE) AS f_not_deleted,
    (cr.tenant_id IS NULL OR t.advisor_tenant = ANY(cr.tenant_id)) AS f_tenant_ok,
    
    -- Filtro de periodo/subrate (completo)
    (
      (cr.rate_mode = 'Indexada'
        AND (
            t.preferred_subrate IS NULL
            OR t.preferred_subrate = ''
            OR LOWER(cr.subrate_name::text) = LOWER(t.preferred_subrate::text)
        )
      )
      OR (cr.rate_mode <> 'Indexada'
          AND ((cr.invoice_month = t.invoice_month AND cr.invoice_year = t.invoice_year)
            AND (
                t.preferred_subrate IS NULL
                OR t.preferred_subrate = ''
                OR LOWER(cr.subrate_name::text) = LOWER(t.preferred_subrate::text)
            )
          )
      )
      OR (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
      OR (
          cr.rate_mode <> 'Indexada'
          AND (cr.invoice_month = t.invoice_month AND cr.invoice_year = t.invoice_year)
          AND NOT EXISTS (
              SELECT 1
              FROM comparison_rates crs
              WHERE crs.type = 'light'
                AND crs.company <> t.company
                AND crs.invoice_month = t.invoice_month
                AND crs.invoice_year = t.invoice_year
                AND crs.rate_mode <> 'Indexada'
                AND LOWER(crs.subrate_name::text) = LOWER(t.preferred_subrate::text)
          )
      )
      OR (
          cr.rate_mode <> 'Indexada'
          AND cr.invoice_year = t.invoice_year
          AND NOT EXISTS (
              SELECT 1
              FROM comparison_rates cry
              WHERE cry.type = 'light'
                AND cry.company <> t.company
                AND cry.invoice_month = t.invoice_month
                AND cry.invoice_year = t.invoice_year
                AND cry.rate_mode <> 'Indexada'
          )
      )
    ) AS f_period_subrate,

    (t.region IS NULL OR t.region = ANY (cr.region)) AS f_region,
    
    -- Exclusión de compañías
    (
      t.excluded_company_ids IS NULL 
      OR NOT (
        cr.company IN (
          SELECT c_ex.name 
          FROM companies c_ex 
          WHERE c_ex.id = ANY (t.excluded_company_ids)
        )
      )
    ) AS f_not_excluded,

    -- Autoconsumo (el filtro crítico)
    (
      (t.selfconsumption = TRUE AND COALESCE(cr.selfconsumption, FALSE) = TRUE)
      OR (t.selfconsumption IS DISTINCT FROM TRUE AND cr.selfconsumption IS DISTINCT FROM TRUE)
    ) AS f_selfconsumption,

    (cr.cif IS NULL OR cr.cif = t.cif) AS f_cif,
    (t.wants_permanence IS NULL OR cr.has_permanence = t.wants_permanence) AS f_permanence,
    (t.wants_gdo = false OR cr.has_gdo = true) AS f_gdo,
    (t.valuation_id is null) AS f_no_valuation,
    (t.deleted = false) AS f_not_deleted_client,

    -- Resultado global
    (
      (cr.company <> t.company)
      AND (cr.deleted = FALSE)
      AND (cr.tenant_id IS NULL OR t.advisor_tenant = ANY(cr.tenant_id))
      AND (
        (cr.rate_mode = 'Indexada'
          AND (
            t.preferred_subrate IS NULL
            OR t.preferred_subrate = ''
            OR LOWER(cr.subrate_name::text) = LOWER(t.preferred_subrate::text)
          )
        )
        OR (cr.rate_mode <> 'Indexada'
            AND ((cr.invoice_month = t.invoice_month AND cr.invoice_year = t.invoice_year)
              AND (
                t.preferred_subrate IS NULL
                OR t.preferred_subrate = ''
                OR LOWER(cr.subrate_name::text) = LOWER(t.preferred_subrate::text)
              )
            )
          )
        OR (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
        OR (
            cr.rate_mode <> 'Indexada'
            AND (cr.invoice_month = t.invoice_month AND cr.invoice_year = t.invoice_year)
            AND NOT EXISTS (
                SELECT 1
                FROM comparison_rates crs
                WHERE crs.type = 'light'
                  AND crs.company <> t.company
                  AND crs.invoice_month = t.invoice_month
                  AND crs.invoice_year = t.invoice_year
                  AND crs.rate_mode <> 'Indexada'
                  AND LOWER(crs.subrate_name::text) = LOWER(t.preferred_subrate::text)
            )
          )
        OR (
            cr.rate_mode <> 'Indexada'
            AND cr.invoice_year = t.invoice_year
            AND NOT EXISTS (
                SELECT 1
                FROM comparison_rates cry
                WHERE cry.type = 'light'
                  AND cry.company <> t.company
                  AND cry.invoice_month = t.invoice_month
                  AND cry.invoice_year = t.invoice_year
                  AND cry.rate_mode <> 'Indexada'
            )
          )
      )
      AND (t.region IS NULL OR t.region = ANY (cr.region))
      AND (
        t.excluded_company_ids IS NULL 
        OR NOT (
          cr.company IN (
            SELECT c_ex.name 
            FROM companies c_ex 
            WHERE c_ex.id = ANY (t.excluded_company_ids)
          )
        )
      )
      AND (
        (t.selfconsumption = TRUE AND COALESCE(cr.selfconsumption, FALSE) = TRUE)
        OR (t.selfconsumption IS DISTINCT FROM TRUE AND cr.selfconsumption IS DISTINCT FROM TRUE)
      )
      AND (cr.cif IS NULL OR cr.cif = t.cif)
      AND (t.wants_permanence IS NULL OR cr.has_permanence = t.wants_permanence)
      AND (t.wants_gdo = false OR cr.has_gdo = true)
      AND (t.valuation_id is null)
      AND (t.deleted = false)
    ) AS passes_all_filters

  FROM target t
  JOIN comparison_rates cr
    ON cr.type = 'light'
)
SELECT
  c.rate_company,
  c.rate_name,
  c.subrate_name,
  c.selfconsumption,
  c.has_permanence,
  c.rate_mode,
  c.tenant_id,
  c.advisor_tenant,
  
  -- Estado de cada filtro
  f.filter_name,
  f.passes AS filter_passes,
  CASE WHEN f.passes THEN '[OK]' ELSE '[NO]' END AS checkmark,
  
  c.passes_all_filters,
  CASE WHEN c.passes_all_filters THEN '[APROBADA]' ELSE '[RECHAZADA]' END AS final_status

FROM candidates c
CROSS JOIN LATERAL (
  VALUES
    ('f_different_company', c.f_different_company),
    ('f_not_deleted', c.f_not_deleted),
    ('f_tenant_ok', c.f_tenant_ok),
    ('f_period_subrate', c.f_period_subrate),
    ('f_region', c.f_region),
    ('f_not_excluded', c.f_not_excluded),
    ('f_selfconsumption', c.f_selfconsumption),
    ('f_cif', c.f_cif),
    ('f_permanence', c.f_permanence),
    ('f_gdo', c.f_gdo),
    ('f_no_valuation', c.f_no_valuation),
    ('f_not_deleted_client', c.f_not_deleted_client)
) AS f(filter_name, passes)
WHERE c.selfconsumption = TRUE  -- Solo tarifas con autoconsumo
ORDER BY 
  c.passes_all_filters DESC,
  c.rate_company,
  c.rate_name,
  f.filter_name;
