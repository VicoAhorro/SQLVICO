--DROP VIEW IF EXISTS public._comparisons_detailed_light;

CREATE OR REPLACE VIEW public._comparisons_detailed_light AS
WITH
-- ====== Base con tarifas candidatas ======
base AS (
  SELECT
    cl.id,
    cl.created_at,
    cl.client_email,
    cl.advisor_id,

    -- Segmento desde tabla comparisons
    cmp.client_type,

    -- Consumos (light: P1..P3)
    cl.consumption_p1,
    cl.consumption_p2,
    cl.consumption_p3,

    -- Potencias (light: P1..P2)
    cl.power_p1,
    cl.power_p2,

    cl.current_total_invoice,
    cl.surpluses,
    cl."VAT",
    cl.power_days,
    cl.pdf_invoice,
    cl."CUPS",
    cl.address_id,
    cl.company,
    cl.rate_name,
    cl.invoice_month,
    cl.equipment_rental,
    cl.selfconsumption,
    cl.manual_data,
    cl.valuation_id,
    cl.invoice_year,
    cl.temp_client_name,
    cl.temp_client_last_name,
    cl.deleted,
    cl.deleted_reason,
    cl.deleted_at,
    cl.preferred_subrate,
    cl.wants_permanence,

    -- Anuales (light: P1..P3)
    cl.anual_consumption_p1,
    cl.anual_consumption_p2,
    cl.anual_consumption_p3,

    cl.max_power,

    -- Precios actuales
    cl."precio_kwh_P1",
    cl."precio_kwh_P2",
    cl."precio_kwh_P3",
    cl."precio_kw_P1",
    cl."precio_kw_P2",

    -- Autoconsumo y totales precalculados
    cl.autoconsumo_precio,
    cl.totalconsumo,
    cl.totalpotencia,

    cl.tarifa_plana,
    cl.cif,
    cl.region,
    cl.term_month_i_want,
    cl.excluded_company_ids,
    cl.wants_gdo,
    cl.temp_client_phone,
    cl.comparison_id,

    -- Candidata de tarifas nuevas
    cr.id          AS new_rate_id,
    cr.company     AS new_company,
    cr.rate_name   AS new_rate_name,
    cr.subrate_name AS new_subrate_name,
    cr.term_month,

    cr.price_pp1, cr.price_pp2, cr.price_pp3, cr.price_pp4, cr.price_pp5, cr.price_pp6,
    cr.price_cp1, cr.price_cp2, cr.price_cp3, cr.price_cp4, cr.price_cp5, cr.price_cp6,
    cr.price_surpluses,

    cr.has_maintenance,
    cr.daily_maintenance_with_vat,
    cr.has_permanence,
    cr.has_gdo,
    cr.rate_mode,
    cl.total_excedentes_precio

  FROM (SELECT * FROM comparison_light WHERE valuation_id IS NULL AND deleted = false) cl
  LEFT JOIN public.comparisons cmp ON cl.comparison_id = cmp.id
  LEFT JOIN users u ON u.user_id = cl.advisor_id
  LEFT JOIN comparison_rates cr
  ON cr.type = 'light'
  AND cr.company <> cl.company
  AND (cr.deleted = FALSE)
  AND (cr.tenant_id IS NULL OR u.tenant = ANY(cr.tenant_id))
  LEFT JOIN companies c ON c.name = cr.company
  WHERE (
      (cr.rate_mode <> 'Indexada'
        AND (
            cl.preferred_subrate IS NULL
            OR cl.preferred_subrate = ''
            OR LOWER(cr.subrate_name::text) = LOWER(cl.preferred_subrate::text)
        )
      )
      OR (cr.rate_mode = 'Indexada'
          AND ((cr.invoice_month = cl.invoice_month AND cr.invoice_year = cl.invoice_year)
            AND (
                cl.preferred_subrate IS NULL
                OR cl.preferred_subrate = ''
                OR LOWER(cr.subrate_name::text) = LOWER(cl.preferred_subrate::text)
            )
          )
      )
      OR (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
      OR (
          cr.rate_mode = 'Indexada'
          AND (cr.invoice_month = cl.invoice_month AND cr.invoice_year = cl.invoice_year)
          AND NOT EXISTS (
              SELECT 1 FROM comparison_rates crs WHERE crs.type = 'light' AND crs.company <> cl.company AND crs.invoice_month = cl.invoice_month AND crs.invoice_year = cl.invoice_year AND crs.rate_mode = 'Indexada' AND LOWER(crs.subrate_name::text) = LOWER(cl.preferred_subrate::text)
          )
      )
      OR (
          cr.rate_mode = 'Indexada' AND cr.invoice_year = cl.invoice_year AND NOT EXISTS (
              SELECT 1 FROM comparison_rates cry WHERE cry.type = 'light' AND cry.company <> cl.company AND cry.invoice_month = cl.invoice_month AND cry.invoice_year = cl.invoice_year AND cry.rate_mode = 'Indexada'
          )
      )
  )
  AND (cl.region IS NULL OR cl.region = ANY (cr.region))
  AND (cl.excluded_company_ids IS NULL OR NOT (cr.company IN (SELECT c_ex.name FROM companies c_ex WHERE c_ex.id = ANY (cl.excluded_company_ids))))
  AND (
    (cl.selfconsumption = TRUE AND COALESCE(cr.selfconsumption, FALSE) = TRUE)
    OR (cl.selfconsumption IS DISTINCT FROM TRUE AND cr.selfconsumption IS DISTINCT FROM TRUE)
  )
  AND (cr.cif IS NULL OR cr.cif = cl.cif)
  AND (cl.wants_permanence IS NULL OR COALESCE(cr.has_permanence, false) = cl.wants_permanence)
  AND (cl.wants_permanence IS NOT TRUE OR cl.term_month_i_want IS NULL OR (cr.term_month <= cl.term_month_i_want AND cr.term_month > (cl.term_month_i_want - 12)))
  AND (cl.wants_gdo = false OR cr.has_gdo = true)
),

m_calc AS (
  SELECT
    b.*,
    CASE WHEN b.has_maintenance = true THEN b.daily_maintenance_with_vat * COALESCE(b.power_days, 0)::double precision ELSE 0 END AS maintenance_total,
    (COALESCE(b.consumption_p1,0::real)*COALESCE(b.price_cp1,0::real) + COALESCE(b.consumption_p2,0::real)*COALESCE(b.price_cp2,0::real) + COALESCE(b.consumption_p3,0::real)*COALESCE(b.price_cp3,0::real)) AS m_consumo,
    (COALESCE(b.power_p1,0::real)*COALESCE(b.price_pp1,0::real)*COALESCE(b.power_days,0::double precision) + COALESCE(b.power_p2,0::real)*COALESCE(b.price_pp2,0::real)*COALESCE(b.power_days,0::double precision)) AS m_potencia,
    (COALESCE(b.consumption_p1,0::real)*COALESCE(b.price_cp1,0::real) + COALESCE(b.consumption_p2,0::real)*COALESCE(b.price_cp2,0::real) + COALESCE(b.consumption_p3,0::real)*COALESCE(b.price_cp3,0::real)) AS total_consumption_price,
    (COALESCE(b.power_p1,0::real)*COALESCE(b.price_pp1,0::real)*COALESCE(b.power_days,0::double precision) + COALESCE(b.power_p2,0::real)*COALESCE(b.price_pp2,0::real)*COALESCE(b.power_days,0::double precision)) AS total_power_price,
    COALESCE(b.surpluses,0)*COALESCE(b.price_surpluses,0) AS total_surpluses_price,
    (
      COALESCE(b.power_p1, 0::real) * COALESCE(b.price_pp1, 0::real) * COALESCE(b.power_days, 0)::double precision +
      COALESCE(b.power_p2, 0::real) * COALESCE(b.price_pp2, 0::real) * COALESCE(b.power_days, 0)::double precision +
      COALESCE(b.consumption_p1, 0::real) * COALESCE(b.price_cp1, 0::real) +
      COALESCE(b.consumption_p2, 0::real) * COALESCE(b.price_cp2, 0::real) +
      COALESCE(b.consumption_p3, 0::real) * COALESCE(b.price_cp3, 0::real) -
      COALESCE(b.surpluses, 0::real) * COALESCE(b.price_surpluses, 0::real)
    ) AS new_total_price
  FROM base b
),

tot AS (
  SELECT
    m.*,
    (m.m_consumo + m.m_potencia) * 0.05113::double precision AS iee_monthly,
    (( (COALESCE(m.new_total_price, 0)::double precision * 1.05113) + COALESCE(m.equipment_rental, 0) ) * (1.0 + COALESCE(m."VAT", 0))) AS new_total_price_with_vat_base,
    ((
      COALESCE(m.anual_consumption_p1,0::real)*COALESCE(m.price_cp1,0::real) +
      COALESCE(m.anual_consumption_p2,0::real)*COALESCE(m.price_cp2,0::real) +
      COALESCE(m.anual_consumption_p3,0::real)*COALESCE(m.price_cp3,0::real) +
      COALESCE(NULLIF(m.power_p1,0::double precision),1::real)*COALESCE(m.price_pp1,0::real)*365::double precision +
      COALESCE(m.power_p2,0::real)*COALESCE(m.price_pp2,0::real)*365::double precision
      - COALESCE(m.surpluses,0) * 182.5::double precision / NULLIF(m.power_days::double precision,0) * COALESCE(m.price_surpluses,0::real)
    ) * (1 + 0.05113) * (1 + COALESCE(m."VAT",0))) + (COALESCE(m.daily_maintenance_with_vat, 0) * 365) AS new_total_yearly_price_with_vat,

    (
      COALESCE(m.anual_consumption_p1,0::real)*COALESCE(m."precio_kwh_P1",0::real) +
      COALESCE(m.anual_consumption_p2,0::real)*COALESCE(m."precio_kwh_P2",0::real) +
      COALESCE(m.anual_consumption_p3,0::real)*COALESCE(m."precio_kwh_P3",0::real) +
      COALESCE(NULLIF(m.power_p1,0::double precision),1::real)*COALESCE(m."precio_kw_P1",0::real)*365::double precision +
      COALESCE(m.power_p2,0::real)*COALESCE(m."precio_kw_P2",0::real)*365::double precision
      - COALESCE(m.surpluses,0) * 182.5::double precision / NULLIF(m.power_days::double precision,0) * COALESCE(m.autoconsumo_precio,0)
    ) * (1 + 0.05113) * (1 + COALESCE(m."VAT",0)) AS current_total_yearly_price_with_vat
  FROM m_calc m
),

with_crs AS (
  SELECT
    t.*,
    crs.id AS crs_id,
    COALESCE(t.anual_consumption_p1,0::real)*COALESCE(crs.crs_cp1,0::real) +
    COALESCE(t.anual_consumption_p2,0::real)*COALESCE(crs.crs_cp2,0::real) +
    COALESCE(t.anual_consumption_p3,0::real)*COALESCE(crs.crs_cp3,0::real) +
    COALESCE(t.power_p1,0::real)*COALESCE(crs.crs_pp1,0::real) +
    COALESCE(t.power_p2,0::real)*COALESCE(crs.crs_pp2,0::real) +
    COALESCE(crs.fixed_crs,0::real) AS total_crs,

    CASE
      WHEN t.new_company IS NOT NULL THEN
        COALESCE(t.current_total_invoice, 0::real)::double precision - (t.new_total_price_with_vat_base + COALESCE(t.maintenance_total, 0))
      ELSE 0.0::double precision
    END AS savings,
    CASE
      WHEN t.tarifa_plana = TRUE THEN t.current_total_invoice * (365.0 / NULLIF(t.power_days::numeric,0))::double precision - t.new_total_yearly_price_with_vat
      WHEN t.new_company IS NOT NULL THEN t.current_total_yearly_price_with_vat - t.new_total_yearly_price_with_vat
      ELSE 0.0::double precision
    END AS savings_yearly
  FROM tot t
  LEFT JOIN comparison_rates_crs crs
    ON crs.comparison_rate_id = t.new_rate_id
   AND (crs.min_kw_anual IS NULL OR (COALESCE(t.anual_consumption_p1,0::real)+COALESCE(t.anual_consumption_p2,0::real)+COALESCE(t.anual_consumption_p3,0::real)) >= crs.min_kw_anual)
   AND (crs.max_kw_anual IS NULL OR (COALESCE(t.anual_consumption_p1,0::real)+COALESCE(t.anual_consumption_p2,0::real)+COALESCE(t.anual_consumption_p3,0::real)) <  crs.max_kw_anual)
   AND (crs.min_power   IS NULL OR t.power_p1 >= crs.min_power)
   AND (crs.max_power   IS NULL OR t.power_p1 <  crs.max_power)
),

-- ====== AHORRO % PARA LOGICA K ======
with_savings_percentage AS (
  SELECT
    wc.*,
    CASE
      WHEN wc.new_company IS NOT NULL AND wc.current_total_yearly_price_with_vat <> 0 AND wc.tarifa_plana IS NOT TRUE
        THEN (wc.current_total_yearly_price_with_vat - wc.new_total_yearly_price_with_vat) / wc.current_total_yearly_price_with_vat
      WHEN wc.tarifa_plana = TRUE AND wc.power_days > 0
        THEN (wc.current_total_invoice * (365.0 / wc.power_days::double precision) - wc.new_total_yearly_price_with_vat) / NULLIF(wc.current_total_invoice * (365.0 / wc.power_days::double precision), 0::double precision)
      ELSE 0.0::double precision
    END AS saving_percentage
  FROM with_crs wc
),

-- ====== FILTRO NP > Y ======
filtered_np AS (
  SELECT
    s.*
  FROM with_savings_percentage s
  WHERE (
    -- Luz B2C (Particular): NP > 30
    (COALESCE(s.client_type::text, 'Particular') = 'Particular' AND s.total_crs > 30)
    OR
    -- Luz B2B (Empresa): NP > 100
    (s.client_type::text = 'Empresa' AND s.total_crs > 100)
    -- Si no hay match (fallback por seguridad si Total CRS es muy bajo y no queremos tirar todo)
    -- Pero la imagen dice "Definir valor minimo", asi que filtramos.
  )
),

rank_prep AS (
  SELECT
    f.*,
    (NULLIF(f.preferred_subrate, '') IS NOT NULL) AS has_subrate_pref,
    (NULLIF(f.preferred_subrate, '') IS NOT NULL AND f.new_subrate_name = f.preferred_subrate) AS subrate_match,
    -- Logica k
    CASE
      WHEN f.saving_percentage <= 0.10 THEN 0
      WHEN f.rate_mode = 'Indexada' THEN 500
      ELSE 1000 -- Fija
    END AS k_factor
  FROM filtered_np f
),

subrate_exist AS (
  SELECT id, BOOL_OR(subrate_match) AS exists_subrate_match_for_id FROM rank_prep GROUP BY id
),

ranked AS (
  SELECT
    rp.*,
    se.exists_subrate_match_for_id,
    rp.savings_yearly + (rp.k_factor * rp.total_crs) AS ranked_crs,

    ROW_NUMBER() OVER (
      PARTITION BY rp.id
      ORDER BY
        CASE WHEN rp.has_subrate_pref AND se.exists_subrate_match_for_id THEN CASE WHEN rp.subrate_match THEN 1 ELSE 0 END ELSE 1 END DESC,
        CASE WHEN rp.savings_yearly > 0 THEN 1 ELSE 0 END DESC,
        rp.savings_yearly + (rp.k_factor * rp.total_crs) DESC
    ) AS rank
  FROM rank_prep rp
  LEFT JOIN subrate_exist se USING (id)
),

with_advisor AS (
  SELECT r.*, us.supervisors, us.email AS advisor_email, us.display_name AS advisor_display_name FROM ranked r LEFT JOIN _users_supervisors_all us ON r.advisor_id = us.user_id
)

SELECT DISTINCT
  rc.id, rc.created_at, rc.client_email, rc.advisor_id,
  rc.consumption_p1, rc.consumption_p2, rc.consumption_p3, 0::real AS consumption_p4, 0::real AS consumption_p5, 0::real AS consumption_p6,
  rc.anual_consumption_p1, rc.anual_consumption_p2, rc.anual_consumption_p3, 0::real AS anual_consumption_p4, 0::real AS anual_consumption_p5, 0::real AS anual_consumption_p6,
  rc.autoconsumo_precio,
  rc."precio_kw_P1", rc."precio_kw_P2", 0::real AS "precio_kw_P3", 0::real AS "precio_kw_P4", 0::real AS "precio_kw_P5", 0::real AS "precio_kw_P6",
  rc."precio_kwh_P1", rc."precio_kwh_P2", rc."precio_kwh_P3", 0::real AS "precio_kwh_P4", 0::real AS "precio_kwh_P5", 0::real AS "precio_kwh_P6",
  (COALESCE(rc.consumption_p1,0::real)+COALESCE(rc.consumption_p2,0::real)+COALESCE(rc.consumption_p3,0::real))::real AS total_consumption,
  (COALESCE(rc.anual_consumption_p1,0::real)+COALESCE(rc.anual_consumption_p2,0::real)+COALESCE(rc.anual_consumption_p3,0::real))::real AS total_anual_consumption,
  rc.power_p1, rc.power_p2, 0::real AS power_p3, 0::real AS power_p4, 0::real AS power_p5, 0::real AS power_p6,
  rc.current_total_invoice, rc.surpluses, rc.total_surpluses_price, 0::real AS power_surpluses,
  rc."VAT", rc.power_days AS days, rc.pdf_invoice, rc."CUPS", rc.address_id, rc.company, rc.rate_name, rc.invoice_month, rc.equipment_rental, rc.selfconsumption, rc.manual_data,
  0::real AS reactive, rc.valuation_id, rc.invoice_year, 0::real AS meter_rental, rc.preferred_subrate,
  rc.new_company, rc.new_rate_name, rc.new_subrate_name,
  rc.price_pp1, rc.price_pp2, rc.price_pp3, rc.price_pp4, rc.price_pp5, rc.price_pp6,
  rc.price_cp1, rc.price_cp2, rc.price_cp3, rc.price_cp4, rc.price_cp5, rc.price_cp6,
  rc.price_surpluses,
  rc.total_power_price, rc.total_consumption_price, rc.new_total_price,
  'light'::text AS type, COALESCE(rc.temp_client_name,'') AS temp_client_name, COALESCE(rc.temp_client_last_name,'') AS temp_client_last_name, ARRAY['light'::text,'All'::text] AS type_filter,
  rc.deleted, rc.deleted_reason, rc.deleted_at, rc.new_rate_id, COALESCE(rc.max_power,0)::real AS max_power,
  0 AS speed_fiber, 0 AS mobile_lines, 0 AS mobile_total_gb, FALSE AS fijo, 0 AS new_speed_fiber, 0 AS new_total_mobile_lines, 0 AS new_mobile_total_gb, ''::text AS rate_pack, 0 AS phone_total_anual_price,
  rc.crs_id, rc.total_crs, rc.savings, rc.savings_yearly, rc.ranked_crs, rc.rank,
  rc.tarifa_plana, rc.iee_monthly,
  ((COALESCE(rc.anual_consumption_p1,0::real)*COALESCE(rc.price_cp1,0::real) + COALESCE(rc.anual_consumption_p2,0::real)*COALESCE(rc.price_cp2,0::real) + COALESCE(rc.anual_consumption_p3,0::real)*COALESCE(rc.price_cp3,0::real) + (COALESCE(rc.power_p1,0::real)*COALESCE(rc.price_pp1,0::real) + COALESCE(rc.power_p2,0::real)*COALESCE(rc.price_pp2,0::real)) * 365::double precision) * 0.05113::double precision) AS iee,
  rc.new_total_price_with_vat_base + COALESCE(rc.maintenance_total, 0) AS new_total_price_with_vat,
  rc.new_total_yearly_price_with_vat,
  rc.saving_percentage,
  rc.supervisors, COALESCE(rc.temp_client_name,'') AS client_name, COALESCE(rc.temp_client_last_name,'') AS client_last_name, rc.advisor_email, rc.advisor_display_name, ARRAY[COALESCE(rc.advisor_email,''::text),'All'] AS advisor_filter,
  EXTRACT(MONTH FROM rc.created_at)::text AS created_month, EXTRACT(YEAR  FROM rc.created_at)::text AS created_year,
  COALESCE(rc."CUPS",'') || ' ' || COALESCE(rc.advisor_display_name,'') || ' ' || COALESCE(rc.advisor_email,'') || ' ' || LOWER(COALESCE(rc.client_email,'') || ' ' || COALESCE(rc.company,'') || ' ' || COALESCE(rc.rate_name,'') || ' ' || COALESCE(rc.temp_client_name,'') || ' ' || COALESCE(rc.temp_client_last_name,'')) AS search,
  ARRAY[COALESCE(rc.company,''::text),'All'] AS company_filter,
  rc.cif, rc.region, rc.daily_maintenance_with_vat::numeric(8,2), rc.has_permanence, rc.rate_mode, rc.total_excedentes_precio, null::rate_mode_type AS rate_i_have, rc.term_month, rc.term_month_i_want, rc.excluded_company_ids, rc.wants_gdo, rc.temp_client_phone, rc.comparison_id, rc.wants_permanence, null::text AS ssaa_preference, null::text AS new_ssaa, rc.has_gdo

FROM with_advisor rc
WHERE rc.rank = 1;
