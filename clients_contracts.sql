create table public.clients_contracts (
  id uuid not null default gen_random_uuid (),
  created_at timestamp without time zone not null default now(),
  business_id uuid null,
  client_email text null,
  advisor_id uuid null,
  contract_type text null,
  status text null,
  activation_date timestamp without time zone null,
  last_update timestamp without time zone null,
  payment_date timestamp without time zone null,
  firma_date timestamp without time zone null,
  "CUPS" text null,
  saving_percentage real not null default '0'::real,
  client_address_id uuid null,
  selfconsumption boolean null,
  ownership_change boolean not null default false,
  ownership_change_pdf text null,
  power_change boolean not null default false,
  power_change_new_value real null,
  paper_invoices boolean not null default false,
  new_registration boolean not null default false,
  account_number text null,
  account_ownership_pdf text null,
  new_company text null,
  in_process_substatus text null,
  incident_reason text null,
  delegated_signature boolean not null default false,
  delegated_signature_email text null,
  pdf_contract text null,
  max_power real null,
  crs real not null default '0'::real,
  pdf_invoice text null,
  new_rate text null,
  new_subrate text null,
  idrow_glide text null,
  client_id uuid null,
  "contratoreprePDF" text null,
  activo boolean null,
  precioconsumop2 real null,
  precioconsumop1 real null,
  precioconsumop3 real null,
  precioconsumop4 real null,
  precioconsumop5 real null,
  precioconsumop6 real null,
  preciopotencia1 real null,
  preciopotencia2 real null,
  preciopotencia3 real null,
  preciopotencia4 real null,
  preciopotencia5 real null,
  preciopotencia6 real null,
  potenciacontratadap1 real null,
  potenciacontratadap2 real null,
  potenciacontratadap3 real null,
  potenciacontratadap4 real null,
  potenciacontratadap5 real null,
  potenciacontratadap6 real null,
  consumoanualp1 real null,
  consumoanualp2 real null,
  consumoanualp3 real null,
  consumoanualp4 real null,
  consumoanualp5 real null,
  consumoanualp6 real null,
  iddocusign text null,
  subestadocompanias text null,
  motivo_rechazo text null,
  fecha_baja date null,
  representacion boolean null,
  comentario_tarifa text null,
  baja_firma_delegada date null,
  deleted boolean not null default false,
  deleted_reason text not null default ' '::text,
  fecha_prevista_renovacion date null,
  cif boolean null default false,
  region text null default 'PENINSULA'::text,
  is_carga_contrato boolean null,
  has_permanence boolean not null default false,
  deleted_at timestamp without time zone null,
  deleted_by uuid null,
  cie_pdf text null,
  insurance_type text null,
  constraint clients_contracts_pkey primary key (id),
  constraint clients_contracts_advisor_id_fkey foreign KEY (advisor_id) references auth.users (id) on delete set null,
  constraint clients_contracts_business_id_fkey foreign KEY (business_id) references business (id),
  constraint clients_contracts_client_address_id_fkey foreign KEY (client_address_id) references clients_addresses (id) on delete set null,
  constraint clients_contracts_client_id_fkey foreign KEY (client_id) references clients (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_contracts_advisor_created on public.clients_contracts using btree (advisor_id, created_at) TABLESPACE pg_default;

create index IF not exists idx_contracts_activation on public.clients_contracts using btree (advisor_id, activation_date) TABLESPACE pg_default;

create index IF not exists idx_contracts_firma on public.clients_contracts using btree (advisor_id, firma_date) TABLESPACE pg_default;

create index IF not exists idx_contracts_baja on public.clients_contracts using btree (advisor_id, fecha_baja) TABLESPACE pg_default;

create index IF not exists idx_contracts_last_update on public.clients_contracts using btree (advisor_id, last_update) TABLESPACE pg_default;

create index IF not exists idx_contracts_advisor_status on public.clients_contracts using btree (advisor_id, status) TABLESPACE pg_default;

create index IF not exists idx_contracts_status on public.clients_contracts using btree (status) TABLESPACE pg_default;

create index IF not exists idx_cc_active_status_effective_ts on public.clients_contracts using btree (
  status,
  in_process_substatus,
  COALESCE(last_update, created_at),
  id
) TABLESPACE pg_default
where
  (deleted = false);

create index IF not exists idx_cc_active_advisor_status_effective_ts on public.clients_contracts using btree (
  advisor_id,
  status,
  in_process_substatus,
  COALESCE(last_update, created_at),
  id
) TABLESPACE pg_default
where
  (deleted = false);

create trigger trg_set_deleted_at BEFORE
update on clients_contracts for EACH row
execute FUNCTION set_deleted_at_on_delete ();

create trigger trg_sync_contracts_index
after INSERT
or
update on clients_contracts for EACH row
execute FUNCTION fn_sync_contracts_search_index ();