create table public.clients (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  name text null,
  email text null,
  photo text null,
  advisor_id uuid null,
  phone_number text null,
  last_name text null,
  "DNI" text null,
  "DNI_pdf" text null,
  client_type text null,
  status text null,
  "DNI_expire_date" date null,
  birth_date date null,
  inactive boolean null default false,
  nombre_representante text null,
  dni_repre text null,
  cif_pdf text null,
  apellido_representante text null,
  comentario text null,
  "aceptacionRacc" text null,
  idioma text null,
  constraint clients_pkey primary key (id),
  constraint clients_advisor_id_fkey foreign KEY (advisor_id) references auth.users (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_clients_advisor_id on public.clients using btree (advisor_id) TABLESPACE pg_default;

create index IF not exists idx_clients_email on public.clients using btree (email) TABLESPACE pg_default;

create index IF not exists idx_clients_lower_email on public.clients using btree (lower(email)) TABLESPACE pg_default;

create index IF not exists idx_clients_advisor_created on public.clients using btree (advisor_id, created_at) TABLESPACE pg_default;