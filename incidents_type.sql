create table public.incidents_type (
  id serial not null,
  parent_id integer null,
  name character varying(255) not null,
  whatsapp_template_id smallint null,
  whatsapp_text text null,
  constraint incidents_type_pkey primary key (id),
  constraint incidents_type_parent_id_fkey foreign KEY (parent_id) references incidents_type (id) on delete CASCADE
) TABLESPACE pg_default;