create or replace view public._comparisons_detailed as
with recursive
  base_rates as (
    select
      crp.id as rate_id,
      crp.company as rate_company,
      crp.rate as rate_name,
      crp.fibra_mb,
      crp.mobile_lines as total_lines,
      crp.total_gb_mobile as total_gb,
      crp.price as total_price,
      crp.anual_price as total_anual_price,
      crp.crs as total_crs,
      crp.crs_calculation,
      crp.excluded_companies,
      crp.rate as rate_pack,
      crp.type as rate_type,
      crp.allow_landline
    from
      comparison_rates_phone crp
    where
      crp.type <> 'Adicional'::text
  ),
  recursive_combinations as (
    select
      br.rate_id,
      br.rate_company,
      br.rate_name,
      br.fibra_mb,
      br.total_lines,
      br.total_gb,
      br.total_price,
      br.total_anual_price,
      br.total_crs,
      br.crs_calculation,
      br.excluded_companies,
      br.rate_pack,
      br.rate_type,
      br.allow_landline
    from
      base_rates br
    union all
    select
      rc_1.rate_id,
      rc_1.rate_company,
      rc_1.rate_name,
      rc_1.fibra_mb,
      rc_1.total_lines + al.mobile_lines,
      rc_1.total_gb + al.total_gb_mobile,
      rc_1.total_price + al.price,
      rc_1.total_anual_price + al.anual_price,
      rc_1.total_crs + al.crs,
      rc_1.crs_calculation + al.crs_calculation,
      rc_1.excluded_companies,
      concat_ws(', '::text, rc_1.rate_pack, al.rate) as rate_pack,
      rc_1.rate_type,
      rc_1.allow_landline
    from
      recursive_combinations rc_1
      join comparison_rates_phone al on al.type = 'Adicional'::text
      and al.company = rc_1.rate_company
      and (
        al.is_unique = false
        or not (
          al.rate in (
            select
              unnest(string_to_array(rc_1.rate_pack, ', '::text)) as unnest
          )
        )
      )
      and rc_1.total_lines < (
        (
          select
            max(comparison_phone.mobile_lines + 2) as max
          from
            comparison_phone
        )
      )
  ),
  ranked_phone as (
    select
      cp.id,
      cp.created_at,
      cp.client_email,
      cp.advisor_id,
      0 as consumption_p1,
      0 as consumption_p2,
      0 as consumption_p3,
      0 as consumption_p4,
      0 as consumption_p5,
      0 as consumption_p6,
      0 as anual_consumption_p1,
      0 as anual_consumption_p2,
      0 as anual_consumption_p3,
      0 as anual_consumption_p4,
      0 as anual_consumption_p5,
      0 as anual_consumption_p6,
      0 as autoconsumo_precio,
      0 as "precio_kw_P1",
      0 as "precio_kw_P2",
      0 as "precio_kw_P3",
      0 as "precio_kw_P4",
      0 as "precio_kw_P5",
      0 as "precio_kw_P6",
      0 as "precio_kwh_P1",
      0 as "precio_kwh_P2",
      0 as "precio_kwh_P3",
      0 as "precio_kwh_P4",
      0 as "precio_kwh_P5",
      0 as "precio_kwh_P6",
      0 as total_consumption,
      0 as total_anual_consumption,
      0 as power_p1,
      0 as power_p2,
      0 as power_p3,
      0 as power_p4,
      0 as power_p5,
      0 as power_p6,
      cp.current_total_invoice,
      0 as surpluses,
      0 as total_surpluses_price,
      0 as power_surpluses,
      0 as "VAT",
      0 as days,
      cp.pdf_invoice,
      ''::text as cups,
      null::uuid as address_id,
      cp.company,
      ''::text as rate_name,
      0 as invoice_month,
      0 as equipment_rental,
      false as selfconsumption,
      true as manual_data,
      0 as reactive,
      cp.valuation_id,
      0 as invoice_year,
      0 as meter_rental,
      ''::text as preferred_subrate,
      rc_1.rate_company as new_company,
      rc_1.rate_name as new_rate_name,
      ''::text as new_subrate_name,
      0 as price_pp1,
      0 as price_pp2,
      0 as price_pp3,
      0 as price_pp4,
      0 as price_pp5,
      0 as price_pp6,
      0 as price_cp1,
      0 as price_cp2,
      0 as price_cp3,
      0 as price_cp4,
      0 as price_cp5,
      0 as price_cp6,
      0 as price_surpluses,
      0 as total_power_price,
      0 as total_consumption_price,
      rc_1.total_price as new_total_price,
      'phone'::text as type,
      COALESCE(cp.temp_client_name, ''::text) as temp_client_name,
      COALESCE(cp.temp_client_last_name, ''::text) as temp_client_last_name,
      array['phone'::text, 'All'::text] as type_filter,
      cp.deleted,
      cp.deleted_reason,
      rc_1.rate_id as new_rate_id,
      0 as max_power,
      cp.speed_fiber,
      cp.mobile_lines,
      cp.mobile_total_gb,
      cp.landline as fijo,
      rc_1.fibra_mb as new_speed_fiber,
      rc_1.total_lines as new_total_mobile_lines,
      rc_1.total_gb as new_mobile_total_gb,
      rc_1.rate_pack,
      rc_1.total_anual_price as phone_total_anual_price,
      rc_1.rate_id as crs_id,
      rc_1.total_crs,
      cp.current_total_invoice::double precision - rc_1.total_price as savings,
      (cp.current_total_invoice * 12::numeric)::double precision - rc_1.total_anual_price as savings_yearly,
      (
        (cp.current_total_invoice * 12::numeric)::double precision - rc_1.total_anual_price
      ) * 1::double precision + rc_1.total_crs * 4::double precision as ranked_crs,
      row_number() over (
        partition by
          cp.id
        order by
          (
            (
              (cp.current_total_invoice * 12::numeric)::double precision - rc_1.total_anual_price
            ) * 1::double precision + rc_1.total_crs * 4::double precision
          ) desc
      ) as rank
    from
      comparison_phone cp
      join recursive_combinations rc_1 on rc_1.fibra_mb >= cp.speed_fiber
      and rc_1.total_lines >= cp.mobile_lines
      and rc_1.total_lines <= (cp.mobile_lines + 2)
      and rc_1.rate_type = cp.rate_type
      and rc_1.total_gb >= cp.mobile_total_gb
      and (
        not (
          exists (
            select
              1
            from
              unnest(rc_1.excluded_companies) ex (ex)
            where
              ex.ex = cp.company
          )
        )
        or rc_1.excluded_companies is null
      )
      and (
        cp.landline = false
        or rc_1.allow_landline = true
      )
      and (
        cp.deleted is null
        or cp.deleted = false
      )
    order by
      (
        (
          (cp.current_total_invoice * 12::numeric)::double precision - rc_1.total_anual_price
        ) * 1::double precision + rc_1.total_crs * 4::double precision
      ) desc
  ),
  calculated_prices_light as (
    select
      cl_1.id,
      cl_1.created_at,
      cl_1.client_email,
      cl_1.advisor_id,
      cl_1.consumption_p1,
      cl_1.consumption_p2,
      cl_1.consumption_p3,
      0 as consumption_p4,
      0 as consumption_p5,
      0 as consumption_p6,
      cl_1.anual_consumption_p1,
      cl_1.anual_consumption_p2,
      cl_1.anual_consumption_p3,
      0 as anual_consumption_p4,
      0 as anual_consumption_p5,
      0 as anual_consumption_p6,
      cl_1.autoconsumo_precio,
      cl_1."precio_kw_P1",
      cl_1."precio_kw_P2",
      0 as "precio_kw_P3",
      0 as "precio_kw_P4",
      0 as "precio_kw_P5",
      0 as "precio_kw_P6",
      cl_1."precio_kwh_P1",
      cl_1."precio_kwh_P2",
      cl_1."precio_kwh_P3",
      0 as "precio_kwh_P4",
      0 as "precio_kwh_P5",
      0 as "precio_kwh_P6",
      COALESCE(cl_1.consumption_p1, 0.0::real) +
      COALESCE(cl_1.consumption_p2, 0.0::real) +
      COALESCE(cl_1.consumption_p3, 0.0::real) 
      as total_consumption,
      COALESCE(cl_1.anual_consumption_p1, 0.0::real) + 
      COALESCE(cl_1.anual_consumption_p2, 0.0::real) + 
      COALESCE(cl_1.anual_consumption_p3, 0.0::real)
      as total_anual_consumption,
      cl_1.power_p1,
      cl_1.power_p2,
      0 as power_p3,
      0 as power_p4,
      0 as power_p5,
      0 as power_p6,
      cl_1.current_total_invoice,
      cl_1.surpluses,
      COALESCE(cl_1.surpluses, 0::real) * COALESCE(cr.price_surpluses, 0::real) as total_surpluses_price,
      0 as power_surpluses,
      cl_1."VAT",
      cl_1.power_days as days,
      cl_1.pdf_invoice,
      cl_1."CUPS",
      cl_1.address_id,
      cl_1.company,
      cl_1.rate_name,
      cl_1.invoice_month,
      cl_1.equipment_rental,
      cl_1.selfconsumption,
      cl_1.manual_data,
      0 as reactive,
      cl_1.valuation_id,
      cl_1.invoice_year,
      0 as meter_rental,
      cl_1.preferred_subrate,
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
      COALESCE(cl_1.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real) * COALESCE(cl_1.power_days, 0)::double precision +
      COALESCE(cl_1.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real) * COALESCE(cl_1.power_days, 0)::double precision
      as total_power_price,
      COALESCE(cl_1.consumption_p1, 0::real) * COALESCE(cr.price_cp1, 0::real) +
      COALESCE(cl_1.consumption_p2, 0::real) * COALESCE(cr.price_cp2, 0::real) +
      COALESCE(cl_1.consumption_p3, 0::real) * COALESCE(cr.price_cp3, 0::real)
      as total_consumption_price,
      COALESCE(cl_1.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real) * COALESCE(cl_1.power_days, 0)::double precision +
      COALESCE(cl_1.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real) * COALESCE(cl_1.power_days, 0)::double precision +
      COALESCE(cl_1.consumption_p1, 0::real) * COALESCE(cr.price_cp1, 0::real) + 
      COALESCE(cl_1.consumption_p2, 0::real) * COALESCE(cr.price_cp2, 0::real) + 
      COALESCE(cl_1.consumption_p3, 0::real) * COALESCE(cr.price_cp3, 0::real) -
      COALESCE(cl_1.surpluses, 0::real) * COALESCE(cr.price_surpluses, 0::real) 
      as new_total_price,
      'light'::text as type,
      COALESCE(cl_1.temp_client_name, ''::text) as temp_client_name,
      COALESCE(cl_1.temp_client_last_name, ''::text) as temp_client_last_name,
      array['light'::text, 'All'::text] as type_filter,
      cl_1.deleted,
      cl_1.deleted_reason,
      cr.id as new_rate_id,
      COALESCE(cl_1.max_power, 0::real) as max_power,
      0 as speed_fiber,
      0 as mobile_lines,
      0 as mobile_total_gb,
      false as fijo,
      0 as new_speed_fiber,
      0 as new_total_mobile_lines,
      0 as new_mobile_total_gb,
      ''::text as rate_pack,
      0 as phone_total_anual_price,
      cl_1.tarifa_plana,
      cl_1.cif,
      cl_1.region
    from
      comparison_light cl_1
      left join comparison_rates cr on cr.type = 'light'::text
      and cr.company <> cl_1.company
      and (
        cr.invoice_month is null
        and cr.invoice_year is null
        or cr.invoice_month = cl_1.invoice_month
        and cr.invoice_year = cl_1.invoice_year
      )
      and (
        cl_1.preferred_subrate is null
        or cl_1.preferred_subrate = ''::text
        or cr.subrate_name = cl_1.preferred_subrate
      )
      and (
        cl_1.selfconsumption = true
        and cr.selfconsumption = true
        or cl_1.selfconsumption = false
      )
      and (
        cl_1.deleted is null
        or cl_1.deleted = false
      )
      -- and (
      --   cl_1.cif = false
      --   or cr.cif = cl_1.cif
      -- )
      and (
        cl_1.region IS NULL
        OR cl_1.region = ANY (cr.region)
      )
  ),
  calculated_prices_3_0 as (
    select
      c30.id,
      c30.created_at,
      c30.client_email,
      c30.advisor_id,
      c30.consumption_p1,
      c30.consumption_p2,
      c30.consumption_p3,
      c30.consumption_p4,
      c30.consumption_p5,
      c30.consumption_p6,
      c30.anual_consumption_p1,
      c30.anual_consumption_p2,
      c30.anual_consumption_p3,
      c30.anual_consumption_p4,
      c30.anual_consumption_p5,
      c30.anual_consumption_p6,
      c30.autoconsumo_precio,
      c30."precio_kw_P1",
      c30."precio_kw_P2",
      c30."precio_kw_P3",
      c30."precio_kw_P4",
      c30."precio_kw_P5",
      c30."precio_kw_P6",
      c30."precio_kwh_P1",
      c30."precio_kwh_P2",
      c30."precio_kwh_P3",
      c30."precio_kwh_P4",
      c30."precio_kwh_P5",
      c30."precio_kwh_P6",
      COALESCE(c30.consumption_p1, 0.0::real) + COALESCE(c30.consumption_p2, 0.0::real) +
      COALESCE(c30.consumption_p3, 0.0::real) + COALESCE(c30.consumption_p4, 0.0::real) +
      COALESCE(c30.consumption_p5, 0.0::real) + COALESCE(c30.consumption_p6, 0.0::real) 
      as total_consumption,
      COALESCE(c30.anual_consumption_p1, 0.0::real) + COALESCE(c30.anual_consumption_p2, 0.0::real) + 
      COALESCE(c30.anual_consumption_p3, 0.0::real) + COALESCE(c30.anual_consumption_p4, 0.0::real) + 
      COALESCE(c30.anual_consumption_p5, 0.0::real) + COALESCE(c30.anual_consumption_p6, 0.0::real) 
      as total_anual_consumption,
      c30.power_p1,
      c30.power_p2,
      c30.power_p3,
      c30.power_p4,
      c30.power_p5,
      c30.power_p6,
      c30.current_total_invoice,
      c30.surpluses,
      COALESCE(c30.surpluses, 0::real) * COALESCE(cr.price_surpluses, 0::real) as total_surpluses_price,
      c30.power_surpluses,
      c30."VAT",
      c30.power_days as days,
      c30.pdf_invoice,
      c30."CUPS",
      c30.address_id,
      c30.company,
      c30.rate_name,
      c30.invoice_month,
      c30.equipment_rental,
      c30.selfconsumption,
      c30.manual_data,
      c30.reactive,
      c30.valuation_id,
      c30.invoice_year,
      0 as meter_rental,
      c30.preferred_subrate,
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
-- ================================================================================
-- TOTAL POWER PRICE
-- ================================================================================
      COALESCE(c30.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real) * COALESCE(c30.power_days, 0)::double precision + 
      COALESCE(c30.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real) * COALESCE(c30.power_days, 0)::double precision + 
      COALESCE(c30.power_p3, 0::real) * COALESCE(cr.price_pp3, 0::real) * COALESCE(c30.power_days, 0)::double precision + 
      COALESCE(c30.power_p4, 0::real) * COALESCE(cr.price_pp4, 0::real) * COALESCE(c30.power_days, 0)::double precision + 
      COALESCE(c30.power_p5, 0::real) * COALESCE(cr.price_pp5, 0::real) * COALESCE(c30.power_days, 0)::double precision + 
      COALESCE(c30.power_p6, 0::real) * COALESCE(cr.price_pp6, 0::real) * COALESCE(c30.power_days, 0)::double precision
      as total_power_price,
-- ================================================================================
-- TOTAL CONSUMPTION PRICE
-- ================================================================================
      COALESCE(c30.consumption_p1, 0::real) * COALESCE(cr.price_cp1, 0::real) +
      COALESCE(c30.consumption_p2, 0::real) * COALESCE(cr.price_cp2, 0::real) +
      COALESCE(c30.consumption_p3, 0::real) * COALESCE(cr.price_cp3, 0::real) +
      COALESCE(c30.consumption_p4, 0::real) * COALESCE(cr.price_cp4, 0::real) +
      COALESCE(c30.consumption_p5, 0::real) * COALESCE(cr.price_cp5, 0::real) + 
      COALESCE(c30.consumption_p6, 0::real) * COALESCE(cr.price_cp6, 0::real) 
      as total_consumption_price,
-- ================================================================================
-- NEW TOTAL PRICE
-- ================================================================================
      COALESCE(c30.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real) * COALESCE(c30.power_days, 0)::double precision +
      COALESCE(c30.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real) * COALESCE(c30.power_days, 0)::double precision +
      COALESCE(c30.power_p3, 0::real) * COALESCE(cr.price_pp3, 0::real) * COALESCE(c30.power_days, 0)::double precision +
      COALESCE(c30.power_p4, 0::real) * COALESCE(cr.price_pp4, 0::real) * COALESCE(c30.power_days, 0)::double precision + 
      COALESCE(c30.power_p5, 0::real) * COALESCE(cr.price_pp5, 0::real) * COALESCE(c30.power_days, 0)::double precision + 
      COALESCE(c30.power_p6, 0::real) * COALESCE(cr.price_pp6, 0::real) * COALESCE(c30.power_days, 0)::double precision +
      COALESCE(c30.consumption_p1, 0::real) * COALESCE(cr.price_cp1, 0::real) + COALESCE(c30.consumption_p2, 0::real) * COALESCE(cr.price_cp2, 0::real) +
      COALESCE(c30.consumption_p3, 0::real) * COALESCE(cr.price_cp3, 0::real) + COALESCE(c30.consumption_p4, 0::real) * COALESCE(cr.price_cp4, 0::real) +
      COALESCE(c30.consumption_p5, 0::real) * COALESCE(cr.price_cp5, 0::real) + COALESCE(c30.consumption_p6, 0::real) * COALESCE(cr.price_cp6, 0::real) +
      COALESCE(c30.power_surpluses, 0::real) - COALESCE(c30.surpluses, 0::real) * COALESCE(cr.price_surpluses, 0::real)
      as new_total_price,
-- ================================================================================
      '3_0'::text as type,
      COALESCE(c30.temp_client_name, ''::text) as temp_client_name,
      COALESCE(c30.temp_client_last_name, ''::text) as temp_client_last_name,
      array['3_0'::text, 'All'::text] as type_filter,
      c30.deleted,
      c30.deleted_reason,
      cr.id as new_rate_id,
      COALESCE(c30.max_power, 0::real) as max_power,
      0 as speed_fiber,
      0 as mobile_lines,
      0 as mobile_total_gb,
      false as fijo,
      0 as new_speed_fiber,
      0 as new_total_mobile_lines,
      0 as new_mobile_total_gb,
      ''::text as rate_pack,
      0 as phone_total_anual_price,
      false as tarifa_plana,
      c30.cif,
      c30.region
    from
      comparison_3_0 c30
      left join comparison_rates cr on cr.type = '3_0'::text
      and cr.company <> c30.company
      and (
        cr.invoice_month is null
        and cr.invoice_year is null
        or cr.invoice_month = c30.invoice_month
        and cr.invoice_year = c30.invoice_year
      )
      and (
        c30.preferred_subrate is null
        or c30.preferred_subrate = ''::text
        or cr.subrate_name = c30.preferred_subrate
      )
      and (
        c30.deleted is null
        or c30.deleted = false
      )
      /* and (
          cl_1.cif = false
          or cr.cif = cl_1.cif
        ) */
      and (
        c30.region is null
        or (c30.region = any (cr.region))
      )
  ),
  calculated_prices_gas as (
    select
      cg.id,
      cg.created_at,
      cg.client_email,
      cg.advisor_id,
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
      cg."precio actual kw" as precio_kwh_p1,
      0 as precio_kw_p2,
      0 as precio_kw_p3,
      0 as precio_kw_p4,
      0 as precio_kw_p5,
      0 as precio_kw_p6,
      cg."precio fijo actual dia" as precio_kw_p1,
      0 as precio_kwh_p2,
      0 as precio_kwh_p3,
      0 as precio_kwh_p4,
      0 as precio_kwh_p5,
      0 as precio_kwh_p6,
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
      COALESCE(cg.days::real, 0::real) * COALESCE(cr.price_pp1, 0::real) as total_power_price,
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
    from
      comparison_gas cg
      left join comparison_rates cr on cr.type = 'gas'::text
      and cr.company <> cg.company
      and cr.subrate_name = cg.rate_name
      and (
        cr.invoice_month is null
        and cr.invoice_year is null
        or cr.invoice_month = cg.invoice_month
        and cr.invoice_year = cg.invoice_year
      )
      and (
        cg.preferred_subrate is null
        or cg.preferred_subrate = ''::text
        or cr.subrate_name = cg.rate_name
      )
      and (
        cg.deleted is null
        or cg.deleted = false
      )
      /* and (
          cl_1.cif = false
          or cr.cif = cl_1.cif
        ) */
      and (
        cg.region is null
        or (cg.region = any (cr.region))
      )
  ),
  unified_calculated_prices as (
    select
      l.id,
      l.created_at,
      l.client_email,
      l.advisor_id,
      l.consumption_p1,
      l.consumption_p2,
      l.consumption_p3,
      l.consumption_p4,
      l.consumption_p5,
      l.consumption_p6,
      l.anual_consumption_p1,
      l.anual_consumption_p2,
      l.anual_consumption_p3,
      l.anual_consumption_p4,
      l.anual_consumption_p5,
      l.anual_consumption_p6,
      l.autoconsumo_precio,
      l."precio_kw_P1",
      l."precio_kw_P2",
      l."precio_kw_P3",
      l."precio_kw_P4",
      l."precio_kw_P5",
      l."precio_kw_P6",
      l."precio_kwh_P1",
      l."precio_kwh_P2",
      l."precio_kwh_P3",
      l."precio_kwh_P4",
      l."precio_kwh_P5",
      l."precio_kwh_P6",
      l.total_consumption,
      l.total_anual_consumption,
      l.power_p1,
      l.power_p2,
      l.power_p3,
      l.power_p4,
      l.power_p5,
      l.power_p6,
      l.current_total_invoice,
      l.surpluses,
      l.total_surpluses_price,
      l.power_surpluses,
      l."VAT",
      l.days,
      l.pdf_invoice,
      l."CUPS",
      l.address_id,
      l.company,
      l.rate_name,
      l.invoice_month,
      l.equipment_rental,
      l.selfconsumption,
      l.manual_data,
      l.reactive,
      l.valuation_id,
      l.invoice_year,
      l.meter_rental,
      l.preferred_subrate,
      l.new_company,
      l.new_rate_name,
      l.new_subrate_name,
      l.price_pp1,
      l.price_pp2,
      l.price_pp3,
      l.price_pp4,
      l.price_pp5,
      l.price_pp6,
      l.price_cp1,
      l.price_cp2,
      l.price_cp3,
      l.price_cp4,
      l.price_cp5,
      l.price_cp6,
      l.price_surpluses,
      l.total_power_price,
      l.total_consumption_price,
      l.new_total_price,
      l.type,
      l.temp_client_name,
      l.temp_client_last_name,
      l.type_filter,
      l.deleted,
      l.deleted_reason,
      l.new_rate_id,
      l.max_power,
      l.speed_fiber,
      l.mobile_lines,
      l.mobile_total_gb,
      l.fijo,
      l.new_speed_fiber,
      l.new_total_mobile_lines,
      l.new_mobile_total_gb,
      l.rate_pack,
      l.phone_total_anual_price,
      l.tarifa_plana,
      l.cif,
      l.region
    from
      calculated_prices_light l
    union all
    select
      c30.id,
      c30.created_at,
      c30.client_email,
      c30.advisor_id,
      c30.consumption_p1,
      c30.consumption_p2,
      c30.consumption_p3,
      c30.consumption_p4,
      c30.consumption_p5,
      c30.consumption_p6,
      c30.anual_consumption_p1,
      c30.anual_consumption_p2,
      c30.anual_consumption_p3,
      c30.anual_consumption_p4,
      c30.anual_consumption_p5,
      c30.anual_consumption_p6,
      c30.autoconsumo_precio,
      c30."precio_kw_P1",
      c30."precio_kw_P2",
      c30."precio_kw_P3",
      c30."precio_kw_P4",
      c30."precio_kw_P5",
      c30."precio_kw_P6",
      c30."precio_kwh_P1",
      c30."precio_kwh_P2",
      c30."precio_kwh_P3",
      c30."precio_kwh_P4",
      c30."precio_kwh_P5",
      c30."precio_kwh_P6",
      c30.total_consumption,
      c30.total_anual_consumption,
      c30.power_p1,
      c30.power_p2,
      c30.power_p3,
      c30.power_p4,
      c30.power_p5,
      c30.power_p6,
      c30.current_total_invoice,
      c30.surpluses,
      c30.total_surpluses_price,
      c30.power_surpluses,
      c30."VAT",
      c30.days,
      c30.pdf_invoice,
      c30."CUPS",
      c30.address_id,
      c30.company,
      c30.rate_name,
      c30.invoice_month,
      c30.equipment_rental,
      c30.selfconsumption,
      c30.manual_data,
      c30.reactive,
      c30.valuation_id,
      c30.invoice_year,
      c30.meter_rental,
      c30.preferred_subrate,
      c30.new_company,
      c30.new_rate_name,
      c30.new_subrate_name,
      c30.price_pp1,
      c30.price_pp2,
      c30.price_pp3,
      c30.price_pp4,
      c30.price_pp5,
      c30.price_pp6,
      c30.price_cp1,
      c30.price_cp2,
      c30.price_cp3,
      c30.price_cp4,
      c30.price_cp5,
      c30.price_cp6,
      c30.price_surpluses,
      c30.total_power_price,
      c30.total_consumption_price,
      c30.new_total_price,
      c30.type,
      c30.temp_client_name,
      c30.temp_client_last_name,
      c30.type_filter,
      c30.deleted,
      c30.deleted_reason,
      c30.new_rate_id,
      c30.max_power,
      c30.speed_fiber,
      c30.mobile_lines,
      c30.mobile_total_gb,
      c30.fijo,
      c30.new_speed_fiber,
      c30.new_total_mobile_lines,
      c30.new_mobile_total_gb,
      c30.rate_pack,
      c30.phone_total_anual_price,
      c30.tarifa_plana,
      c30.cif,
      c30.region
    from
      calculated_prices_3_0 c30
    union all
    select
      g.id,
      g.created_at,
      g.client_email,
      g.advisor_id,
      g.consumption_p1,
      g.consumption_p2,
      g.consumption_p3,
      g.consumption_p4,
      g.consumption_p5,
      g.consumption_p6,
      g.anual_consumption_p1,
      g.anual_consumption_p2,
      g.anual_consumption_p3,
      g.anual_consumption_p4,
      g.anual_consumption_p5,
      g.anual_consumption_p6,
      g.autoconsumo_precio,
      g.precio_kw_p1,
      g.precio_kw_p2,
      g.precio_kw_p3,
      g.precio_kw_p4,
      g.precio_kw_p5,
      g.precio_kw_p1,
      g.precio_kwh_p1,
      g.precio_kwh_p2,
      g.precio_kwh_p3,
      g.precio_kwh_p4,
      g.precio_kwh_p5,
      g.precio_kwh_p6,
      g.total_consumption,
      g.total_anual_consumption,
      g.power_p1,
      g.power_p2,
      g.power_p3,
      g.power_p4,
      g.power_p5,
      g.power_p6,
      g.current_total_invoice,
      g.surpluses,
      g.total_surpluses_price,
      g.power_surpluses,
      g."VAT",
      g.days,
      g.pdf_invoice,
      g."CUPS",
      g.address_id,
      g.company,
      g.rate_name,
      g.invoice_month,
      g.equipment_rental,
      g.selfconsumption,
      g.manual_data,
      g.reactive,
      g.valuation_id,
      g.invoice_year,
      g.meter_rental,
      g.preferred_subrate,
      g.new_company,
      g.new_rate_name,
      g.new_subrate_name,
      g.price_pp1,
      g.price_pp2,
      g.price_pp3,
      g.price_pp4,
      g.price_pp5,
      g.price_pp6,
      g.price_cp1,
      g.price_cp2,
      g.price_cp3,
      g.price_cp4,
      g.price_cp5,
      g.price_cp6,
      g.price_surpluses,
      g.total_power_price,
      g.total_consumption_price,
      g.new_total_price,
      g.type,
      g.temp_client_name,
      g.temp_client_last_name,
      g.type_filter,
      g.deleted,
      g.deleted_reason,
      g.new_rate_id,
      g.max_power,
      g.speed_fiber,
      g.mobile_lines,
      g.mobile_total_gb,
      g.fijo,
      g.new_speed_fiber,
      g.new_total_mobile_lines,
      g.new_mobile_total_gb,
      g.rate_pack,
      g.phone_total_anual_price,
      g.tarifa_plana,
      g.cif,
      g.region
    from
      calculated_prices_gas g
  ),
  unified_extended_prices as (
    select
      ucp.id,
      ucp.created_at,
      ucp.client_email,
      ucp.advisor_id,
      ucp.consumption_p1,
      ucp.consumption_p2,
      ucp.consumption_p3,
      ucp.consumption_p4,
      ucp.consumption_p5,
      ucp.consumption_p6,
      ucp.anual_consumption_p1,
      ucp.anual_consumption_p2,
      ucp.anual_consumption_p3,
      ucp.anual_consumption_p4,
      ucp.anual_consumption_p5,
      ucp.anual_consumption_p6,
      ucp.autoconsumo_precio,
      ucp."precio_kw_P1",
      ucp."precio_kw_P2",
      ucp."precio_kw_P3",
      ucp."precio_kw_P4",
      ucp."precio_kw_P5",
      ucp."precio_kw_P6",
      ucp."precio_kwh_P1",
      ucp."precio_kwh_P2",
      ucp."precio_kwh_P3",
      ucp."precio_kwh_P4",
      ucp."precio_kwh_P5",
      ucp."precio_kwh_P6",
      ucp.total_consumption,
      ucp.total_anual_consumption,
      ucp.power_p1,
      ucp.power_p2,
      ucp.power_p3,
      ucp.power_p4,
      ucp.power_p5,
      ucp.power_p6,
      ucp.current_total_invoice,
      ucp.surpluses,
      ucp.total_surpluses_price,
      ucp.power_surpluses,
      ucp."VAT",
      ucp.days,
      ucp.pdf_invoice,
      ucp."CUPS",
      ucp.address_id,
      ucp.company,
      ucp.rate_name,
      ucp.invoice_month,
      ucp.equipment_rental,
      ucp.selfconsumption,
      ucp.manual_data,
      ucp.reactive,
      ucp.valuation_id,
      ucp.invoice_year,
      ucp.meter_rental,
      ucp.preferred_subrate,
      ucp.new_company,
      ucp.new_rate_name,
      ucp.new_subrate_name,
      ucp.price_pp1,
      ucp.price_pp2,
      ucp.price_pp3,
      ucp.price_pp4,
      ucp.price_pp5,
      ucp.price_pp6,
      ucp.price_cp1,
      ucp.price_cp2,
      ucp.price_cp3,
      ucp.price_cp4,
      ucp.price_cp5,
      ucp.price_cp6,
      ucp.price_surpluses,
      ucp.total_power_price,
      ucp.total_consumption_price,
      ucp.new_total_price,
      ucp.type,
      ucp.temp_client_name,
      ucp.temp_client_last_name,
      ucp.type_filter,
      ucp.deleted,
      ucp.deleted_reason,
      ucp.new_rate_id,
      ucp.max_power,
      ucp.speed_fiber,
      ucp.mobile_lines,
      ucp.mobile_total_gb,
      ucp.fijo,
      ucp.new_speed_fiber,
      ucp.new_total_mobile_lines,
      ucp.new_mobile_total_gb,
      ucp.rate_pack,
      ucp.phone_total_anual_price,
      ucp.tarifa_plana,
      crs.id as crs_id,
-- ================================================================================
-- TOTAL CRS
-- ================================================================================
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
      COALESCE(crs.fixed_crs, 0::real)
     as total_crs,
-- ================================================================================
-- SAVINGS
-- ================================================================================
      case
        when ucp.new_company is not null then
          COALESCE(ucp.current_total_invoice, 0::real)
          -
          case
            when ucp.type = any (array['light'::text, '3_0'::text]) then
              (
                COALESCE(ucp.new_total_price, 0::real::double precision) * 1.05113::double precision
                + COALESCE(ucp.equipment_rental, 0::real)
              ) * (
                1::double precision + COALESCE(ucp."VAT", 0::real)
              )
            else
              (
                COALESCE(ucp.new_total_price, 0::real::double precision)
                + COALESCE(ucp.equipment_rental, 0::real)
              ) * (
                1::double precision + COALESCE(ucp."VAT", 0::real)
              )
          end
        else 0.0::double precision
      end as savings,
-- ================================================================================
-- SAVINGS YEARLY //TO DO TARIFA PLANA GAS Y 3_0 WHENS\\
-- ================================================================================
      case
        when ucp.tarifa_plana = true and ucp.type = 'light' then 
        COALESCE(ucp.current_total_invoice, 0::real) * (365.0 / ucp.days::numeric)::double precision
         -
          (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp.price_cp1, 0::real) + 
            COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp.price_cp2, 0::real) + 
            COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp.price_cp3, 0::real) + 
            COALESCE(NULLIF(ucp.power_p1, 0::double precision),1::real) * COALESCE(ucp.price_pp1, 0::real) * COALESCE(365, 0)::double precision +
            COALESCE(NULLIF(ucp.power_p2, 0::double precision),1::real) * COALESCE(ucp.price_pp2, 0::real) * COALESCE(365, 0)::double precision
          ) 
        * (1::numeric + 0.05113)::double precision 
        * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          )
        when ucp.tarifa_plana = true and ucp.type = 'gas' then 
        COALESCE(ucp.current_total_invoice, 0::real) * (365.0 / ucp.days::numeric)::double precision
         -
          (
            COALESCE(ucp.anual_consumption_p1, 0::real) * (COALESCE(ucp.price_cp1, 0::real)+0.00234) + 
            COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp.price_cp2, 0::real) + 
            COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp.price_cp3, 0::real) + 
            COALESCE(NULLIF(ucp.power_p1, 0::double precision),1::real) * COALESCE(ucp.price_pp1, 0::real) * COALESCE(365, 0)::double precision +
            COALESCE(NULLIF(ucp.power_p2, 0::double precision),1::real) * COALESCE(ucp.price_pp2, 0::real) * COALESCE(365, 0)::double precision
          ) 
        * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          )
        when ucp.new_company is not null and ucp.type <> '3_0'::text then
         (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp."precio_kwh_P1", 0::real) + 
            COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp."precio_kwh_P2", 0::real) + 
            COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp."precio_kwh_P3", 0::real) + 
            COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp."precio_kwh_P4", 0::real) + 
            COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp."precio_kwh_P5", 0::real) + 
            COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp."precio_kwh_P6", 0::real) + 

            COALESCE(NULLIF(ucp.power_p1, 0::double precision),1::real) * COALESCE(ucp."precio_kw_P1", 0::real) * 365::double precision +
            COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp."precio_kw_P2", 0::real) * 365::double precision +
            COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp."precio_kw_P3", 0::real) * 365::double precision +
            COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp."precio_kw_P4", 0::real) * 365::double precision +
            COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp."precio_kw_P5", 0::real) * 365::double precision +
            COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp."precio_kw_P6", 0::real) * 365::double precision - 
            COALESCE(ucp.surpluses, 0::real) * 182.5::double precision 
            / 
            case
              when COALESCE(ucp.days::real, 0::real) = 0::double precision then 182.5
                else ucp.days::numeric
              end::double precision * COALESCE(ucp.autoconsumo_precio, 0::real)
          ) 
          * case
            when ucp.type = 'light'::text then 1.05113::double precision
              else 1.0::double precision
            end 
            * (1::double precision + COALESCE(ucp."VAT", 0::real)) 
          - 
          (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp.price_cp1, 0::real) + 
            COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp.price_cp2, 0::real) + 
            COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp.price_cp3, 0::real) + 
            COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp.price_cp4, 0::real) +
            COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp.price_cp5, 0::real) + 
            COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp.price_cp6, 0::real) + 
            COALESCE(
              NULLIF(ucp.power_p1, 0::double precision),
              1::real
            ) 
            * 
            COALESCE(ucp.price_pp1, 0::real) * 365::double precision + 
            COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp.price_pp2, 0::real) * 365::double precision +
            COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp.price_pp3, 0::real) * 365::double precision + 
            COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp.price_pp4, 0::real) * 365::double precision + 
            COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp.price_pp5, 0::real) * 365::double precision +
            COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp.price_pp6, 0::real) * 365::double precision -
            COALESCE(ucp.surpluses, 0::real) * 182.5::double precision
            / 
            case
              when COALESCE(ucp.days::real, 0::real) = 0::double precision then 182.5
              else ucp.days::numeric
            end::double precision * COALESCE(ucp.price_surpluses, 0::real)
          ) 
        * case 
            when ucp.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
          else 1.0::double precision
        end 
        * (1::double precision + COALESCE(ucp."VAT", 0::real))

        when ucp.type = '3_0'::text then
          (
            (
              COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp."precio_kwh_P1", 0::real) +
              COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp."precio_kwh_P2", 0::real) +
              COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp."precio_kwh_P3", 0::real) +
              COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp."precio_kwh_P4", 0::real) +
              COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp."precio_kwh_P5", 0::real) +
              COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp."precio_kwh_P6", 0::real) +

              COALESCE(NULLIF(ucp.power_p1, 0::double precision), 1::real) * COALESCE(ucp."precio_kw_P1", 0::real) * 365 +
              COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp."precio_kw_P2", 0::real) * 365 +
              COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp."precio_kw_P3", 0::real) * 365 +
              COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp."precio_kw_P4", 0::real) * 365 +
              COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp."precio_kw_P5", 0::real) * 365 +
              COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp."precio_kw_P6", 0::real) * 365 -

              COALESCE(ucp.surpluses, 0::real) * 182.5 / 
              NULLIF(ucp.days::numeric, 0)::double precision * COALESCE(ucp.autoconsumo_precio, 0::real)
            )
            * 1.05113
            * (1 + COALESCE(ucp."VAT", 0::real))
          )
          -
          (
            (
              COALESCE(ucp.total_consumption_price, 0::real) / NULLIF(ucp.total_consumption, 0::real)
            ) 
            * COALESCE(ucp.total_anual_consumption, 0::real) +
            COALESCE(ucp.power_p1, 0::real) * COALESCE(ucp.price_pp1, 0::real) * 365 +
            COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp.price_pp2, 0::real) * 365 +
            COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp.price_pp3, 0::real) * 365 +
            COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp.price_pp4, 0::real) * 365 +
            COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp.price_pp5, 0::real) * 365 +
            COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp.price_pp6, 0::real) * 365
          )
          * 1.05113
          * (1 + COALESCE(ucp."VAT", 0::real))
        else 0.0::double precision
      end as savings_yearly,
      ucp.cif,
      ucp.region
    from
      unified_calculated_prices ucp
      left join comparison_rates_crs crs on crs.comparison_rate_id = ucp.new_rate_id
      and (
        crs.min_kw_anual is null
        or ucp.total_anual_consumption >= crs.min_kw_anual
      )
      and (
        crs.max_kw_anual is null
        or ucp.total_anual_consumption < crs.max_kw_anual
      )
      and (
        crs.min_power is null
        or ucp.power_p1 >= crs.min_power
      )
      and (
        crs.max_power is null
        or ucp.power_p1 < crs.max_power
      )
  ),
  ranked_comparisons as (
    select
      uep.id,
      uep.created_at,
      uep.client_email,
      uep.advisor_id,
      uep.consumption_p1,
      uep.consumption_p2,
      uep.consumption_p3,
      uep.consumption_p4,
      uep.consumption_p5,
      uep.consumption_p6,
      uep.anual_consumption_p1,
      uep.anual_consumption_p2,
      uep.anual_consumption_p3,
      uep.anual_consumption_p4,
      uep.anual_consumption_p5,
      uep.anual_consumption_p6,
      uep.autoconsumo_precio,
      uep."precio_kw_P1",
      uep."precio_kw_P2",
      uep."precio_kw_P3",
      uep."precio_kw_P4",
      uep."precio_kw_P5",
      uep."precio_kw_P6",
      uep."precio_kwh_P1",
      uep."precio_kwh_P2",
      uep."precio_kwh_P3",
      uep."precio_kwh_P4",
      uep."precio_kwh_P5",
      uep."precio_kwh_P6",
      uep.total_consumption,
      uep.total_anual_consumption,
      uep.power_p1,
      uep.power_p2,
      uep.power_p3,
      uep.power_p4,
      uep.power_p5,
      uep.power_p6,
      uep.current_total_invoice,
      uep.surpluses,
      uep.total_surpluses_price,
      uep.power_surpluses,
      uep."VAT",
      uep.days,
      uep.pdf_invoice,
      uep."CUPS",
      uep.address_id,
      uep.company,
      uep.rate_name,
      uep.invoice_month,
      uep.equipment_rental,
      uep.selfconsumption,
      uep.manual_data,
      uep.reactive,
      uep.valuation_id,
      uep.invoice_year,
      uep.meter_rental,
      uep.preferred_subrate,
      uep.new_company,
      uep.new_rate_name,
      uep.new_subrate_name,
      uep.price_pp1,
      uep.price_pp2,
      uep.price_pp3,
      uep.price_pp4,
      uep.price_pp5,
      uep.price_pp6,
      uep.price_cp1,
      uep.price_cp2,
      uep.price_cp3,
      uep.price_cp4,
      uep.price_cp5,
      uep.price_cp6,
      uep.price_surpluses,
      uep.total_power_price,
      uep.total_consumption_price,
      uep.new_total_price,
      uep.type,
      uep.temp_client_name,
      uep.temp_client_last_name,
      uep.type_filter,
      uep.deleted,
      uep.deleted_reason,
      uep.new_rate_id,
      uep.max_power,
      uep.speed_fiber,
      uep.mobile_lines,
      uep.mobile_total_gb,
      uep.fijo,
      uep.new_speed_fiber,
      uep.new_total_mobile_lines,
      uep.new_mobile_total_gb,
      uep.rate_pack,
      uep.phone_total_anual_price,
      uep.crs_id,
      uep.total_crs,
      uep.savings,
      uep.savings_yearly,
      uep.tarifa_plana,
      CASE
          WHEN ((uep.new_company IS NOT NULL) AND (uep.savings_yearly > (0)::double precision)) 
              THEN ((uep.savings_yearly * (1)::double precision) + (COALESCE(uep.total_crs, (0)::real) * (4)::double precision))
          ELSE (uep.savings_yearly * (1)::double precision) + (COALESCE(uep.total_crs, (0)::real) * (4)::double precision)
      END AS ranked_crs,
      row_number() over (
          partition by uep.id
          order by (
              case
                  when uep.new_company is not null and uep.savings_yearly > 0::double precision 
                      then uep.savings_yearly * 1::double precision + COALESCE(uep.total_crs, 0::real) * 4::double precision
                  else uep.savings_yearly * 1::double precision + COALESCE(uep.total_crs, 0::real) * 4::double precision
              end
          ) desc
      ) as rank,
      uep.cif,
      uep.region
    from
      unified_extended_prices uep
  ),
  all_comparisons_ranked as (
    select
      ranked_comparisons.id,
      ranked_comparisons.created_at,
      ranked_comparisons.client_email,
      ranked_comparisons.advisor_id,
      ranked_comparisons.consumption_p1,
      ranked_comparisons.consumption_p2,
      ranked_comparisons.consumption_p3,
      ranked_comparisons.consumption_p4,
      ranked_comparisons.consumption_p5,
      ranked_comparisons.consumption_p6,
      ranked_comparisons.anual_consumption_p1,
      ranked_comparisons.anual_consumption_p2,
      ranked_comparisons.anual_consumption_p3,
      ranked_comparisons.anual_consumption_p4,
      ranked_comparisons.anual_consumption_p5,
      ranked_comparisons.anual_consumption_p6,
      ranked_comparisons.autoconsumo_precio,
      ranked_comparisons."precio_kw_P1",
      ranked_comparisons."precio_kw_P2",
      ranked_comparisons."precio_kw_P3",
      ranked_comparisons."precio_kw_P4",
      ranked_comparisons."precio_kw_P5",
      ranked_comparisons."precio_kw_P6",
      ranked_comparisons."precio_kwh_P1",
      ranked_comparisons."precio_kwh_P2",
      ranked_comparisons."precio_kwh_P3",
      ranked_comparisons."precio_kwh_P4",
      ranked_comparisons."precio_kwh_P5",
      ranked_comparisons."precio_kwh_P6",
      ranked_comparisons.total_consumption,
      ranked_comparisons.total_anual_consumption,
      ranked_comparisons.power_p1,
      ranked_comparisons.power_p2,
      ranked_comparisons.power_p3,
      ranked_comparisons.power_p4,
      ranked_comparisons.power_p5,
      ranked_comparisons.power_p6,
      ranked_comparisons.current_total_invoice,
      ranked_comparisons.surpluses,
      ranked_comparisons.total_surpluses_price,
      ranked_comparisons.power_surpluses,
      ranked_comparisons."VAT",
      ranked_comparisons.days,
      ranked_comparisons.pdf_invoice,
      ranked_comparisons."CUPS",
      ranked_comparisons.address_id,
      ranked_comparisons.company,
      ranked_comparisons.rate_name,
      ranked_comparisons.invoice_month,
      ranked_comparisons.equipment_rental,
      ranked_comparisons.selfconsumption,
      ranked_comparisons.manual_data,
      ranked_comparisons.reactive,
      ranked_comparisons.valuation_id,
      ranked_comparisons.invoice_year,
      ranked_comparisons.meter_rental,
      ranked_comparisons.preferred_subrate,
      ranked_comparisons.new_company,
      ranked_comparisons.new_rate_name,
      ranked_comparisons.new_subrate_name,
      ranked_comparisons.price_pp1,
      ranked_comparisons.price_pp2,
      ranked_comparisons.price_pp3,
      ranked_comparisons.price_pp4,
      ranked_comparisons.price_pp5,
      ranked_comparisons.price_pp6,
      ranked_comparisons.price_cp1,
      ranked_comparisons.price_cp2,
      ranked_comparisons.price_cp3,
      ranked_comparisons.price_cp4,
      ranked_comparisons.price_cp5,
      ranked_comparisons.price_cp6,
      ranked_comparisons.price_surpluses,
      ranked_comparisons.total_power_price,
      ranked_comparisons.total_consumption_price,
      ranked_comparisons.new_total_price,
      ranked_comparisons.type,
      ranked_comparisons.temp_client_name,
      ranked_comparisons.temp_client_last_name,
      ranked_comparisons.type_filter,
      ranked_comparisons.deleted,
      ranked_comparisons.deleted_reason,
      ranked_comparisons.new_rate_id,
      ranked_comparisons.max_power,
      ranked_comparisons.speed_fiber,
      ranked_comparisons.mobile_lines,
      ranked_comparisons.mobile_total_gb,
      ranked_comparisons.fijo,
      ranked_comparisons.new_speed_fiber,
      ranked_comparisons.new_total_mobile_lines,
      ranked_comparisons.new_mobile_total_gb,
      ranked_comparisons.rate_pack,
      ranked_comparisons.phone_total_anual_price,
      ranked_comparisons.crs_id,
      ranked_comparisons.total_crs,
      ranked_comparisons.savings,
      ranked_comparisons.savings_yearly,
      ranked_comparisons.ranked_crs,
      ranked_comparisons.rank,
      ranked_comparisons.tarifa_plana,
      ranked_comparisons.cif,
      ranked_comparisons.region
    from
      ranked_comparisons
    union all
    select
      ranked_phone.id,
      ranked_phone.created_at,
      ranked_phone.client_email,
      ranked_phone.advisor_id,
      ranked_phone.consumption_p1,
      ranked_phone.consumption_p2,
      ranked_phone.consumption_p3,
      ranked_phone.consumption_p4,
      ranked_phone.consumption_p5,
      ranked_phone.consumption_p6,
      ranked_phone.anual_consumption_p1,
      ranked_phone.anual_consumption_p2,
      ranked_phone.anual_consumption_p3,
      ranked_phone.anual_consumption_p4,
      ranked_phone.anual_consumption_p5,
      ranked_phone.anual_consumption_p6,
      ranked_phone.autoconsumo_precio,
      ranked_phone."precio_kw_P1",
      ranked_phone."precio_kw_P2",
      ranked_phone."precio_kw_P3",
      ranked_phone."precio_kw_P4",
      ranked_phone."precio_kw_P5",
      ranked_phone."precio_kw_P6",
      ranked_phone."precio_kwh_P1",
      ranked_phone."precio_kwh_P2",
      ranked_phone."precio_kwh_P3",
      ranked_phone."precio_kwh_P4",
      ranked_phone."precio_kwh_P5",
      ranked_phone."precio_kwh_P6",
      ranked_phone.total_consumption,
      ranked_phone.total_anual_consumption,
      ranked_phone.power_p1,
      ranked_phone.power_p2,
      ranked_phone.power_p3,
      ranked_phone.power_p4,
      ranked_phone.power_p5,
      ranked_phone.power_p6,
      ranked_phone.current_total_invoice,
      ranked_phone.surpluses,
      ranked_phone.total_surpluses_price,
      ranked_phone.power_surpluses,
      ranked_phone."VAT",
      ranked_phone.days,
      ranked_phone.pdf_invoice,
      ranked_phone.cups,
      ranked_phone.address_id,
      ranked_phone.company,
      ranked_phone.rate_name,
      ranked_phone.invoice_month,
      ranked_phone.equipment_rental,
      ranked_phone.selfconsumption,
      ranked_phone.manual_data,
      ranked_phone.reactive,
      ranked_phone.valuation_id,
      ranked_phone.invoice_year,
      ranked_phone.meter_rental,
      ranked_phone.preferred_subrate,
      ranked_phone.new_company,
      ranked_phone.new_rate_name,
      ranked_phone.new_subrate_name,
      ranked_phone.price_pp1,
      ranked_phone.price_pp2,
      ranked_phone.price_pp3,
      ranked_phone.price_pp4,
      ranked_phone.price_pp5,
      ranked_phone.price_pp6,
      ranked_phone.price_cp1,
      ranked_phone.price_cp2,
      ranked_phone.price_cp3,
      ranked_phone.price_cp4,
      ranked_phone.price_cp5,
      ranked_phone.price_cp6,
      ranked_phone.price_surpluses,
      ranked_phone.total_power_price,
      ranked_phone.total_consumption_price,
      ranked_phone.new_total_price,
      ranked_phone.type,
      ranked_phone.temp_client_name,
      ranked_phone.temp_client_last_name,
      ranked_phone.type_filter,
      ranked_phone.deleted,
      ranked_phone.deleted_reason,
      ranked_phone.new_rate_id,
      ranked_phone.max_power,
      ranked_phone.speed_fiber,
      ranked_phone.mobile_lines,
      ranked_phone.mobile_total_gb,
      ranked_phone.fijo,
      ranked_phone.new_speed_fiber,
      ranked_phone.new_total_mobile_lines,
      ranked_phone.new_mobile_total_gb,
      ranked_phone.rate_pack,
      ranked_phone.phone_total_anual_price,
      ranked_phone.crs_id,
      ranked_phone.total_crs,
      ranked_phone.savings,
      ranked_phone.savings_yearly,
      ranked_phone.ranked_crs,
      ranked_phone.rank,
      false as tarifa_plana,
      false as cif,
      NULL AS region
    from
      ranked_phone
  )
