create table public.valuations_search_index (
  id uuid not null,
  contract_id uuid null,
  temp_client_name text null,
  cups text null,
  saving_percentage real null,
  crs real null,
  deleted boolean null,
  supervisors uuid[] null,
  contract_type_filter text[] null,
  advisor_filter text[] null,
  new_company_filter text[] null,
  search text null,
  created_month text null,
  created_year text null,
  created_at timestamp without time zone null,
  client_email text null,
  deleted_reason text null,
  temp_client_last_name text null,
  constraint valuations_search_index_pkey primary key (id),
  constraint valuations_search_index_id_fkey foreign KEY (id) references clients_valuations (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_vsi_search on public.valuations_search_index using gin (search gin_trgm_ops) TABLESPACE pg_default;

create index IF not exists idx_vsi_supervisors on public.valuations_search_index using gin (supervisors) TABLESPACE pg_default;

create index IF not exists idx_vsi_advisor on public.valuations_search_index using gin (advisor_filter) TABLESPACE pg_default;

create index IF not exists idx_vsi_created_at on public.valuations_search_index using btree (created_at desc) TABLESPACE pg_default;