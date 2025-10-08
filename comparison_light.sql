 --DROP VIEW IF EXISTS public._comparisons_detailed_light;

CREATE OR REPLACE VIEW public._comparisons_detailed_light_test AS
WITH

-- ====== Base con tarifas candidatas ======
base AS (
  SELECT
    cl.id,
    cl.created_at,
    cl.client_email,
    cl.advisor_id,

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
    cl.preferred_subrate,
    cl.wants_permanence,

    -- Anuales (light: P1..P3)
    cl.anual_consumption_p1,
    cl.anual_consumption_p2,
    cl.anual_consumption_p3,

    cl.max_power,

    -- Precios actuales (para coste "actual")
    cl."precio_kwh_P1",
    cl."precio_kwh_P2",
    cl."precio_kwh_P3",
    cl."precio_kw_P1",
    cl."precio_kw_P2",

    -- Autoconsumo y totales precalculados de la factura original
    cl.autoconsumo_precio,
    cl.totalconsumo,
    cl.totalpotencia,

    -- Flags
    cl.tarifa_plana,
    cl.cif,
    cl.region,

    -- Candidata de tarifas nuevas
    cr.id          AS new_rate_id,
    cr.company     AS new_company,
    cr.rate_name   AS new_rate_name,
    cr.subrate_name AS new_subrate_name,

    cr.price_pp1, cr.price_pp2, cr.price_pp3, cr.price_pp4, cr.price_pp5, cr.price_pp6,
    cr.price_cp1, cr.price_cp2, cr.price_cp3, cr.price_cp4, cr.price_cp5, cr.price_cp6,
    cr.price_surpluses,

    -- Columnas de mantenimiento
    cr.has_maintenance,
    cr.daily_maintenance_with_vat,
    cr.has_permanence,
    cr.rate_mode

  FROM comparison_light cl
  LEFT JOIN comparison_rates cr
    ON cr.type = 'light'
   AND cr.company <> cl.company
   AND (
        (cr.invoice_month IS NULL AND cr.invoice_year IS NULL)
        OR (cr.invoice_month = cl.invoice_month AND cr.invoice_year = cl.invoice_year)
   )
   AND (
        cl.preferred_subrate IS NULL
        OR cl.preferred_subrate = ''
        OR cr.subrate_name = cl.preferred_subrate
   )
   AND (
        (cl.selfconsumption = TRUE AND cr.selfconsumption = TRUE)
        OR (cl.selfconsumption = FALSE)
   )
   AND (cl.region IS NULL OR cl.region = ANY (cr.region))
   AND (
        (cl.wants_permanence = TRUE AND cr.has_permanence = TRUE)
        OR (cl.wants_permanence = FALSE)
   )
  WHERE cl.deleted IS DISTINCT FROM TRUE
),

