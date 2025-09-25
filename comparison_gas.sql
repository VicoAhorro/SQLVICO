drop view public._comparisons_detailed_gas;
create or replace view public._comparisons_detailed_gas as
with
-- ====================== BASE GAS ======================
calculated_prices_gas as (
  select
    cg.id,
    cg.created_at,
    cg.client_email,
    cg.advisor_id,

    -- Consumos y anual
    cg.consumption as consumption_p1,
    0 as consumption_p2,
    0 as consumption_p3,
    0 as consumption_p4,
    0 as consumption_p5,
    0 as consumption_p6,
    cg.anual_consumption as anual_consumption_p1,
    0 as anual_consumption_p2,
    0 as anual_consumption_p3,
    0 as anual_consumption_p4,
    0 as anual_consumption_p5,
    0 as anual_consumption_p6,

    0 as autoconsumo_precio,

    -- Precios kWh (P1 en REAL como la original) -> ACTUAL (cg)
    cg."precio actual kw"::real as "precio_kwh_P1",
    0 as "precio_kwh_P2",
    0 as "precio_kwh_P3",
    0 as "precio_kwh_P4",
    0 as "precio_kwh_P5",
    0 as "precio_kwh_P6",

    -- Precio potencia/día actual
    cg."precio fijo actual dia" as "precio_kw_P1",
    0 as "precio_kw_P2",
    0 as "precio_kw_P3",
    0 as "precio_kw_P4",
    0 as "precio_kw_P5",
    0 as "precio_kw_P6",

    -- Totales base
    cg.consumption as total_consumption,
    cg.anual_consumption as total_anual_consumption,
    0 as power_p1,
    0 as power_p2,
    0 as power_p3,
    0 as power_p4,
    0 as power_p5,
    0 as power_p6,

    cg.current_total_invoice,
    0 as surpluses,
    0 as total_surpluses_price,
    0 as power_surpluses,
    cg."VAT",
    cg.days,
    cg.pdf_invoice,
    cg."CUPS",
    cg.address_id,
    cg.company,
    cg.rate_name,
    cg.invoice_month,
    cg.equipment_rental,
    false as selfconsumption,
    cg.manual_data,
    0 as reactive,
    cg.valuation_id,
    cg.invoice_year,
    cg.meter_rental,
    cg.preferred_subrate,

    -- Nueva tarifa (cr)
    cr.company as new_company,
    cr.rate_name as new_rate_name,
    cr.subrate_name as new_subrate_name,
    cr.price_pp1,
    cr.price_pp2,
    cr.price_pp3,
    cr.price_pp4,
    cr.price_pp5,
    cr.price_pp6,
    cr.price_cp1,
    cr.price_cp2,
    cr.price_cp3,
    cr.price_cp4,
    cr.price_cp5,
    cr.price_cp6,
    cr.price_surpluses,

    -- Cálculos GAS (mensual base nuevo)
    (
      COALESCE(cg.days::real, 0::real) * COALESCE(cr.price_pp1, 0::real)
    )::double precision as total_power_price,  -- float8
    COALESCE(cg.consumption, 0::real) * COALESCE(cr.price_cp1, 0::real) as total_consumption_price,
    COALESCE(cg.days::real, 0::real) * COALESCE(cr.price_pp1, 0::real) +
    COALESCE(cg.consumption, 0::real) * (COALESCE(cr.price_cp1, 0::real) + 0.00234::double precision)
      as new_total_price,

    'gas'::text as type,
    COALESCE(cg.temp_client_name, ''::text) as temp_client_name,
    COALESCE(cg.temp_client_last_name, ''::text) as temp_client_last_name,
    array['gas'::text, 'All'::text] as type_filter,

    cg.deleted,
    cg.deleted_reason,
    cr.id as new_rate_id,
    0 as max_power,
    0 as speed_fiber,
    0 as mobile_lines,
    0 as mobile_total_gb,
    false as fijo,
    0 as new_speed_fiber,
    0 as new_total_mobile_lines,
    0 as new_mobile_total_gb,
    ''::text as rate_pack,
    0 as phone_total_anual_price,
    cg.tarifa_plana,
    cg.cif,
    cg.region
  from comparison_gas cg
  left join comparison_rates cr
    on cr.type = 'gas'
   and cr.company <> cg.company
   and cr.subrate_name = cg.rate_name
   and (
        (cr.invoice_month is null and cr.invoice_year is null)
        or (cr.invoice_month = cg.invoice_month and cr.invoice_year = cg.invoice_year)
   )
   and (
        cg.preferred_subrate is null
        or cg.preferred_subrate = ''
        or cr.subrate_name = cg.rate_name
   )
  where (cg.deleted is null or cg.deleted = false)
    and (cg.region is null or cg.region = any (cr.region))
),

