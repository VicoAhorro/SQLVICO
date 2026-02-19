create view public._contracts_optimized as
select
  c.id,
  c.status,
  c.contract_type,
  cl.name as client_name,
  cl.last_name as client_last_name,
  case
    when length(
      TRIM(
        both
        from
          c."CUPS"
      )
    ) = 22 then "left" (
      TRIM(
        both
        from
          c."CUPS"
      ),
      20
    )
    else TRIM(
      both
      from
        c."CUPS"
    )
  end as "CUPS",
  c.in_process_substatus,
  c.created_at,
  c.saving_percentage,
  c.crs,
  c.subestadocompanias as subestado_companias,
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
        array_cat(us.supervisors, array_agg(ur.user_id)) as array_cat
      from
        users_racc ur
    )
    else us.supervisors
  end as supervisors,
  array[c.contract_type, 'All'::text] as contract_type_filter,
  array[c.advisor_id::text, 'All'::text] as advisor_filter,
  concat_ws(
    ' '::text,
    c.id::text,
    c.created_at::text,
    c.client_email,
    c.contract_type,
    c.status,
    cl.name,
    cl.last_name,
    u.email,
    case
      when length(
        TRIM(
          both
          from
            c."CUPS"
        )
      ) = 22 then "left" (
        TRIM(
          both
          from
            c."CUPS"
        ),
        20
      )
      else TRIM(
        both
        from
          c."CUPS"
      )
    end,
    cl.phone_number
  ) as search,
  to_char(c.created_at, 'MM'::text) as created_month,
  to_char(c.created_at, 'YYYY'::text) as created_year,
  c.deleted,
  array[c.new_company, 'All'::text] as new_company_filter,
  u.racc as is_racc,
  c.last_update,
  cl.phone_number,
  array[c.subestadocompanias, 'All'::text] as contract_subestatus_filter
from
  clients_contracts c
  left join clients cl on c.client_id = cl.id
  left join users u on c.advisor_id = u.user_id
  left join _users_supervisors us on c.advisor_id = us.user_id;