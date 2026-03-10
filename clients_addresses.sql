create table public.clients_addresses (
  id uuid not null default gen_random_uuid (),
  created_at timestamp without time zone not null default now(),
  alias text null,
  client_email text null,
  address text null,
  client_id uuid null,
  latitude numeric(9, 6) null,
  longitude numeric(9, 6) null,
  floor text null,
  door text null,
  stairs text null,
  block text null,
  constraint users_addresses_pkey primary key (id),
  constraint clients_addresses_client_id_fkey foreign KEY (client_id) references clients (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_clients_addresses_client_id on public.clients_addresses using btree (client_id) TABLESPACE pg_default;