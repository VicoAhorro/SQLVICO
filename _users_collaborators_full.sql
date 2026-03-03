CREATE VIEW public._users_collaborators AS
SELECT
    NULL::uuid AS user_id,
    NULL::timestamp without time zone AS created_at,
    NULL::text AS email,
    NULL::uuid AS role_id,
    NULL::uuid AS supervisor_id,
    NULL::boolean AS is_admin,
    NULL::text AS name,
    NULL::text AS last_name,
    NULL::real AS crs,
    NULL::text AS city,
    NULL::text AS business_name,
    NULL::text AS dni,
    NULL::text AS pdf_dni,
    NULL::text AS cif,
    NULL::text AS pdf_cif,
    NULL::text AS type,
    NULL::date AS contract_signed_date,
    NULL::text AS phone_number,
    NULL::text AS pdf_collaboration_contract,
    NULL::real AS crs_as_supervisor,
    NULL::text AS imagen,
    NULL::text AS role_name,
    NULL::text AS supervisor_name,
    NULL::real AS total_crs,
    NULL::real AS crs_difference,
    NULL::text AS account_number,
    NULL::boolean AS deleted,
    NULL::text AS deleted_reason;


ALTER TABLE public._users_collaborators OWNER TO postgres;

--
-- Name: _users_collaborators_monthly_crs; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public._users_collaborators_monthly_crs WITH (security_invoker='on') AS
 WITH months AS (
         SELECT (generate_series(('2020-01-01'::date)::timestamp with time zone, date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone), '1 mon'::interval))::date AS month_start
        ), collaborators AS (
         SELECT u.user_id,
            u.name,
            u.last_name,
            r.role AS role_name,
            u.supervisor_id,
            concat(sup.name, ' ', sup.last_name) AS supervisor_name
           FROM (((public.users u
             JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
             LEFT JOIN public.users sup ON ((u.supervisor_id = sup.user_id)))
             LEFT JOIN public.roles r ON ((u.role_id = r.id)))
          WHERE (auth.uid() = ANY (us.supervisors))
        ), credits AS (
         SELECT cc.advisor_id,
            (date_trunc('month'::text, cc.created_at))::date AS month_start,
            sum(cc.crs) AS total_crs
           FROM public.clients_contracts cc
          GROUP BY cc.advisor_id, ((date_trunc('month'::text, cc.created_at))::date)
        ), payments AS (
         SELECT cc.advisor_id,
            (date_trunc('month'::text, (ccp.fecha_pago)::timestamp with time zone))::date AS month_start,
            sum(ccp."crs cobrado") AS crs_pagados
           FROM (public.clients_contracts_payments ccp
             JOIN public.clients_contracts cc ON ((ccp.contract_id = cc.id)))
          GROUP BY cc.advisor_id, ((date_trunc('month'::text, (ccp.fecha_pago)::timestamp with time zone))::date)
        ), calculated AS (
         SELECT m.month_start,
            c.user_id,
            c.name,
            c.last_name,
            c.role_name,
            c.supervisor_name,
            COALESCE(cr.total_crs, (0)::real) AS total_crs,
            COALESCE(p.crs_pagados, (0)::real) AS crs_pagados,
            to_char((m.month_start)::timestamp with time zone, 'MM/YY'::text) AS formatted_month,
            ( SELECT u_auth.crs_as_supervisor
                   FROM public.users u_auth
                  WHERE (u_auth.user_id = auth.uid())) AS my_crs,
            ( SELECT u.user_id
                   FROM (public.users u
                     JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                  WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup.supervisors) AS unnest
                           FROM public._users_supervisors us_sup
                          WHERE ((us_sup.user_id = c.user_id) AND (auth.uid() = ANY (us_sup.supervisors))))) AND (( SELECT roles.hierarchy
                           FROM public.roles
                          WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                           FROM public.roles
                          WHERE (roles.id = ( SELECT users.role_id
                                   FROM public.users
                                  WHERE (users.user_id = auth.uid()))))))
                  ORDER BY ( SELECT roles.hierarchy
                           FROM public.roles
                          WHERE (roles.id = u.role_id))
                 LIMIT 1) AS immediate_supervised_user_id,
            ( SELECT u_sup.crs_as_supervisor
                   FROM public.users u_sup
                  WHERE (u_sup.user_id = ( SELECT u.user_id
                           FROM (public.users u
                             JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                          WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup2.supervisors) AS unnest
                                   FROM public._users_supervisors us_sup2
                                  WHERE ((us_sup2.user_id = c.user_id) AND (auth.uid() = ANY (us_sup2.supervisors))))) AND (( SELECT roles.hierarchy
                                   FROM public.roles
                                  WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                                   FROM public.roles
                                  WHERE (roles.id = ( SELECT users.role_id
   FROM public.users
  WHERE (users.user_id = auth.uid()))))))
                          ORDER BY ( SELECT roles.hierarchy
                                   FROM public.roles
                                  WHERE (roles.id = u.role_id))
                         LIMIT 1))) AS immediate_supervised_crs,
                CASE
                    WHEN (( SELECT users.is_admin
                       FROM public.users
                      WHERE (users.user_id = auth.uid())) = true) THEN (2.0)::real
                    ELSE (COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = auth.uid())), (0)::real) - COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = ( SELECT u.user_id
                               FROM (public.users u
                                 JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                              WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup2.supervisors) AS unnest
                                       FROM public._users_supervisors us_sup2
                                      WHERE ((us_sup2.user_id = c.user_id) AND (auth.uid() = ANY (us_sup2.supervisors))))) AND (( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = ( SELECT users_1.role_id
    FROM public.users users_1
   WHERE (users_1.user_id = auth.uid()))))))
                              ORDER BY ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id))
                             LIMIT 1))), (0)::real))
                END AS crs_difference,
            (COALESCE(cr.total_crs, (0)::real) *
                CASE
                    WHEN (( SELECT users.is_admin
                       FROM public.users
                      WHERE (users.user_id = auth.uid())) = true) THEN (2.0)::real
                    ELSE (COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = auth.uid())), (0)::real) - COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = ( SELECT u.user_id
                               FROM (public.users u
                                 JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                              WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup2.supervisors) AS unnest
                                       FROM public._users_supervisors us_sup2
                                      WHERE ((us_sup2.user_id = c.user_id) AND (auth.uid() = ANY (us_sup2.supervisors))))) AND (( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = ( SELECT users_1.role_id
    FROM public.users users_1
   WHERE (users_1.user_id = auth.uid()))))))
                              ORDER BY ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id))
                             LIMIT 1))), (0)::real))
                END) AS total_commission,
            (COALESCE(p.crs_pagados, (0)::real) *
                CASE
                    WHEN (( SELECT users.is_admin
                       FROM public.users
                      WHERE (users.user_id = auth.uid())) = true) THEN (2.0)::real
                    ELSE (COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = auth.uid())), (0)::real) - COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = ( SELECT u.user_id
                               FROM (public.users u
                                 JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                              WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup2.supervisors) AS unnest
                                       FROM public._users_supervisors us_sup2
                                      WHERE ((us_sup2.user_id = c.user_id) AND (auth.uid() = ANY (us_sup2.supervisors))))) AND (( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = ( SELECT users_1.role_id
    FROM public.users users_1
   WHERE (users_1.user_id = auth.uid()))))))
                              ORDER BY ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id))
                             LIMIT 1))), (0)::real))
                END) AS total_comision_crs_pagados
           FROM (((months m
             CROSS JOIN collaborators c)
             LEFT JOIN credits cr ON (((c.user_id = cr.advisor_id) AND (m.month_start = cr.month_start))))
             LEFT JOIN payments p ON (((c.user_id = p.advisor_id) AND (m.month_start = p.month_start))))
        )
 SELECT calculated.month_start,
    calculated.user_id,
    calculated.name,
    calculated.last_name,
    calculated.role_name,
    calculated.supervisor_name,
    calculated.total_crs,
    calculated.crs_pagados,
    calculated.formatted_month,
    calculated.my_crs,
    calculated.immediate_supervised_user_id,
    calculated.immediate_supervised_crs,
    calculated.crs_difference,
    calculated.total_commission,
    calculated.total_comision_crs_pagados
   FROM calculated;


