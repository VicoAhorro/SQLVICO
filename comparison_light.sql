create table public.comparison_light (
  id uuid not null default gen_random_uuid (),
  created_at timestamp without time zone not null default now(),
  client_email text null,
  advisor_id uuid null,
  consumption_p1 real not null default '0'::real,
  consumption_p2 real not null default '0'::real,
  consumption_p3 real not null default '0'::real,
  power_p1 real not null default '0'::real,
  power_p2 real not null default '0'::real,
  current_total_invoice real not null default '0'::real,
  surpluses real not null default '0'::real,
  "VAT" real not null default '0'::real,
  power_days integer not null default 0,
  pdf_invoice text not null default ''::text,
  proposal_date timestamp without time zone null,
  "CUPS" text not null default ''::text,
  address_id uuid null,
  company text not null default ''::text,
  rate_name text not null default ''::text,
  invoice_month integer null,
  equipment_rental real not null default '0'::real,
  selfconsumption boolean not null default false,
  manual_data boolean not null default false,
  valuation_id uuid null,
  invoice_year integer null,
  temp_client_name text not null default ''::text,
  temp_client_last_name text not null default ''::text,
  deleted boolean not null default false,
  deleted_reason text null,
  preferred_subrate text null,
  anual_consumption_p1 real null,
  anual_consumption_p2 real null,
  anual_consumption_p3 real null,
  max_power real null,
  "precio_kwh_P1" real not null default '0'::real,
  "precio_kwh_P2" real not null default '0'::real,
  "precio_kwh_P3" real not null default '0'::real,
  "precio_kw_P1" real not null default '0'::real,
  "precio_kw_P2" real not null default '0'::real,
  autoconsumo_precio real null default '0'::real,
  totalconsumo real null,
  totalpotencia real null,
  tarifa_plana boolean null,
  cif boolean null default false,
  region text null default 'PENINSULA'::text,
  source_type_id bigint not null default 0,
  wants_permanence boolean null,
  total_excedentes_precio real not null default 0,
  comparison_id uuid null,
  invoice_address text null,
  term_month_i_want numeric null,
  deleted_at timestamp without time zone null,
  excluded_company_ids uuid[] not null default '{}'::uuid[],
  wants_gdo boolean not null default false,
  temp_client_phone text null,
  constraint comparison_light_pkey primary key (id),
  constraint comparison_light_address_id_fkey foreign KEY (address_id) references clients_addresses (id),
  constraint comparison_light_advisor_id_fkey foreign KEY (advisor_id) references auth.users (id) on delete set null,
  constraint comparison_light_comparison_id_fkey foreign KEY (comparison_id) references comparisons (id) on delete CASCADE,
  constraint comparison_light_source_type_id_fkey foreign KEY (source_type_id) references source_type (id) on update CASCADE on delete set default,
  constraint comparison_light_valuation_id_fkey foreign KEY (valuation_id) references clients_valuations (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_comparison_light_deleted_false on public.comparison_light using btree (id) TABLESPACE pg_default
where
  (deleted = false);

create index IF not exists idx_comparison_light_created_at on public.comparison_light using btree (created_at) TABLESPACE pg_default;

create index IF not exists idx_comparison_light_advisor on public.comparison_light using btree (advisor_id) TABLESPACE pg_default;

create index IF not exists idx_comparison_light_selfconsumption on public.comparison_light using btree (selfconsumption) TABLESPACE pg_default;

create trigger trg_set_deleted_at BEFORE
update on comparison_light for EACH row
execute FUNCTION set_deleted_at_on_delete ();