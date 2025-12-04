create or replace view public.v_contracts_decomision_hoy as
with pagos as (
  select contract_id, coalesce(sum(p."crs cobrado"), 0) as total_cobrado
  from public.clients_contracts_payments p
  group by contract_id
),
contratos as (
  select
    c.id as contract_id,
    c."CUPS" as cups,
    c.contract_type,
    upper(trim(coalesce(c.new_company, ''))) as new_company,
    coalesce(c.crs, 0) as crs_base,
    c.activation_date::date as activation_date,
    coalesce(p.total_cobrado, 0) as total_cobrado
  from public.clients_contracts c
  left join pagos p on p.contract_id = c.id
),
calc as (
  select *,
    case
      when new_company in ('BASSOLS','IMAGINA','LOGOS','PLENITUDE','CYE','GALP','ELEIA')
           and activation_date is not null
        then least(greatest((current_date - activation_date) / 365.0, 0), 1.0)
      else 1.0
    end as porcentaje
  from contratos
)
select
  contract_id,
  cups,
  contract_type,
  new_company,
  crs_base,
  round((crs_base * porcentaje)::numeric, 2) as decomision_hoy,
  total_cobrado,
  round(((crs_base * porcentaje) - total_cobrado)::numeric, 2) as pendiente
from calc;