-- ====== Metrizaciones mensuales y totales base ======
m_calc AS (
  SELECT
    b.*,

    -- Cálculo de mantenimiento mensual
    CASE 
      WHEN b.has_maintenance = true THEN 
        b.daily_maintenance_with_vat * COALESCE(b.power_days, 0)::double precision
      ELSE 0 
    END AS maintenance_total,

    -- Totales "nuevo" (energia + potencia) por mes, pre-IVA (para trazabilidad)
    (COALESCE(b.consumption_p1,0::real)*COALESCE(b.price_cp1,0::real) +
     COALESCE(b.consumption_p2,0::real)*COALESCE(b.price_cp2,0::real) +
     COALESCE(b.consumption_p3,0::real)*COALESCE(b.price_cp3,0::real))                 AS m_consumo,

    (COALESCE(b.power_p1,0::real)*COALESCE(b.price_pp1,0::real)*COALESCE(b.power_days,0::double precision) +
     COALESCE(b.power_p2,0::real)*COALESCE(b.price_pp2,0::real)*COALESCE(b.power_days,0::double precision)) AS m_potencia,

    -- Totales mensuales por bloque (para trazabilidad)
    (COALESCE(b.consumption_p1,0::real)*COALESCE(b.price_cp1,0::real) +
     COALESCE(b.consumption_p2,0::real)*COALESCE(b.price_cp2,0::real) +
     COALESCE(b.consumption_p3,0::real)*COALESCE(b.price_cp3,0::real))                 AS total_consumption_price,

    (COALESCE(b.power_p1,0::real)*COALESCE(b.price_pp1,0::real)*COALESCE(b.power_days,0::double precision) +
     COALESCE(b.power_p2,0::real)*COALESCE(b.price_pp2,0::real)*COALESCE(b.power_days,0::double precision)) AS total_power_price,

    COALESCE(b.surpluses,0)*COALESCE(b.price_surpluses,0)                   AS total_surpluses_price,

    -- Precio mensual NUEVO (pre-IVA, sin IEE)
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

-- ====== Totales con IEE/VAT y anuales ======
tot AS (
  SELECT
    m.*,

    -- IEE mensual (para columna iee_monthly)
    (m.m_consumo + m.m_potencia) * 0.05113::double precision                                     AS iee_monthly,

    -- Calcular base sin mantenimiento primero
    CASE
      WHEN m.tarifa_plana = TRUE THEN
        (
          (COALESCE(m.new_total_price, 0::double precision) * 1.05113::double precision)
          + COALESCE(m.equipment_rental, 0::real)
        ) * (1::double precision + COALESCE(m."VAT", 0::real))
      ELSE
        (
          (COALESCE(m.new_total_price, 0::double precision))::double precision
          ) * 1.05113::double precision
          + COALESCE(m.equipment_rental, 0::real)
        ) * (1::double precision + COALESCE(m."VAT", 0::real))
    END::numeric::double precision AS new_total_price_with_vat_base,

    -- Precio anual NUEVO con IEE + VAT + mantenimiento anual
    (
      COALESCE(m.anual_consumption_p1,0::real)*COALESCE(m.price_cp1,0::real) +
      COALESCE(m.anual_consumption_p2,0::real)*COALESCE(m.price_cp2,0::real) +
      COALESCE(m.anual_consumption_p3,0::real)*COALESCE(m.price_cp3,0::real) +
      COALESCE(NULLIF(m.power_p1,0::double precision),1::real)*COALESCE(m.price_pp1,0::real)*365::double precision +
      COALESCE(m.power_p2,0::real)*COALESCE(m.price_pp2,0::real)*365::double precision
    ) * (1 + 0.05113::double precision) * (1 + COALESCE(m."VAT",0::real)) 
    + (COALESCE(m.daily_maintenance_with_vat, 0) * 365) AS new_total_yearly_price_with_vat,

    -- Precio anual ACTUAL con IEE + VAT (para savings_yearly)
    (
      COALESCE(m.anual_consumption_p1,0::real)*COALESCE(m."precio_kwh_P1",0::real) +
      COALESCE(m.anual_consumption_p2,0::real)*COALESCE(m."precio_kwh_P2",0::real) +
      COALESCE(m.anual_consumption_p3,0::real)*COALESCE(m."precio_kwh_P3",0::real) +
      COALESCE(NULLIF(m.power_p1,0::double precision),1::real)*COALESCE(m."precio_kw_P1",0::real)*365::double precision +
      COALESCE(m.power_p2,0::real)*COALESCE(m."precio_kw_P2",0::real)*365::double precision
      - COALESCE(m.surpluses,0) * 182.5::double precision / NULLIF(m.power_days::double precision,0) * COALESCE(m.autoconsumo_precio,0)
    ) * (1 + 0.05113::double precision) * (1 + COALESCE(m."VAT",0::real))                         AS current_total_yearly_price_with_vat
  FROM m_calc m
),

