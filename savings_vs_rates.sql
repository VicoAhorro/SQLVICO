create view public._contracts_savings_vs_rates as
with
  contracts as (
    select
      c.id as contract_id,
      c.contract_type,
      COALESCE(c.region, 'PENINSULA'::text) as region,
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
      cr.id as rate_id,
      cr.company as new_company,
      cr.rate_name as new_rate_name,
      cr.subrate_name as new_subrate_name,
      case
        when cc_1.contract_type = 'gas'::text then 365::numeric * COALESCE(cr.price_pp1, 0::real)::numeric + COALESCE(
          (
            select
              COALESCE(ca.consumoanualp1, 0::real)::numeric as "coalesce"
            from
              clients_contracts ca
            where
              ca.id = cc_1.contract_id
          ),
          0::numeric
        ) * (
          COALESCE(cr.price_cp1, 0::real)::numeric + 0.00234
        )
        when cc_1.contract_type = any (array['light'::text, '3_0'::text]) then (
          (
            (
              select
                COALESCE(ca.consumoanualp1, 0::real)::numeric * COALESCE(cr.price_cp1, 0::real)::numeric + COALESCE(ca.consumoanualp2, 0::real)::numeric * COALESCE(cr.price_cp2, 0::real)::numeric + COALESCE(ca.consumoanualp3, 0::real)::numeric * COALESCE(cr.price_cp3, 0::real)::numeric + COALESCE(ca.consumoanualp4, 0::real)::numeric * COALESCE(cr.price_cp4, 0::real)::numeric + COALESCE(ca.consumoanualp5, 0::real)::numeric * COALESCE(cr.price_cp5, 0::real)::numeric + COALESCE(ca.consumoanualp6, 0::real)::numeric * COALESCE(cr.price_cp6, 0::real)::numeric
              from
                clients_contracts ca
              where
                ca.id = cc_1.contract_id
            )
          ) + (
            (
              select
                (
                  COALESCE(ca.potenciacontratadap1, 0::real)::numeric * COALESCE(cr.price_pp1, 0::real)::numeric + COALESCE(ca.potenciacontratadap2, 0::real)::numeric * COALESCE(cr.price_pp2, 0::real)::numeric + COALESCE(ca.potenciacontratadap3, 0::real)::numeric * COALESCE(cr.price_pp3, 0::real)::numeric + COALESCE(ca.potenciacontratadap4, 0::real)::numeric * COALESCE(cr.price_pp4, 0::real)::numeric + COALESCE(ca.potenciacontratadap5, 0::real)::numeric * COALESCE(cr.price_pp5, 0::real)::numeric + COALESCE(ca.potenciacontratadap6, 0::real)::numeric * COALESCE(cr.price_pp6, 0::real)::numeric
                ) * 365::numeric
              from
                clients_contracts ca
              where
                ca.id = cc_1.contract_id
            )
          )
        ) * 1.05113
        else null::numeric
      end as new_year_cost
    from
      contracts_costs cc_1
      join comparison_rates cr on cr.type = cc_1.contract_type
      and (
        cc_1.region is null
        or (cc_1.region = any (cr.region))
      )
  ),
  candidates_scored as (
    select
      candidates.contract_id,
      candidates.rate_id,
      candidates.new_company,
      candidates.new_rate_name,
      candidates.new_subrate_name,
      candidates.current_year_cost_iee,
      candidates.new_year_cost,
      round(
        GREATEST(
          candidates.current_year_cost_iee - COALESCE(
            candidates.new_year_cost,
            candidates.current_year_cost_iee
          ),
          0::numeric
        ),
        2
      )::numeric(12, 2) as new_savings_yearly,
      GREATEST(
        candidates.current_year_cost_iee - COALESCE(
          candidates.new_year_cost,
          candidates.current_year_cost_iee
        ),
        0::numeric
      ) / NULLIF(candidates.current_year_cost_iee, 0::numeric) as new_saving_percentage
    from
      candidates
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
  br.new_subrate_name
from
  contracts_costs cc
  join best_rate br on br.contract_id = cc.contract_id
  and br.rn = 1
where
  (
    br.new_saving_percentage - cc.saving_percentage_actual
  ) > 0.05;