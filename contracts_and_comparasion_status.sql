create or replace view public._contracts_and_comparasion_status as
select
  null::uuid as comparison_id,
  c.contract_type,
  c.status,
  c.created_at,
  null::numeric as savings_yearly,
  null::text as pdf_proposal,
  c.last_update
from
  clients_contracts c
where
  c.client_email = (auth.jwt () ->> 'email'::text)
  and c.status <> 'ACEPTADO'::text
union all
select
  d.id as comparison_id,
  d.type as contract_type,
  'COMPARATIVA'::text as status,
  d.created_at,
  d.savings_yearly,
  v.pdf_proposal,
  null::timestamp without time zone as last_update
from
  _comparisons_detailed d
  join _valuations_detailed v on v.id = d.valuation_id
where
  d.client_email = (auth.jwt () ->> 'email'::text)
  and d.deleted = false
  and v.deleted = false
  and v.contract_id is null
union all
select
  s.id as comparison_id,
  'seguros'::text as contract_type,
  'COMPARATIVA'::text as status,
  s.created_at,
  null::numeric as savings_yearly,
  null::text as pdf_proposal,
  null::timestamp without time zone as last_update
from
  comparison_seguros s
where
  s.client_email = (auth.jwt () ->> 'email'::text)
  and (
    s.deleted is null
    or s.deleted = false
  );