-- ====== CRS y ahorros ======
with_crs AS (
  SELECT
    t.*,
    crs.id AS crs_id,
    -- CRS total (solo P1..P3 energía y P1..P2 potencia en light)
    COALESCE(t.anual_consumption_p1,0::real)*COALESCE(crs.crs_cp1,0::real) +
    COALESCE(t.anual_consumption_p2,0::real)*COALESCE(crs.crs_cp2,0::real) +
    COALESCE(t.anual_consumption_p3,0::real)*COALESCE(crs.crs_cp3,0::real) +
    COALESCE(t.power_p1,0::real)*COALESCE(crs.crs_pp1,0::real) +
    COALESCE(t.power_p2,0::real)*COALESCE(crs.crs_pp2,0::real) +
    COALESCE(crs.fixed_crs,0::real)                                                         AS total_crs,

    -- Ahorro mensual (actual mensual - nuevo mensual con mantenimiento)
    CASE
      WHEN t.new_company IS NOT NULL THEN
        COALESCE(t.current_total_invoice, 0::real)::double precision
        -
        (
          t.new_total_price_with_vat_base + COALESCE(t.maintenance_total, 0)
        )
      ELSE 0.0::double precision
    END                                                                                AS savings,

    -- Ahorro anual (actual anual - nuevo anual con mantenimiento)
    CASE
      WHEN t.tarifa_plana = TRUE THEN
        t.current_total_invoice * (365.0 / NULLIF(t.power_days::numeric,0))::double precision
        - t.new_total_yearly_price_with_vat
      WHEN t.new_company IS NOT NULL THEN
        t.current_total_yearly_price_with_vat - t.new_total_yearly_price_with_vat
      ELSE 0.0::double precision
    END                                                                                AS savings_yearly
  FROM tot t
  LEFT JOIN comparison_rates_crs crs
    ON crs.comparison_rate_id = t.new_rate_id
   AND (crs.min_kw_anual IS NULL OR (COALESCE(t.anual_consumption_p1,0::real)+COALESCE(t.anual_consumption_p2,0::real)+COALESCE(t.anual_consumption_p3,0::real)) >= crs.min_kw_anual)
   AND (crs.max_kw_anual IS NULL OR (COALESCE(t.anual_consumption_p1,0::real)+COALESCE(t.anual_consumption_p2,0::real)+COALESCE(t.anual_consumption_p3,0::real)) <  crs.max_kw_anual)
   AND (crs.min_power   IS NULL OR t.power_p1 >= crs.min_power)
   AND (crs.max_power   IS NULL OR t.power_p1 <  crs.max_power)
),

-- ====== Ranking ======
ranked AS (
  SELECT
    w.*,
    CASE
      WHEN w.new_company IS NOT NULL AND w.savings_yearly > 0
        THEN w.savings_yearly + COALESCE(w.total_crs,0::real)::double precision * 4.0
      ELSE w.savings_yearly + COALESCE(w.total_crs,0::real)::double precision * 4.0
    END AS ranked_crs,
    ROW_NUMBER() OVER (
      PARTITION BY w.id
      ORDER BY
        CASE
          WHEN w.new_company IS NOT NULL AND w.savings_yearly > 0
            THEN w.savings_yearly + COALESCE(w.total_crs,0::real)::double precision * 4.0
          ELSE w.savings_yearly + COALESCE(w.total_crs,0::real)::double precision * 4.0
        END DESC
    ) AS rank
  FROM with_crs w
),

-- ====== Supervisores y datos asesor ======
with_advisor AS (
  SELECT
    r.*,
    CASE
      WHEN (SELECT u2.racc FROM users u2 WHERE u2.user_id = r.advisor_id LIMIT 1) = TRUE
        THEN (SELECT array_cat(us.supervisors, array_agg(ur.user_id)) FROM users_racc ur)
      ELSE us.supervisors
    END                       AS supervisors,
    u.email                   AS advisor_email,
    u.name                    AS advisor_display_name
  FROM ranked r
  LEFT JOIN _users_supervisors us ON r.advisor_id = us.user_id
  LEFT JOIN users u               ON u.user_id     = r.advisor_id
)

