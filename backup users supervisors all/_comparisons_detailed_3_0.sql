create view public._comparisons_detailed_3_0 as
with
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
      COALESCE(c30.consumption_p1, 0::real) + COALESCE(c30.consumption_p2, 0::real) + COALESCE(c30.consumption_p3, 0::real) + COALESCE(c30.consumption_p4, 0::real) + COALESCE(c30.consumption_p5, 0::real) + COALESCE(c30.consumption_p6, 0::real) as total_consumption,
      COALESCE(c30.anual_consumption_p1, 0::real) + COALESCE(c30.anual_consumption_p2, 0::real) + COALESCE(c30.anual_consumption_p3, 0::real) + COALESCE(c30.anual_consumption_p4, 0::real) + COALESCE(c30.anual_consumption_p5, 0::real) + COALESCE(c30.anual_consumption_p6, 0::real) as total_anual_consumption,
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
      0::real as meter_rental,
      c30.preferred_subrate,
      c30.rate_i_have,
      c30.term_month_i_want,
      c30.temp_client_phone,
      c30.wants_gdo,
      c30.excluded_company_ids,
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
      cr.has_permanence,
      cr.has_gdo,
      cr.rate_mode,
      0::real as total_excedentes_precio,
      COALESCE(c30.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p3, 0::real) * COALESCE(cr.price_pp3, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p4, 0::real) * COALESCE(cr.price_pp4, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p5, 0::real) * COALESCE(cr.price_pp5, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p6, 0::real) * COALESCE(cr.price_pp6, 0::real) * COALESCE(c30.power_days, 0)::double precision as total_power_price,
      COALESCE(c30.consumption_p1, 0::numeric::real) * COALESCE(cr.price_cp1, 0::numeric::real) + COALESCE(c30.consumption_p2, 0::numeric::real) * COALESCE(cr.price_cp2, 0::numeric::real) + COALESCE(c30.consumption_p3, 0::numeric::real) * COALESCE(cr.price_cp3, 0::numeric::real) + COALESCE(c30.consumption_p4, 0::numeric::real) * COALESCE(cr.price_cp4, 0::numeric::real) + COALESCE(c30.consumption_p5, 0::numeric::real) * COALESCE(cr.price_cp5, 0::numeric::real) + COALESCE(c30.consumption_p6, 0::numeric::real) * COALESCE(cr.price_cp6, 0::numeric::real) as total_consumption_price,
      COALESCE(c30.power_p1, 0::real) * COALESCE(cr.price_pp1, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p2, 0::real) * COALESCE(cr.price_pp2, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p3, 0::real) * COALESCE(cr.price_pp3, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p4, 0::real) * COALESCE(cr.price_pp4, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p5, 0::real) * COALESCE(cr.price_pp5, 0::real) * COALESCE(c30.power_days, 0)::double precision + COALESCE(c30.power_p6, 0::real) * COALESCE(cr.price_pp6, 0::real) * COALESCE(c30.power_days, 0)::double precision + (
        (
          COALESCE(c30.consumption_p1, 0::real) * COALESCE(cr.price_cp1, 0::real)
        )::double precision + (
          COALESCE(c30.consumption_p2, 0::real) * COALESCE(cr.price_cp2, 0::real)
        )::double precision + (
          COALESCE(c30.consumption_p3, 0::real) * COALESCE(cr.price_cp3, 0::real)
        )::double precision + (
          COALESCE(c30.consumption_p4, 0::real) * COALESCE(cr.price_cp4, 0::real)
        )::double precision + (
          COALESCE(c30.consumption_p5, 0::real) * COALESCE(cr.price_cp5, 0::real)
        )::double precision + (
          COALESCE(c30.consumption_p6, 0::real) * COALESCE(cr.price_cp6, 0::real)
        )::double precision
      ) + COALESCE(c30.power_surpluses, 0::real)::double precision - (
        COALESCE(c30.surpluses, 0::real) * COALESCE(cr.price_surpluses, 0::real)
      )::double precision as new_total_price,
      '3_0'::text as type,
      COALESCE(c30.temp_client_name, ''::text) as temp_client_name,
      COALESCE(c30.temp_client_last_name, ''::text) as temp_client_last_name,
      array['3_0'::text, 'All'::text] as type_filter,
      c30.deleted,
      c30.deleted_reason,
      c30.deleted_at,
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
      c30.region,
      c30.comparison_id
    from
      (
        select
          comparison_3_0.id,
          comparison_3_0.created_at,
          comparison_3_0.advisor_id,
          comparison_3_0.invoice_month,
          comparison_3_0.consumption_p1,
          comparison_3_0.consumption_p2,
          comparison_3_0.consumption_p3,
          comparison_3_0.consumption_p4,
          comparison_3_0.consumption_p5,
          comparison_3_0.consumption_p6,
          comparison_3_0.power_p1,
          comparison_3_0.power_p2,
          comparison_3_0.power_p3,
          comparison_3_0.power_p4,
          comparison_3_0.power_p5,
          comparison_3_0.power_p6,
          comparison_3_0.current_total_invoice,
          comparison_3_0."VAT",
          comparison_3_0.power_days,
          comparison_3_0.client_email,
          comparison_3_0.pdf_invoice,
          comparison_3_0."CUPS",
          comparison_3_0.address_id,
          comparison_3_0.rate_name,
          comparison_3_0.manual_data,
          comparison_3_0.equipment_rental,
          comparison_3_0.reactive,
          comparison_3_0.valuation_id,
          comparison_3_0.invoice_year,
          comparison_3_0.company,
          comparison_3_0.temp_client_name,
          comparison_3_0.temp_client_last_name,
          comparison_3_0.power_surpluses,
          comparison_3_0.surpluses,
          comparison_3_0.deleted,
          comparison_3_0.deleted_reason,
          comparison_3_0.selfconsumption,
          comparison_3_0.preferred_subrate,
          comparison_3_0.anual_consumption_p1,
          comparison_3_0.anual_consumption_p2,
          comparison_3_0.anual_consumption_p3,
          comparison_3_0.anual_consumption_p4,
          comparison_3_0.anual_consumption_p5,
          comparison_3_0.anual_consumption_p6,
          comparison_3_0.max_power,
          comparison_3_0."precio_kwh_P1",
          comparison_3_0."precio_kwh_P2",
          comparison_3_0."precio_kwh_P3",
          comparison_3_0."precio_kwh_P4",
          comparison_3_0."precio_kwh_P5",
          comparison_3_0."precio_kwh_P6",
          comparison_3_0."precio_kw_P1",
          comparison_3_0."precio_kw_P2",
          comparison_3_0."precio_kw_P3",
          comparison_3_0."precio_kw_P4",
          comparison_3_0."precio_kw_P5",
          comparison_3_0."precio_kw_P6",
          comparison_3_0.autoconsumo_precio,
          comparison_3_0.totalconsumo,
          comparison_3_0.totalpotencia,
          comparison_3_0.region,
          comparison_3_0.cif,
          comparison_3_0.source_type_id,
          comparison_3_0.rate_i_have,
          comparison_3_0.rate_i_want,
          comparison_3_0.wants_permanence,
          comparison_3_0.comparison_id,
          comparison_3_0.term_month_i_want,
          comparison_3_0.wants_gdo,
          comparison_3_0.invoice_address,
          comparison_3_0.deleted_at,
          comparison_3_0.temp_client_phone,
          comparison_3_0.excluded_company_ids
        from
          comparison_3_0
        where
          comparison_3_0.valuation_id is null
          and (
            comparison_3_0.deleted is null
            or comparison_3_0.deleted = false
          )
      ) c30
      left join users u on u.user_id = c30.advisor_id
      left join lateral (
        select
          cr_1.id,
          cr_1.company,
          cr_1.rate_name,
          cr_1.price_pp1,
          cr_1.price_pp2,
          cr_1.price_pp3,
          cr_1.price_pp4,
          cr_1.price_pp5,
          cr_1.price_pp6,
          cr_1.price_cp1,
          cr_1.price_cp2,
          cr_1.price_cp3,
          cr_1.price_cp4,
          cr_1.price_cp5,
          cr_1.price_cp6,
          cr_1.type,
          cr_1.selfconsumption,
          cr_1.price_surpluses,
          cr_1.invoice_month,
          cr_1.invoice_year,
          cr_1.subrate_name,
          cr_1.cif,
          cr_1.region,
          cr_1.has_maintenance,
          cr_1.daily_maintenance_with_vat,
          cr_1.has_permanence,
          cr_1.rate_mode,
          cr_1.last_update,
          cr_1.deleted,
          cr_1.tenant_id,
          cr_1.min_power,
          cr_1.max_power,
          cr_1.min_consumption,
          cr_1.max_consumption,
          cr_1.term_month,
          cr_1.has_gdo
        from
          comparison_rates cr_1
        where
          cr_1.type = '3_0'::text
          and (
            c30.rate_i_have = 'Fija'::rate_mode_type
            and c30.rate_i_want = 'Indexada'::rate_mode_type
            and cr_1.id = 'febdbb18-8de5-4f2c-982a-ddfe2e18b3c8'::uuid
            or (
              c30.rate_i_have is distinct from 'Fija'::rate_mode_type
              or cr_1.rate_mode is distinct from 'Indexada'::rate_mode_type
            )
            and cr_1.company <> c30.company
            and cr_1.deleted = false
            and (
              cr_1.tenant_id is null
              or (u.tenant = any (cr_1.tenant_id))
            )
            and (
              cr_1.rate_mode::text <> 'Indexada'::text
              or cr_1.invoice_month is null
              and cr_1.invoice_year is null
              or cr_1.invoice_month = c30.invoice_month
              and cr_1.invoice_year = c30.invoice_year
            )
            and (
              c30.preferred_subrate is null
              or c30.preferred_subrate = ''::text
              or cr_1.subrate_name = c30.preferred_subrate
            )
            and (
              c30.wants_permanence is not true
              or cr_1.has_permanence = true
              or not (
                exists (
                  select
                    1
                  from
                    comparison_rates crp
                  where
                    crp.type = '3_0'::text
                    and crp.company <> c30.company
                    and (
                      crp.rate_mode::text <> 'Indexada'::text
                      or crp.invoice_month is null
                      and crp.invoice_year is null
                      or crp.invoice_month = c30.invoice_month
                      and crp.invoice_year = c30.invoice_year
                    )
                    and (
                      c30.preferred_subrate is null
                      or c30.preferred_subrate = ''::text
                      or crp.subrate_name = c30.preferred_subrate
                    )
                    and (
                      c30.region is null
                      or (c30.region = any (crp.region))
                    )
                    and crp.has_permanence = true
                    and (
                      c30.wants_gdo = false
                      or crp.has_gdo = true
                    )
                )
              )
            )
            and (
              cr_1.cif is null
              or cr_1.cif = c30.cif
            )
            and (
              c30.region is null
              or (c30.region = any (cr_1.region))
            )
            and (
              c30.wants_gdo = false
              or cr_1.has_gdo = true
            )
            and (
              c30.excluded_company_ids is null
              or not (
                cr_1.company in (
                  select
                    c_ex.name
                  from
                    companies c_ex
                  where
                    c_ex.id = any (c30.excluded_company_ids)
                )
              )
            )
            and (
              c30.wants_permanence is not true
              or c30.term_month_i_want is null
              or cr_1.term_month <= c30.term_month_i_want
            )
          )
      ) cr on true
  ),
  unified_calculated_prices as (
    select
      calculated_prices_3_0.id,
      calculated_prices_3_0.created_at,
      calculated_prices_3_0.client_email,
      calculated_prices_3_0.advisor_id,
      calculated_prices_3_0.consumption_p1,
      calculated_prices_3_0.consumption_p2,
      calculated_prices_3_0.consumption_p3,
      calculated_prices_3_0.consumption_p4,
      calculated_prices_3_0.consumption_p5,
      calculated_prices_3_0.consumption_p6,
      calculated_prices_3_0.anual_consumption_p1,
      calculated_prices_3_0.anual_consumption_p2,
      calculated_prices_3_0.anual_consumption_p3,
      calculated_prices_3_0.anual_consumption_p4,
      calculated_prices_3_0.anual_consumption_p5,
      calculated_prices_3_0.anual_consumption_p6,
      calculated_prices_3_0.autoconsumo_precio,
      calculated_prices_3_0."precio_kw_P1",
      calculated_prices_3_0."precio_kw_P2",
      calculated_prices_3_0."precio_kw_P3",
      calculated_prices_3_0."precio_kw_P4",
      calculated_prices_3_0."precio_kw_P5",
      calculated_prices_3_0."precio_kw_P6",
      calculated_prices_3_0."precio_kwh_P1",
      calculated_prices_3_0."precio_kwh_P2",
      calculated_prices_3_0."precio_kwh_P3",
      calculated_prices_3_0."precio_kwh_P4",
      calculated_prices_3_0."precio_kwh_P5",
      calculated_prices_3_0."precio_kwh_P6",
      calculated_prices_3_0.total_consumption,
      calculated_prices_3_0.total_anual_consumption,
      calculated_prices_3_0.power_p1,
      calculated_prices_3_0.power_p2,
      calculated_prices_3_0.power_p3,
      calculated_prices_3_0.power_p4,
      calculated_prices_3_0.power_p5,
      calculated_prices_3_0.power_p6,
      calculated_prices_3_0.current_total_invoice,
      calculated_prices_3_0.surpluses,
      calculated_prices_3_0.total_surpluses_price,
      calculated_prices_3_0.power_surpluses,
      calculated_prices_3_0."VAT",
      calculated_prices_3_0.days,
      calculated_prices_3_0.pdf_invoice,
      calculated_prices_3_0."CUPS",
      calculated_prices_3_0.address_id,
      calculated_prices_3_0.company,
      calculated_prices_3_0.rate_name,
      calculated_prices_3_0.invoice_month,
      calculated_prices_3_0.equipment_rental,
      calculated_prices_3_0.selfconsumption,
      calculated_prices_3_0.manual_data,
      calculated_prices_3_0.reactive,
      calculated_prices_3_0.valuation_id,
      calculated_prices_3_0.invoice_year,
      calculated_prices_3_0.meter_rental,
      calculated_prices_3_0.preferred_subrate,
      calculated_prices_3_0.rate_i_have,
      calculated_prices_3_0.term_month_i_want,
      calculated_prices_3_0.temp_client_phone,
      calculated_prices_3_0.wants_gdo,
      calculated_prices_3_0.excluded_company_ids,
      calculated_prices_3_0.new_company,
      calculated_prices_3_0.new_rate_name,
      calculated_prices_3_0.new_subrate_name,
      calculated_prices_3_0.term_month,
      calculated_prices_3_0.price_pp1,
      calculated_prices_3_0.price_pp2,
      calculated_prices_3_0.price_pp3,
      calculated_prices_3_0.price_pp4,
      calculated_prices_3_0.price_pp5,
      calculated_prices_3_0.price_pp6,
      calculated_prices_3_0.price_cp1,
      calculated_prices_3_0.price_cp2,
      calculated_prices_3_0.price_cp3,
      calculated_prices_3_0.price_cp4,
      calculated_prices_3_0.price_cp5,
      calculated_prices_3_0.price_cp6,
      calculated_prices_3_0.price_surpluses,
      calculated_prices_3_0.has_permanence,
      calculated_prices_3_0.has_gdo,
      calculated_prices_3_0.rate_mode,
      calculated_prices_3_0.total_excedentes_precio,
      calculated_prices_3_0.total_power_price,
      calculated_prices_3_0.total_consumption_price,
      calculated_prices_3_0.new_total_price,
      calculated_prices_3_0.type,
      calculated_prices_3_0.temp_client_name,
      calculated_prices_3_0.temp_client_last_name,
      calculated_prices_3_0.type_filter,
      calculated_prices_3_0.deleted,
      calculated_prices_3_0.deleted_reason,
      calculated_prices_3_0.deleted_at,
      calculated_prices_3_0.new_rate_id,
      calculated_prices_3_0.max_power,
      calculated_prices_3_0.speed_fiber,
      calculated_prices_3_0.mobile_lines,
      calculated_prices_3_0.mobile_total_gb,
      calculated_prices_3_0.fijo,
      calculated_prices_3_0.new_speed_fiber,
      calculated_prices_3_0.new_total_mobile_lines,
      calculated_prices_3_0.new_mobile_total_gb,
      calculated_prices_3_0.rate_pack,
      calculated_prices_3_0.phone_total_anual_price,
      calculated_prices_3_0.tarifa_plana,
      calculated_prices_3_0.cif,
      calculated_prices_3_0.region,
      calculated_prices_3_0.comparison_id
    from
      calculated_prices_3_0
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
      ucp.rate_i_have,
      ucp.term_month_i_want,
      ucp.temp_client_phone,
      ucp.wants_gdo,
      ucp.excluded_company_ids,
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
      ucp.has_permanence,
      ucp.has_gdo,
      ucp.rate_mode,
      ucp.total_excedentes_precio,
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
      ucp.comparison_id,
      crs.id as crs_id,
      c30_base.rate_i_want,
      COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(crs.crs_cp1, 0::real) + COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(crs.crs_cp2, 0::real) + COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(crs.crs_cp3, 0::real) + COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(crs.crs_cp4, 0::real) + COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(crs.crs_cp5, 0::real) + COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(crs.crs_cp6, 0::real) + COALESCE(ucp.power_p1, 0::real) * COALESCE(crs.crs_pp1, 0::real) + COALESCE(ucp.power_p2, 0::real) * COALESCE(crs.crs_pp2, 0::real) + COALESCE(ucp.power_p3, 0::real) * COALESCE(crs.crs_pp3, 0::real) + COALESCE(ucp.power_p4, 0::real) * COALESCE(crs.crs_pp4, 0::real) + COALESCE(ucp.power_p5, 0::real) * COALESCE(crs.crs_pp5, 0::real) + COALESCE(ucp.power_p6, 0::real) * COALESCE(crs.crs_pp6, 0::real) + COALESCE(crs.fixed_crs, 0::real) as total_crs,
      case
        when ucp.new_company is not null then case
          when c30_base.rate_i_have = 'Indexada'::rate_mode_type
          and ucp.rate_mode = 'Indexada'::rate_mode_type then (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp."precio_kwh_P1", 0::real) + COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp."precio_kwh_P2", 0::real) + COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp."precio_kwh_P3", 0::real) + COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp."precio_kwh_P4", 0::real) + COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp."precio_kwh_P5", 0::real) + COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp."precio_kwh_P6", 0::real) + COALESCE(
              NULLIF(ucp.power_p1, 0::double precision),
              1::real
            ) * COALESCE(ucp."precio_kw_P1", 0::real) * 365.0::double precision + COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp."precio_kw_P2", 0::real) * 365.0::double precision + COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp."precio_kw_P3", 0::real) * 365.0::double precision + COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp."precio_kw_P4", 0::real) * 365.0::double precision + COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp."precio_kw_P5", 0::real) * 365.0::double precision + COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp."precio_kw_P6", 0::real) * 365.0::double precision - COALESCE(ucp.surpluses, 0::real) * (
              182.5::double precision / NULLIF(ucp.days::numeric, 0::numeric)::double precision
            ) * COALESCE(ucp.autoconsumo_precio, 0::real)
          ) * 1.05113::double precision * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          ) - (
            COALESCE(ucp.total_consumption_price, 0::real) / NULLIF(ucp.total_consumption, 0::double precision) * COALESCE(ucp.total_anual_consumption, 0::real) + COALESCE(ucp.power_p1, 0::real) * COALESCE(ucp.price_pp1, 0::real) * 365.0::double precision + COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp.price_pp2, 0::real) * 365.0::double precision + COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp.price_pp3, 0::real) * 365.0::double precision + COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp.price_pp4, 0::real) * 365.0::double precision + COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp.price_pp5, 0::real) * 365.0::double precision + COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp.price_pp6, 0::real) * 365.0::double precision
          ) * 1.05113::double precision * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          )
          when c30_base.rate_i_have = 'Fija'::rate_mode_type
          and ucp.rate_mode = 'Fija'::rate_mode_type then (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp."precio_kwh_P1", 0::real) + COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp."precio_kwh_P2", 0::real) + COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp."precio_kwh_P3", 0::real) + COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp."precio_kwh_P4", 0::real) + COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp."precio_kwh_P5", 0::real) + COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp."precio_kwh_P6", 0::real) + COALESCE(
              NULLIF(ucp.power_p1, 0::double precision),
              1::real
            ) * COALESCE(ucp."precio_kw_P1", 0::real) * 365.0::double precision + COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp."precio_kw_P2", 0::real) * 365.0::double precision + COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp."precio_kw_P3", 0::real) * 365.0::double precision + COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp."precio_kw_P4", 0::real) * 365.0::double precision + COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp."precio_kw_P5", 0::real) * 365.0::double precision + COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp."precio_kw_P6", 0::real) * 365.0::double precision - COALESCE(ucp.surpluses, 0::real) * (
              182.5::double precision / NULLIF(ucp.days::numeric, 0::numeric)::double precision
            ) * COALESCE(ucp.autoconsumo_precio, 0::real)
          ) * 1.05113::double precision * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          ) - (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp.price_cp1, 0::real) + COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp.price_cp2, 0::real) + COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp.price_cp3, 0::real) + COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp.price_cp4, 0::real) + COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp.price_cp5, 0::real) + COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp.price_cp6, 0::real) + COALESCE(ucp.power_p1, 0::real) * COALESCE(ucp.price_pp1, 0::real) * 365.0::double precision + COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp.price_pp2, 0::real) * 365.0::double precision + COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp.price_pp3, 0::real) * 365.0::double precision + COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp.price_pp4, 0::real) * 365.0::double precision + COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp.price_pp5, 0::real) * 365.0::double precision + COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp.price_pp6, 0::real) * 365.0::double precision
          ) * 1.05113::double precision * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          )
          when c30_base.rate_i_have = 'Indexada'::rate_mode_type
          and ucp.rate_mode = 'Fija'::rate_mode_type then (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp."precio_kwh_P1", 0::real) + COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp."precio_kwh_P2", 0::real) + COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp."precio_kwh_P3", 0::real) + COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp."precio_kwh_P4", 0::real) + COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp."precio_kwh_P5", 0::real) + COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp."precio_kwh_P6", 0::real) + COALESCE(
              NULLIF(ucp.power_p1, 0::double precision),
              1::real
            ) * COALESCE(ucp."precio_kw_P1", 0::real) * 365.0::double precision + COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp."precio_kw_P2", 0::real) * 365.0::double precision + COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp."precio_kw_P3", 0::real) * 365.0::double precision + COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp."precio_kw_P4", 0::real) * 365.0::double precision + COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp."precio_kw_P5", 0::real) * 365.0::double precision + COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp."precio_kw_P6", 0::real) * 365.0::double precision - COALESCE(ucp.surpluses, 0::real) * (
              182.5::double precision / NULLIF(ucp.days::numeric, 0::numeric)::double precision
            ) * COALESCE(ucp.autoconsumo_precio, 0::real)
          ) * 1.05113::double precision * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          ) - (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp.price_cp1, 0::real) + COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp.price_cp2, 0::real) + COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp.price_cp3, 0::real) + COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp.price_cp4, 0::real) + COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp.price_cp5, 0::real) + COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp.price_cp6, 0::real) + COALESCE(ucp.power_p1, 0::real) * COALESCE(ucp.price_pp1, 0::real) * 365.0::double precision + COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp.price_pp2, 0::real) * 365.0::double precision + COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp.price_pp3, 0::real) * 365.0::double precision + COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp.price_pp4, 0::real) * 365.0::double precision + COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp.price_pp5, 0::real) * 365.0::double precision + COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp.price_pp6, 0::real) * 365.0::double precision
          ) * 1.05113::double precision * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          )
          when c30_base.rate_i_have = 'Fija'::rate_mode_type
          and ucp.rate_mode = 'Indexada'::rate_mode_type then (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp."precio_kwh_P1", 0::real) + COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp."precio_kwh_P2", 0::real) + COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp."precio_kwh_P3", 0::real) + COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp."precio_kwh_P4", 0::real) + COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp."precio_kwh_P5", 0::real) + COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp."precio_kwh_P6", 0::real) + COALESCE(
              NULLIF(ucp.power_p1, 0::double precision),
              1::real
            ) * COALESCE(ucp."precio_kw_P1", 0::real) * 365.0::double precision + COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp."precio_kw_P2", 0::real) * 365.0::double precision + COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp."precio_kw_P3", 0::real) * 365.0::double precision + COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp."precio_kw_P4", 0::real) * 365.0::double precision + COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp."precio_kw_P5", 0::real) * 365.0::double precision + COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp."precio_kw_P6", 0::real) * 365.0::double precision - COALESCE(ucp.surpluses, 0::real) * (
              182.5::double precision / NULLIF(ucp.days::numeric, 0::numeric)::double precision
            ) * COALESCE(ucp.autoconsumo_precio, 0::real)
          ) * 1.05113::double precision * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          ) - (
            COALESCE(ucp.anual_consumption_p1, 0::real) * COALESCE(ucp.price_cp1, 0::real) + COALESCE(ucp.anual_consumption_p2, 0::real) * COALESCE(ucp.price_cp2, 0::real) + COALESCE(ucp.anual_consumption_p3, 0::real) * COALESCE(ucp.price_cp3, 0::real) + COALESCE(ucp.anual_consumption_p4, 0::real) * COALESCE(ucp.price_cp4, 0::real) + COALESCE(ucp.anual_consumption_p5, 0::real) * COALESCE(ucp.price_cp5, 0::real) + COALESCE(ucp.anual_consumption_p6, 0::real) * COALESCE(ucp.price_cp6, 0::real) + COALESCE(ucp.power_p1, 0::real) * COALESCE(ucp.price_pp1, 0::real) * 365.0::double precision + COALESCE(ucp.power_p2, 0::real) * COALESCE(ucp.price_pp2, 0::real) * 365.0::double precision + COALESCE(ucp.power_p3, 0::real) * COALESCE(ucp.price_pp3, 0::real) * 365.0::double precision + COALESCE(ucp.power_p4, 0::real) * COALESCE(ucp.price_pp4, 0::real) * 365.0::double precision + COALESCE(ucp.power_p5, 0::real) * COALESCE(ucp.price_pp5, 0::real) * 365.0::double precision + COALESCE(ucp.power_p6, 0::real) * COALESCE(ucp.price_pp6, 0::real) * 365.0::double precision
          ) * 1.05113::double precision * (
            1::double precision + COALESCE(ucp."VAT", 0::real)
          )
          else 0.0::double precision
        end
        else 0.0::double precision
      end as savings_yearly,
      case
        when ucp.new_company is not null then COALESCE(ucp.current_total_invoice, 0::real) - (
          COALESCE(ucp.new_total_price, 0::real::double precision) * 1.05113::double precision + COALESCE(ucp.equipment_rental, 0::real)
        ) * (
          1::double precision + COALESCE(ucp."VAT", 0::real)
        )
        else 0.0::double precision
      end as savings
    from
      unified_calculated_prices ucp
      left join comparison_3_0 c30_base on c30_base.id = ucp.id
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
  filtered_prices as (
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
      uep.rate_i_have,
      uep.term_month_i_want,
      uep.temp_client_phone,
      uep.wants_gdo,
      uep.excluded_company_ids,
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
      uep.has_permanence,
      uep.has_gdo,
      uep.rate_mode,
      uep.total_excedentes_precio,
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
      uep.comparison_id,
      uep.crs_id,
      uep.rate_i_want,
      uep.total_crs,
      uep.savings_yearly,
      uep.savings,
      u.tenant,
      c30.wants_permanence,
      c30.region as c30_region,
      c30.cif as c30_cif
    from
      unified_extended_prices uep
      left join comparison_3_0 c30 on c30.id = uep.id
      left join users u on u.user_id = c30.advisor_id
  ),
  ranked_comparisons as (
    select
      fp.id,
      fp.created_at,
      fp.client_email,
      fp.advisor_id,
      fp.consumption_p1,
      fp.consumption_p2,
      fp.consumption_p3,
      fp.consumption_p4,
      fp.consumption_p5,
      fp.consumption_p6,
      fp.anual_consumption_p1,
      fp.anual_consumption_p2,
      fp.anual_consumption_p3,
      fp.anual_consumption_p4,
      fp.anual_consumption_p5,
      fp.anual_consumption_p6,
      fp.autoconsumo_precio,
      fp."precio_kw_P1",
      fp."precio_kw_P2",
      fp."precio_kw_P3",
      fp."precio_kw_P4",
      fp."precio_kw_P5",
      fp."precio_kw_P6",
      fp."precio_kwh_P1",
      fp."precio_kwh_P2",
      fp."precio_kwh_P3",
      fp."precio_kwh_P4",
      fp."precio_kwh_P5",
      fp."precio_kwh_P6",
      fp.total_consumption,
      fp.total_anual_consumption,
      fp.power_p1,
      fp.power_p2,
      fp.power_p3,
      fp.power_p4,
      fp.power_p5,
      fp.power_p6,
      fp.current_total_invoice,
      fp.surpluses,
      fp.total_surpluses_price,
      fp.power_surpluses,
      fp."VAT",
      fp.days,
      fp.pdf_invoice,
      fp."CUPS",
      fp.address_id,
      fp.company,
      fp.rate_name,
      fp.invoice_month,
      fp.equipment_rental,
      fp.selfconsumption,
      fp.manual_data,
      fp.reactive,
      fp.valuation_id,
      fp.invoice_year,
      fp.meter_rental,
      fp.preferred_subrate,
      fp.rate_i_have,
      fp.term_month_i_want,
      fp.temp_client_phone,
      fp.wants_gdo,
      fp.excluded_company_ids,
      fp.new_company,
      fp.new_rate_name,
      fp.new_subrate_name,
      fp.term_month,
      fp.price_pp1,
      fp.price_pp2,
      fp.price_pp3,
      fp.price_pp4,
      fp.price_pp5,
      fp.price_pp6,
      fp.price_cp1,
      fp.price_cp2,
      fp.price_cp3,
      fp.price_cp4,
      fp.price_cp5,
      fp.price_cp6,
      fp.price_surpluses,
      fp.has_permanence,
      fp.has_gdo,
      fp.rate_mode,
      fp.total_excedentes_precio,
      fp.total_power_price,
      fp.total_consumption_price,
      fp.new_total_price,
      fp.type,
      fp.temp_client_name,
      fp.temp_client_last_name,
      fp.type_filter,
      fp.deleted,
      fp.deleted_reason,
      fp.deleted_at,
      fp.new_rate_id,
      fp.max_power,
      fp.speed_fiber,
      fp.mobile_lines,
      fp.mobile_total_gb,
      fp.fijo,
      fp.new_speed_fiber,
      fp.new_total_mobile_lines,
      fp.new_mobile_total_gb,
      fp.rate_pack,
      fp.phone_total_anual_price,
      fp.tarifa_plana,
      fp.cif,
      fp.region,
      fp.comparison_id,
      fp.crs_id,
      fp.rate_i_want,
      fp.total_crs,
      fp.savings_yearly,
      fp.savings,
      fp.tenant,
      fp.wants_permanence,
      fp.c30_region,
      fp.c30_cif,
      case
        when fp.new_company is not null
        and fp.savings_yearly > 0::double precision then fp.savings_yearly + COALESCE(fp.total_crs, 0::real) * 4::double precision
        else fp.savings_yearly + COALESCE(fp.total_crs, 0::real) * 4::double precision
      end as ranked_crs,
      row_number() over (
        partition by
          fp.id,
          fp.rate_mode
        order by
          (
            case
              when fp.new_company is not null
              and fp.savings_yearly > 0::double precision then fp.savings_yearly + COALESCE(fp.total_crs, 0::real) * 4::double precision
              else fp.savings_yearly + COALESCE(fp.total_crs, 0::real) * 4::double precision
            end
          ) desc
      ) as rank_by_mode,
      row_number() over (
        partition by
          fp.id
        order by
          (
            case
              when fp.new_company is not null
              and fp.savings_yearly > 0::double precision then fp.savings_yearly + COALESCE(fp.total_crs, 0::real) * 4::double precision
              else fp.savings_yearly + COALESCE(fp.total_crs, 0::real) * 4::double precision
            end
          ) desc
      ) as rank
    from
      filtered_prices fp
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
      ranked_comparisons.rate_i_have,
      ranked_comparisons.term_month_i_want,
      ranked_comparisons.temp_client_phone,
      ranked_comparisons.wants_gdo,
      ranked_comparisons.excluded_company_ids,
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
      ranked_comparisons.has_permanence,
      ranked_comparisons.has_gdo,
      ranked_comparisons.rate_mode,
      ranked_comparisons.total_excedentes_precio,
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
      ranked_comparisons.comparison_id,
      ranked_comparisons.crs_id,
      ranked_comparisons.rate_i_want,
      ranked_comparisons.total_crs,
      ranked_comparisons.savings_yearly,
      ranked_comparisons.savings,
      ranked_comparisons.tenant,
      ranked_comparisons.wants_permanence,
      ranked_comparisons.c30_region,
      ranked_comparisons.c30_cif,
      ranked_comparisons.ranked_crs,
      ranked_comparisons.rank_by_mode,
      ranked_comparisons.rank
    from
      ranked_comparisons
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
  rc.savings,
  rc.savings_yearly,
  rc.ranked_crs,
  rc.rank,
  rc.tarifa_plana,
  (
    COALESCE(rc.consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) + COALESCE(rc.consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) + COALESCE(rc.consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) + COALESCE(rc.consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) + COALESCE(rc.consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) + COALESCE(rc.consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) + COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) * COALESCE(rc.days, 0)::double precision + COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * COALESCE(rc.days, 0)::double precision + COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * COALESCE(rc.days, 0)::double precision + COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * COALESCE(rc.days, 0)::double precision + COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * COALESCE(rc.days, 0)::double precision + COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * COALESCE(rc.days, 0)::double precision
  ) * 0.05113::double precision as iee_monthly,
  (
    COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) + COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) + COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) + COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) + COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) + COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) + (
      COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) + COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) + COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) + COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) + COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) + COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real)
    ) * 365::double precision
  ) * 0.05113::double precision as iee,
  (
    COALESCE(rc.new_total_price, 0::real::double precision) * 1.05113::double precision + COALESCE(rc.equipment_rental, 0::real)
  ) * (1::double precision + COALESCE(rc."VAT", 0::real)) as new_total_price_with_vat,
  (
    COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) + COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) + COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) + COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc.price_cp4, 0::real) + COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc.price_cp5, 0::real) + COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc.price_cp6, 0::real) + COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) * 365::double precision + COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real) * 365::double precision + COALESCE(rc.power_p3, 0::real) * COALESCE(rc.price_pp3, 0::real) * 365::double precision + COALESCE(rc.power_p4, 0::real) * COALESCE(rc.price_pp4, 0::real) * 365::double precision + COALESCE(rc.power_p5, 0::real) * COALESCE(rc.price_pp5, 0::real) * 365::double precision + COALESCE(rc.power_p6, 0::real) * COALESCE(rc.price_pp6, 0::real) * 365::double precision
  ) * (1::numeric + 0.05113)::double precision * (1::double precision + COALESCE(rc."VAT", 0::real)) as new_total_yearly_price_with_vat,
  case
    when rc.new_company is not null then rc.savings_yearly / NULLIF(
      (
        COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc."precio_kwh_P1", 0::real) + COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc."precio_kwh_P2", 0::real) + COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc."precio_kwh_P3", 0::real) + COALESCE(rc.anual_consumption_p4, 0::real) * COALESCE(rc."precio_kwh_P4", 0::real) + COALESCE(rc.anual_consumption_p5, 0::real) * COALESCE(rc."precio_kwh_P5", 0::real) + COALESCE(rc.anual_consumption_p6, 0::real) * COALESCE(rc."precio_kwh_P6", 0::real) + COALESCE(NULLIF(rc.power_p1, 0::double precision), 1::real) * COALESCE(rc."precio_kw_P1", 0::real) * 365.0::double precision + COALESCE(rc.power_p2, 0::real) * COALESCE(rc."precio_kw_P2", 0::real) * 365.0::double precision + COALESCE(rc.power_p3, 0::real) * COALESCE(rc."precio_kw_P3", 0::real) * 365.0::double precision + COALESCE(rc.power_p4, 0::real) * COALESCE(rc."precio_kw_P4", 0::real) * 365.0::double precision + COALESCE(rc.power_p5, 0::real) * COALESCE(rc."precio_kw_P5", 0::real) * 365.0::double precision + COALESCE(rc.power_p6, 0::real) * COALESCE(rc."precio_kw_P6", 0::real) * 365.0::double precision - COALESCE(rc.surpluses, 0::real) * (
          182.5::double precision / NULLIF(rc.days::numeric, 0::numeric)::double precision
        ) * COALESCE(rc.autoconsumo_precio, 0::real)
      ) * 1.05113::double precision * (1::double precision + COALESCE(rc."VAT", 0::real)),
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
  lower(
    (
      (
        (
          (
            (
              (
                (
                  (
                    (
                      (
                        (
                          (
                            (COALESCE(rc."CUPS", ''::text) || ' '::text) || COALESCE(rc.client_email, ''::text)
                          ) || ' '::text
                        ) || COALESCE(rc.company, ''::text)
                      ) || ' '::text
                    ) || COALESCE(rc.rate_name, ''::text)
                  ) || ' '::text
                ) || COALESCE(rc.temp_client_name, ''::text)
              ) || ' '::text
            ) || COALESCE(rc.temp_client_last_name, ''::text)
          ) || ' '::text
        ) || COALESCE(us.display_name, ''::text)
      ) || ' '::text
    ) || COALESCE(us.email, ''::text)
  ) as search,
  array[COALESCE(rc.company, ''::text), 'All'::text] as company_filter,
  rc.cif,
  rc.region,
  0.0::numeric(8, 2) as daily_maintenance_with_vat,
  rc.has_permanence,
  rc.rate_mode,
  rc.total_excedentes_precio,
  rc.rate_i_have,
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
  rc.rate_i_want is null
  and rc.rank = 1
  or rc.rate_i_want = 'Fija'::rate_mode_type
  and rc.rate_mode = 'Fija'::rate_mode_type
  and rc.rank_by_mode = 1
  or rc.rate_i_want = 'Indexada'::rate_mode_type
  and rc.rate_mode = 'Indexada'::rate_mode_type
  and rc.rank_by_mode = 1;