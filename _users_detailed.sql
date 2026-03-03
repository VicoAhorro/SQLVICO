CREATE OR REPLACE VIEW public._users_detailed WITH (security_invoker='on') AS
 WITH c_latest AS (
         SELECT DISTINCT ON ((lower(c.email))) lower(c.email) AS email_lc,
            NULLIF(btrim(c."DNI"), ''::text) AS dni_client,
            NULLIF(btrim(c."DNI_pdf"), ''::text) AS pdf_dni_client,
            c.created_at
           FROM public.clients c
          WHERE (c.email IS NOT NULL)
          ORDER BY (lower(c.email)), c.created_at DESC
        )
 SELECT u.user_id,
    u.created_at,
    u.email,
    u.role_id,
    u.supervisor_id,
    u.is_admin,
    u.name,
    u.last_name,
    u.crs,
    u.city,
    u.business_name,
    COALESCE(NULLIF(btrim(u.dni), ''::text), c_latest.dni_client) AS dni,
    u.pdf_dni,
    u.cif,
    u.pdf_cif,
    u.type,
    u.contract_signed_date,
    u.phone_number,
    u.pdf_collaboration_contract,
    u.crs_as_supervisor,
    u.imagen,
    us.supervisors,
    r.role AS role_name,
    u.racc,
    concat_ws(' '::text, NULLIF(btrim(u.name), ''::text), NULLIF(btrim(u.last_name), ''::text)) AS full_name,
    u.tenant
   FROM (((public.users u
     LEFT JOIN c_latest ON ((lower(u.email) = c_latest.email_lc)))
     LEFT JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
     LEFT JOIN public.roles r ON ((u.role_id = r.id)));