select distinct
  rc.id,
  rc.created_at,
  rc.client_email,
  rc.advisor_id,
  rc.consumption_p1,
  rc.consumption_p2,
  rc.consumption_p3,
  rc.consumption_p4,
  rc.consumption_p5,
  rc.consumption_p6,
  rc.anual_consumption_p1,
  rc.anual_consumption_p2,
  rc.anual_consumption_p3,
  rc.anual_consumption_p4,
  rc.anual_consumption_p5,
  rc.anual_consumption_p6,
  rc.autoconsumo_precio,
  rc."precio_kw_P1",
  rc."precio_kw_P2",
  rc."precio_kw_P3",
  rc."precio_kw_P4",
  rc."precio_kw_P5",
  rc."precio_kw_P6",
  rc."precio_kwh_P1",
  rc."precio_kwh_P2",
  rc."precio_kwh_P3",
  rc."precio_kwh_P4",
  rc."precio_kwh_P5",
  rc."precio_kwh_P6",
  rc.total_consumption,
  rc.total_anual_consumption,
  rc.power_p1,
  rc.power_p2,
  rc.power_p3,
  rc.power_p4,
  rc.power_p5,
  rc.power_p6,
  rc.current_total_invoice,
  rc.surpluses,
  rc.total_surpluses_price,
  rc.power_surpluses,
  rc."VAT",
  rc.days,
  rc.pdf_invoice,
  rc."CUPS",
  rc.address_id,
  rc.company,
  rc.rate_name,
  rc.invoice_month,
  rc.equipment_rental,
  rc.selfconsumption,
  rc.manual_data,
  rc.reactive,
  rc.valuation_id,
  rc.invoice_year,
  rc.meter_rental,
  rc.preferred_subrate,
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
  rc.total_power_price,
  rc.total_consumption_price,
  rc.new_total_price,
  rc.type,
  rc.temp_client_name,
  rc.temp_client_last_name,
  rc.type_filter,
  rc.deleted,
  rc.deleted_reason,
  rc.new_rate_id,
  rc.max_power,
  rc.speed_fiber,
  rc.mobile_lines,
  rc.mobile_total_gb,
  rc.fijo,
  rc.new_speed_fiber,
  rc.new_total_mobile_lines,
  rc.new_mobile_total_gb,
  rc.rate_pack,
  rc.phone_total_anual_price,
  rc.crs_id,
  rc.total_crs,
  rc.savings,
  rc.savings_yearly,
  rc.ranked_crs,
  rc.rank,
  rc.tarifa_plana,
