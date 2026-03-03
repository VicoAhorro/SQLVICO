CREATE OR REPLACE VIEW public.v_clients_contracts_payments_filtered WITH (security_invoker='on') AS
WITH RECURSIVE 
  -- 1. Calculamos la jerarquía de IDs una sola vez para todos los usuarios
  hierarchy_build AS (
    SELECT 
      user_id AS leaf_user_id,
      supervisor_id,
      1 AS lvl,
      ARRAY[user_id] AS path
    FROM public.users
    WHERE supervisor_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
      hb.leaf_user_id,
      u.supervisor_id,
      hb.lvl + 1,
      hb.path || u.user_id
    FROM hierarchy_build hb
    JOIN public.users u ON u.user_id = hb.supervisor_id
    WHERE u.supervisor_id IS NOT NULL 
      AND NOT (u.supervisor_id = ANY(hb.path))
  ),
  -- 2. Convertimos esa jerarquía a nombres y generamos la cadena de texto
  supervisor_chains AS (
    SELECT 
      hb.leaf_user_id,
      string_agg(concat(u.name, ' ', u.last_name), ' -> ' ORDER BY hb.lvl) AS chain
    FROM hierarchy_build hb
    JOIN public.users u ON u.user_id = hb.supervisor_id
    GROUP BY hb.leaf_user_id
  )
SELECT 
    to_char((ccp.fecha_pago AT TIME ZONE 'UTC'), 'MM') AS mes_de_cobro,
    to_char((ccp.fecha_pago AT TIME ZONE 'UTC'), 'YYYY') AS anio_de_cobro,
    ccp.cups,
    ccp."crs cobrado" AS crs,
    u.user_id AS asesor_id,
    concat(u.name, ' ', u.last_name) AS asesor,
    COALESCE(cs.chain, 'Sin Supervisores') AS supervisores_chain
FROM public.clients_contracts_payments_deprecated ccp
JOIN public.clients_contracts c ON ccp.contract_id = c.id
JOIN public.users u ON c.advisor_id = u.user_id
-- 3. Filtrado de seguridad usando la vista maestra pre-calculada
JOIN public._users_supervisors_all us ON u.user_id = us.user_id 
  AND (auth.uid() = ANY (us.supervisors))
-- 4. Join con la cadena de nombres de supervisor pre-calculada
LEFT JOIN supervisor_chains cs ON cs.leaf_user_id = u.user_id;
