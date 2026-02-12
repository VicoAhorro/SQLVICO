create view public._valuations_detailed_optimized as
select distinct
  on (v.id) v.id,
  v.contract_id,
  v.contract_type,
  case
    when v.client_email is null
    or v.client_email = ''::text then v.temp_client_name
    else COALESCE(cl.name, v.temp_client_name)
  end as temp_client_name,
  case
    when v.client_email is null
    or v.client_email = ''::text then v.temp_client_last_name
    else COALESCE(cl.last_name, v.temp_client_last_name)
  end as temp_client_last_name,
  v."CUPS",
  v.saving_percentage,
  v.crs,
  v.deleted,
  case
    when u.racc = true then (
      select
        array_cat(us.supervisors, array_agg(ur.user_id)) as array_cat
      from
        users_racc ur
    )
    else us.supervisors
  end as supervisors,
  array[v.contract_type, 'All'::text] as contract_type_filter,
  array[v.advisor_id::text, 'All'::text] as advisor_filter,
  concat_ws(
    ' '::text,
    v.client_email,
    v.temp_client_name,
    v.temp_client_last_name,
    v.contract_type,
    u.email,
    v."CUPS",
    cl.name,
    cl.last_name,
    cl."DNI",
    cl.phone_number,
    v.temp_mobile_number
  ) as search,
  to_char(v.created_at, 'MM'::text) as created_month,
  to_char(v.created_at, 'YYYY'::text) as created_year,
  array[v.new_company, 'All'::text] as new_company_filter,
  v.created_at,
  v.client_email,
  v.deleted_reason
from
  clients_valuations v
  left join _users_supervisors us on v.advisor_id = us.user_id
  left join clients cl on v.client_email = cl.email
  and v.client_email <> ''::text
  left join users u on v.advisor_id = u.user_id;