-- ================================================================================
-- IEE MONTHLY
-- ================================================================================
  case
    when rc.type = any (array['light'::text, '3_0'::text]) then 
      (
        COALESCE(rc.consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) +
        COALESCE(rc.consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) +
        COALESCE(rc.consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) +
        COALESCE(rc.consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) + 
        COALESCE(rc.consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) +
        COALESCE(rc.consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) +
        COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * COALESCE(rc.days, 0)::double precision +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * COALESCE(rc.days, 0)::double precision
      ) * 0.05113::double precision
    else 0.0::double precision
  end as iee_monthly,
-- ================================================================================
-- IEE
-- ================================================================================
  case
    when rc.type = any (array['light'::text, '3_0'::text]) then 
    (
      COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) + 
      COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) +
      COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) +
      COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) + 
      COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) +
      COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) +
      (
        COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) + 
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) + 
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real)
      ) * 365::double precision
    ) * 0.05113::double precision
    else 0.0::double precision
  end as iee,
-- ================================================================================
-- NEW TOTAL PRICE WITH VAT
-- ================================================================================
  case
    when rc.type = 'phone'::text then rc.new_total_price
    when rc.new_company is not null then case
    when rc.type = 'light'::text and rc.tarifa_plana = 'true' then 
      (
        (
          COALESCE(rc.new_total_price, 0::real::double precision) * 1.05113::double precision ) + COALESCE(rc.equipment_rental)
      ) * (1::double precision + COALESCE(rc."VAT", 0::real))

    when rc.type = 'light'::text then 
    (
      (
        COALESCE(rc.new_total_price, 0::real::double precision) + (COALESCE(rc.days)::numeric * 0.012742)::double precision
      ) * 1.05113::double precision + COALESCE(rc.equipment_rental)
    ) * (1::double precision + COALESCE(rc."VAT", 0::real))

    when rc.type = '3_0'::text then 
    (
      COALESCE(rc.new_total_price, 0::real::double precision) * 1.05113::double precision + COALESCE(rc.equipment_rental)
    ) * (1::double precision + COALESCE(rc."VAT", 0::real))

    when rc.type = 'gas'::text then
    (
      COALESCE(rc.new_total_price, 0::real::double precision) + COALESCE(rc.equipment_rental)
    ) * (1::double precision + COALESCE(rc."VAT", 0::real))
    
      else 0.0::double precision
    end::numeric::double precision
    else 0.0::double precision
  end as new_total_price_with_vat,
