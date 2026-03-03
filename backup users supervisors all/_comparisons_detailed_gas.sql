create view public._comparisons_detailed_gas as
with
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
      cg."precio actual kw" as "precio_kwh_P1",
      0 as "precio_kwh_P2",
      0 as "precio_kwh_P3",
      0 as "precio_kwh_P4",
      0 as "precio_kwh_P5",
      0 as "precio_kwh_P6",
      cg."precio fijo actual dia" as "precio_kw_P1",
      0 as "precio_kw_P2",
      0 as "precio_kw_P3",
      0 as "precio_kw_P4",
      0 as "precio_kw_P5",
      0 as "precio_kw_P6",
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
      cg.wants_permanence,
      cg.term_month_i_want,
      cg.excluded_company_ids,
      cg.wants_gdo,
      cg.temp_client_phone,
      cr.company as new_company,
      cr.rate_name as new_rate_name,
      cr.subrate_name as new_subrate_name,
      cr.term_month,
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
      (
        COALESCE(cg.days::real, 0::real) * COALESCE(cr.price_pp1, 0::real)
      )::double precision as total_power_price,
      COALESCE(cg.consumption, 0::real) * COALESCE(cr.price_cp1, 0::real) as total_consumption_price,
      COALESCE(cg.days::real, 0::real) * COALESCE(cr.price_pp1, 0::real) + COALESCE(cg.consumption, 0::real) * (
        COALESCE(cr.price_cp1, 0::real) + 0.00234::double precision
      ) as new_total_price,
      'gas'::text as type,
      COALESCE(cg.temp_client_name, ''::text) as temp_client_name,
      COALESCE(cg.temp_client_last_name, ''::text) as temp_client_last_name,
      array['gas'::text, 'All'::text] as type_filter,
      cg.deleted,
      cg.deleted_reason,
      cg.deleted_at,
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
      cg.region,
      cr.has_permanence,
      cr.rate_mode,
      0 as total_excedentes_precio,
      cg.comparison_id
    from
      (
        select
          comparison_gas.id,
          comparison_gas.created_at,
          comparison_gas.client_email,
          comparison_gas.consumption,
          comparison_gas.current_total_invoice,
          comparison_gas.days,
          comparison_gas."VAT",
          comparison_gas.meter_rental,
          comparison_gas.advisor_id,
          comparison_gas.proposal_date,
          comparison_gas."CUPS",
          comparison_gas.pdf_invoice,
          comparison_gas.address_id,
          comparison_gas.rate_name,
          comparison_gas.manual_data,
          comparison_gas.equipment_rental,
          comparison_gas.valuation_id,
          comparison_gas.invoice_month,
          comparison_gas.invoice_year,
          comparison_gas.company,
          comparison_gas.temp_client_name,
          comparison_gas.temp_client_last_name,
          comparison_gas.deleted,
          comparison_gas.deleted_reason,
          comparison_gas.preferred_subrate,
          comparison_gas.anual_consumption,
          comparison_gas."precio actual kw",
          comparison_gas."precio fijo actual dia",
          comparison_gas.totalconsumo,
          comparison_gas.totalfijo,
          comparison_gas.region,
          comparison_gas.tarifa_plana,
          comparison_gas.cif,
          comparison_gas.source_type_id,
          comparison_gas.wants_permanence,
          comparison_gas.rate_mode,
          comparison_gas.prefered_rate_type,
          comparison_gas.comparison_id,
          comparison_gas.term_month_i_want,
          comparison_gas.invoice_address,
          comparison_gas.deleted_at,
          comparison_gas.excluded_company_ids,
          comparison_gas.wants_gdo,
          comparison_gas.temp_client_phone
        from
          comparison_gas
        where
          comparison_gas.valuation_id is null
          and comparison_gas.deleted = false
      ) cg
      left join users u on u.user_id = cg.advisor_id
      left join comparison_rates cr on cr.type = 'gas'::text
      and cr.company <> cg.company
      and cr.deleted = false
      and (
        cr.tenant_id is null
        or (u.tenant = any (cr.tenant_id))
      )
      and cr.subrate_name = cg.rate_name
      and (
        cr.invoice_month is null
        and cr.invoice_year is null
        or cr.invoice_month = cg.invoice_month
        and cr.invoice_year = cg.invoice_year
      )
      and (
        cr.cif is null
        or cr.cif = cg.cif
      )
      and (
        cg.preferred_subrate is null
        or cg.preferred_subrate = ''::text
        or cr.subrate_name = cg.rate_name
      )
      and (
        cg.prefered_rate_type is null
        or cr.rate_mode = cg.prefered_rate_type
        or cg.prefered_rate_type = 'Indexada'::rate_mode_type
        and cr.rate_mode is null
        or not (
          exists (
            select
              1
            from
              comparison_rates cr2
            where
              cr2.type = 'gas'::text
              and cr2.company <> cg.company
              and cr2.subrate_name = cg.rate_name
              and cr2.deleted = false
              and (
                cr2.tenant_id is null
                or (u.tenant = any (cr2.tenant_id))
              )
              and (
                cr2.invoice_month is null
                and cr2.invoice_year is null
                or cr2.invoice_month = cg.invoice_month
                and cr2.invoice_year = cg.invoice_year
              )
              and (
                cr2.cif is null
                or cr2.cif = cg.cif
              )
              and (
                cg.preferred_subrate is null
                or cg.preferred_subrate = ''::text
                or cr2.subrate_name = cg.rate_name
              )
              and (
                cr2.rate_mode = cg.prefered_rate_type
                or cg.prefered_rate_type = 'Indexada'::rate_mode_type
                and cr2.rate_mode is null
              )
          )
        )
      )
      and (
        cg.wants_permanence is not true
        or cr.has_permanence = true
        or not (
          exists (
            select
              1
            from
              comparison_rates crp
            where
              crp.type = 'gas'::text
              and crp.company <> cg.company
              and crp.subrate_name = cg.rate_name
              and (
                crp.invoice_month is null
                and crp.invoice_year is null
                or crp.invoice_month = cg.invoice_month
                and crp.invoice_year = cg.invoice_year
              )
              and (
                cg.region is null
                or (cg.region = any (crp.region))
              )
              and (
                cg.preferred_subrate is null
                or cg.preferred_subrate = ''::text
                or crp.subrate_name = cg.rate_name
              )
              and crp.has_permanence = true
          )
        )
      )
      and (
        cg.region is null
        or (cg.region = any (cr.region))
      )
      and (
        cg.excluded_company_ids is null
        or not (
          cr.company in (
            select
              c_ex.name
            from
              companies c_ex
            where
              c_ex.id = any (cg.excluded_company_ids)
          )
        )
      )
  ),
  unified_calculated_prices as (
    select
      calculated_prices_gas.id,
      calculated_prices_gas.created_at,
      calculated_prices_gas.client_email,
      calculated_prices_gas.advisor_id,
      calculated_prices_gas.consumption_p1,
      calculated_prices_gas.consumption_p2,
      calculated_prices_gas.consumption_p3,
      calculated_prices_gas.consumption_p4,
      calculated_prices_gas.consumption_p5,
      calculated_prices_gas.consumption_p6,
      calculated_prices_gas.anual_consumption_p1,
      calculated_prices_gas.anual_consumption_p2,
      calculated_prices_gas.anual_consumption_p3,
      calculated_prices_gas.anual_consumption_p4,
      calculated_prices_gas.anual_consumption_p5,
      calculated_prices_gas.anual_consumption_p6,
      calculated_prices_gas.autoconsumo_precio,
      calculated_prices_gas."precio_kwh_P1",
      calculated_prices_gas."precio_kwh_P2",
      calculated_prices_gas."precio_kwh_P3",
      calculated_prices_gas."precio_kwh_P4",
      calculated_prices_gas."precio_kwh_P5",
      calculated_prices_gas."precio_kwh_P6",
      calculated_prices_gas."precio_kw_P1",
      calculated_prices_gas."precio_kw_P2",
      calculated_prices_gas."precio_kw_P3",
      calculated_prices_gas."precio_kw_P4",
      calculated_prices_gas."precio_kw_P5",
      calculated_prices_gas."precio_kw_P6",
      calculated_prices_gas.total_consumption,
      calculated_prices_gas.total_anual_consumption,
      calculated_prices_gas.power_p1,
      calculated_prices_gas.power_p2,
      calculated_prices_gas.power_p3,
      calculated_prices_gas.power_p4,
      calculated_prices_gas.power_p5,
      calculated_prices_gas.power_p6,
      calculated_prices_gas.current_total_invoice,
      calculated_prices_gas.surpluses,
      calculated_prices_gas.total_surpluses_price,
      calculated_prices_gas.power_surpluses,
      calculated_prices_gas."VAT",
      calculated_prices_gas.days,
      calculated_prices_gas.pdf_invoice,
      calculated_prices_gas."CUPS",
      calculated_prices_gas.address_id,
      calculated_prices_gas.company,
      calculated_prices_gas.rate_name,
      calculated_prices_gas.invoice_month,
      calculated_prices_gas.equipment_rental,
      calculated_prices_gas.selfconsumption,
      calculated_prices_gas.manual_data,
      calculated_prices_gas.reactive,
      calculated_prices_gas.valuation_id,
      calculated_prices_gas.invoice_year,
      calculated_prices_gas.meter_rental,
      calculated_prices_gas.preferred_subrate,
      calculated_prices_gas.wants_permanence,
      calculated_prices_gas.term_month_i_want,
      calculated_prices_gas.excluded_company_ids,
      calculated_prices_gas.wants_gdo,
      calculated_prices_gas.temp_client_phone,
      calculated_prices_gas.new_company,
      calculated_prices_gas.new_rate_name,
      calculated_prices_gas.new_subrate_name,
      calculated_prices_gas.term_month,
      calculated_prices_gas.price_pp1,
      calculated_prices_gas.price_pp2,
      calculated_prices_gas.price_pp3,
      calculated_prices_gas.price_pp4,
      calculated_prices_gas.price_pp5,
      calculated_prices_gas.price_pp6,
      calculated_prices_gas.price_cp1,
      calculated_prices_gas.price_cp2,
      calculated_prices_gas.price_cp3,
      calculated_prices_gas.price_cp4,
      calculated_prices_gas.price_cp5,
      calculated_prices_gas.price_cp6,
      calculated_prices_gas.price_surpluses,
      calculated_prices_gas.total_power_price,
      calculated_prices_gas.total_consumption_price,
      calculated_prices_gas.new_total_price,
      calculated_prices_gas.type,
      calculated_prices_gas.temp_client_name,
      calculated_prices_gas.temp_client_last_name,
      calculated_prices_gas.type_filter,
      calculated_prices_gas.deleted,
      calculated_prices_gas.deleted_reason,
      calculated_prices_gas.deleted_at,
      calculated_prices_gas.new_rate_id,
      calculated_prices_gas.max_power,
      calculated_prices_gas.speed_fiber,
      calculated_prices_gas.mobile_lines,
      calculated_prices_gas.mobile_total_gb,
      calculated_prices_gas.fijo,
      calculated_prices_gas.new_speed_fiber,
      calculated_prices_gas.new_total_mobile_lines,
      calculated_prices_gas.new_mobile_total_gb,
      calculated_prices_gas.rate_pack,
      calculated_prices_gas.phone_total_anual_price,
      calculated_prices_gas.tarifa_plana,
      calculated_prices_gas.cif,
      calculated_prices_gas.region,
      calculated_prices_gas.has_permanence,
      calculated_prices_gas.rate_mode,
      calculated_prices_gas.total_excedentes_precio,
      calculated_prices_gas.comparison_id
    from
      calculated_prices_gas
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
      ucp."precio_kwh_P1",
      ucp."precio_kwh_P2",
      ucp."precio_kwh_P3",
      ucp."precio_kwh_P4",
      ucp."precio_kwh_P5",
      ucp."precio_kwh_P6",
      ucp."precio_kw_P1",
      ucp."precio_kw_P2",
      ucp."precio_kw_P3",
      ucp."precio_kw_P4",
      ucp."precio_kw_P5",
      ucp."precio_kw_P6",
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
      ucp.wants_permanence,
      ucp.term_month_i_want,
      ucp.excluded_company_ids,
      ucp.wants_gdo,
      ucp.temp_client_phone,
      ucp.new_company,
      ucp.new_rate_name,
      ucp.new_subrate_name,
      ucp.term_month,
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
      ucp.deleted_at,
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
      ucp.cif,
      ucp.region,
      ucp.has_permanence,
      ucp.rate_mode,
      ucp.total_excedentes_precio,
      ucp.comparison_id,
      crs.id as crs_id,
      COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(crs.crs_cp1, 0::real) + COALESCE(ucp.anual_consumption_p2::real, 0::real) * COALESCE(crs.crs_cp2, 0::real) + COALESCE(ucp.anual_consumption_p3::real, 0::real) * COALESCE(crs.crs_cp3, 0::real) + COALESCE(ucp.anual_consumption_p4::real, 0::real) * COALESCE(crs.crs_cp4, 0::real) + COALESCE(ucp.anual_consumption_p5::real, 0::real) * COALESCE(crs.crs_cp5, 0::real) + COALESCE(ucp.anual_consumption_p6::real, 0::real) * COALESCE(crs.crs_cp6, 0::real) + COALESCE(ucp.power_p1::real, 0::real) * COALESCE(crs.crs_pp1, 0::real) + COALESCE(ucp.power_p2::real, 0::real) * COALESCE(crs.crs_pp2, 0::real) + COALESCE(ucp.power_p3::real, 0::real) * COALESCE(crs.crs_pp3, 0::real) + COALESCE(ucp.power_p4::real, 0::real) * COALESCE(crs.crs_pp4, 0::real) + COALESCE(ucp.power_p5::real, 0::real) * COALESCE(crs.crs_pp5, 0::real) + COALESCE(ucp.power_p6::real, 0::real) * COALESCE(crs.crs_pp6, 0::real) + COALESCE(crs.fixed_crs, 0::real) as total_crs,
      v.annual_new_with_vat,
      v.annual_old_with_vat,
      v.monthly_new_with_vat,
      v.current_monthly_annualized,
      sly.savings_yearly
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
        or ucp.power_p1::double precision >= crs.min_power
      )
      and (
        crs.max_power is null
        or ucp.power_p1::double precision < crs.max_power
      )
      cross join lateral (
        select
          COALESCE(
            NULLIF(
              ucp.power_p1::double precision,
              0::double precision
            ),
            1::real::double precision
          ) as power1_or_1,
          COALESCE(ucp.power_p2::real, 0::real) as p2,
          COALESCE(ucp.power_p3::real, 0::real) as p3,
          COALESCE(ucp.power_p4::real, 0::real) as p4,
          COALESCE(ucp.power_p5::real, 0::real) as p5,
          COALESCE(ucp.power_p6::real, 0::real) as p6
      ) pwr
      cross join lateral (
        select
          COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp."precio_kwh_P1", 0::real) + COALESCE(ucp.anual_consumption_p2::real, 0::real) * COALESCE(ucp."precio_kwh_P2"::real, 0::real) + COALESCE(ucp.anual_consumption_p3::real, 0::real) * COALESCE(ucp."precio_kwh_P3"::real, 0::real) + COALESCE(ucp.anual_consumption_p4::real, 0::real) * COALESCE(ucp."precio_kwh_P4"::real, 0::real) + COALESCE(ucp.anual_consumption_p5::real, 0::real) * COALESCE(ucp."precio_kwh_P5"::real, 0::real) + COALESCE(ucp.anual_consumption_p6::real, 0::real) * COALESCE(ucp."precio_kwh_P6"::real, 0::real) as annual_new_energy_pre_vat
      ) a1
      cross join lateral (
        select
          COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp.price_cp1, 0::real) + COALESCE(ucp.anual_consumption_p2::real, 0::real) * COALESCE(ucp.price_cp2, 0::real) + COALESCE(ucp.anual_consumption_p3::real, 0::real) * COALESCE(ucp.price_cp3, 0::real) + COALESCE(ucp.anual_consumption_p4::real, 0::real) * COALESCE(ucp.price_cp4, 0::real) + COALESCE(ucp.anual_consumption_p5::real, 0::real) * COALESCE(ucp.price_cp5, 0::real) + COALESCE(ucp.anual_consumption_p6::real, 0::real) * COALESCE(ucp.price_cp6, 0::real) as annual_old_energy_pre_vat
      ) a2
      cross join lateral (
        select
          pwr.power1_or_1 * COALESCE(ucp."precio_kw_P1", 0::real) * 365::double precision + pwr.p2 * COALESCE(ucp."precio_kw_P2"::real, 0::real) * 365::double precision + pwr.p3 * COALESCE(ucp."precio_kw_P3"::real, 0::real) * 365::double precision + pwr.p4 * COALESCE(ucp."precio_kw_P4"::real, 0::real) * 365::double precision + pwr.p5 * COALESCE(ucp."precio_kw_P5"::real, 0::real) * 365::double precision + pwr.p6 * COALESCE(ucp."precio_kw_P6"::real, 0::real) * 365::double precision as annual_new_power_pre_vat,
          COALESCE(
            NULLIF(
              ucp.power_p1::double precision,
              0::double precision
            ),
            1::real::double precision
          ) * COALESCE(ucp.price_pp1, 0::real) * 365::double precision + COALESCE(ucp.power_p2::real, 0::real) * COALESCE(ucp.price_pp2, 0::real) * 365::double precision + COALESCE(ucp.power_p3::real, 0::real) * COALESCE(ucp.price_pp3, 0::real) * 365::double precision + COALESCE(ucp.power_p4::real, 0::real) * COALESCE(ucp.price_pp4, 0::real) * 365::double precision + COALESCE(ucp.power_p5::real, 0::real) * COALESCE(ucp.price_pp5, 0::real) * 365::double precision + COALESCE(ucp.power_p6::real, 0::real) * COALESCE(ucp.price_pp6, 0::real) * 365::double precision as annual_old_power_pre_vat
      ) pwr_year
      cross join lateral (
        select
          a1.annual_new_energy_pre_vat + pwr_year.annual_new_power_pre_vat as annual_new_pre_vat,
          a2.annual_old_energy_pre_vat + pwr_year.annual_old_power_pre_vat as annual_old_pre_vat
      ) base
      cross join lateral (
        select
          base.annual_new_pre_vat * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          ) as annual_new_with_vat,
          base.annual_old_pre_vat * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          ) as annual_old_with_vat,
          (
            COALESCE(ucp.new_total_price, 0::double precision) + COALESCE(ucp.equipment_rental, 0::real)
          ) * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          ) as monthly_new_with_vat,
          COALESCE(ucp.current_total_invoice, 0::real) * (365.0 / NULLIF(ucp.days::numeric, 0::numeric))::double precision as current_monthly_annualized
      ) v
      cross join lateral (
        select
          case
            when ucp.tarifa_plana = true then COALESCE(ucp.current_total_invoice, 0::real) * (365.0 / NULLIF(ucp.days::numeric, 0::numeric))::double precision - (
              COALESCE(ucp.anual_consumption_p1, 0::real) * (
                COALESCE(ucp.price_cp1, 0::real) + 0.00234::double precision
              ) + COALESCE(
                NULLIF(
                  ucp.power_p1::double precision,
                  0::double precision
                ),
                1::real::double precision
              ) * COALESCE(ucp.price_pp1, 0::real) * 365::double precision + COALESCE(
                NULLIF(
                  ucp.power_p2::double precision,
                  0::double precision
                ),
                1::real::double precision
              ) * COALESCE(ucp.price_pp2, 0::real) * 365::double precision
            ) * (
              1::double precision + COALESCE(ucp."VAT", 0::real)
            )
            when ucp.new_company is not null then v.annual_new_with_vat - v.annual_old_with_vat
            else 0.0::double precision
          end as savings_yearly
      ) sly
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
      uep."precio_kwh_P1",
      uep."precio_kwh_P2",
      uep."precio_kwh_P3",
      uep."precio_kwh_P4",
      uep."precio_kwh_P5",
      uep."precio_kwh_P6",
      uep."precio_kw_P1",
      uep."precio_kw_P2",
      uep."precio_kw_P3",
      uep."precio_kw_P4",
      uep."precio_kw_P5",
      uep."precio_kw_P6",
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
      uep.wants_permanence,
      uep.term_month_i_want,
      uep.excluded_company_ids,
      uep.wants_gdo,
      uep.temp_client_phone,
      uep.new_company,
      uep.new_rate_name,
      uep.new_subrate_name,
      uep.term_month,
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
      uep.deleted_at,
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
      uep.tarifa_plana,
      uep.cif,
      uep.region,
      uep.has_permanence,
      uep.rate_mode,
      uep.total_excedentes_precio,
      uep.comparison_id,
      uep.crs_id,
      uep.total_crs,
      uep.annual_new_with_vat,
      uep.annual_old_with_vat,
      uep.monthly_new_with_vat,
      uep.current_monthly_annualized,
      uep.savings_yearly,
      case
        when uep.new_company is not null
        and uep.savings_yearly > 0::double precision then uep.savings_yearly + COALESCE(uep.total_crs, 0::real) * 4::double precision
        else uep.savings_yearly + COALESCE(uep.total_crs, 0::real) * 4::double precision
      end as ranked_crs,
      row_number() over (
        partition by
          uep.id
        order by
          (
            case
              when uep.new_company is not null
              and uep.savings_yearly > 0::double precision then uep.savings_yearly + COALESCE(uep.total_crs, 0::real) * 4::double precision
              else uep.savings_yearly + COALESCE(uep.total_crs, 0::real) * 4::double precision
            end
          ) desc
      ) as rank
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
      ranked_comparisons."precio_kwh_P1",
      ranked_comparisons."precio_kwh_P2",
      ranked_comparisons."precio_kwh_P3",
      ranked_comparisons."precio_kwh_P4",
      ranked_comparisons."precio_kwh_P5",
      ranked_comparisons."precio_kwh_P6",
      ranked_comparisons."precio_kw_P1",
      ranked_comparisons."precio_kw_P2",
      ranked_comparisons."precio_kw_P3",
      ranked_comparisons."precio_kw_P4",
      ranked_comparisons."precio_kw_P5",
      ranked_comparisons."precio_kw_P6",
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
      ranked_comparisons.wants_permanence,
      ranked_comparisons.term_month_i_want,
      ranked_comparisons.excluded_company_ids,
      ranked_comparisons.wants_gdo,
      ranked_comparisons.temp_client_phone,
      ranked_comparisons.new_company,
      ranked_comparisons.new_rate_name,
      ranked_comparisons.new_subrate_name,
      ranked_comparisons.term_month,
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
      ranked_comparisons.deleted_at,
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
      ranked_comparisons.tarifa_plana,
      ranked_comparisons.cif,
      ranked_comparisons.region,
      ranked_comparisons.has_permanence,
      ranked_comparisons.rate_mode,
      ranked_comparisons.total_excedentes_precio,
      ranked_comparisons.comparison_id,
      ranked_comparisons.crs_id,
      ranked_comparisons.total_crs,
      ranked_comparisons.annual_new_with_vat,
      ranked_comparisons.annual_old_with_vat,
      ranked_comparisons.monthly_new_with_vat,
      ranked_comparisons.current_monthly_annualized,
      ranked_comparisons.savings_yearly,
      ranked_comparisons.ranked_crs,
      ranked_comparisons.rank
    from
      ranked_comparisons
  )
