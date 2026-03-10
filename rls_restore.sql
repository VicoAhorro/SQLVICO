CREATE POLICY "Clients: Delete if admin or advisor/supervisor" ON public.clients FOR DELETE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = clients.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: clients Clients: Insert if admin, advisor, or supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients: Insert if admin, advisor, or supervisor" ON public.clients FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = clients.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: clients Clients: Select if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients: Select if admin or advisor/supervisor" ON public.clients FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = clients.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc))) OR (email = auth.email())));


--
-- Name: clients Clients: Update if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients: Update if admin or advisor/supervisor" ON public.clients FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = clients.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc))) OR (email = auth.email())));


--
-- Name: clients_contracts ClientsContracts: Delete if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ClientsContracts: Delete if admin or advisor/supervisor" ON public.clients_contracts FOR DELETE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = clients_contracts.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: clients_contracts ClientsContracts: Insert if admin, advisor, or supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ClientsContracts: Insert if admin, advisor, or supervisor" ON public.clients_contracts FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = clients_contracts.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: clients_contracts ClientsContracts: Select if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ClientsContracts: Select if admin or advisor/supervisor" ON public.clients_contracts FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = clients_contracts.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc))) OR (client_email = auth.email())));


--
-- Name: clients_contracts ClientsContracts: Update if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ClientsContracts: Update if admin or advisor/supervisor" ON public.clients_contracts FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = clients_contracts.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc))) OR (client_email = auth.email())));


--
-- Name: comparison_3_0 Comparison3_0: Delete if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Comparison3_0: Delete if admin or advisor/supervisor" ON public.comparison_3_0 FOR DELETE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_3_0.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_3_0 Comparison3_0: Insert if admin, advisor, or supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Comparison3_0: Insert if admin, advisor, or supervisor" ON public.comparison_3_0 FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_3_0.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_3_0 Comparison3_0: Select if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Comparison3_0: Select if admin or advisor/supervisor" ON public.comparison_3_0 FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_3_0.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_3_0 Comparison3_0: Update if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Comparison3_0: Update if admin or advisor/supervisor" ON public.comparison_3_0 FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_3_0.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_gas ComparisonGas: Delete if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonGas: Delete if admin or advisor/supervisor" ON public.comparison_gas FOR DELETE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_gas.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_gas ComparisonGas: Insert if admin, advisor, or supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonGas: Insert if admin, advisor, or supervisor" ON public.comparison_gas FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_gas.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_gas ComparisonGas: Select if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonGas: Select if admin or advisor/supervisor" ON public.comparison_gas FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_gas.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_gas ComparisonGas: Update if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonGas: Update if admin or advisor/supervisor" ON public.comparison_gas FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_gas.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_light ComparisonLight: Delete if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonLight: Delete if admin or advisor/supervisor" ON public.comparison_light FOR DELETE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_light.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_light ComparisonLight: Insert if admin, advisor, or supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonLight: Insert if admin, advisor, or supervisor" ON public.comparison_light FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_light.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_light ComparisonLight: Select if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonLight: Select if admin or advisor/supervisor" ON public.comparison_light FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_light.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_light ComparisonLight: Select own comparisons; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonLight: Select own comparisons" ON public.comparison_light FOR SELECT TO authenticated USING (((advisor_id = auth.uid()) OR (client_email = auth.email())));


--
-- Name: comparison_light ComparisonLight: Update if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonLight: Update if admin or advisor/supervisor" ON public.comparison_light FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_light.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_phone ComparisonPhone: Delete if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonPhone: Delete if admin or advisor/supervisor" ON public.comparison_phone FOR DELETE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_phone.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_phone ComparisonPhone: Insert if admin, advisor, or supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonPhone: Insert if admin, advisor, or supervisor" ON public.comparison_phone FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_phone.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_phone ComparisonPhone: Select if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonPhone: Select if admin or advisor/supervisor" ON public.comparison_phone FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_phone.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: comparison_phone ComparisonPhone: Update if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ComparisonPhone: Update if admin or advisor/supervisor" ON public.comparison_phone FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_phone.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: blog_news Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.blog_news FOR SELECT TO authenticated USING (true);


