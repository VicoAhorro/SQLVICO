create table public.renewals_racc (
  document_identity character varying(50) null,
  document_type character varying(20) null,
  first_name character varying(255) null,
  last_name character varying(255) null,
  client_type character varying(20) null,
  phone character varying(50) null,
  email character varying(255) null,
  cups character varying(50) null,
  energy_type text null,
  min_creation_date date null,
  contract_date date null,
  sign_date date null,
  current_company character varying(100) null,
  current_rate_type character varying(20) null,
  current_energy_price numeric(12, 6) null,
  current_power_price numeric(12, 6) null,
  annual_consumption numeric(14, 2) null,
  current_savings_percentage numeric(7, 4) null,
  proposed_company character varying(100) null,
  proposed_rate_type character varying(20) null,
  proposed_savings_percentage numeric(7, 4) null,
  id uuid not null default gen_random_uuid (),
  current_crs numeric(12, 2) null,
  proposed_crs numeric(12, 2) null,
  lost_crs numeric(12, 2) null,
  net_crs_gain numeric(12, 2) null,
  current_price_cp1 numeric(12, 6) null,
  current_price_cp2 numeric(12, 6) null,
  current_price_cp3 numeric(12, 6) null,
  current_price_cp4 numeric(12, 6) null,
  current_price_cp5 numeric(12, 6) null,
  current_price_cp6 numeric(12, 6) null,
  current_price_pp1 numeric(12, 6) null,
  current_price_pp2 numeric(12, 6) null,
  current_price_pp3 numeric(12, 6) null,
  current_price_pp4 numeric(12, 6) null,
  current_price_pp5 numeric(12, 6) null,
  current_price_pp6 numeric(12, 6) null,
  proposed_price_cp1 numeric(12, 6) null,
  proposed_price_cp2 numeric(12, 6) null,
  proposed_price_cp3 numeric(12, 6) null,
  proposed_price_cp4 numeric(12, 6) null,
  proposed_price_cp5 numeric(12, 6) null,
  proposed_price_cp6 numeric(12, 6) null,
  proposed_price_pp1 numeric(12, 6) null,
  proposed_price_pp2 numeric(12, 6) null,
  proposed_price_pp3 numeric(12, 6) null,
  proposed_price_pp4 numeric(12, 6) null,
  proposed_price_pp5 numeric(12, 6) null,
  proposed_price_pp6 numeric(12, 6) null,
  status public.renewals_status null default 'pending'::renewals_status,
  changed_by uuid null,
  changed_at timestamp without time zone null,
  created_at timestamp without time zone not null default now(),
  updated_at timestamp without time zone not null default now(),
  contract_id uuid null,
  comparison_rate_id uuid null,
  rejected_type text null,
  proposed_savings_yearly numeric(12, 2) null,
  proposed_savings_monthly numeric(12, 2) null,
  constraint renewals_racc_pkey primary key (id),
  constraint renewals_racc_changed_by_fkey foreign KEY (changed_by) references users (user_id),
  constraint renewals_racc_rejected_type_fkey foreign KEY (rejected_type) references renewal_rejected_type (name),
  constraint ck_renewals_racc_client_type check (
    (
      (client_type is null)
      or (
        (client_type)::text = any (
          (
            array[
              'Particular'::character varying,
              'Empresa'::character varying
            ]
          )::text[]
        )
      )
    )
  ),
  constraint ck_renewals_racc_proposed_rate_type check (
    (
      (proposed_rate_type is null)
      or (
        (proposed_rate_type)::text = any (
          (
            array[
              'Fija'::character varying,
              'Indexada'::character varying
            ]
          )::text[]
        )
      )
    )
  ),
  constraint ck_renewals_racc_current_rate_type check (
    (
      (current_rate_type is null)
      or (
        (current_rate_type)::text = any (
          (
            array[
              'Fija'::character varying,
              'Indexada'::character varying
            ]
          )::text[]
        )
      )
    )
  ),
  constraint ck_renewals_racc_document_type check (
    (
      (document_type is null)
      or (
        (document_type)::text = any (
          (
            array[
              'DNI'::character varying,
              'NIE'::character varying,
              'CIF'::character varying
            ]
          )::text[]
        )
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_renewals_racc_document_identity on public.renewals_racc using btree (document_identity) TABLESPACE pg_default;

create index IF not exists idx_renewals_racc_email on public.renewals_racc using btree (email) TABLESPACE pg_default;

create index IF not exists idx_renewals_racc_cups on public.renewals_racc using btree (cups) TABLESPACE pg_default;

create index IF not exists idx_renewals_racc_current_company on public.renewals_racc using btree (current_company) TABLESPACE pg_default;

create index IF not exists idx_renewals_racc_contract_date on public.renewals_racc using btree (contract_date) TABLESPACE pg_default;