-- ====== SELECT FINAL ======
SELECT DISTINCT
  -- Identificación y cabecera
  rc.id,
  rc.created_at,
  rc.client_email,
  rc.advisor_id,

  -- Consumos por periodo (normalizamos P4..P6 = 0)
  rc.consumption_p1,
  rc.consumption_p2,
  rc.consumption_p3,
  0::real AS consumption_p4,
  0::real AS consumption_p5,
  0::real AS consumption_p6,

  -- Anuales por periodo (normalizamos P4..P6 = 0)
  rc.anual_consumption_p1,
  rc.anual_consumption_p2,
  rc.anual_consumption_p3,
  0::real AS anual_consumption_p4,
  0::real AS anual_consumption_p5,
  0::real AS anual_consumption_p6,

  -- Autoconsumo
  rc.autoconsumo_precio,

  -- Precios potencia nuevos (P3..P6 = 0 en light)
  rc."precio_kw_P1",
  rc."precio_kw_P2",
  0::real AS "precio_kw_P3",
  0::real AS "precio_kw_P4",
  0::real AS "precio_kw_P5",
  0::real AS "precio_kw_P6",

  -- Precios energía nuevos (P4..P6 = 0 en light)
  rc."precio_kwh_P1",
  rc."precio_kwh_P2",
  rc."precio_kwh_P3",
  0::real AS "precio_kwh_P4",
  0::real AS "precio_kwh_P5",
  0::real AS "precio_kwh_P6",

  -- Totales consumo
  (COALESCE(rc.consumption_p1,0::real)+COALESCE(rc.consumption_p2,0::real)+COALESCE(rc.consumption_p3,0::real))::real AS total_consumption,
  (COALESCE(rc.anual_consumption_p1,0::real)+COALESCE(rc.anual_consumption_p2,0::real)+COALESCE(rc.anual_consumption_p3,0::real))::real AS total_anual_consumption,

  -- Potencias (normalizamos P3..P6 = 0)
  rc.power_p1,
  rc.power_p2,
  0::real AS power_p3,
  0::real AS power_p4,
  0::real AS power_p5,
  0::real AS power_p6,

  -- Factura actual / excedentes
  rc.current_total_invoice,
  rc.surpluses,
  rc.total_surpluses_price,
  0::real AS power_surpluses,

  -- Fiscalidad y metadatos
  rc."VAT",
  rc.power_days AS days,
  rc.pdf_invoice,
  rc."CUPS",
  rc.address_id,
  rc.company,
  rc.rate_name,
  rc.invoice_month,
  rc.equipment_rental,
  rc.selfconsumption,
  rc.manual_data,
  0::real AS reactive,            -- no aplica en light (normalizado a 0)
  rc.valuation_id,
  rc.invoice_year,
  0::real AS meter_rental,        -- no aplica, normalizado a 0
  rc.preferred_subrate,

  -- Nueva tarifa
  rc.new_company,
  rc.new_rate_name,
  rc.new_subrate_name,
  rc.price_pp1,
  rc.price_pp2,
  rc.price_pp3,
  rc.price_pp4,
  rc.price_pp5,
  rc.price_pp6,
  rc.price_cp1,
  rc.price_cp2,
  rc.price_cp3,
  rc.price_cp4,
  rc.price_cp5,
  rc.price_cp6,
  rc.price_surpluses,

  -- Totales cálculo nuevo (mensual pre-IVA)
  rc.total_power_price,
  rc.total_consumption_price,
  rc.new_total_price,

  -- Tipo y metadatos de cliente/filtros
  'light'::text AS type,
  COALESCE(rc.temp_client_name,'')      AS temp_client_name,
  COALESCE(rc.temp_client_last_name,'') AS temp_client_last_name,
  ARRAY['light'::text,'All'::text]      AS type_filter,

  rc.deleted,
  rc.deleted_reason,
  rc.new_rate_id,
  COALESCE(rc.max_power,0)::real AS max_power,

  -- Telefonía/pack normalizados a 0 en light
  0 AS speed_fiber,
  0 AS mobile_lines,
  0 AS mobile_total_gb,
  FALSE AS fijo,
  0 AS new_speed_fiber,
  0 AS new_total_mobile_lines,
  0 AS new_mobile_total_gb,
  ''::text AS rate_pack,
  0 AS phone_total_anual_price,

  -- CRS y ahorros
  rc.crs_id,
  rc.total_crs,
  rc.savings,
  rc.savings_yearly,
  rc.ranked_crs,
  rc.rank,

  -- Flags e impuestos
  rc.tarifa_plana,
  rc.iee_monthly,

  -- IEE anual (derivado de anuales * factor)
  (
    (
      COALESCE(rc.anual_consumption_p1,0::real)*COALESCE(rc.price_cp1,0::real) +
      COALESCE(rc.anual_consumption_p2,0::real)*COALESCE(rc.price_cp2,0::real) +
      COALESCE(rc.anual_consumption_p3,0::real)*COALESCE(rc.price_cp3,0::real) +
      (COALESCE(rc.power_p1,0::real)*COALESCE(rc.price_pp1,0::real) +
       COALESCE(rc.power_p2,0::real)*COALESCE(rc.price_pp2,0::real)) * 365::double precision
    ) * 0.05113::double precision
  ) AS iee,

  -- Precio nuevo mensual con IVA + mantenimiento
  rc.new_total_price_with_vat_base + COALESCE(rc.maintenance_total, 0) AS new_total_price_with_vat,

  rc.new_total_yearly_price_with_vat,

  -- % ahorro (coherente con gas/3_0)
  CASE
    WHEN rc.new_company IS NOT NULL AND rc.current_total_yearly_price_with_vat <> 0
      THEN (rc.current_total_yearly_price_with_vat - rc.new_total_yearly_price_with_vat)
           / rc.current_total_yearly_price_with_vat
    WHEN rc.tarifa_plana = TRUE AND rc.power_days > 0
      THEN (
        rc.current_total_invoice * (365.0 / rc.power_days::double precision) - rc.new_total_yearly_price_with_vat
      ) / NULLIF(rc.current_total_invoice * (365.0 / rc.power_days::double precision), 0::double precision)
    ELSE 0.0::double precision
  END AS saving_percentage,

  -- Personas
  rc.supervisors,
  COALESCE(rc.temp_client_name,'')      AS client_name,
  COALESCE(rc.temp_client_last_name,'') AS client_last_name,
  u.email                               AS advisor_email,
  u.name                                AS advisor_display_name,
  ARRAY[COALESCE(u.email,''::text),'All'] AS advisor_filter,

  -- Derivados de fecha, búsqueda y filtros
  EXTRACT(MONTH FROM rc.created_at)::text AS created_month,
  EXTRACT(YEAR  FROM rc.created_at)::text AS created_year,
  LOWER(
    COALESCE(rc."CUPS",'') || ' ' ||
    COALESCE(rc.client_email,'') || ' ' ||
    COALESCE(rc.company,'') || ' ' ||
    COALESCE(rc.rate_name,'') || ' ' ||
    COALESCE(rc.temp_client_name,'') || ' ' ||
    COALESCE(rc.temp_client_last_name,'')
  ) AS search,
  ARRAY[COALESCE(rc.company,''::text),'All'] AS company_filter,
  rc.cif,
  rc.region,
  rc.daily_maintenance_with_vat::numeric(8,2),
  rc.has_permanence,
  rc.rate_mode

FROM with_advisor rc
LEFT JOIN users u ON u.user_id = rc.advisor_id
WHERE rc.rank = 1
  AND (rc.deleted IS NULL OR rc.deleted = FALSE);