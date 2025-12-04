create or replace view public._comparisons_detailed_light2 as
with
  base as (
    select
      cl.id,
      cl.created_at,
      cl.client_email,
      cl.advisor_id,
      cl.consumption_p1,
      cl.consumption_p2,
      cl.consumption_p3,
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
      cl.anual_consumption_p1,
      cl.anual_consumption_p2,
      cl.anual_consumption_p3,
      cl.max_power,
      cl."precio_kwh_P1",
      cl."precio_kwh_P2",
      cl."precio_kwh_P3",
      cl."precio_kw_P1",
      cl."precio_kw_P2",
      cl.autoconsumo_precio,
      cl.totalconsumo,
      cl.totalpotencia,
      cl.tarifa_plana,
      cl.cif,
      cl.region,
      cr.id as new_rate_id,
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
      cr.has_maintenance,
      cr.daily_maintenance_with_vat,
      cr.has_permanence,
      cr.rate_mode,
      cl.total_excedentes_precio
    from
      comparison_light cl
      left join users u_1 on u_1.user_id = cl.advisor_id
      left join comparison_rates_v2 cr on cr.type = 'light'::text
      and cr.company <> cl.company
      and cr.deleted = false
      and (
        cr.tenant_id is null
        or (u_1.tenant = any (cr.tenant_id))
      )
      and (
        cr.invoice_month = cl.invoice_month
        and cr.invoice_year = cl.invoice_year
        and (
          cl.preferred_subrate is null
          or cl.preferred_subrate = ''::text
          or lower(cr.subrate_name) = lower(cl.preferred_subrate)
        )
        or cr.invoice_month is null
        and cr.invoice_year is null
        or cr.invoice_month = cl.invoice_month
        and cr.invoice_year = cl.invoice_year
        and not (
          exists (
            select
              1
            from
              comparison_rates_v2 crs
            where
              crs.type = 'light'::text
              and crs.company <> cl.company
              and crs.invoice_month = cl.invoice_month
              and crs.invoice_year = cl.invoice_year
              and lower(crs.subrate_name) = lower(cl.preferred_subrate)
          )
        )
        or cr.invoice_year = cl.invoice_year
        and not (
          exists (
            select
              1
            from
              comparison_rates_v2 cry
            where
              cry.type = 'light'::text
              and cry.company <> cl.company
              and cry.invoice_month = cl.invoice_month
              and cry.invoice_year = cl.invoice_year
          )
        )
      )
      and (
        cl.region is null
        or (cl.region = any (cr.region))
      )
      and (
        cl.selfconsumption = true
        and COALESCE(cr.selfconsumption, false) = true
        or cl.selfconsumption is distinct from true
        and cr.selfconsumption is distinct from true
      )
      and (
        cr.cif is null
        or cr.cif = cl.cif
      )
      and (
        cl.wants_permanence is not true
        or cr.has_permanence = true
        or not (
          exists (
            select
              1
            from
              comparison_rates_v2 crp
            where
              crp.type = 'light'::text
              and crp.company <> cl.company
              and (
                crp.invoice_month is null
                and crp.invoice_year is null
                or crp.invoice_month = cl.invoice_month
                and crp.invoice_year = cl.invoice_year
              )
              and (
                cl.region is null
                or (cl.region = any (crp.region))
              )
              and (
                cl.selfconsumption = true
                and COALESCE(crp.selfconsumption, false) = true
                or cl.selfconsumption is distinct from true
                and crp.selfconsumption is distinct from true
              )
              and (
                crp.cif is null
                or crp.cif = cl.cif
            )
            and crp.has_permanence = true
          )
        )
      )
    where
      cl.valuation_id is null
      and cl.deleted = false
  ),
  m_calc as (
    select
      b.id,
      b.created_at,
      b.client_email,
      b.advisor_id,
      b.consumption_p1,
      b.consumption_p2,
      b.consumption_p3,
      b.power_p1,
      b.power_p2,
      b.current_total_invoice,
      b.surpluses,
      b."VAT",
      b.power_days,
      b.pdf_invoice,
      b."CUPS",
      b.address_id,
      b.company,
      b.rate_name,
      b.invoice_month,
      b.equipment_rental,
      b.selfconsumption,
      b.manual_data,
      b.valuation_id,
      b.invoice_year,
      b.temp_client_name,
      b.temp_client_last_name,
      b.deleted,
      b.deleted_reason,
      b.preferred_subrate,
      b.wants_permanence,
      b.anual_consumption_p1,
      b.anual_consumption_p2,
      b.anual_consumption_p3,
      b.max_power,
      b."precio_kwh_P1",
      b."precio_kwh_P2",
      b."precio_kwh_P3",
      b."precio_kw_P1",
      b."precio_kw_P2",
      b.autoconsumo_precio,
      b.totalconsumo,
      b.totalpotencia,
      b.tarifa_plana,
      b.cif,
      b.region,
      b.new_rate_id,
      b.new_company,
      b.new_rate_name,
      b.new_subrate_name,
      b.price_pp1,
      b.price_pp2,
      b.price_pp3,
      b.price_pp4,
      b.price_pp5,
      b.price_pp6,
      b.price_cp1,
      b.price_cp2,
      b.price_cp3,
      b.price_cp4,
      b.price_cp5,
      b.price_cp6,
      b.price_surpluses,
      b.has_maintenance,
      b.daily_maintenance_with_vat,
      b.has_permanence,
      b.rate_mode,
      b.total_excedentes_precio,
      case
        when b.has_maintenance = true then b.daily_maintenance_with_vat::double precision * COALESCE(b.power_days, 0)::double precision
        else 0::double precision
      end as maintenance_total,
      COALESCE(b.consumption_p1, 0::real) * COALESCE(b.price_cp1, 0::real) + COALESCE(b.consumption_p2, 0::real) * COALESCE(b.price_cp2, 0::real) + COALESCE(b.consumption_p3, 0::real) * COALESCE(b.price_cp3, 0::real) as m_consumo,
      COALESCE(b.power_p1, 0::real) * COALESCE(b.price_pp1, 0::real) * COALESCE(
        b.power_days::double precision,
        0::double precision
      ) + COALESCE(b.power_p2, 0::real) * COALESCE(b.price_pp2, 0::real) * COALESCE(
        b.power_days::double precision,
        0::double precision
      ) as m_potencia,
      COALESCE(b.consumption_p1, 0::real) * COALESCE(b.price_cp1, 0::real) + COALESCE(b.consumption_p2, 0::real) * COALESCE(b.price_cp2, 0::real) + COALESCE(b.consumption_p3, 0::real) * COALESCE(b.price_cp3, 0::real) as total_consumption_price,
      COALESCE(b.power_p1, 0::real) * COALESCE(b.price_pp1, 0::real) * COALESCE(
        b.power_days::double precision,
        0::double precision
      ) + COALESCE(b.power_p2, 0::real) * COALESCE(b.price_pp2, 0::real) * COALESCE(
        b.power_days::double precision,
        0::double precision
      ) as total_power_price,
      COALESCE(b.surpluses, 0::real) * COALESCE(b.price_surpluses, 0::real) as total_surpluses_price,
      COALESCE(b.power_p1, 0::real) * COALESCE(b.price_pp1, 0::real) * COALESCE(b.power_days, 0)::double precision + COALESCE(b.power_p2, 0::real) * COALESCE(b.price_pp2, 0::real) * COALESCE(b.power_days, 0)::double precision + COALESCE(b.consumption_p1, 0::real) * COALESCE(b.price_cp1, 0::real) + COALESCE(b.consumption_p2, 0::real) * COALESCE(b.price_cp2, 0::real) + COALESCE(b.consumption_p3, 0::real) * COALESCE(b.price_cp3, 0::real) - COALESCE(b.surpluses, 0::real) * COALESCE(b.price_surpluses, 0::real) as new_total_price
    from
      base b
  ),
  tot as (
    select
      m.id,
      m.created_at,
      m.client_email,
      m.advisor_id,
      m.consumption_p1,
      m.consumption_p2,
      m.consumption_p3,
      m.power_p1,
      m.power_p2,
      m.current_total_invoice,
      m.surpluses,
      m."VAT",
      m.power_days,
      m.pdf_invoice,
      m."CUPS",
      m.address_id,
      m.company,
      m.rate_name,
      m.invoice_month,
      m.equipment_rental,
      m.selfconsumption,
      m.manual_data,
      m.valuation_id,
      m.invoice_year,
      m.temp_client_name,
      m.temp_client_last_name,
      m.deleted,
      m.deleted_reason,
      m.preferred_subrate,
      m.wants_permanence,
      m.anual_consumption_p1,
      m.anual_consumption_p2,
      m.anual_consumption_p3,
      m.max_power,
      m."precio_kwh_P1",
      m."precio_kwh_P2",
      m."precio_kwh_P3",
      m."precio_kw_P1",
      m."precio_kw_P2",
      m.autoconsumo_precio,
      m.totalconsumo,
      m.totalpotencia,
      m.tarifa_plana,
      m.cif,
      m.region,
      m.new_rate_id,
      m.new_company,
      m.new_rate_name,
      m.new_subrate_name,
      m.price_pp1,
      m.price_pp2,
      m.price_pp3,
      m.price_pp4,
      m.price_pp5,
      m.price_pp6,
      m.price_cp1,
      m.price_cp2,
      m.price_cp3,
      m.price_cp4,
      m.price_cp5,
      m.price_cp6,
      m.price_surpluses,
      m.has_maintenance,
      m.daily_maintenance_with_vat,
      m.has_permanence,
      m.rate_mode,
      m.total_excedentes_precio,
      m.maintenance_total,
      m.m_consumo,
      m.m_potencia,
      m.total_consumption_price,
      m.total_power_price,
      m.total_surpluses_price,
      m.new_total_price,
      (m.m_consumo + m.m_potencia) * 0.05113::double precision as iee_monthly,
      case
        when m.tarifa_plana = true then (
          COALESCE(m.new_total_price, 0::double precision) * 1.05113::double precision + COALESCE(m.equipment_rental, 0::real)::double precision
        ) * (
          1.0::double precision + COALESCE(m."VAT", 0::real)::double precision
        )
        else (
          COALESCE(m.new_total_price, 0::double precision) * 1.05113::double precision + COALESCE(m.equipment_rental, 0::real)::double precision
        ) * (
          1.0::double precision + COALESCE(m."VAT", 0::real)::double precision
        )
      end as new_total_price_with_vat_base,
      (
        COALESCE(m.anual_consumption_p1, 0::real) * COALESCE(m.price_cp1, 0::real) + COALESCE(m.anual_consumption_p2, 0::real) * COALESCE(m.price_cp2, 0::real) + COALESCE(m.anual_consumption_p3, 0::real) * COALESCE(m.price_cp3, 0::real) + COALESCE(NULLIF(m.power_p1, 0::double precision), 1::real) * COALESCE(m.price_pp1, 0::real) * 365::double precision + COALESCE(m.power_p2, 0::real) * COALESCE(m.price_pp2, 0::real) * 365::double precision - COALESCE(m.surpluses, 0::real) * 182.5::double precision / NULLIF(
          m.power_days::double precision,
          0::double precision
        ) * COALESCE(m.price_surpluses, 0::real)
      ) * (1::double precision + 0.05113::double precision) * (1::double precision + COALESCE(m."VAT", 0::real)) + (
        COALESCE(m.daily_maintenance_with_vat, 0::numeric) * 365::numeric
      )::double precision as new_total_yearly_price_with_vat,
      (
        COALESCE(m.anual_consumption_p1, 0::real) * COALESCE(m."precio_kwh_P1", 0::real) + COALESCE(m.anual_consumption_p2, 0::real) * COALESCE(m."precio_kwh_P2", 0::real) + COALESCE(m.anual_consumption_p3, 0::real) * COALESCE(m."precio_kwh_P3", 0::real) + COALESCE(NULLIF(m.power_p1, 0::double precision), 1::real) * COALESCE(m."precio_kw_P1", 0::real) * 365::double precision + COALESCE(m.power_p2, 0::real) * COALESCE(m."precio_kw_P2", 0::real) * 365::double precision - COALESCE(m.surpluses, 0::real) * 182.5::double precision / NULLIF(
          m.power_days::double precision,
          0::double precision
        ) * COALESCE(m.autoconsumo_precio, 0::real)
      ) * (1::double precision + 0.05113::double precision) * (1::double precision + COALESCE(m."VAT", 0::real)) as current_total_yearly_price_with_vat
    from
      m_calc m
  ),
  with_crs as (
    select
      t.id,
      t.created_at,
      t.client_email,
      t.advisor_id,
      t.consumption_p1,
      t.consumption_p2,
      t.consumption_p3,
      t.power_p1,
      t.power_p2,
      t.current_total_invoice,
      t.surpluses,
      t."VAT",
      t.power_days,
      t.pdf_invoice,
      t."CUPS",
      t.address_id,
      t.company,
      t.rate_name,
      t.invoice_month,
      t.equipment_rental,
      t.selfconsumption,
      t.manual_data,
      t.valuation_id,
      t.invoice_year,
      t.temp_client_name,
      t.temp_client_last_name,
      t.deleted,
      t.deleted_reason,
      t.preferred_subrate,
      t.wants_permanence,
      t.anual_consumption_p1,
      t.anual_consumption_p2,
      t.anual_consumption_p3,
      t.max_power,
      t."precio_kwh_P1",
      t."precio_kwh_P2",
      t."precio_kwh_P3",
      t."precio_kw_P1",
      t."precio_kw_P2",
      t.autoconsumo_precio,
      t.totalconsumo,
      t.totalpotencia,
      t.tarifa_plana,
      t.cif,
      t.region,
      t.new_rate_id,
      t.new_company,
      t.new_rate_name,
      t.new_subrate_name,
      t.price_pp1,
      t.price_pp2,
      t.price_pp3,
      t.price_pp4,
      t.price_pp5,
      t.price_pp6,
      t.price_cp1,
      t.price_cp2,
      t.price_cp3,
      t.price_cp4,
      t.price_cp5,
      t.price_cp6,
      t.price_surpluses,
      t.has_maintenance,
      t.daily_maintenance_with_vat,
      t.has_permanence,
      t.rate_mode,
      t.total_excedentes_precio,
      t.maintenance_total,
      t.m_consumo,
      t.m_potencia,
      t.total_consumption_price,
      t.total_power_price,
      t.total_surpluses_price,
      t.new_total_price,
      t.iee_monthly,
      t.new_total_price_with_vat_base,
      t.new_total_yearly_price_with_vat,
      t.current_total_yearly_price_with_vat,
      crs.id as crs_id,
      COALESCE(t.anual_consumption_p1, 0::real) * COALESCE(crs.crs_cp1, 0::real) + COALESCE(t.anual_consumption_p2, 0::real) * COALESCE(crs.crs_cp2, 0::real) + COALESCE(t.anual_consumption_p3, 0::real) * COALESCE(crs.crs_cp3, 0::real) + COALESCE(t.power_p1, 0::real) * COALESCE(crs.crs_pp1, 0::real) + COALESCE(t.power_p2, 0::real) * COALESCE(crs.crs_pp2, 0::real) + COALESCE(crs.fixed_crs, 0::real) as total_crs,
      case
        when t.new_company is not null then COALESCE(t.current_total_invoice, 0::real)::double precision - (
          t.new_total_price_with_vat_base + COALESCE(t.maintenance_total, 0::double precision)
        )
        else 0.0::double precision
      end as savings,
      case
        when t.tarifa_plana = true then t.current_total_invoice * (365.0 / NULLIF(t.power_days::numeric, 0::numeric))::double precision - t.new_total_yearly_price_with_vat
        when t.new_company is not null then t.current_total_yearly_price_with_vat - t.new_total_yearly_price_with_vat
        else 0.0::double precision
      end as savings_yearly
    from
      tot t
      left join comparison_rates_crs_duplicate crs on crs.comparison_rate_id = t.new_rate_id
      and (
        crs.min_kw_anual is null
        or (
          COALESCE(t.anual_consumption_p1, 0::real) + COALESCE(t.anual_consumption_p2, 0::real) + COALESCE(t.anual_consumption_p3, 0::real)
        ) >= crs.min_kw_anual
      )
      and (
        crs.max_kw_anual is null
        or (
          COALESCE(t.anual_consumption_p1, 0::real) + COALESCE(t.anual_consumption_p2, 0::real) + COALESCE(t.anual_consumption_p3, 0::real)
        ) < crs.max_kw_anual
      )
      and (
        crs.min_power is null
        or t.power_p1 >= crs.min_power
      )
      and (
        crs.max_power is null
        or t.power_p1 < crs.max_power
      )
  ),
  rank_prep as (
    select
      w.id,
      w.created_at,
      w.client_email,
      w.advisor_id,
      w.consumption_p1,
      w.consumption_p2,
      w.consumption_p3,
      w.power_p1,
      w.power_p2,
      w.current_total_invoice,
      w.surpluses,
      w."VAT",
      w.power_days,
      w.pdf_invoice,
      w."CUPS",
      w.address_id,
      w.company,
      w.rate_name,
      w.invoice_month,
      w.equipment_rental,
      w.selfconsumption,
      w.manual_data,
      w.valuation_id,
      w.invoice_year,
      w.temp_client_name,
      w.temp_client_last_name,
      w.deleted,
      w.deleted_reason,
      w.preferred_subrate,
      w.wants_permanence,
      w.anual_consumption_p1,
      w.anual_consumption_p2,
      w.anual_consumption_p3,
      w.max_power,
      w."precio_kwh_P1",
      w."precio_kwh_P2",
      w."precio_kwh_P3",
      w."precio_kw_P1",
      w."precio_kw_P2",
      w.autoconsumo_precio,
      w.totalconsumo,
      w.totalpotencia,
      w.tarifa_plana,
      w.cif,
      w.region,
      w.new_rate_id,
      w.new_company,
      w.new_rate_name,
      w.new_subrate_name,
      w.price_pp1,
      w.price_pp2,
      w.price_pp3,
      w.price_pp4,
      w.price_pp5,
      w.price_pp6,
      w.price_cp1,
      w.price_cp2,
      w.price_cp3,
      w.price_cp4,
      w.price_cp5,
      w.price_cp6,
      w.price_surpluses,
      w.has_maintenance,
      w.daily_maintenance_with_vat,
      w.has_permanence,
      w.rate_mode,
      w.total_excedentes_precio,
      w.maintenance_total,
      w.m_consumo,
      w.m_potencia,
      w.total_consumption_price,
      w.total_power_price,
      w.total_surpluses_price,
      w.new_total_price,
      w.iee_monthly,
      w.new_total_price_with_vat_base,
      w.new_total_yearly_price_with_vat,
      w.current_total_yearly_price_with_vat,
      w.crs_id,
      w.total_crs,
      w.savings,
      w.savings_yearly,
      NULLIF(w.preferred_subrate, ''::text) is not null as has_subrate_pref,
      NULLIF(w.preferred_subrate, ''::text) is not null
      and w.new_subrate_name = w.preferred_subrate as subrate_match
    from
      with_crs w
  ),
  subrate_exist as (
    select
      rank_prep.id,
      bool_or(rank_prep.subrate_match) as exists_subrate_match_for_id
    from
      rank_prep
    group by
      rank_prep.id
  ),
  ranked as (
    select
      rp.id,
      rp.created_at,
      rp.client_email,
      rp.advisor_id,
      rp.consumption_p1,
      rp.consumption_p2,
      rp.consumption_p3,
      rp.power_p1,
      rp.power_p2,
      rp.current_total_invoice,
      rp.surpluses,
      rp."VAT",
      rp.power_days,
      rp.pdf_invoice,
      rp."CUPS",
      rp.address_id,
      rp.company,
      rp.rate_name,
      rp.invoice_month,
      rp.equipment_rental,
      rp.selfconsumption,
      rp.manual_data,
      rp.valuation_id,
      rp.invoice_year,
      rp.temp_client_name,
      rp.temp_client_last_name,
      rp.deleted,
      rp.deleted_reason,
      rp.preferred_subrate,
      rp.wants_permanence,
      rp.anual_consumption_p1,
      rp.anual_consumption_p2,
      rp.anual_consumption_p3,
      rp.max_power,
      rp."precio_kwh_P1",
      rp."precio_kwh_P2",
      rp."precio_kwh_P3",
      rp."precio_kw_P1",
      rp."precio_kw_P2",
      rp.autoconsumo_precio,
      rp.totalconsumo,
      rp.totalpotencia,
      rp.tarifa_plana,
      rp.cif,
      rp.region,
      rp.new_rate_id,
      rp.new_company,
      rp.new_rate_name,
      rp.new_subrate_name,
      rp.price_pp1,
      rp.price_pp2,
      rp.price_pp3,
      rp.price_pp4,
      rp.price_pp5,
      rp.price_pp6,
      rp.price_cp1,
      rp.price_cp2,
      rp.price_cp3,
      rp.price_cp4,
      rp.price_cp5,
      rp.price_cp6,
      rp.price_surpluses,
      rp.has_maintenance,
      rp.daily_maintenance_with_vat,
      rp.has_permanence,
      rp.rate_mode,
      rp.total_excedentes_precio,
      rp.maintenance_total,
      rp.m_consumo,
      rp.m_potencia,
      rp.total_consumption_price,
      rp.total_power_price,
      rp.total_surpluses_price,
      rp.new_total_price,
      rp.iee_monthly,
      rp.new_total_price_with_vat_base,
      rp.new_total_yearly_price_with_vat,
      rp.current_total_yearly_price_with_vat,
      rp.crs_id,
      rp.total_crs,
      rp.savings,
      rp.savings_yearly,
      rp.has_subrate_pref,
      rp.subrate_match,
      se.exists_subrate_match_for_id,
      case
        when rp.new_company is not null
        and rp.savings_yearly > 0::double precision then rp.savings_yearly + COALESCE(rp.total_crs, 0::real)::double precision * 4.0::double precision
        else rp.savings_yearly + COALESCE(rp.total_crs, 0::real)::double precision * 4.0::double precision
      end as ranked_crs,
      row_number() over (
        partition by
          rp.id
        order by
          (
            case
              when rp.has_subrate_pref
              and se.exists_subrate_match_for_id then case
                when rp.subrate_match then 1
                else 0
              end
              else 1
            end
          ) desc,
          (
            case
              when rp.new_company is not null
              and rp.savings_yearly > 0::double precision then rp.savings_yearly + COALESCE(rp.total_crs, 0::real)::double precision * 4.0::double precision
              else rp.savings_yearly + COALESCE(rp.total_crs, 0::real)::double precision * 4.0::double precision
            end
          ) desc
      ) as rank
    from
      rank_prep rp
      left join subrate_exist se using (id)
  ),
  with_advisor as (
    select
      r.id,
      r.created_at,
      r.client_email,
      r.advisor_id,
      r.consumption_p1,
      r.consumption_p2,
      r.consumption_p3,
      r.power_p1,
      r.power_p2,
      r.current_total_invoice,
      r.surpluses,
      r."VAT",
      r.power_days,
      r.pdf_invoice,
      r."CUPS",
      r.address_id,
      r.company,
      r.rate_name,
      r.invoice_month,
      r.equipment_rental,
      r.selfconsumption,
      r.manual_data,
      r.valuation_id,
      r.invoice_year,
      r.temp_client_name,
      r.temp_client_last_name,
      r.deleted,
      r.deleted_reason,
      r.preferred_subrate,
      r.wants_permanence,
      r.anual_consumption_p1,
      r.anual_consumption_p2,
      r.anual_consumption_p3,
      r.max_power,
      r."precio_kwh_P1",
      r."precio_kwh_P2",
      r."precio_kwh_P3",
      r."precio_kw_P1",
      r."precio_kw_P2",
      r.autoconsumo_precio,
      r.totalconsumo,
      r.totalpotencia,
      r.tarifa_plana,
      r.cif,
      r.region,
      r.new_rate_id,
      r.new_company,
      r.new_rate_name,
      r.new_subrate_name,
      r.price_pp1,
      r.price_pp2,
      r.price_pp3,
      r.price_pp4,
      r.price_pp5,
      r.price_pp6,
      r.price_cp1,
      r.price_cp2,
      r.price_cp3,
      r.price_cp4,
      r.price_cp5,
      r.price_cp6,
      r.price_surpluses,
      r.has_maintenance,
      r.daily_maintenance_with_vat,
      r.has_permanence,
      r.rate_mode,
      r.total_excedentes_precio,
      r.maintenance_total,
      r.m_consumo,
      r.m_potencia,
      r.total_consumption_price,
      r.total_power_price,
      r.total_surpluses_price,
      r.new_total_price,
      r.iee_monthly,
      r.new_total_price_with_vat_base,
      r.new_total_yearly_price_with_vat,
      r.current_total_yearly_price_with_vat,
      r.crs_id,
      r.total_crs,
      r.savings,
      r.savings_yearly,
      r.has_subrate_pref,
      r.subrate_match,
      r.exists_subrate_match_for_id,
      r.ranked_crs,
      r.rank,
      case
        when (
          (
            select
              u2.racc
            from
              users u2
            where
              u2.user_id = r.advisor_id
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
      u_1.email as advisor_email,
      u_1.name as advisor_display_name
    from
      ranked r
      left join _users_supervisors us on r.advisor_id = us.user_id
      left join users u_1 on u_1.user_id = r.advisor_id
  )
select distinct
  rc.id,
  rc.created_at,
  rc.client_email,
  rc.advisor_id,
  rc.consumption_p1,
  rc.consumption_p2,
  rc.consumption_p3,
  0::real as consumption_p4,
  0::real as consumption_p5,
  0::real as consumption_p6,
  rc.anual_consumption_p1,
  rc.anual_consumption_p2,
  rc.anual_consumption_p3,
  0::real as anual_consumption_p4,
  0::real as anual_consumption_p5,
  0::real as anual_consumption_p6,
  rc.autoconsumo_precio,
  rc."precio_kw_P1",
  rc."precio_kw_P2",
  0::real as "precio_kw_P3",
  0::real as "precio_kw_P4",
  0::real as "precio_kw_P5",
  0::real as "precio_kw_P6",
  rc."precio_kwh_P1",
  rc."precio_kwh_P2",
  rc."precio_kwh_P3",
  0::real as "precio_kwh_P4",
  0::real as "precio_kwh_P5",
  0::real as "precio_kwh_P6",
  COALESCE(rc.consumption_p1, 0::real) + COALESCE(rc.consumption_p2, 0::real) + COALESCE(rc.consumption_p3, 0::real) as total_consumption,
  COALESCE(rc.anual_consumption_p1, 0::real) + COALESCE(rc.anual_consumption_p2, 0::real) + COALESCE(rc.anual_consumption_p3, 0::real) as total_anual_consumption,
  rc.power_p1,
  rc.power_p2,
  0::real as power_p3,
  0::real as power_p4,
  0::real as power_p5,
  0::real as power_p6,
  rc.current_total_invoice,
  rc.surpluses,
  rc.total_surpluses_price,
  0::real as power_surpluses,
  rc."VAT",
  rc.power_days as days,
  rc.pdf_invoice,
  rc."CUPS",
  rc.address_id,
  rc.company,
  rc.rate_name,
  rc.invoice_month,
  rc.equipment_rental,
  rc.selfconsumption,
  rc.manual_data,
  0::real as reactive,
  rc.valuation_id,
  rc.invoice_year,
  0::real as meter_rental,
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
  'light'::text as type,
  COALESCE(rc.temp_client_name, ''::text) as temp_client_name,
  COALESCE(rc.temp_client_last_name, ''::text) as temp_client_last_name,
  array['light'::text, 'All'::text] as type_filter,
  rc.deleted,
  rc.deleted_reason,
  rc.new_rate_id,
  COALESCE(rc.max_power, 0::real) as max_power,
  0 as speed_fiber,
  0 as mobile_lines,
  0 as mobile_total_gb,
  false as fijo,
  0 as new_speed_fiber,
  0 as new_total_mobile_lines,
  0 as new_mobile_total_gb,
  ''::text as rate_pack,
  0 as phone_total_anual_price,
  rc.crs_id,
  rc.total_crs,
  rc.savings,
  rc.savings_yearly,
  rc.ranked_crs,
  rc.rank,
  rc.tarifa_plana,
  rc.iee_monthly,
  (
    COALESCE(rc.anual_consumption_p1, 0::real) * COALESCE(rc.price_cp1, 0::real) + COALESCE(rc.anual_consumption_p2, 0::real) * COALESCE(rc.price_cp2, 0::real) + COALESCE(rc.anual_consumption_p3, 0::real) * COALESCE(rc.price_cp3, 0::real) + (
      COALESCE(rc.power_p1, 0::real) * COALESCE(rc.price_pp1, 0::real) + COALESCE(rc.power_p2, 0::real) * COALESCE(rc.price_pp2, 0::real)
    ) * 365::double precision
  ) * 0.05113::double precision as iee,
  rc.new_total_price_with_vat_base + COALESCE(rc.maintenance_total, 0::double precision) as new_total_price_with_vat,
  rc.new_total_yearly_price_with_vat,
  case
    when rc.new_company is not null
    and rc.current_total_yearly_price_with_vat <> 0::double precision
    and rc.tarifa_plana is not true then (
      rc.current_total_yearly_price_with_vat - rc.new_total_yearly_price_with_vat
    ) / rc.current_total_yearly_price_with_vat
    when rc.tarifa_plana = true
    and rc.power_days > 0 then (
      rc.current_total_invoice * (
        365.0::double precision / rc.power_days::double precision
      ) - rc.new_total_yearly_price_with_vat
    ) / NULLIF(
      rc.current_total_invoice * (
        365.0::double precision / rc.power_days::double precision
      ),
      0::double precision
    )
    else 0.0::double precision
  end as saving_percentage,
  rc.supervisors,
  COALESCE(rc.temp_client_name, ''::text) as client_name,
  COALESCE(rc.temp_client_last_name, ''::text) as client_last_name,
  u.email as advisor_email,
  u.name as advisor_display_name,
  array[COALESCE(u.email, ''::text), 'All'::text] as advisor_filter,
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
                    (COALESCE(rc."CUPS", ''::text) || ' '::text) || COALESCE(rc.client_email, ''::text)
                  ) || ' '::text
                ) || COALESCE(rc.company, ''::text)
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
  rc.daily_maintenance_with_vat::numeric(8, 2) as daily_maintenance_with_vat,
  rc.has_permanence,
  rc.rate_mode,
  rc.total_excedentes_precio,
  null::text as rate_i_have
from
  with_advisor rc
  left join users u on u.user_id = rc.advisor_id
where
  rc.rank = 1
  and (
    rc.deleted is null
    or rc.deleted = false
  );