--
-- Name: comparison_light Enable users to view their own data only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable users to view their own data only" ON public.comparison_light FOR SELECT USING ((( SELECT auth.email() AS email) = client_email));


--
-- Name: comparison_seguros Enable users to view their own data only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable users to view their own data only" ON public.comparison_seguros FOR SELECT TO authenticated USING ((( SELECT auth.email() AS email) = client_email));


--
-- Name: invoice_submissions Public Access for invoice_submissions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public Access for invoice_submissions" ON public.invoice_submissions USING (true) WITH CHECK (true);


--
-- Name: users Users: Delete if admin; Type: POLICY; Schema: public; Owner: postgres
--

--
CREATE POLICY "client own comparativa" ON public.comparison_3_0 FOR SELECT USING ((client_email = (auth.jwt() ->> 'email'::text)));


--
-- Name: comparison_phone client own comparativa; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "client own comparativa" ON public.comparison_phone FOR SELECT USING ((client_email = (auth.jwt() ->> 'email'::text)));


--
-- Name: clients; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

--
-- Name: clients_contracts; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.clients_contracts ENABLE ROW LEVEL SECURITY;

--
-- Name: clients_contracts_reserva; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.clients_contracts_reserva ENABLE ROW LEVEL SECURITY;

--
CREATE POLICY "insert own contract" ON public.clients_contracts FOR INSERT TO authenticated WITH CHECK ((client_email = (auth.jwt() ->> 'email'::text)));


--
-- Name: clients insert to auth and email same; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "insert to auth and email same" ON public.clients FOR INSERT TO authenticated WITH CHECK ((email = (auth.jwt() ->> 'email'::text)));


--
-- Name: invoice_submissions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.invoice_submissions ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: comparison_gas own valoration; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "own valoration" ON public.comparison_gas FOR SELECT TO authenticated USING ((client_email = (auth.jwt() ->> 'email'::text)));


--
-- Name: periodos_tarifa_2_0_peninsula; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.periodos_tarifa_2_0_peninsula ENABLE ROW LEVEL SECURITY;

--
-- Name: periodos_tarifas_horarios; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.periodos_tarifas_horarios ENABLE ROW LEVEL SECURITY;

--
-- Name: precio_medio; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.precio_medio ENABLE ROW LEVEL SECURITY;

--
CREATE POLICY "select own client to auth" ON public.clients FOR SELECT TO authenticated USING ((email = (auth.jwt() ->> 'email'::text)));


--
-- Name: comparison_seguros select to admin or supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "select to admin or supervisor" ON public.comparison_seguros FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.users u_admin
  WHERE ((u_admin.user_id = auth.uid()) AND (u_admin.is_admin = true)))) OR (advisor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public._users_supervisors us
  WHERE ((us.user_id = comparison_seguros.advisor_id) AND (auth.uid() = ANY (us.supervisors))))) OR ((auth.uid() IN ( SELECT users_racc.user_id
   FROM public.users_racc)) AND (advisor_id IN ( SELECT users_racc.user_id
   FROM public.users_racc)))));


--
-- Name: servicios_externos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.servicios_externos ENABLE ROW LEVEL SECURITY;


--
-- Name: clients_addresses; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.clients_addresses ENABLE ROW LEVEL SECURITY;


--
-- Name: clients_addresses ClientsAddresses: Delete if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ClientsAddresses: Delete if admin or advisor/supervisor" ON public.clients_addresses FOR DELETE USING (
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


--
-- Name: clients_addresses ClientsAddresses: Insert if admin, advisor, or supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ClientsAddresses: Insert if admin, advisor, or supervisor" ON public.clients_addresses FOR INSERT WITH CHECK (
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


--
-- Name: clients_addresses ClientsAddresses: Select if admin or advisor/supervisor; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ClientsAddresses: Select if admin or advisor/supervisor" ON public.clients_addresses FOR SELECT USING (
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
