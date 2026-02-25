create table public.contracts_search_index (
  id uuid not null,
  client_name text null,
  client_last_name text null,
  cups text null,
  supervisors uuid[] null,
  contract_type_filter text[] null,
  advisor_filter text[] null,
  new_company_filter text[] null,
  contract_subestatus_filter text[] null,
  search text null,
  created_month text null,
  created_year text null,
  created_at timestamp without time zone null,
  deleted boolean null,
  is_racc boolean null,
  constraint contracts_search_index_pkey primary key (id),
  constraint contracts_search_index_id_fkey foreign KEY (id) references clients_contracts (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_csi_supervisors on public.contracts_search_index using gin (supervisors) TABLESPACE pg_default;

create index IF not exists idx_csi_search on public.contracts_search_index using gin (search gin_trgm_ops) TABLESPACE pg_default;

create index IF not exists idx_csi_advisor on public.contracts_search_index using gin (advisor_filter) TABLESPACE pg_default;

create index IF not exists idx_csi_created_at on public.contracts_search_index using btree (created_at desc) TABLESPACE pg_default;