create or replace function public.tenant_kpis_range(
  p_tenant_id int,
  p_entity_id text default null,           -- ✅ cambiado a text
  p_role_id   text default null,
  p_supervisor_id text default null,
  p_from      text default null,
  p_to        text default null
)
returns table (
  tenant_id int,
  entity_id uuid,
  entity_name text,
  entity_email text,
  role_id uuid,
  supervisor_id uuid,
  clientes_totales int,
  vals_totales int,
  vals_firmadas int,
  vals_pendientes int,
  vals_rechazadas int,
  vals_to_contracts int,
  contratos_totales int,
  contratos_activos int,
  contratos_bajas_totales int,
  contratos_firmados int,
  contratos_pendientes int,
  contratos_rechazados int,
  comps_totales int,
  comps_to_valuations int
)
language sql
stable
security definer
set search_path = public
set statement_timeout = '20s'   -- ✅ válido en Supabase RPC
as $$
with args as (
  select
    p_tenant_id as tenant_id,
    coalesce(to_timestamp(nullif(p_from,'null'), 'DD/MM/YYYY'), '-infinity'::timestamp) as dfrom,
    coalesce(to_timestamp(nullif(p_to,'null'),   'DD/MM/YYYY') + interval '1 day', now()) as dto,
    nullif(p_entity_id,'null')::uuid        as entity_uuid,       -- ✅ convertido internamente
    nullif(p_role_id,'null')::uuid          as role_uuid,
    nullif(p_supervisor_id,'null')::uuid    as supervisor_uuid
),
base_entities as (
  select 
    u.tenant as tenant_id,
    u.user_id as entity_id,
    u.role_id,
    u.supervisor_id,
    u.name as entity_name,
    u.email as entity_email
  from public.users u
  join args a on true
  where u.deleted = false
    and u.tenant = a.tenant_id
    and (a.entity_uuid is null or u.user_id = a.entity_uuid)   -- ✅ ahora compara bien
    and (a.role_uuid is null or u.role_id = a.role_uuid)
    and (a.supervisor_uuid is null or u.supervisor_id = a.supervisor_uuid)
),
cli as (
  select u.user_id as entity_id, count(*) as clientes_totales
  from public.clients c
  join public.users u on u.user_id = c.advisor_id and u.deleted = false
  join args a on true
  join base_entities be on be.entity_id = u.user_id
  where c.created_at >= a.dfrom and c.created_at < a.dto
  group by u.user_id
),
val as (
  select u.user_id as entity_id,
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
  from public._valuations_detailed v
  join public.users u on u.user_id = v.advisor_id and u.deleted = false
  join args a on true
  join base_entities be on be.entity_id = u.user_id
  group by u.user_id
),
ctr as (
  select u.user_id as entity_id,
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
  from public.clients_contracts cc
  join public.users u on u.user_id = cc.advisor_id and u.deleted = false
  join args a on true
  join base_entities be on be.entity_id = u.user_id
  group by u.user_id
),
cmp as (
  select u.user_id as entity_id,
    count(*) filter (where v.created_at >= a.dfrom and v.created_at < a.dto) as comps_totales,
    count(*) filter (where v.valuation_id is not null 
                     and v.created_at >= a.dfrom and v.created_at < a.dto) as comps_to_valuations
  from public.mat_comparisons_historic v
  join public.users u on u.user_id = v.advisor_id and u.deleted = false
  join args a on true
  join base_entities be on be.entity_id = u.user_id
  group by u.user_id
)
select 
  be.tenant_id,
  be.entity_id,
  be.entity_name,
  be.entity_email,
  be.role_id,
  be.supervisor_id,
  coalesce(cli.clientes_totales,0),
  coalesce(val.vals_totales,0),
  coalesce(val.vals_firmadas,0),
  coalesce(val.vals_pendientes,0),
  coalesce(val.vals_rechazadas,0),
  coalesce(val.vals_to_contracts,0),
  coalesce(ctr.contratos_totales,0),
  coalesce(ctr.contratos_activos,0),
  coalesce(ctr.contratos_bajas_totales,0),
  coalesce(ctr.contratos_firmados,0),
  coalesce(ctr.contratos_pendientes,0),
  coalesce(ctr.contratos_rechazados,0),
  coalesce(cmp.comps_totales,0),
  coalesce(cmp.comps_to_valuations,0)
from base_entities be
left join cli on cli.entity_id = be.entity_id
left join val on val.entity_id = be.entity_id
left join ctr on ctr.entity_id = be.entity_id
left join cmp on cmp.entity_id = be.entity_id
order by be.entity_name nulls last, be.entity_id;
$$;