ALTER TABLE public._users_collaborators_monthly_crs OWNER TO postgres;

--
-- Name: _users_collaborators_monthly_crs2; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public._users_collaborators_monthly_crs2 WITH (security_invoker='on') AS
 WITH months AS (
         SELECT (generate_series(('2020-01-01'::date)::timestamp with time zone, date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone), '1 mon'::interval))::date AS month_start
        ), collaborators AS (
         SELECT u.user_id,
            u.name,
            u.last_name,
            r.role AS role_name,
            r.hierarchy AS role_hierarchy,
            u.supervisor_id,
            COALESCE(((sup.name || ' '::text) || sup.last_name), 'Admin'::text) AS supervisor_name,
            u.crs_as_supervisor
           FROM (((public.users u
             JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
             LEFT JOIN public.users sup ON ((u.supervisor_id = sup.user_id)))
             LEFT JOIN public.roles r ON ((u.role_id = r.id)))
        ), credits AS (
         SELECT cc.advisor_id,
            (date_trunc('month'::text, cc.created_at))::date AS month_start,
            sum(cc.crs) AS total_crs
           FROM public.clients_contracts cc
          GROUP BY cc.advisor_id, ((date_trunc('month'::text, cc.created_at))::date)
        ), payments AS (
         SELECT cc.advisor_id,
            (date_trunc('month'::text, (ccp.fecha_pago)::timestamp with time zone))::date AS month_start,
            sum(ccp."crs cobrado") AS crs_pagados
           FROM (public.clients_contracts_payments ccp
             JOIN public.clients_contracts cc ON ((ccp.contract_id = cc.id)))
          GROUP BY cc.advisor_id, ((date_trunc('month'::text, (ccp.fecha_pago)::timestamp with time zone))::date)
        ), calculated AS (
         SELECT m.month_start,
            c.user_id,
            c.name,
            c.last_name,
            c.role_name,
            c.role_hierarchy,
            c.supervisor_name,
            COALESCE(cr.total_crs, (0)::real) AS total_crs,
            COALESCE(p.crs_pagados, (0)::real) AS crs_pagados,
            to_char((m.month_start)::timestamp with time zone, 'MM/YY'::text) AS formatted_month,
            COALESCE(c.crs_as_supervisor, (0)::real) AS my_crs,
            COALESCE(u_sup.crs_as_supervisor, (0)::real) AS immediate_supervised_crs,
            COALESCE(c.supervisor_id, NULL::uuid) AS has_supervisor
           FROM ((((months m
             CROSS JOIN collaborators c)
             LEFT JOIN credits cr ON (((c.user_id = cr.advisor_id) AND (m.month_start = cr.month_start))))
             LEFT JOIN payments p ON (((c.user_id = p.advisor_id) AND (m.month_start = p.month_start))))
             LEFT JOIN public.users u_sup ON ((u_sup.user_id = c.supervisor_id)))
        )
 SELECT DISTINCT ON (calculated.month_start, calculated.user_id) calculated.month_start,
    calculated.user_id,
    calculated.name,
    calculated.last_name,
    calculated.role_name,
    calculated.supervisor_name,
    calculated.total_crs,
    calculated.crs_pagados,
    calculated.formatted_month,
    calculated.my_crs,
    calculated.immediate_supervised_crs,
        CASE
            WHEN (calculated.has_supervisor IS NULL) THEN (calculated.my_crs - (1.2)::double precision)
            ELSE ((calculated.my_crs - calculated.immediate_supervised_crs))::double precision
        END AS crs_difference,
    calculated.total_crs AS crs_generated,
    calculated.crs_pagados AS crs_paid,
    GREATEST((
        CASE
            WHEN (calculated.has_supervisor IS NULL) THEN (calculated.my_crs - (1.2)::double precision)
            ELSE ((calculated.my_crs - calculated.immediate_supervised_crs))::double precision
        END * calculated.total_crs), (0)::double precision) AS total_commission,
    GREATEST((
        CASE
            WHEN (calculated.has_supervisor IS NULL) THEN (calculated.my_crs - (1.2)::double precision)
            ELSE ((calculated.my_crs - calculated.immediate_supervised_crs))::double precision
        END * calculated.crs_pagados), (0)::double precision) AS total_comision_crs_pagados
   FROM calculated;


ALTER TABLE public._users_collaborators_monthly_crs2 OWNER TO postgres;

--
-- Name: _users_collaborators_monthly_crs3; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public._users_collaborators_monthly_crs3 WITH (security_invoker='on') AS
 WITH months AS (
         SELECT (generate_series(('2020-01-01'::date)::timestamp with time zone, date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone), '1 mon'::interval))::date AS month_start
        ), collaborators AS (
         SELECT u.user_id,
            u.name,
            u.last_name,
            r.role AS role_name,
            u.supervisor_id,
            concat(sup.name, ' ', sup.last_name) AS supervisor_name
           FROM (((public.users u
             JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
             LEFT JOIN public.users sup ON ((u.supervisor_id = sup.user_id)))
             LEFT JOIN public.roles r ON ((u.role_id = r.id)))
          WHERE (auth.uid() = ANY (us.supervisors))
        ), credits AS (
         SELECT cc.advisor_id,
            (date_trunc('month'::text, cc.created_at))::date AS month_start,
            sum(cc.crs) AS total_crs
           FROM public.clients_contracts cc
          GROUP BY cc.advisor_id, ((date_trunc('month'::text, cc.created_at))::date)
        ), payments AS (
         SELECT cc.advisor_id,
            (date_trunc('month'::text, (ccp.fecha_pago)::timestamp with time zone))::date AS month_start,
            sum(ccp."crs cobrado") AS crs_pagados
           FROM (public.clients_contracts_payments ccp
             JOIN public.clients_contracts cc ON ((ccp.contract_id = cc.id)))
          GROUP BY cc.advisor_id, ((date_trunc('month'::text, (ccp.fecha_pago)::timestamp with time zone))::date)
        ), calculated AS (
         SELECT m.month_start,
            c.user_id,
            c.name,
            c.last_name,
            c.role_name,
            c.supervisor_name,
            COALESCE(cr.total_crs, (0)::real) AS total_crs,
            COALESCE(p.crs_pagados, (0)::real) AS crs_pagados,
            to_char((m.month_start)::timestamp with time zone, 'MM/YY'::text) AS formatted_month,
            ( SELECT u_auth.crs_as_supervisor
                   FROM public.users u_auth
                  WHERE (u_auth.user_id = auth.uid())) AS my_crs,
            ( SELECT u.user_id
                   FROM (public.users u
                     JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                  WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup.supervisors) AS unnest
                           FROM public._users_supervisors us_sup
                          WHERE ((us_sup.user_id = c.user_id) AND (auth.uid() = ANY (us_sup.supervisors))))) AND (( SELECT roles.hierarchy
                           FROM public.roles
                          WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                           FROM public.roles
                          WHERE (roles.id = ( SELECT users.role_id
                                   FROM public.users
                                  WHERE (users.user_id = auth.uid()))))))
                  ORDER BY ( SELECT roles.hierarchy
                           FROM public.roles
                          WHERE (roles.id = u.role_id))
                 LIMIT 1) AS immediate_supervised_user_id,
            ( SELECT u_sup.crs_as_supervisor
                   FROM public.users u_sup
                  WHERE (u_sup.user_id = ( SELECT u.user_id
                           FROM (public.users u
                             JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                          WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup2.supervisors) AS unnest
                                   FROM public._users_supervisors us_sup2
                                  WHERE ((us_sup2.user_id = c.user_id) AND (auth.uid() = ANY (us_sup2.supervisors))))) AND (( SELECT roles.hierarchy
                                   FROM public.roles
                                  WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                                   FROM public.roles
                                  WHERE (roles.id = ( SELECT users.role_id
   FROM public.users
  WHERE (users.user_id = auth.uid()))))))
                          ORDER BY ( SELECT roles.hierarchy
                                   FROM public.roles
                                  WHERE (roles.id = u.role_id))
                         LIMIT 1))) AS immediate_supervised_crs,
                CASE
                    WHEN (( SELECT users.is_admin
                       FROM public.users
                      WHERE (users.user_id = auth.uid())) = true) THEN (2.0)::real
                    ELSE (COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = auth.uid())), (0)::real) - COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = ( SELECT u.user_id
                               FROM (public.users u
                                 JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                              WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup2.supervisors) AS unnest
                                       FROM public._users_supervisors us_sup2
                                      WHERE ((us_sup2.user_id = c.user_id) AND (auth.uid() = ANY (us_sup2.supervisors))))) AND (( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = ( SELECT users_1.role_id
    FROM public.users users_1
   WHERE (users_1.user_id = auth.uid()))))))
                              ORDER BY ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id))
                             LIMIT 1))), (0)::real))
                END AS crs_difference,
            (COALESCE(cr.total_crs, (0)::real) *
                CASE
                    WHEN (( SELECT users.is_admin
                       FROM public.users
                      WHERE (users.user_id = auth.uid())) = true) THEN (2.0)::real
                    ELSE (COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = auth.uid())), (0)::real) - COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = ( SELECT u.user_id
                               FROM (public.users u
                                 JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                              WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup2.supervisors) AS unnest
                                       FROM public._users_supervisors us_sup2
                                      WHERE ((us_sup2.user_id = c.user_id) AND (auth.uid() = ANY (us_sup2.supervisors))))) AND (( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id)) > ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = ( SELECT users_1.role_id
    FROM public.users users_1
   WHERE (users_1.user_id = auth.uid()))))))
                              ORDER BY ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id))
                             LIMIT 1))), (0)::real))
                END) AS total_commission,
            (COALESCE(p.crs_pagados, (0)::real) *
                CASE
                    WHEN (( SELECT users.is_admin
                       FROM public.users
                      WHERE (users.user_id = auth.uid())) = true) THEN (2.0)::real
                    ELSE (COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = auth.uid())), (0)::real) - COALESCE(( SELECT users.crs_as_supervisor
                       FROM public.users
                      WHERE (users.user_id = ( SELECT u.user_id
                               FROM (public.users u
                                 JOIN public._users_supervisors us ON ((u.user_id = us.user_id)))
                              WHERE ((u.user_id <> auth.uid()) AND (u.is_admin = false) AND (u.user_id IN ( SELECT unnest(us_sup2.supervisors) AS unnest
                                       FROM public._users_supervisors us_sup2
                                      WHERE ((us_sup2.user_id = c.user_id) AND (auth.uid() = ANY (us_sup2.supervisors))))))
                              ORDER BY ( SELECT roles.hierarchy
                                       FROM public.roles
                                      WHERE (roles.id = u.role_id))
                             LIMIT 1))), (0)::real))
                END) AS total_comision_crs_pagados
           FROM (((months m
             CROSS JOIN collaborators c)
             LEFT JOIN credits cr ON (((c.user_id = cr.advisor_id) AND (m.month_start = cr.month_start))))
             LEFT JOIN payments p ON (((c.user_id = p.advisor_id) AND (m.month_start = p.month_start))))
        )
 SELECT calculated.month_start,
    calculated.user_id,
    calculated.name,
    calculated.last_name,
    calculated.role_name,
    calculated.supervisor_name,
    calculated.total_crs,
    calculated.crs_pagados,
    calculated.formatted_month,
    calculated.my_crs,
    calculated.immediate_supervised_user_id,
    calculated.immediate_supervised_crs,
    calculated.crs_difference,
    calculated.total_commission,
    calculated.total_comision_crs_pagados
   FROM calculated;


