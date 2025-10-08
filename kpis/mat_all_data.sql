DROP MATERIALIZED VIEW IF EXISTS public.mat_all_data_racc;
DROP MATERIALIZED VIEW IF EXISTS public.mat_all_data;

CREATE MATERIALIZED VIEW public.mat_all_data AS
WITH latest_val AS (
  -- Última valoración por (email, asesor) - se usa en el bloque CLIENTS
  SELECT DISTINCT ON (client_email, advisor_id)
         client_email,
         advisor_id,
         id         AS valuation_id,
         created_at AS valuation_created_at,
         pdf_proposal
  FROM public._valuations_detailed
  ORDER BY client_email, advisor_id, created_at DESC
),
latest_val_by_contract AS (
  -- Última valoración por contrato - se usa en el bloque CONTRACTS
  SELECT DISTINCT ON (contract_id)
         contract_id,
         id         AS valuation_id,
         created_at AS valuation_created_at,
         pdf_proposal
  FROM public._valuations_detailed
  WHERE contract_id IS NOT NULL
  ORDER BY contract_id, created_at DESC
),
latest_cmp AS (
  -- Última comparación por valoración (vista unificada)
  SELECT DISTINCT ON (valuation_id)
         valuation_id,
         id         AS comparison_id,
         created_at AS comparison_created_at,
         pdf_invoice
  FROM public.mat_comparisons_historic
  ORDER BY valuation_id, created_at DESC
)

-- =============================== CONTRACTS ===============================
SELECT
  u.tenant,                          --  1 tenant
  'contract'::text AS source,        --  2 source
  c.id,                              --  3 id
  c.created_at,                      --  4 created_at
  c.activation_date,                 --  5 activation_date
  c.client_email,                    --  6 client_email
  c.advisor_id,                      --  7 advisor_id
  u.email AS advisor_email,          --  8 advisor_email
  c.client_name AS name,             --  9
  c.client_last_name AS last_name,   -- 10
  c."DNI",                           -- 11
  c.client_address AS address,       -- 12
  c.phone_number AS phone,           -- 13
  c.client_type,                     -- 14
  c.contract_type,                   -- 15
  c.new_company,                     -- 16
  c.new_rate AS new_rate_name,       -- 17
  c.new_subrate,                     -- 18
  c.saving_percentage,               -- 19
  c.pdf_invoice,                     -- 20
  c.total_savings,                   -- 21
  c."CUPS",                          -- 22
  c.status,                          -- 23
  c.last_update,                     -- 24
  c.fecha_baja,                      -- 25
  c.baja_firma_delegada,             -- 26
  c.firma_date,                      -- 27
  lvc.valuation_id          AS valuation_id,          -- 28 (desde última valoración del contrato)
  lvc.valuation_created_at  AS valuation_created_at,  -- 29
  lvc.pdf_proposal          AS pdf_proposal,          -- 30
  lcc.comparison_id         AS comparison_id,         -- 31 (última comparación de esa valoración)
  lcc.comparison_created_at AS comparison_created_at  -- 32
FROM public._contracts_detailed c
JOIN public.users u ON u.user_id = c.advisor_id
LEFT JOIN latest_val_by_contract lvc ON lvc.contract_id = c.id
LEFT JOIN latest_cmp            lcc ON lcc.valuation_id = lvc.valuation_id

UNION ALL
-- ============================== COMPARISONS ==============================
SELECT
  c.tenant,                          --  1 tenant
  'comparison'::text AS source,      --  2
  c.id,                              --  3
  c.created_at,                      --  4
  NULL::timestamp   AS activation_date, -- 5
  c.client_email,                    --  6
  c.advisor_id,                      --  7
  u.email AS advisor_email,          --  8
  c.client_name       AS name,       --  9
  c.client_last_name  AS last_name,  -- 10
  c."DNI",                           -- 11
  NULL::text          AS address,    -- 12
  c.phone             AS phone,      -- 13
  NULL::text          AS client_type,-- 14
  c.contract_type,                   -- 15
  c.new_company,                     -- 16
  c.new_rate_name,                   -- 17
  c.new_subrate,                     -- 18
  c.saving_percentage,               -- 19
  c.pdf_invoice,                     -- 20
  NULL::double precision AS total_savings, -- 21
  c."CUPS",                          -- 22
  NULL::text         AS status,          -- 23
  NULL::timestamp    AS last_update,     -- 24
  NULL::timestamp    AS fecha_baja,      -- 25
  NULL::timestamp    AS baja_firma_delegada, -- 26
  NULL::timestamp    AS firma_date,      -- 27
  c.valuation_id      AS valuation_id,       -- 28
  v.created_at        AS valuation_created_at, -- 29
  v.pdf_proposal      AS pdf_proposal,        -- 30
  c.id                AS comparison_id,       -- 31
  c.created_at        AS comparison_created_at -- 32
