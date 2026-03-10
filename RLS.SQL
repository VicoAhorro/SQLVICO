alter policy "Clients: Delete if admin or advisor/supervisor"
on "public"."clients"
to public
using (
     ((EXISTS ( SELECT 1
   FROM users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM _users_supervisors us
  WHERE ((us.user_id = clients.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM users_racc))))
   );

alter policy "Clients: Insert if admin, advisor, or supervisor"
on "public"."clients"
to public
with check (
     ((EXISTS ( SELECT 1
   FROM users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM _users_supervisors us
  WHERE ((us.user_id = clients.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM users_racc))))
   );

alter policy "Clients: Select if admin or advisor/supervisor"
on "public"."clients"
to public
using (
      ((EXISTS ( SELECT 1
   FROM users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM _users_supervisors us
  WHERE ((us.user_id = clients.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM users_racc))) OR (email = auth.email()))
   );

alter policy "Clients: Update if admin or advisor/supervisor"
on "public"."clients"
to public
using (
      ((EXISTS ( SELECT 1
   FROM users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM _users_supervisors us
  WHERE ((us.user_id = clients.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM users_racc))) OR (email = auth.email()))
   );

alter policy "insert to auth and email same"
on "public"."clients"
to authenticated
with check ((email = (auth.jwt() ->> 'email'::text)));

alter policy "select own client to auth"
on "public"."clients"
to authenticated
using ((email = (auth.jwt() ->> 'email'::text)));

CREATE POLICY "authenticated update"
ON public.comparison_summary
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "authenticated insert"
ON public.comparison_summary
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "authenticated select"
ON public.comparison_summary
FOR SELECT
TO authenticated
USING (true);

-- clients_addresses RLS policies
ALTER TABLE public.clients_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ClientsAddresses: Delete if admin or advisor/supervisor"
ON public.clients_addresses
FOR DELETE
USING (
    (EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR
    (EXISTS ( SELECT 1
   FROM public.clients c
  WHERE ((c.id = clients_addresses.client_id) AND (
      (c.advisor_id = auth.uid()) OR
      (EXISTS ( SELECT 1
         FROM public._users_supervisors us
        WHERE ((us.user_id = c.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR
      ((auth.uid() IN ( SELECT users_racc.user_id FROM public.users_racc)) AND
       (c.advisor_id IN ( SELECT users_racc.user_id FROM public.users_racc)))
  ))))
);

CREATE POLICY "ClientsAddresses: Insert if admin, advisor, or supervisor"
ON public.clients_addresses
FOR INSERT
WITH CHECK (
    (EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR
    (EXISTS ( SELECT 1
   FROM public.clients c
  WHERE ((c.id = clients_addresses.client_id) AND (
      (c.advisor_id = auth.uid()) OR
      (EXISTS ( SELECT 1
         FROM public._users_supervisors us
        WHERE ((us.user_id = c.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR
      ((auth.uid() IN ( SELECT users_racc.user_id FROM public.users_racc)) AND
       (c.advisor_id IN ( SELECT users_racc.user_id FROM public.users_racc)))
  ))))
);

CREATE POLICY "ClientsAddresses: Select if admin or advisor/supervisor"
ON public.clients_addresses
FOR SELECT
USING (
    (EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR
    (EXISTS ( SELECT 1
   FROM public.clients c
  WHERE ((c.id = clients_addresses.client_id) AND (
      (c.advisor_id = auth.uid()) OR
      (EXISTS ( SELECT 1
         FROM public._users_supervisors us
        WHERE ((us.user_id = c.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR
      ((auth.uid() IN ( SELECT users_racc.user_id FROM public.users_racc)) AND
       (c.advisor_id IN ( SELECT users_racc.user_id FROM public.users_racc)))
  )))) OR
    (client_email = auth.email())
);