ALTER TABLE public._users_collaborators_monthly_crs3 OWNER TO postgres;

--
-- Name: _users_collaborators_monthly_crs3_grouped; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public._users_collaborators_monthly_crs3_grouped WITH (security_invoker='on') AS
 SELECT to_char((_users_collaborators_monthly_crs3.month_start)::timestamp with time zone, 'YYYY'::text) AS anio,
    to_char((_users_collaborators_monthly_crs3.month_start)::timestamp with time zone, 'MM'::text) AS mes,
    sum(_users_collaborators_monthly_crs3.total_crs) AS total_crs_acumulados,
    sum(_users_collaborators_monthly_crs3.crs_pagados) AS total_crs_pagados,
    sum(_users_collaborators_monthly_crs3.total_commission) AS total_comision_crs_generados,
    sum(_users_collaborators_monthly_crs3.total_comision_crs_pagados) AS total_comision_crs_pagados
   FROM public._users_collaborators_monthly_crs3
  GROUP BY (to_char((_users_collaborators_monthly_crs3.month_start)::timestamp with time zone, 'YYYY'::text)), (to_char((_users_collaborators_monthly_crs3.month_start)::timestamp with time zone, 'MM'::text))
  ORDER BY (to_char((_users_collaborators_monthly_crs3.month_start)::timestamp with time zone, 'YYYY'::text)), (to_char((_users_collaborators_monthly_crs3.month_start)::timestamp with time zone, 'MM'::text));