unified_calculated_prices as (
  select * from calculated_prices_gas
),

-- ====================== CRS Y FACTORIZACIÓN DE FÓRMULAS ======================
unified_extended_prices as (
  select
    ucp.*,
    crs.id as crs_id,

    -- CRS total (misma lógica general)
    COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(crs.crs_cp1, 0::real) +
    COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(crs.crs_cp2, 0::real) +
    COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(crs.crs_cp3, 0::real) +
    COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(crs.crs_cp4, 0::real) +
    COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(crs.crs_cp5, 0::real) +
    COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(crs.crs_cp6, 0::real) +
    COALESCE(ucp.power_p1, 0::real) * COALESCE(crs.crs_pp1, 0::real) +
    COALESCE(ucp.power_p2, 0::real) * COALESCE(crs.crs_pp2, 0::real) +
    COALESCE(ucp.power_p3, 0::real) * COALESCE(crs.crs_pp3, 0::real) +
    COALESCE(ucp.power_p4, 0::real) * COALESCE(crs.crs_pp4, 0::real) +
    COALESCE(ucp.power_p5, 0::real) * COALESCE(crs.crs_pp5, 0::real) +
    COALESCE(ucp.power_p6, 0::real) * COALESCE(crs.crs_pp6, 0::real) +
    COALESCE(crs.fixed_crs, 0::real) as total_crs,

    -- ====== BLOQUES LATERALES REUTILIZABLES ======
    v.*,
    sly.savings_yearly
  from unified_calculated_prices ucp
  left join comparison_rates_crs crs
    on crs.comparison_rate_id = ucp.new_rate_id
   and (crs.min_kw_anual is null or ucp.total_anual_consumption >= crs.min_kw_anual)
   and (crs.max_kw_anual is null or ucp.total_anual_consumption <  crs.max_kw_anual)
   and (crs.min_power   is null or ucp.power_p1 >= crs.min_power)
   and (crs.max_power   is null or ucp.power_p1 <  crs.max_power)

  cross join lateral (
    -- Potencia con “1 si 0”
    SELECT
      COALESCE(NULLIF(ucp.power_p1, 0::double precision), 1::real)    AS power1_or_1,
      COALESCE(ucp.power_p2, 0::real)                                 AS p2,
      COALESCE(ucp.power_p3, 0::real)                                 AS p3,
      COALESCE(ucp.power_p4, 0::real)                                 AS p4,
      COALESCE(ucp.power_p5, 0::real)                                 AS p5,
      COALESCE(ucp.power_p6, 0::real)                                 AS p6
  ) pwr

  cross join lateral (
    -- Energía anual NUEVA (pre-IVA) con "precio_kwh_P*"
    SELECT
      COALESCE(ucp.anual_consumption_p1,0::real) * COALESCE(ucp."precio_kwh_P1",0::real) +
      COALESCE(ucp.anual_consumption_p2,0::real) * COALESCE(ucp."precio_kwh_P2",0::real) +
      COALESCE(ucp.anual_consumption_p3,0::real) * COALESCE(ucp."precio_kwh_P3",0::real) +
      COALESCE(ucp.anual_consumption_p4,0::real) * COALESCE(ucp."precio_kwh_P4",0::real) +
      COALESCE(ucp.anual_consumption_p5,0::real) * COALESCE(ucp."precio_kwh_P5",0::real) +
      COALESCE(ucp.anual_consumption_p6,0::real) * COALESCE(ucp."precio_kwh_P6",0::real)
      AS annual_new_energy_pre_vat
  ) a1

  cross join lateral (
    -- Energía anual ACTUAL (pre-IVA) con price_cp*
    SELECT
      COALESCE(ucp.anual_consumption_p1,0::real) * COALESCE(ucp.price_cp1,0::real) +
      COALESCE(ucp.anual_consumption_p2,0::real) * COALESCE(ucp.price_cp2,0::real) +
      COALESCE(ucp.anual_consumption_p3,0::real) * COALESCE(ucp.price_cp3,0::real) +
      COALESCE(ucp.anual_consumption_p4,0::real) * COALESCE(ucp.price_cp4,0::real) +
      COALESCE(ucp.anual_consumption_p5,0::real) * COALESCE(ucp.price_cp5,0::real) +
      COALESCE(ucp.anual_consumption_p6,0::real) * COALESCE(ucp.price_cp6,0::real)
      AS annual_old_energy_pre_vat
  ) a2

  cross join lateral (
    -- Potencia anual NUEVA / ACTUAL (pre-IVA)
    SELECT
      (pwr.power1_or_1 * COALESCE(ucp."precio_kw_P1",0::real) * 365::double precision) +
      (pwr.p2           * COALESCE(ucp."precio_kw_P2",0::real) * 365::double precision) +
      (pwr.p3           * COALESCE(ucp."precio_kw_P3",0::real) * 365::double precision) +
      (pwr.p4           * COALESCE(ucp."precio_kw_P4",0::real) * 365::double precision) +
      (pwr.p5           * COALESCE(ucp."precio_kw_P5",0::real) * 365::double precision) +
      (pwr.p6           * COALESCE(ucp."precio_kw_P6",0::real) * 365::double precision)
      AS annual_new_power_pre_vat,

      (COALESCE(NULLIF(ucp.power_p1,0::double precision),1::real) * COALESCE(ucp.price_pp1,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p2,0::real) * COALESCE(ucp.price_pp2,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p3,0::real) * COALESCE(ucp.price_pp3,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p4,0::real) * COALESCE(ucp.price_pp4,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p5,0::real) * COALESCE(ucp.price_pp5,0::real) * 365::double precision) +
      (COALESCE(ucp.power_p6,0::real) * COALESCE(ucp.price_pp6,0::real) * 365::double precision)
      AS annual_old_power_pre_vat
  ) pwr_year

  cross join lateral (
    -- Anuales pre-IVA compuestos
    SELECT
      (a1.annual_new_energy_pre_vat + pwr_year.annual_new_power_pre_vat) AS annual_new_pre_vat,
      (a2.annual_old_energy_pre_vat + pwr_year.annual_old_power_pre_vat) AS annual_old_pre_vat
  ) base

  cross join lateral (
    -- Con IVA + auxiliares para mensual
    SELECT
      base.annual_new_pre_vat * (1::double precision + COALESCE(ucp."VAT",0::real))
        AS annual_new_with_vat,
      base.annual_old_pre_vat * (1::double precision + COALESCE(ucp."VAT",0::real))
        AS annual_old_with_vat,

      -- Mensual nuevo con IVA (para "savings")
      (COALESCE(ucp.new_total_price,0::double precision) + COALESCE(ucp.equipment_rental,0::real))
        * (1::double precision + COALESCE(ucp."VAT",0::real))
        AS monthly_new_with_vat,

      -- Anualización del actual mensual (tarifa plana)
      COALESCE(ucp.current_total_invoice,0::real) * (365.0 / NULLIF(ucp.days::numeric,0))
        AS current_monthly_annualized
  ) v

  cross join lateral (
    -- savings_yearly (misma lógica original; usa v.*)
    SELECT
      CASE
        -- tarifa plana GAS
        WHEN ucp.tarifa_plana = true THEN
          COALESCE(ucp.current_total_invoice, 0::real) * (365.0 / NULLIF(ucp.days::numeric,0))::double precision
          -
          (
            COALESCE(ucp.anual_consumption_p1, 0::real) * (COALESCE(ucp.price_cp1, 0::real) + 0.00234) + 
            COALESCE(NULLIF(ucp.power_p1, 0::double precision),1::real) * COALESCE(ucp.price_pp1, 0::real) * 365::double precision +
            COALESCE(NULLIF(ucp.power_p2, 0::double precision),1::real) * COALESCE(ucp.price_pp2, 0::real) * 365::double precision
          ) 
          * (1::double precision + COALESCE(ucp."VAT", 0::real))

        -- GAS normal con nueva compañía
        WHEN ucp.new_company is not null THEN
          v.annual_new_with_vat - v.annual_old_with_vat
        ELSE 0.0::double precision
      END AS savings_yearly
  ) sly
),