FROM public.mat_comparisons_historic c
LEFT JOIN public._valuations_detailed v ON v.id = c.valuation_id
LEFT JOIN public.users u ON u.user_id = c.advisor_id

UNION ALL
-- =============================== VALUATIONS ===============================
SELECT
  u.tenant,                          --  1
  'valuation'::text AS source,       --  2
  v.id,                              --  3
  v.created_at,                      --  4
  NULL::timestamp   AS activation_date, -- 5
  v.client_email,                    --  6
  v.advisor_id,                      --  7
  u.email AS advisor_email,          --  8
  v.client_name      AS name,        --  9
  v.client_last_name AS last_name,   -- 10
  v.client_dni       AS "DNI",       -- 11
  NULL::text         AS address,     -- 12
  v.client_phone_number AS phone,    -- 13
  NULL::text         AS client_type, -- 14
  v.contract_type,                   -- 15
  v.new_company,                     -- 16
  v.new_rate         AS new_rate_name, -- 17
  v.new_subrate,                     -- 18
  v.saving_percentage,               -- 19
  v.pdf_invoice,                     -- 20
  NULL::double precision AS total_savings, -- 21
  v."CUPS",                          -- 22
  NULL::text         AS status,          -- 23
  NULL::timestamp    AS last_update,     -- 24
  NULL::timestamp    AS fecha_baja,      -- 25
  NULL::timestamp    AS baja_firma_delegada, -- 26
  NULL::timestamp    AS firma_date,      -- 27
  v.id               AS valuation_id,    -- 28
  v.created_at       AS valuation_created_at, -- 29
  v.pdf_proposal     AS pdf_proposal,    -- 30
  NULL::uuid         AS comparison_id,   -- 31
  NULL::timestamp    AS comparison_created_at -- 32
FROM public._valuations_detailed v
LEFT JOIN public.users u ON u.user_id = v.advisor_id

UNION ALL
-- ================================ CLIENTS ================================
SELECT
  u.tenant,                          --  1
  'client'::text AS source,          --  2
  cl.id,                             --  3
  cl.created_at,                     --  4
  NULL::timestamp   AS activation_date, -- 5
  cl.email          AS client_email, --  6
  cl.advisor_id,                     --  7
  u.email AS advisor_email,          --  8
  cl.name,                            --  9
  cl.last_name,                       -- 10
  cl."DNI",                           -- 11
  NULL::text       AS address,        -- 12
  cl.phone_number   AS phone,         -- 13
  cl.client_type,                    -- 14
  NULL::text       AS contract_type, -- 15
  NULL::text       AS new_company,   -- 16
  NULL::text       AS new_rate_name, -- 17
  NULL::text       AS new_subrate,   -- 18
  NULL::double precision AS saving_percentage, -- 19
  lc.pdf_invoice,                    -- 20 (última comparación)
  cl.total_savings,                  -- 21
  NULL::text       AS "CUPS",        -- 22
  NULL::text       AS status,        -- 23
  NULL::timestamp  AS last_update,   -- 24
  NULL::timestamp  AS fecha_baja,    -- 25
  NULL::timestamp  AS baja_firma_delegada, -- 26
  NULL::timestamp  AS firma_date,    -- 27
  lv.valuation_id,                   -- 28
  lv.valuation_created_at,           -- 29
  lv.pdf_proposal,                   -- 30
  lc.comparison_id,                  -- 31
  lc.comparison_created_at           -- 32
FROM public._clients_detailed cl
LEFT JOIN public.users u ON u.user_id = cl.advisor_id
LEFT JOIN latest_val lv
       ON lv.client_email = cl.email
      AND lv.advisor_id   = cl.advisor_id
LEFT JOIN latest_cmp lc
       ON lc.valuation_id = lv.valuation_id;