ALTER TABLE public._users_collaborators_monthly_crs3_grouped OWNER TO postgres;

--
-- Name: _users_detailed; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public._users_detailed WITH (security_invoker='on') AS
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


ALTER TABLE public._users_detailed OWNER TO postgres;

--
-- Name: _users_supervisors_all; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public._users_supervisors_all AS
 WITH RECURSIVE supervisor_chain AS (
         SELECT u1.user_id,
            u1.supervisor_id,
            ARRAY[u1.user_id, u1.supervisor_id] AS all_supervisors
           FROM public.users u1
          WHERE (u1.supervisor_id IS NOT NULL)
        UNION ALL
         SELECT sc.user_id,
            u1.supervisor_id,
            (sc.all_supervisors || u1.supervisor_id)
           FROM (supervisor_chain sc
             JOIN public.users u1 ON ((u1.user_id = sc.supervisor_id)))
          WHERE (u1.supervisor_id IS NOT NULL)
        ), admins AS (
         SELECT COALESCE(array_agg(u_1.user_id), ARRAY[]::uuid[]) AS ids
           FROM public.users u_1
          WHERE (u_1.is_admin = true)
        ), racc_group AS (
         SELECT COALESCE(array_agg(u_1.user_id), ARRAY[]::uuid[]) AS ids
           FROM public.users u_1
          WHERE (u_1.racc = true)
        )
 SELECT u.tenant,
    u.user_id,
        CASE
            WHEN (u.racc = true) THEN ( SELECT ARRAY( SELECT DISTINCT x.x
                       FROM unnest((rg.ids || a.ids)) x(x)) AS "array"
               FROM racc_group rg,
                admins a)
            ELSE ( SELECT ARRAY( SELECT DISTINCT x.x
                       FROM unnest((COALESCE(( SELECT sc2.all_supervisors
                               FROM supervisor_chain sc2
                              WHERE (sc2.user_id = u.user_id)
                              ORDER BY (array_length(sc2.all_supervisors, 1)) DESC
                             LIMIT 1), ARRAY[u.user_id]) || a.ids)) x(x)) AS "array"
               FROM admins a)
        END AS supervisors,
    u.email,
    concat(u.name, ' ', u.last_name) AS display_name,
        CASE
            WHEN (u.tenant = 1) THEN u.email
            ELSE COALESCE(NULLIF(btrim(concat(u.name, ' ', COALESCE(u.last_name, ''::text))), ''::text),
            CASE
                WHEN (u.name = '-'::text) THEN NULL::text
                ELSE NULL::text
            END, u.email)
        END AS flutter_name
   FROM public.users u
  WITH NO DATA;


