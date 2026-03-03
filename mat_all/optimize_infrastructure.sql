-- OPTIMIZACIÓN DE INFRAESTRUCTURA - ÍNDICES DE BASE
-- Estos índices mejoran el rendimiento de las vistas detalladas y las vistas materializadas mat_all_data y mat_comparison_historic.

-- 1. Optimización para clients_valuations (DISTINCT ON y Joins)
CREATE INDEX IF NOT EXISTS idx_clients_valuations_contract_id ON public.clients_valuations (contract_id);
CREATE INDEX IF NOT EXISTS idx_clients_valuations_performance ON public.clients_valuations (client_email, advisor_id, created_at DESC);

-- 2. Optimización para tablas de comparaciones (Joins laterales en _valuations_detailed)
CREATE INDEX IF NOT EXISTS idx_comparison_light_valuation_id ON public.comparison_light (valuation_id);
CREATE INDEX IF NOT EXISTS idx_comparison_3_0_valuation_id ON public.comparison_3_0 (valuation_id);
CREATE INDEX IF NOT EXISTS idx_comparison_gas_valuation_id ON public.comparison_gas (valuation_id);
CREATE INDEX IF NOT EXISTS idx_comparison_phone_valuation_id ON public.comparison_phone (valuation_id);

-- 3. Optimización para clientes y contratos
CREATE INDEX IF NOT EXISTS idx_clients_email_advisor ON public.clients (email, advisor_id);
CREATE INDEX IF NOT EXISTS idx_clients_contracts_advisor_id ON public.clients_contracts (advisor_id);
CREATE INDEX IF NOT EXISTS idx_clients_contracts_cups ON public.clients_contracts ("CUPS");

-- 4. Optimización de usuarios (si no existían)
CREATE INDEX IF NOT EXISTS idx_users_user_id_tenant ON public.users (user_id, tenant);
