create view public._clients_detailed as
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
    case
      when (
        (
          select
            u2.racc
          from
            users u2
          where
            u2.user_id = c.advisor_id
          limit
            1
        )
      ) = true then (
        select
          array_cat(us.supervisors, array_agg(users_racc.user_id)) as array_cat
        from
          users_racc
      )
      else us.supervisors
    end,
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
  (
    select
      u2.racc
    from
      users u2
    where
      u2.user_id = c.advisor_id
    limit
      1
  ) as is_racc,
  c.apellido_representante
from
  clients c
  left join _users_supervisors us on c.advisor_id = us.user_id
  left join _clients_total_savings ts on c.email = ts.client_email;