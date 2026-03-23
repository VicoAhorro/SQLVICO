create table public.comparison_rates (
  id uuid not null default gen_random_uuid (),
  company text null,
  rate_name text null,
  price_pp1 real null,
  price_pp2 real null,
  price_pp3 real null,
  price_pp4 real null,
  price_pp5 real null,
  price_pp6 real null,
  price_cp1 real null,
  price_cp2 real null,
  price_cp3 real null,
  price_cp4 real null,
  price_cp5 real null,
  price_cp6 real null,
  type text null,
  selfconsumption boolean null,
  price_surpluses real null,
  invoice_month integer null,
  invoice_year integer null,
  subrate_name text null,
  cif boolean null default false,
  region text[] null,
  has_maintenance boolean not null default false,
  daily_maintenance_with_vat numeric not null default '0'::numeric,
  has_permanence boolean null,
  rate_mode public.rate_mode_type null,
  last_update timestamp without time zone not null default now(),
  deleted boolean not null default false,
  tenant_id integer[] not null default '{0,1,2,3}'::integer[],
  min_power real null,
  max_power real null,
  min_consumption real null,
  max_consumption real null,
  term_month numeric null,
  has_gdo boolean not null default false,
  ssaa text null,
  constraint comparison_rates_duplicate_pkey primary key (id)
) TABLESPACE pg_default;

create index IF not exists comparison_rates_duplicate_type_company_idx on public.comparison_rates using btree (type, company) TABLESPACE pg_default;

create index IF not exists comparison_rates_duplicate_type_subrate_name_invoice_year_i_idx on public.comparison_rates using btree (type, subrate_name, invoice_year, invoice_month) TABLESPACE pg_default;

create index IF not exists comparison_rates_duplicate_type_subrate_name_idx on public.comparison_rates using btree (type, subrate_name) TABLESPACE pg_default
where
  (
    (invoice_month is null)
    and (invoice_year is null)
  );

create index IF not exists comparison_rates_duplicate_type_selfconsumption_idx on public.comparison_rates using btree (type, selfconsumption) TABLESPACE pg_default;

create index IF not exists comparison_rates_duplicate_company_idx on public.comparison_rates using btree (company) TABLESPACE pg_default;

create index IF not exists comparison_rates_duplicate_region_idx on public.comparison_rates using gin (region) TABLESPACE pg_default;

create index IF not exists comparison_rates_duplicate_rate_mode_idx on public.comparison_rates using btree (rate_mode) TABLESPACE pg_default;
