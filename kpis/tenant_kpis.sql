create or replace function public.tenant_kpis(
  p_from text default null,
  p_to   text default null
)
returns table (
  tenant_id int,
  tenant_name text,
  clientes_totales bigint,
  vals_totales bigint,
  vals_firmadas bigint,
  vals_pendientes bigint,
  vals_rechazadas bigint,
  vals_to_contracts bigint,
  contratos_totales bigint,
  contratos_activos bigint,
  contratos_bajas_totales bigint,
  contratos_firmados bigint,
  contratos_pendientes bigint,
  contratos_rechazados bigint,
  comps_totales bigint,
  comps_to_valuations bigint
)
language sql
stable
security definer
set search_path = public
set statement_timeout = '50s'  -- ✅ esta línea es válida y se aplicará en llamadas RPC
as $$
with args as (
  select
    coalesce(to_timestamp(nullif(p_from,'null'), 'DD/MM/YYYY'),'-infinity'::timestamp) as dfrom,
    coalesce(to_timestamp(nullif(p_to,'null'), 'DD/MM/YYYY') + interval '1 day',now()) as dto
),
clientes_por_advisor as (
  select
    u.tenant,
    count(*) as clientes_totales
  from clients c
  join users u on u.user_id = c.advisor_id and u.deleted = false
  join args a on true
  where c.created_at >= a.dfrom and c.created_at < a.dto
  group by u.tenant
),
valoraciones as (
  select
    u.tenant,
    count(*) filter (where v.created_at >= a.dfrom and v.created_at < a.dto) as vals_totales,
    count(*) filter (where v.contract_id is not null
                     and coalesce(v.signature_date, v.created_at) >= a.dfrom
                     and coalesce(v.signature_date, v.created_at) <  a.dto) as vals_firmadas,
    count(*) filter (where v.contract_id is null and coalesce(v.deleted,false) = false
                     and v.created_at >= a.dfrom and v.created_at < a.dto) as vals_pendientes,
    count(*) filter (where v.contract_id is null and coalesce(v.deleted,false) = true
                     and v.created_at >= a.dfrom and v.created_at < a.dto) as vals_rechazadas,
    count(*) filter (where v.contract_id is not null
                     and coalesce(v.signature_date, v.created_at) >= a.dfrom
                     and coalesce(v.signature_date, v.created_at) <  a.dto) as vals_to_contracts
  from _valuations_detailed v
  join users u on u.user_id = v.advisor_id and u.deleted = false
  join args a on true
  group by u.tenant
),
contratos as (
  select
    u.tenant,
    count(*) filter (where cc.deleted = false
                     and cc.created_at >= a.dfrom and cc.created_at < a.dto) as contratos_totales,
    count(*) filter (where coalesce(
                        case when cc.activo is not null then cc.activo
                             else (cc.activation_date is not null and cc.fecha_baja is null and cc.deleted = false)
                        end,false)
                     and cc.activation_date >= a.dfrom and cc.activation_date < a.dto) as contratos_activos,
    count(*) filter (where cc.fecha_baja is not null and cc.deleted = false
                     and cc.fecha_baja >= a.dfrom and cc.fecha_baja < a.dto) as contratos_bajas_totales,
    count(*) filter (where cc.firma_date is not null and cc.deleted = false
                     and cc.firma_date >= a.dfrom and cc.firma_date < a.dto) as contratos_firmados,
    count(*) filter (where cc.status = 'PENDIENTE_FIRMA' and cc.deleted = false
                     and cc.last_update >= a.dfrom and cc.last_update < a.dto) as contratos_pendientes,
    count(*) filter (where cc.status = 'RECHAZADO' and cc.deleted = false
                     and cc.last_update >= a.dfrom and cc.last_update < a.dto) as contratos_rechazados
  from clients_contracts cc
  join users u on u.user_id = cc.advisor_id and u.deleted = false
  join args a on true
  group by u.tenant
),
comparativas as (
  select
    u.tenant,
    count(*) filter (where v.created_at >= a.dfrom and v.created_at < a.dto) as comps_totales,
    count(*) filter (where v.valuation_id is not null
                     and v.created_at >= a.dfrom and v.created_at < a.dto) as comps_to_valuations
  from mat_comparisons_historic v
  left join users u on u.user_id = v.advisor_id
  join args a on true
  group by u.tenant
)
select
  t.id as tenant_id,
  t.name as tenant_name,
  coalesce(cpa.clientes_totales,0) as clientes_totales,
  coalesce(val.vals_totales,0) as vals_totales,
  coalesce(val.vals_firmadas,0) as vals_firmadas,
  coalesce(val.vals_pendientes,0) as vals_pendientes,
  coalesce(val.vals_rechazadas,0) as vals_rechazadas,
  coalesce(val.vals_to_contracts,0) as vals_to_contracts,
  coalesce(ct.contratos_totales,0) as contratos_totales,
  coalesce(ct.contratos_activos,0) as contratos_activos,
  coalesce(ct.contratos_bajas_totales,0) as contratos_bajas_totales,
  coalesce(ct.contratos_firmados,0) as contratos_firmados,
  coalesce(ct.contratos_pendientes,0) as contratos_pendientes,
  coalesce(ct.contratos_rechazados,0) as contratos_rechazados,
  coalesce(cp.comps_totales,0) as comps_totales,
  coalesce(cp.comps_to_valuations,0) as comps_to_valuations
from tenant t
left join clientes_por_advisor cpa on cpa.tenant = t.id
left join valoraciones val on val.tenant = t.id
left join contratos ct on ct.tenant = t.id
left join comparativas cp on cp.tenant = t.id
order by t.id;
$$;
