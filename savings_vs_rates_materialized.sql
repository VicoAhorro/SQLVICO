-- Primero creamos índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_clients_contracts_lookup
  ON clients_contracts(id, contract_type, deleted)
  WHERE deleted = false;

CREATE INDEX IF NOT EXISTS idx_comparison_rates_lookup
  ON comparison_rates_v2(type, company);

CREATE INDEX IF NOT EXISTS idx_comparison_rates_crs_lookup
  ON comparison_rates_crs_duplicate(comparison_rate_id, min_kw_anual, max_kw_anual, min_power, max_power);

CREATE INDEX IF NOT EXISTS idx_payment_control_contract
  ON payment_control(contract_id);

-- Ahora creamos la vista materializada
DROP MATERIALIZED VIEW IF EXISTS public.contracts_savings_vs_rates CASCADE;

CREATE MATERIALIZED VIEW public.contracts_savings_vs_rates AS
with
  pagos as (
    select
      contract_id,
      coalesce(sum(p."crs"), 0) as total_cobrado
    from
      public.payment_control p
    group by
      contract_id
  ),
  contracts as (
    select
      c.id as contract_id,
      c.contract_type,
      COALESCE(c.region, 'PENINSULA'::text) as region,
      upper(trim(coalesce(c.new_company, ''))) as current_company,
      c.activation_date::date as activation_date,
      coalesce(c.crs, 0) as crs_base,
      -- Consumos anuales por periodo
      COALESCE(c.consumoanualp1, 0::real) as anual_consumption_p1,
      COALESCE(c.consumoanualp2, 0::real) as anual_consumption_p2,
      COALESCE(c.consumoanualp3, 0::real) as anual_consumption_p3,
      COALESCE(c.consumoanualp4, 0::real) as anual_consumption_p4,
      COALESCE(c.consumoanualp5, 0::real) as anual_consumption_p5,
      COALESCE(c.consumoanualp6, 0::real) as anual_consumption_p6,
      -- Potencias contratadas
      COALESCE(c.potenciacontratadap1, 0::real) as power_p1,
      COALESCE(c.potenciacontratadap2, 0::real) as power_p2,
      COALESCE(c.potenciacontratadap3, 0::real) as power_p3,
      COALESCE(c.potenciacontratadap4, 0::real) as power_p4,
      COALESCE(c.potenciacontratadap5, 0::real) as power_p5,
      COALESCE(c.potenciacontratadap6, 0::real) as power_p6,
      GREATEST(
        LEAST(
          COALESCE(c.saving_percentage, 0::real)::numeric,
          1::numeric
        ),
        0::numeric
      ) as saving_percentage_actual,
      COALESCE(c.consumoanualp1, 0::real)::numeric * COALESCE(c.precioconsumop1, 0::real)::numeric + COALESCE(c.consumoanualp2, 0::real)::numeric * COALESCE(c.precioconsumop2, 0::real)::numeric + COALESCE(c.consumoanualp3, 0::real)::numeric * COALESCE(c.precioconsumop3, 0::real)::numeric + COALESCE(c.consumoanualp4, 0::real)::numeric * COALESCE(c.precioconsumop4, 0::real)::numeric + COALESCE(c.consumoanualp5, 0::real)::numeric * COALESCE(c.precioconsumop5, 0::real)::numeric + COALESCE(c.consumoanualp6, 0::real)::numeric * COALESCE(c.precioconsumop6, 0::real)::numeric as energy_cost_year_curr,
      (
        COALESCE(c.potenciacontratadap1, 0::real)::numeric * COALESCE(c.preciopotencia1, 0::real)::numeric + COALESCE(c.potenciacontratadap2, 0::real)::numeric * COALESCE(c.preciopotencia2, 0::real)::numeric + COALESCE(c.potenciacontratadap3, 0::real)::numeric * COALESCE(c.preciopotencia3, 0::real)::numeric + COALESCE(c.potenciacontratadap4, 0::real)::numeric * COALESCE(c.preciopotencia4, 0::real)::numeric + COALESCE(c.potenciacontratadap5, 0::real)::numeric * COALESCE(c.preciopotencia5, 0::real)::numeric + COALESCE(c.potenciacontratadap6, 0::real)::numeric * COALESCE(c.preciopotencia6, 0::real)::numeric
      ) * 365::numeric as power_cost_year_curr
    from
      clients_contracts c
    where
      COALESCE(c.deleted, false) = false
      and (
        c.contract_type = any (array['light'::text, 'gas'::text, '3_0'::text])
      )
  ),
  decomision_calc as (
    select
      co.contract_id,
      co.current_company,
      co.crs_base,
      coalesce(p.total_cobrado, 0) as total_cobrado,
      case
        -- ENDESA: 100% durante los primeros 2 meses, luego 0%
        when co.current_company = 'ENDESA' and co.activation_date is not null then
          case
            when (current_date - co.activation_date) <= 60 then 1.0
            else 0.0
          end

        -- NATURGY: 0-2 meses: 100%, 2-4 meses: 50%, >4 meses: 0%
        when co.current_company = 'NATURGY' and co.activation_date is not null then
          case
            when (current_date - co.activation_date) <= 60 then 1.0
            when (current_date - co.activation_date) <= 120 then 0.50
            else 0.0
          end

        -- GANA: Escalonado por trimestres
        -- 0-3 meses: 100%, 3-6: 75%, 6-9: 50%, 9-12: 25%, >12: 0%
        when co.current_company = 'GANA' and co.activation_date is not null then
          case
            when (current_date - co.activation_date) <= 90 then 1.0
            when (current_date - co.activation_date) <= 180 then 0.75
            when (current_date - co.activation_date) <= 270 then 0.50
            when (current_date - co.activation_date) <= 365 then 0.25
            else 0.0
          end

        -- BASSOLS, IMAGINA, LOGOS, PLENITUDE, CYE, GALP, ELEIA: Prorrateado lineal
        when co.current_company in ('BASSOLS','IMAGINA','LOGOS','PLENITUDE','CYE','GALP','ELEIA')
             and co.activation_date is not null
          then least(greatest((current_date - co.activation_date) / 365.0, 0), 1.0)

        -- Resto de empresas: 100% siempre
        else 1.0
      end as porcentaje_decomision,
      -- Decomisión hoy: lo que SE DEBE DEVOLVER si el cliente se va ahora
      round((co.crs_base *
        case
          -- ENDESA: 100% primeros 2 meses, luego 0%
          when co.current_company = 'ENDESA' and co.activation_date is not null then
            case
              when (current_date - co.activation_date) <= 60 then 1.0
              else 0.0
            end

          -- NATURGY: 0-2 meses: 100%, 2-4 meses: 50%, >4 meses: 0%
          when co.current_company = 'NATURGY' and co.activation_date is not null then
            case
              when (current_date - co.activation_date) <= 60 then 1.0
              when (current_date - co.activation_date) <= 120 then 0.50
              else 0.0
            end

          -- GANA: Escalonado
          when co.current_company = 'GANA' and co.activation_date is not null then
            case
              when (current_date - co.activation_date) <= 90 then 1.0
              when (current_date - co.activation_date) <= 180 then 0.75
              when (current_date - co.activation_date) <= 270 then 0.50
              when (current_date - co.activation_date) <= 365 then 0.25
              else 0.0
            end

          -- BASSOLS, IMAGINA, LOGOS, PLENITUDE, CYE, GALP, ELEIA: Prorrateado lineal
          when co.current_company in ('BASSOLS','IMAGINA','LOGOS','PLENITUDE','CYE','GALP','ELEIA')
               and co.activation_date is not null
            then least(greatest((current_date - co.activation_date) / 365.0, 0), 1.0)

          -- Resto: 100%
          else 1.0
        end)::numeric, 2) as decomision_hoy,
      -- Decomisión pendiente: lo que PERDERÍAS si cambias al cliente ahora
      round((co.crs_base - (co.crs_base *
        case
          when co.current_company = 'ENDESA' and co.activation_date is not null then
            case
              when (current_date - co.activation_date) <= 60 then 1.0
              else 0.0
            end

          when co.current_company = 'NATURGY' and co.activation_date is not null then
            case
              when (current_date - co.activation_date) <= 60 then 1.0
              when (current_date - co.activation_date) <= 120 then 0.50
              else 0.0
            end

          when co.current_company = 'GANA' and co.activation_date is not null then
            case
              when (current_date - co.activation_date) <= 90 then 1.0
              when (current_date - co.activation_date) <= 180 then 0.75
              when (current_date - co.activation_date) <= 270 then 0.50
              when (current_date - co.activation_date) <= 365 then 0.25
              else 0.0
            end

          when co.current_company in ('BASSOLS','IMAGINA','LOGOS','PLENITUDE','CYE','GALP','ELEIA')
               and co.activation_date is not null
            then least(greatest((current_date - co.activation_date) / 365.0, 0), 1.0)

          else 1.0
        end))::numeric, 2) as decomision_pendiente
    from
      contracts co
      left join pagos p on p.contract_id = co.contract_id
  ),
  contracts_costs as (
    select
      contracts.contract_id,
      contracts.contract_type,
      contracts.region,
      contracts.saving_percentage_actual,
      case
        when contracts.contract_type = any (array['light'::text, '3_0'::text]) then (
          contracts.energy_cost_year_curr + contracts.power_cost_year_curr
        ) * 1.05113
        else contracts.energy_cost_year_curr + contracts.power_cost_year_curr
      end as current_year_cost_iee,
      round(
        case
          when contracts.contract_type = any (array['light'::text, '3_0'::text]) then (
            contracts.energy_cost_year_curr + contracts.power_cost_year_curr
          ) * 1.05113 * contracts.saving_percentage_actual
          else (
            contracts.energy_cost_year_curr + contracts.power_cost_year_curr
          ) * contracts.saving_percentage_actual
        end,
        2
      )::numeric(12, 2) as saving_yearly_actual
    from
      contracts
  ),
  candidates as (
    select
      cc_1.contract_id,
      cc_1.contract_type,
      cc_1.region,
      cc_1.current_year_cost_iee,
      cc_1.saving_percentage_actual,
      co.anual_consumption_p1,
      co.anual_consumption_p2,
      co.anual_consumption_p3,
      co.anual_consumption_p4,
      co.anual_consumption_p5,
      co.anual_consumption_p6,
      co.power_p1,
      co.power_p2,
      co.power_p3,
      co.power_p4,
      co.power_p5,
      co.power_p6,
      cr.id as rate_id,
      cr.company as new_company,
      cr.rate_name as new_rate_name,
      cr.subrate_name as new_subrate_name,
      case
        when cc_1.contract_type = 'gas'::text then
          365::numeric * COALESCE(cr.price_pp1, 0::real)::numeric +
          co.anual_consumption_p1::numeric * (COALESCE(cr.price_cp1, 0::real)::numeric + 0.00234)
        when cc_1.contract_type = any (array['light'::text, '3_0'::text]) then (
          (
            co.anual_consumption_p1::numeric * COALESCE(cr.price_cp1, 0::real)::numeric +
            co.anual_consumption_p2::numeric * COALESCE(cr.price_cp2, 0::real)::numeric +
            co.anual_consumption_p3::numeric * COALESCE(cr.price_cp3, 0::real)::numeric +
            co.anual_consumption_p4::numeric * COALESCE(cr.price_cp4, 0::real)::numeric +
            co.anual_consumption_p5::numeric * COALESCE(cr.price_cp5, 0::real)::numeric +
            co.anual_consumption_p6::numeric * COALESCE(cr.price_cp6, 0::real)::numeric
          ) + (
            (
              co.power_p1::numeric * COALESCE(cr.price_pp1, 0::real)::numeric +
              co.power_p2::numeric * COALESCE(cr.price_pp2, 0::real)::numeric +
              co.power_p3::numeric * COALESCE(cr.price_pp3, 0::real)::numeric +
              co.power_p4::numeric * COALESCE(cr.price_pp4, 0::real)::numeric +
              co.power_p5::numeric * COALESCE(cr.price_pp5, 0::real)::numeric +
              co.power_p6::numeric * COALESCE(cr.price_pp6, 0::real)::numeric
            ) * 365::numeric
          )
        ) * 1.05113
        else null::numeric
      end as new_year_cost
    from
      contracts_costs cc_1
      join contracts co on co.contract_id = cc_1.contract_id
      join comparison_rates_v2 cr on cr.type = cc_1.contract_type
      and (
        cc_1.region is null
        or (cc_1.region = any (cr.region))
      )
  ),
  candidates_with_crs as (
    select
      c.*,
      coalesce(crs_calc.total_crs, 0) as new_crs
    from
      candidates c
      left join lateral (
        select
          case
            when c.contract_type = 'gas'::text then
              coalesce(
                c.anual_consumption_p1::numeric * coalesce(crs.crs_cp1, 0::real)::numeric +
                c.power_p1::numeric * coalesce(crs.crs_pp1, 0::real)::numeric +
                coalesce(crs.fixed_crs, 0::real)::numeric,
                0::numeric
              )
            when c.contract_type = any (array['light'::text, '3_0'::text]) then
              coalesce(
                c.anual_consumption_p1::numeric * coalesce(crs.crs_cp1, 0::real)::numeric +
                c.anual_consumption_p2::numeric * coalesce(crs.crs_cp2, 0::real)::numeric +
                c.anual_consumption_p3::numeric * coalesce(crs.crs_cp3, 0::real)::numeric +
                c.anual_consumption_p4::numeric * coalesce(crs.crs_cp4, 0::real)::numeric +
                c.anual_consumption_p5::numeric * coalesce(crs.crs_cp5, 0::real)::numeric +
                c.anual_consumption_p6::numeric * coalesce(crs.crs_cp6, 0::real)::numeric +
                c.power_p1::numeric * coalesce(crs.crs_pp1, 0::real)::numeric +
                c.power_p2::numeric * coalesce(crs.crs_pp2, 0::real)::numeric +
                c.power_p3::numeric * coalesce(crs.crs_pp3, 0::real)::numeric +
                c.power_p4::numeric * coalesce(crs.crs_pp4, 0::real)::numeric +
                c.power_p5::numeric * coalesce(crs.crs_pp5, 0::real)::numeric +
                c.power_p6::numeric * coalesce(crs.crs_pp6, 0::real)::numeric +
                coalesce(crs.fixed_crs, 0::real)::numeric,
                0::numeric
              )
            else 0::numeric
          end as total_crs
        from
          comparison_rates_crs_duplicate crs
        where
          crs.comparison_rate_id = c.rate_id
          -- Filtros de rangos según consumo anual total y potencia
          and (crs.min_kw_anual is null or (
            c.anual_consumption_p1 + c.anual_consumption_p2 + c.anual_consumption_p3 +
            c.anual_consumption_p4 + c.anual_consumption_p5 + c.anual_consumption_p6
          ) >= crs.min_kw_anual)
          and (crs.max_kw_anual is null or (
            c.anual_consumption_p1 + c.anual_consumption_p2 + c.anual_consumption_p3 +
            c.anual_consumption_p4 + c.anual_consumption_p5 + c.anual_consumption_p6
          ) < crs.max_kw_anual)
          and (crs.min_power is null or c.power_p1 >= crs.min_power)
          and (crs.max_power is null or c.power_p1 < crs.max_power)
        limit 1
      ) crs_calc on true
  ),
  candidates_scored as (
    select
      cwc.contract_id,
      cwc.rate_id,
      cwc.new_company,
      cwc.new_rate_name,
      cwc.new_subrate_name,
      cwc.current_year_cost_iee,
      cwc.new_year_cost,
      cwc.new_crs,
      round(
        GREATEST(
          cwc.current_year_cost_iee - COALESCE(
            cwc.new_year_cost,
            cwc.current_year_cost_iee
          ),
          0::numeric
        ),
        2
      )::numeric(12, 2) as new_savings_yearly,
      GREATEST(
        cwc.current_year_cost_iee - COALESCE(
          cwc.new_year_cost,
          cwc.current_year_cost_iee
        ),
        0::numeric
      ) / NULLIF(cwc.current_year_cost_iee, 0::numeric) as new_saving_percentage
    from
      candidates_with_crs cwc
  ),
  best_rate as (
    select
      cs.contract_id,
      cs.rate_id,
      cs.new_company,
      cs.new_rate_name,
      cs.new_subrate_name,
      cs.current_year_cost_iee,
      cs.new_year_cost,
      cs.new_crs,
      cs.new_savings_yearly,
      cs.new_saving_percentage,
      row_number() over (
        partition by
          cs.contract_id
        order by
          cs.new_savings_yearly desc
      ) as rn
    from
      candidates_scored cs
  )