ALTER TABLE public._users_supervisors_all OWNER TO postgres;

--
-- Name: _users_supervisors_racc; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public._users_supervisors_racc AS
 WITH RECURSIVE supervisor_chain AS (
         SELECT u1.user_id,
            u1.supervisor_id,
            ARRAY[u1.user_id, u1.supervisor_id] AS all_supervisors
           FROM public.users u1
          WHERE (u1.supervisor_id IS NOT NULL)
        UNION ALL
         SELECT sc.user_id,
            u1.supervisor_id,
            (sc.all_supervisors || u1.supervisor_id)
           FROM (supervisor_chain sc
             JOIN public.users u1 ON ((u1.user_id = sc.supervisor_id)))
          WHERE (u1.supervisor_id IS NOT NULL)
        ), admins AS (
         SELECT COALESCE(array_agg(u_1.user_id), ARRAY[]::uuid[]) AS ids
           FROM public.users u_1
          WHERE (u_1.is_admin = true)
        ), racc_group AS (
         SELECT COALESCE(array_agg(u_1.user_id), ARRAY[]::uuid[]) AS ids
           FROM public.users u_1
          WHERE (u_1.racc = true)
        )
 SELECT u.user_id,
        CASE
            WHEN (u.racc = true) THEN ( SELECT ARRAY( SELECT DISTINCT x.x
                       FROM unnest((rg.ids || a.ids)) x(x)) AS "array"
               FROM racc_group rg,
                admins a)
            ELSE ( SELECT ARRAY( SELECT DISTINCT x.x
                       FROM unnest((COALESCE(( SELECT sc2.all_supervisors
                               FROM supervisor_chain sc2
                              WHERE (sc2.user_id = u.user_id)
                              ORDER BY (array_length(sc2.all_supervisors, 1)) DESC
                             LIMIT 1), ARRAY[u.user_id]) || a.ids)) x(x)) AS "array"
               FROM admins a)
        END AS supervisors,
    u.email,
    concat(u.name, ' ', u.last_name) AS display_name
   FROM public.users u
  WITH NO DATA;


