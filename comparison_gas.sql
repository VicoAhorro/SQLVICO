create table public.comparison_gas (
  id uuid not null default gen_random_uuid (),
  created_at timestamp without time zone not null default now(),
  client_email text null,
  consumption real not null default '0'::real,
  current_total_invoice real not null default '0'::real,
  days integer not null default 0,
  "VAT" real not null default '0'::real,
  meter_rental real not null default '0'::real,
  advisor_id uuid null,
  proposal_date timestamp without time zone null,
  "CUPS" text not null default ''::text,
  pdf_invoice text not null default ''::text,
  address_id uuid null,
  rate_name text not null default ''::text,
  manual_data boolean not null default false,
  equipment_rental real not null default '0'::real,
  valuation_id uuid null,
  invoice_month integer null,
  invoice_year integer null,
  company text not null default ''::text,
  temp_client_name text not null default ''::text,
  temp_client_last_name text not null default ''::text,
  deleted boolean not null default false,
  deleted_reason text null,
  preferred_subrate text null,
  anual_consumption real null,
  precio actual kw real null,
  precio fijo actual dia real null,
  totalconsumo real null,
  totalfijo real null,
  region text null default 'PENINSULA'::text,
  tarifa_plana boolean null default false,
  cif boolean null default false,
  source_type_id bigint null default '0'::bigint,
  wants_permanence boolean null,
  rate_mode public.rate_mode_type null,
  prefered_rate_type public.rate_mode_type null,
  comparison_id uuid null,
  term_month_i_want numeric null,
  invoice_address text null,
  deleted_at timestamp without time zone null,
  excluded_company_ids uuid[] not null default '{}'::uuid[],
  wants_gdo boolean not null default false,
  temp_client_phone text null,
  constraint comparison_gas_pkey primary key (id),
  constraint comparison_gas_address_id_fkey foreign KEY (address_id) references clients_addresses (id),
  constraint comparison_gas_advisor_id_fkey foreign KEY (advisor_id) references users (user_id) on delete set null,
  constraint comparison_gas_comparison_id_fkey foreign KEY (comparison_id) references comparisons (id) on delete CASCADE,
  constraint comparison_gas_source_type_id_fkey foreign KEY (source_type_id) references source_type (id) on update CASCADE on delete set null,
  constraint comparison_gas_valuation_id_fkey foreign KEY (valuation_id) references clients_valuations (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_comparison_gas_deleted_false on public.comparison_gas using btree (id) TABLESPACE pg_default
where
  (deleted = false);

create index IF not exists idx_comparison_gas_created_at on public.comparison_gas using btree (created_at) TABLESPACE pg_default;

create index IF not exists idx_comparison_gas_advisor on public.comparison_gas using btree (advisor_id) TABLESPACE pg_default;

create trigger trg_set_deleted_at BEFORE
update on comparison_gas for EACH row
execute FUNCTION set_deleted_at_on_delete ();