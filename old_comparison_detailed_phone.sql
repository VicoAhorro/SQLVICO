create view public._comparisons_detailed_phone as
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
      base_rates.rate_id,
      base_rates.rate_company,
      base_rates.rate_name,
      base_rates.fibra_mb,
      base_rates.total_lines,
      base_rates.total_gb,
      base_rates.total_price,
      base_rates.total_anual_price,
      base_rates.total_crs,
      base_rates.crs_calculation,
      base_rates.excluded_companies,
      base_rates.rate_pack,
      base_rates.rate_type,
      base_rates.allow_landline
    from
      base_rates
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
          al.rate = any (string_to_array(rc_1.rate_pack, ', '::text))
        )
      )
      and rc_1.total_lines < (
        (
          select
            max(cp.mobile_lines + 2) as max
          from
            comparison_phone cp
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
      0::real as "VAT",
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
      false as wants_permanence,
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
      (cp.current_total_invoice * 12::numeric)::double precision - rc_1.total_anual_price + rc_1.total_crs * 4::double precision as ranked_crs,
      row_number() over (
        partition by
          cp.id
        order by
          (
            (cp.current_total_invoice * 12::numeric)::double precision - rc_1.total_anual_price + rc_1.total_crs * 4::double precision
          ) desc
      ) as rank,
      0 as "?column?"
    from
      comparison_phone cp
      join recursive_combinations rc_1 on rc_1.fibra_mb >= cp.speed_fiber
      and rc_1.total_lines >= cp.mobile_lines
      and rc_1.total_lines <= (cp.mobile_lines + 2)
      and rc_1.rate_type = cp.rate_type
      and rc_1.total_gb >= cp.mobile_total_gb
      and (
        rc_1.excluded_companies is null
        or not (
          exists (
            select
              1
            from
              unnest(rc_1.excluded_companies) ex (ex)
            where
              ex.ex = cp.company
          )
        )
      )
      and (
        cp.landline = false
        or rc_1.allow_landline = true
      )
      and (
        cp.deleted is null
        or cp.deleted = false
      )
    where
      cp.valuation_id is null
  )
select distinct
  rp.id,
  rp.created_at,
  rp.client_email,
  rp.advisor_id,
  rp.consumption_p1,
  rp.consumption_p2,
  rp.consumption_p3,
  rp.consumption_p4,
  rp.consumption_p5,
  rp.consumption_p6,
  rp.anual_consumption_p1,
  rp.anual_consumption_p2,
  rp.anual_consumption_p3,
  rp.anual_consumption_p4,
  rp.anual_consumption_p5,
  rp.anual_consumption_p6,
  rp.autoconsumo_precio,
  rp."precio_kw_P1",
  rp."precio_kw_P2",
  rp."precio_kw_P3",
  rp."precio_kw_P4",
  rp."precio_kw_P5",
  rp."precio_kw_P6",
  rp."precio_kwh_P1",
  rp."precio_kwh_P2",
  rp."precio_kwh_P3",
  rp."precio_kwh_P4",
  rp."precio_kwh_P5",
  rp."precio_kwh_P6",
  rp.total_consumption,
  rp.total_anual_consumption,
  rp.power_p1,
  rp.power_p2,
  rp.power_p3,
  rp.power_p4,
  rp.power_p5,
  rp.power_p6,
  rp.current_total_invoice,
  rp.surpluses,
  rp.total_surpluses_price,
  rp.power_surpluses,
  rp."VAT",
  rp.days,
  rp.pdf_invoice,
  rp.cups as "CUPS",
  rp.address_id,
  rp.company,
  rp.rate_name,
  rp.invoice_month,
  rp.equipment_rental,
  rp.selfconsumption,
  rp.manual_data,
  rp.reactive,
  rp.valuation_id,
  rp.invoice_year,
  rp.meter_rental,
  rp.preferred_subrate,
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
  rp.total_power_price,
  rp.total_consumption_price,
  rp.new_total_price,
  rp.type,
  rp.temp_client_name,
  rp.temp_client_last_name,
  rp.type_filter,
  rp.deleted,
  rp.deleted_reason,
  rp.new_rate_id,
  rp.max_power,
  rp.speed_fiber,
  rp.mobile_lines,
  rp.mobile_total_gb,
  rp.fijo,
  rp.new_speed_fiber,
  rp.new_total_mobile_lines,
  rp.new_mobile_total_gb,
  rp.rate_pack,
  rp.phone_total_anual_price,
  rp.crs_id,
  rp.total_crs,
  rp.savings,
  rp.savings_yearly,
  rp.ranked_crs,
  rp.rank,
  false as tarifa_plana,
  0.0::double precision as iee_monthly,
  0.0::double precision as iee,
  rp.new_total_price as new_total_price_with_vat,
  COALESCE(
    rp.phone_total_anual_price::double precision,
    rp.new_total_price * 12::double precision
  ) as new_total_yearly_price_with_vat,
  case
    when rp.current_total_invoice > 0::numeric then (
      (rp.current_total_invoice * 12::numeric)::double precision - COALESCE(rp.phone_total_anual_price, 0::real)::double precision
    ) / NULLIF(
      rp.current_total_invoice * 12::numeric,
      0::numeric
    )::double precision
    else 0.0::double precision
  end as saving_percentage,
  us.supervisors,
  COALESCE(rp.temp_client_name, ''::text) as client_name,
  COALESCE(rp.temp_client_last_name, ''::text) as client_last_name,
  u.email as advisor_email,
  u.name as advisor_display_name,
  array[COALESCE(u.email, ''::text), 'All'::text] as advisor_filter,
  EXTRACT(
    month
    from
      rp.created_at
  )::text as created_month,
  EXTRACT(
    year
    from
      rp.created_at
  )::text as created_year,
  concat_ws(', '::text, rp.client_email, rp.cups) as search,
  array[rp.company, 'All'::text] as company_filter,
  false as cif,
  null::text as region,
  0.0::numeric(8, 2) as daily_maintenance_with_vat,
  false as has_permanence,
  null::rate_mode_type as rate_mode,
  0::real as total_excedentes_precio,
  null::rate_mode_type as rate_i_have
from
  ranked_phone rp
  left join _users_supervisors us on rp.advisor_id = us.user_id
  left join users u on u.user_id = rp.advisor_id
where
  rp.rank = 1
  and (
    rp.deleted is null
    or rp.deleted = false
  );