select
  cc.contract_id,
  cc.saving_yearly_actual,
  cc.saving_percentage_actual,
  br.new_savings_yearly,
  br.new_saving_percentage,
  br.new_company,
  br.new_rate_name,
  br.new_subrate_name,
  dc.current_company,
  dc.crs_base as crs_actual,
  br.new_crs,
  dc.total_cobrado,
  dc.decomision_hoy,
  dc.decomision_pendiente,
  round((br.new_crs - dc.decomision_pendiente)::numeric, 2) as ganancia_neta_crs,
  case
    when br.new_savings_yearly > 0 then
      round((dc.decomision_pendiente / (br.new_savings_yearly / 12.0))::numeric, 1)
    else null
  end as meses_recuperacion_decomision,
  case
    when dc.decomision_pendiente <= 0 then 'SI - No hay decomisión pendiente'
    when br.new_crs <= dc.decomision_pendiente then 'NO - El nuevo CRS no cubre la decomisión'
    when br.new_savings_yearly <= 0 then 'NO - No hay ahorro con la nueva tarifa'
    when (dc.decomision_pendiente / (br.new_savings_yearly / 12.0)) <= 12 then 'SI - Se recupera en menos de 12 meses'
    when (dc.decomision_pendiente / (br.new_savings_yearly / 12.0)) <= 24 then 'QUIZAS - Se recupera entre 12 y 24 meses'
    else 'NO - Tarda más de 24 meses en recuperarse'
  end as recomendacion_cambio,
  round((br.new_savings_yearly - dc.decomision_pendiente)::numeric, 2) as ahorro_neto_primer_año,
  round((br.new_savings_yearly * 2 - dc.decomision_pendiente)::numeric, 2) as ahorro_neto_24_meses
from
  contracts_costs cc
  join best_rate br on br.contract_id = cc.contract_id
  and br.rn = 1
  join decomision_calc dc on dc.contract_id = cc.contract_id
where
  (
    br.new_saving_percentage - cc.saving_percentage_actual
  ) > 0.05
  and br.new_crs > dc.decomision_pendiente;

-- Crear índice en la vista materializada
CREATE INDEX idx_mat_savings_contract ON public.contracts_savings_vs_rates(contract_id);
CREATE INDEX idx_mat_savings_company ON public.contracts_savings_vs_rates(new_company);
CREATE INDEX idx_mat_savings_recomendacion ON public.contracts_savings_vs_rates(recomendacion_cambio);

-- Script para refrescar la vista (ejecutar periódicamente, por ejemplo cada noche)
-- REFRESH MATERIALIZED VIEW CONCURRENTLY public.contracts_savings_vs_rates;