-- ================================================================================
-- NEW TOTAL YEARLY PRICE WITH VAT
-- ================================================================================
  case
    when rc.type = 'phone'::text then rc.phone_total_anual_price::double precision
    when rc.type = 'light'::text then 
    (
      COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) +
      COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) +
      COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) +
      COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) * COALESCE(365, 0)::double precision +
      COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * COALESCE(365, 0)::double precision
    ) * (1::numeric + 0.05113)::double precision 
    * (1::double precision + COALESCE(rc."VAT", 0::real))
    when rc.type = '3_0'::text then (
      COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) +
      COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) +
      COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) +
      COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) +
      COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) + 
      COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) +
      (COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) * 365::double precision +
      COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * 365::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * 365::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * 365::double precision +
          COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * 365::double precision +
          COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * 365::double precision
      )
    ) * (1::numeric + 0.05113)::double precision * (1::double precision + COALESCE(rc."VAT", 0::real))
    when rc.type = 'gas'::text then COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) * (1::double precision + COALESCE(rc."VAT", 0::real))
    else 0.0::double precision
  end as new_total_yearly_price_with_vat,
-- ================================================================================
-- SAVING PERCENTAGE
-- ================================================================================
  case
    when rc.type = 'phone'::text then (
      rc.current_total_invoice * 12::double precision - COALESCE(
        rc.phone_total_anual_price::double precision,
        0.0::double precision
      )
    ) / NULLIF(
      rc.current_total_invoice * 12::double precision,
      0.0::double precision
    )
    WHEN rc.tarifa_plana = TRUE and rc.type = 'light' THEN
     (
      (rc.current_total_invoice * (365.0 / rc.days)) -
      ( (
            (COALESCE(rc.anual_consumption_p1, 0) * COALESCE(rc.price_cp1, 0)) +
            (COALESCE(rc.anual_consumption_p2, 0) * COALESCE(rc.price_cp2, 0)) +
            (COALESCE(rc.anual_consumption_p3, 0) * COALESCE(rc.price_cp3, 0)) +
            (COALESCE(rc.power_p1, 0) * COALESCE(rc.price_pp1, 0) * 365) +
            (COALESCE(rc.power_p2, 0) * COALESCE(rc.price_pp2, 0) * 365)
          ) * 1.05113) 
      * (1 + COALESCE(rc."VAT", 0.0))
    ) / (rc.current_total_invoice * (365.0 / rc.days))

    WHEN rc.tarifa_plana = TRUE and rc.type = 'gas' THEN
     (
      (rc.current_total_invoice * (365.0 / rc.days)) -
      ( (
            (COALESCE(rc.anual_consumption_p1, 0) * (COALESCE(rc.price_cp1, 0))+0.00234) +
            (COALESCE(rc.price_pp1, 0) * 365)) * (1 + COALESCE(rc."VAT", 0.0))
    )) / (rc.current_total_invoice * (365.0 / rc.days))
    when rc.new_company is not null and rc.type <> '3_0'::text then 
    (
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) +
        COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) +
        COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) +
        COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) +
        COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) +
        COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) +
        COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365::double precision +
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365::double precision +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365::double precision 
            - 
        COALESCE(rc.surpluses, 0::real) * 182.5::double precision / case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.autoconsumo_precio, 0::real)
      ) 
      * case
        when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
        else 1.0::double precision
      end 
      * (1::double precision + COALESCE(rc."VAT", 0::real)) 
      - 
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) +
        COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) +
        COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) +
        COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) +
        COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) +
        COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) +
        COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc.price_pp1, 0::real) * 365::double precision +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * 365::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * 365::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * 365::double precision +
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * 365::double precision +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * 365::double precision 
        - COALESCE(rc.surpluses, 0::real) * 182.5::double precision 
        / 
        case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.price_surpluses, 0::real)
      ) 
      *
        case
          when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
        else 1.0::double precision
      end 
      * (1::double precision + COALESCE(rc."VAT", 0::real))
    ) / NULLIF(
                (
                  COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) +
                  COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) +
                  COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) + 
                  COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) + 
                  COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) + 
                  COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) + 
                  COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision + 
                  COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365::double precision +
                  COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365::double precision + 
                  COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365::double precision +
                  COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365::double precision +
                  COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365::double precision - 
                  COALESCE(rc.surpluses, 0::real) * 182.5::double precision 
                  /
                  case
                  when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
                    else rc.days::numeric
                  end::double precision 
                  * COALESCE(rc.autoconsumo_precio, 0::real)
                )
                * 
                case
                  when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
                  else 1.0::double precision
                end 
                * (1::double precision + COALESCE(rc."VAT", 0::real)), 0::double precision
              )
    when rc.new_company is not null and rc.type = '3_0'::text then 
    (
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) +
        COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) +
        COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) +
        COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) +
        COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) +
        COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) +
        COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision +
        COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365::double precision +
        COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365::double precision +
        COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365::double precision +
        COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365::double precision +
        COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365::double precision -
        COALESCE(rc.surpluses, 0::real) * 182.5::double precision 
        / 
        case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.autoconsumo_precio, 0::real)
      ) 
      * case
         when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
        else 1.0::double precision
      end * (1::double precision + COALESCE(rc."VAT", 0::real)) - 
        (
          COALESCE(rc.total_consumption_price, 0::real) / COALESCE(rc.total_consumption, 0::real) * COALESCE(rc.total_anual_consumption, 0::real) + 
          COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) * 365::double precision +
          COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * 365::double precision +
          COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * 365::double precision + 
          COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * 365::double precision +
          COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * 365::double precision + 
          COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * 365::double precision
        ) * 1.05113::double precision * (1::double precision + COALESCE(rc."VAT", 0::real))
    ) 
    / 
    NULLIF(
            (
              COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) +
              COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) +
              COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) +
              COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) +
              COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) +
              COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) +
              COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision +
              COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365::double precision +
              COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365::double precision +
              COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365::double precision +
              COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365::double precision + 
              COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365::double precision - 
              COALESCE(rc.surpluses, 0::real) * 182.5::double precision 
              / 
              case
                when COALESCE(rc.days::real, 0::real) = 1::double precision then 182.5
                else rc.days::numeric
              end::double precision
               * COALESCE(rc.autoconsumo_precio, 0::real)
            ) * case
              when rc.type = any (array['light'::text, '3_0'::text]) then 1.05113::double precision
                else 1.0::double precision
              end * (1::double precision + COALESCE(rc."VAT", 0::real)),
            0::double precision
          )
    else 0.0::double precision
  end as saving_percentage,