ALTER TABLE public._users_supervisors_racc OWNER TO postgres;

--
-- Name: _valuations_detailed_clientesprueba; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public._valuations_detailed_clientesprueba WITH (security_invoker='on') AS
 SELECT DISTINCT v.id,
    v.created_at,
    v.client_email,
    v.contract_type,
    v.advisor_id,
    v.pdf_proposal,
    v.status,
    v.proposal_date,
    v.signature,
    v.signature_date,
    v."CUPS",
    v.new_company,
    v.bank_ownership,
    v.saving_percentage,
    v.temp_client_name,
    v.temp_client_last_name,
    v.deleted,
    v.deleted_reason,
    v.contract_id,
    v.pdf_invoice,
    v.temp_account_number,
    v.temp_dni,
    v.crs,
    v.temp_pdf_dni,
    v.temp_mobile_number,
    v.temp_ownership_change,
    v.temp_ownership_change_pdf,
    v.temp_power_change,
    v.temp_power_change_new_value,
    v.temp_paper_invoices,
    v.temp_new_registration,
    v.temp_account_ownership_pdf,
    v.temp_delegated_signature,
    v.temp_delegated_signature_email,
    v.temp_selfconsumption,
    v.max_power,
    v.new_rate,
    v.new_subrate,
    v.idioma,
    v.notificaciones,
    us.supervisors,
    u.email AS advisor_email,
    r.role AS advisor_role,
    v.temp_client_name AS client_name,
    v.temp_client_last_name AS client_last_name,
    v.temp_dni AS client_dni,
    v.temp_pdf_dni AS client_pdf_dni,
    v.temp_mobile_number AS client_phone_number,
    ARRAY[v.contract_type, 'All'::text] AS contract_type_filter,
    ARRAY[(v.advisor_id)::text, 'All'::text] AS advisor_filter,
    concat_ws(' '::text, v.client_email, v.temp_client_name, v.temp_client_last_name, v.contract_type, u.email, r.role, v."CUPS") AS search,
    to_char(v.created_at, 'MM'::text) AS created_month,
    to_char(v.created_at, 'YYYY'::text) AS created_year
   FROM (((public.clients_valuations v
     LEFT JOIN public._users_supervisors us ON ((v.advisor_id = us.user_id)))
     JOIN public.users u ON ((v.advisor_id = u.user_id)))
     JOIN public.roles r ON ((u.role_id = r.id)));


