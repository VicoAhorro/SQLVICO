create table public.contract_incidents (
  id uuid not null default gen_random_uuid (),
  contract_id uuid null,
  incident_type_id integer null,
  user_id uuid null,
  custom_description text null,
  status public.incident_status_type null default 'pendiente'::incident_status_type,
  resolved_by uuid null,
  resolved_at timestamp without time zone null,
  created_at timestamp without time zone null default now(),
  custom_response text null,
  constraint contract_incidents_pkey primary key (id),
  constraint contract_incidents_contract_id_fkey foreign KEY (contract_id) references clients_contracts (id) on delete CASCADE,
  constraint contract_incidents_incident_type_id_fkey foreign KEY (incident_type_id) references incidents_type (id) on delete set null,
  constraint contract_incidents_resolved_by_fkey foreign KEY (resolved_by) references users (user_id) on delete set null,
  constraint contract_incidents_user_id_fkey foreign KEY (user_id) references users (user_id) on delete set null
) TABLESPACE pg_default;