select
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
  rc.deleted_at,
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
  case
    when rc.new_company is not null then COALESCE(rc.current_total_invoice, 0::real) - rc.monthly_new_with_vat
    else 0.0::double precision
  end as savings,
  rc.savings_yearly,
  rc.ranked_crs,
  rc.rank,
  rc.tarifa_plana,
  0.0::double precision as iee_monthly,
  0.0::double precision as iee,
  (
    COALESCE(rc.days::real, 0::real) * COALESCE(rc.price_pp1, 0::real) + COALESCE(rc.consumption_p1, 0::real) * (
      COALESCE(rc.price_cp1, 0::real) + 0.00234::double precision
    ) + COALESCE(
      rc.equipment_rental::double precision,
      0::double precision
    )
  ) * (1::double precision + COALESCE(rc."VAT", 0::real)) as new_total_price_with_vat,
  COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) * (1::double precision + COALESCE(rc."VAT", 0::real)) as new_total_yearly_price_with_vat,
  case
    when rc.tarifa_plana = true
    and rc.type = 'gas'::text then (
      rc.current_total_invoice * (365.0 / rc.days::numeric)::double precision - (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) + 0.00234::double precision + COALESCE(rc.price_pp1, 0::real) * 365::double precision
      ) * (
        1::double precision + COALESCE(rc."VAT", 0.0::real)
      )
    ) / NULLIF(
      rc.current_total_invoice * (365.0 / rc.days::numeric)::double precision,
      0::double precision
    )
    when rc.new_company is not null
    and rc.type <> '3_0'::text then (
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) + COALESCE(rc.anual_consumption_p2::real, 0::real) * COALESCE(rc."precio_kwh_P2"::real, 0::real) + COALESCE(rc.anual_consumption_p3::real, 0::real) * COALESCE(rc."precio_kwh_P3"::real, 0::real) + COALESCE(rc.anual_consumption_p4::real, 0::real) * COALESCE(rc."precio_kwh_P4"::real, 0::real) + COALESCE(rc.anual_consumption_p5::real, 0::real) * COALESCE(rc."precio_kwh_P5"::real, 0::real) + COALESCE(rc.anual_consumption_p6::real, 0::real) * COALESCE(rc."precio_kwh_P6"::real, 0::real) + COALESCE(
          NULLIF(
            rc.power_p1::double precision,
            0::double precision
          ),
          1::real::double precision
        ) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision + COALESCE(rc.power_p2::real, 0::real) * COALESCE(rc."precio_kw_P2"::real, 0::real) * 365::double precision + COALESCE(rc.power_p3::real, 0::real) * COALESCE(rc."precio_kw_P3"::real, 0::real) * 365::double precision + COALESCE(rc.power_p4::real, 0::real) * COALESCE(rc."precio_kw_P4"::real, 0::real) * 365::double precision + COALESCE(rc.power_p5::real, 0::real) * COALESCE(rc."precio_kw_P5"::real, 0::real) * 365::double precision + COALESCE(rc.power_p6::real, 0::real) * COALESCE(rc."precio_kw_P6"::real, 0::real) * 365::double precision - COALESCE(rc.surpluses::real, 0::real) * 182.5::double precision / case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.autoconsumo_precio::real, 0::real)
      ) * 1.0::double precision * (1::double precision + COALESCE(rc."VAT", 0::real)) - (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) + COALESCE(rc.anual_consumption_p2::real, 0::real) * COALESCE(rc.price_cp2, 0::real) + COALESCE(rc.anual_consumption_p3::real, 0::real) * COALESCE(rc.price_cp3, 0::real) + COALESCE(rc.anual_consumption_p4::real, 0::real) * COALESCE(rc.price_cp4, 0::real) + COALESCE(rc.anual_consumption_p5::real, 0::real) * COALESCE(rc.price_cp5, 0::real) + COALESCE(rc.anual_consumption_p6::real, 0::real) * COALESCE(rc.price_cp6, 0::real) + COALESCE(
          NULLIF(
            rc.power_p1::double precision,
            0::double precision
          ),
          1::real::double precision
        ) * COALESCE(rc.price_pp1, 0::real) * 365::double precision + COALESCE(rc.power_p2::real, 0::real) * COALESCE(rc.price_pp2, 0::real) * 365::double precision + COALESCE(rc.power_p3::real, 0::real) * COALESCE(rc.price_pp3, 0::real) * 365::double precision + COALESCE(rc.power_p4::real, 0::real) * COALESCE(rc.price_pp4, 0::real) * 365::double precision + COALESCE(rc.power_p5::real, 0::real) * COALESCE(rc.price_pp5, 0::real) * 365::double precision + COALESCE(rc.power_p6::real, 0::real) * COALESCE(rc.price_pp6, 0::real) * 365::double precision - COALESCE(rc.surpluses::real, 0::real) * 182.5::double precision / case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.price_surpluses, 0::real)
      ) * 1.0::double precision * (1::double precision + COALESCE(rc."VAT", 0::real))
    ) / NULLIF(
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) + COALESCE(rc.anual_consumption_p2::real, 0::real) * COALESCE(rc."precio_kwh_P2"::real, 0::real) + COALESCE(rc.anual_consumption_p3::real, 0::real) * COALESCE(rc."precio_kwh_P3"::real, 0::real) + COALESCE(rc.anual_consumption_p4::real, 0::real) * COALESCE(rc."precio_kwh_P4"::real, 0::real) + COALESCE(rc.anual_consumption_p5::real, 0::real) * COALESCE(rc."precio_kwh_P5"::real, 0::real) + COALESCE(rc.anual_consumption_p6::real, 0::real) * COALESCE(rc."precio_kwh_P6"::real, 0::real) + COALESCE(
          NULLIF(
            rc.power_p1::double precision,
            0::double precision
          ),
          1::real::double precision
        ) * COALESCE(rc."precio_kw_P1", 0::real) * 365::double precision + COALESCE(rc.power_p2::real, 0::real) * COALESCE(rc."precio_kw_P2"::real, 0::real) * 365::double precision + COALESCE(rc.power_p3::real, 0::real) * COALESCE(rc."precio_kw_P3"::real, 0::real) * 365::double precision + COALESCE(rc.power_p4::real, 0::real) * COALESCE(rc."precio_kw_P4"::real, 0::real) * 365::double precision + COALESCE(rc.power_p5::real, 0::real) * COALESCE(rc."precio_kw_P5"::real, 0::real) * 365::double precision + COALESCE(rc.power_p6::real, 0::real) * COALESCE(rc."precio_kw_P6"::real, 0::real) * 365::double precision - COALESCE(rc.surpluses::real, 0::real) * 182.5::double precision / case
          when COALESCE(rc.days::real, 0::real) = 0::double precision then 182.5
          else rc.days::numeric
        end::double precision * COALESCE(rc.autoconsumo_precio::real, 0::real)
      ) * 1.0::double precision * (1::double precision + COALESCE(rc."VAT", 0::real)),
      0::double precision
    )
    else 0.0::double precision
  end as saving_percentage,
  us.supervisors,
  COALESCE(rc.temp_client_name, ''::text) as client_name,
  COALESCE(rc.temp_client_last_name, ''::text) as client_last_name,
  us.email as advisor_email,
  us.display_name as advisor_display_name,
  array[COALESCE(us.email, ''::text), 'All'::text] as advisor_filter,
  EXTRACT(
    month
    from
      rc.created_at
  )::text as created_month,
  EXTRACT(
    year
    from
      rc.created_at
  )::text as created_year,
  (
    (
      (
        (
          (COALESCE(rc."CUPS", ''::text) || ' '::text) || COALESCE(us.display_name, ''::text)
        ) || ' '::text
      ) || COALESCE(us.email, ''::text)
    ) || ' '::text
  ) || lower(
    (
      (
        (
          (
            (
              (
                (COALESCE(rc.client_email, ''::text) || ' '::text) || COALESCE(rc.company, ''::text)
              ) || ' '::text
            ) || COALESCE(rc.rate_name, ''::text)
          ) || ' '::text
        ) || COALESCE(rc.temp_client_name, ''::text)
      ) || ' '::text
    ) || COALESCE(rc.temp_client_last_name, ''::text)
  ) as search,
  array[COALESCE(rc.company, ''::text), 'All'::text] as company_filter,
  rc.cif,
  rc.region,
  0.0::numeric(8, 2) as daily_maintenance_with_vat,
  rc.has_permanence,
  rc.rate_mode,
  rc.total_excedentes_precio,
  null::rate_mode_type as rate_i_have,
  rc.term_month,
  rc.term_month_i_want,
  rc.excluded_company_ids,
  rc.wants_gdo,
  rc.temp_client_phone,
  rc.comparison_id,
  rc.wants_permanence
from
  all_comparisons_ranked rc
  left join _users_supervisors_all us on rc.advisor_id = us.user_id
where
  rc.rank = 1
  and rc.type = 'gas'::text;