ALTER TABLE public._valuations_detailed_clientesprueba OWNER TO postgres;

--
-- Name: _valuations_detailed_optimized; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public._valuations_detailed_optimized AS
 SELECT DISTINCT ON (v.id) v.id,
    v.contract_id,
    v.contract_type,
        CASE
            WHEN ((v.client_email IS NULL) OR (v.client_email = ''::text)) THEN v.temp_client_name
            ELSE COALESCE(cl.name, v.temp_client_name)
        END AS temp_client_name,
        CASE
            WHEN ((v.client_email IS NULL) OR (v.client_email = ''::text)) THEN v.temp_client_last_name
            ELSE COALESCE(cl.last_name, v.temp_client_last_name)
        END AS temp_client_last_name,
    v."CUPS",
    v.saving_percentage,
    v.crs,
    v.deleted,
        CASE
            WHEN (u.racc = true) THEN ( SELECT array_cat(us.supervisors, array_agg(ur.user_id)) AS array_cat
               FROM public.users_racc ur)
            ELSE us.supervisors
        END AS supervisors,
    ARRAY[v.contract_type, 'All'::text] AS contract_type_filter,
    ARRAY[(v.advisor_id)::text, 'All'::text] AS advisor_filter,
    concat_ws(' '::text, v.client_email, v.temp_client_name, v.temp_client_last_name, v.contract_type, v."CUPS") AS search,
    to_char(v.created_at, 'MM'::text) AS created_month,
    to_char(v.created_at, 'YYYY'::text) AS created_year,
    ARRAY[v.new_company, 'All'::text] AS new_company_filter,
    v.created_at,
    v.client_email,
    v.deleted_reason
   FROM (((public.clients_valuations v
     LEFT JOIN public._users_supervisors us ON ((v.advisor_id = us.user_id)))
     LEFT JOIN public.clients cl ON (((v.client_email = cl.email) AND (v.client_email <> ''::text))))
     LEFT JOIN public.users u ON ((v.advisor_id = u.user_id)));