-- ====================== RANKING ======================
ranked_comparisons as (
  select
    uep.*,
    case
      when uep.new_company is not null
           and uep.savings_yearly > 0::double precision
      then uep.savings_yearly + COALESCE(uep.total_crs, 0::real) * 4::double precision
      else 0.0::double precision
    end as ranked_crs,
    row_number() over (
      partition by uep.id
      order by
        case
          when uep.new_company is not null
               and uep.savings_yearly > 0::double precision
          then uep.savings_yearly + COALESCE(uep.total_crs, 0::real) * 4::double precision
          else 0.0::double precision
        end desc
    ) as rank
  from unified_extended_prices uep
),

all_comparisons_ranked as (
  select * from ranked_comparisons
)

-- ====================== SELECT FINAL ======================
select distinct
  rc.*,

  -- IEE mensual y anual (sólo electricidad). En GAS = 0
  0.0::double precision as iee_monthly,
  0.0::double precision as iee,

  -- Precio nuevo con IVA (GAS)
  rc.monthly_new_with_vat as new_total_price_with_vat,

  -- Precio anual con IVA (GAS) – equivalente a la original
  (COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real))
  * (1::double precision + COALESCE(rc."VAT", 0::real)) as new_total_yearly_price_with_vat,

  -- % ahorro (GAS)
  case
    -- tarifa plana gas
    when rc.tarifa_plana = true then
      (
        (rc.current_total_invoice * (365.0 / NULLIF(rc.days,0))) -
        (
          ((COALESCE(rc.anual_consumption_p1, 0) * (COALESCE(rc.price_cp1, 0) + 0.00234)) +
           (COALESCE(rc.price_pp1, 0) * 365))
          * (1 + COALESCE(rc."VAT", 0.0))
        )
      ) / NULLIF((rc.current_total_invoice * (365.0 / NULLIF(rc.days,0))), 0.0)

    -- gas normal con nueva compañía
    when rc.new_company is not null then
      (rc.annual_new_with_vat - rc.annual_old_with_vat)
      / NULLIF(rc.annual_new_with_vat, 0::double precision)
    else 0.0::double precision
  end as saving_percentage,

  -- Ahorro mensual (solo GAS)
  case
    when rc.new_company is not null then
      COALESCE(rc.current_total_invoice,0::real) - rc.monthly_new_with_vat
    else 0.0::double precision
  end as savings

from all_comparisons_ranked rc
left join _users_supervisors us on rc.advisor_id = us.user_id
where rc.rank = 1
  and (rc.deleted is null or rc.deleted = false)
  and rc.type = 'gas';