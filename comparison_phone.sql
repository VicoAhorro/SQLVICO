create table public.comparison_phone (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  client_email text null,
  advisor_id uuid null,
  current_total_invoice numeric(12, 2) null default 0,
  company text null,
  speed_fiber integer null,
  mobile_total_gb integer null,
  mobile_lines integer null,
  pdf_invoice text null,
  valuation_id uuid null,
  deleted boolean null default false,
  deleted_reason text null,
  rate_type text not null,
  landline boolean not null default false,
  temp_client_name text null,
  temp_client_last_name text null,
  temp_client_phone text null,
  installation_address text null,
  source_type_id bigint not null default 0,
  wants_permanence boolean null,
  deleted_at timestamp without time zone null,
  region text null default 'PENINSULA'::text,
  constraint comparison_phone_pkey primary key (id),
  constraint comparison_phone_advisor_id_fkey foreign KEY (advisor_id) references users (user_id) on delete RESTRICT,
  constraint comparison_phone_source_type_id_fkey foreign KEY (source_type_id) references source_type (id) on update CASCADE on delete set default,
  constraint comparison_phone_valuation_id_fkey foreign KEY (valuation_id) references clients_valuations (id) on delete RESTRICT
) TABLESPACE pg_default;

create index IF not exists idx_comparison_phone_speed_lines on public.comparison_phone using btree (speed_fiber, mobile_lines, mobile_total_gb) TABLESPACE pg_default;

create index IF not exists idx_comparison_phone_deleted_false on public.comparison_phone using btree (id) TABLESPACE pg_default
where
  (deleted = false);

create index IF not exists idx_comparison_phone_created_at on public.comparison_phone using btree (created_at) TABLESPACE pg_default;

create index IF not exists idx_comparison_phone_advisor on public.comparison_phone using btree (advisor_id) TABLESPACE pg_default;

create index IF not exists idx_comparison_phone_match on public.comparison_phone using btree (
  rate_type,
  speed_fiber,
  mobile_lines,
  mobile_total_gb,
  landline
) TABLESPACE pg_default;

create trigger trg_set_deleted_at BEFORE
update on comparison_phone for EACH row
execute FUNCTION set_deleted_at_on_delete ();