ALTER TABLE public._valuations_detailed_optimized OWNER TO postgres;

--
-- Name: advisor_monthly_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.advisor_monthly_summary WITH (security_invoker='on') AS
 WITH comparativas AS (
         SELECT all_comparisons.advisor_id,
            date_trunc('month'::text, all_comparisons.created_at) AS month,
            count(*) FILTER (WHERE (all_comparisons.table_name = 'comparison_light'::text)) AS comparison_light,
            count(*) FILTER (WHERE (all_comparisons.table_name = 'comparison_3_0'::text)) AS comparison_3_0,
            count(*) FILTER (WHERE (all_comparisons.table_name = 'comparison_gas'::text)) AS comparison_gas,
            count(*) FILTER (WHERE (all_comparisons.table_name = 'comparison_phone'::text)) AS comparison_phone
           FROM ( SELECT comparison_light.advisor_id,
                    comparison_light.created_at,
                    'comparison_light'::text AS table_name
                   FROM public.comparison_light
                UNION ALL
                 SELECT comparison_3_0.advisor_id,
                    comparison_3_0.created_at,
                    'comparison_3_0'::text AS table_name
                   FROM public.comparison_3_0
                UNION ALL
                 SELECT comparison_gas.advisor_id,
                    comparison_gas.created_at,