-- ================================================================================
-- SUPERVISORS
-- ================================================================================
  case
    when (
      (
        select
          u2.racc
        from
          users u2
        where
          u2.user_id = rc.advisor_id
        limit
          1
      )
    ) = true then (
      select
        array_cat(us.supervisors, array_agg(ur.user_id)) as array_cat
      from
        users_racc ur
    )
    else us.supervisors
  end as supervisors,
  -- ================================================================================
  rc.temp_client_name as client_name,
  rc.temp_client_last_name as client_last_name,
  us.email as advisor_email,
  us.display_name as advisor_display_name,
  case
    when rc.new_company = 'PLENITUDE'::text then 'https://vlpknvvgixhiznqslzwk.supabase.co/storage/v1/object/public/files/companies_logos/6.png'::text
    when rc.new_company = 'GANA'::text then 'https://vlpknvvgixhiznqslzwk.supabase.co/storage/v1/object/public/files/companies_logos/2.png'::text
    when rc.new_company = 'GALP'::text then 'https://vlpknvvgixhiznqslzwk.supabase.co/storage/v1/object/public/files/companies_logos/5.png'::text
    when rc.new_company = 'CYE'::text then 'https://vlpknvvgixhiznqslzwk.supabase.co/storage/v1/object/public/files/companies_logos/1.png'::text
    when rc.new_company = 'BASSOLS'::text then 'https://vlpknvvgixhiznqslzwk.supabase.co/storage/v1/object/public/files/companies_logos/3.png'::text
    when rc.new_company = 'ENDESA'::text then 'https://vlpknvvgixhiznqslzwk.supabase.co/storage/v1/object/public/files/companies_logos/4.png'::text
    when rc.new_company = 'NATURGY'::text then 'https://vlpknvvgixhiznqslzwk.supabase.co/storage/v1/object/public/files/companies_logos/naturgy.png'::text
    when rc.new_company = 'IMAGINA'::text then 'https://upload.wikimedia.org/wikipedia/commons/d/d5/Imagina_Energ%C3%ADa_Logo.png'::text
    else null::text
  end as new_company_logo,
  array[rc.advisor_id::text, 'All'::text] as advisor_filter,
  to_char(rc.created_at, 'MM'::text) as created_month,
  to_char(rc.created_at, 'YYYY'::text) as created_year,
  concat_ws(', '::text, rc.client_email, rc."CUPS") as search,
  array[rc.company, 'All'::text] as company_filter,
  rc.cif,
  rc.region
from
  all_comparisons_ranked rc
  left join _users_supervisors us on rc.advisor_id = us.user_id
where
  rc.rank = 1
  and (
    rc.deleted is null
    or rc.deleted = false
  );