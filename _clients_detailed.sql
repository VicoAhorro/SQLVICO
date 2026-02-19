create or replace view public._clients_detailed as
select
  c.id,
  c.created_at,
  c.name,
  c.email,
  c.photo,
  c.advisor_id,
  c.phone_number,
  c.last_name,
  c."DNI",
  c."DNI_pdf",
  c.client_type,
  c.status,
  c."DNI_expire_date",
  c.birth_date,
  c.inactive,
  c.nombre_representante as business_name,
  c.dni_repre as cif,
  c.cif_pdf,
  COALESCE(
    us.supervisors,
    array['0f317d06-93a8-4b2d-b18d-9a0264e1d288'::uuid]
  ) as supervisors,
  array[c.advisor_id::text, 'All'::text] as advisor_filter,
  COALESCE(ts.total_savings, 0::double precision) as total_savings,
  concat_ws(
    ' '::text,
    c.name,
    c.last_name,
    c.email,
    c.phone_number
  ) as search,
  c.idioma as client_language,
  (ur.user_id is not null) as is_racc,
  c.apellido_representante
from
  public.clients c
  left join public._users_supervisors_all us on c.advisor_id = us.user_id
  left join public.users_racc ur on c.advisor_id = ur.user_id
  left join public._clients_total_savings ts on c.email = ts.client_email;