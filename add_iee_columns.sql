-- ============================================================================
-- Añade la columna `iee` a las tablas de comparación para que el RPC y las
-- vistas dejen de hardcodear el factor 5.1127%.
--
-- Semántica:
--   * comparison_3_0     -> iee en % decimal (e.g. 0.05113 = 5.113%, 0.005 = 0.5%)
--   * comparison_light   -> iee en % decimal (igual que 3_0)
--   * comparison_gas     -> iee en €/kWh sobre el consumo (Impuesto Hidrocarburos)
--
-- Defaults conservan el comportamiento histórico previo al fix.
-- ============================================================================

ALTER TABLE public.comparison_3_0
  ADD COLUMN IF NOT EXISTS iee REAL NOT NULL DEFAULT 0.05113;

ALTER TABLE public.comparison_light
  ADD COLUMN IF NOT EXISTS iee REAL NOT NULL DEFAULT 0.05113;

ALTER TABLE public.comparison_gas
  ADD COLUMN IF NOT EXISTS iee REAL NOT NULL DEFAULT 0.00234;

COMMENT ON COLUMN public.comparison_3_0.iee   IS 'Impuesto Especial Electricidad aplicado en la factura (porcentaje en decimal, e.g. 0.05113 = 5.113%, 0.005 = 0.5%).';
COMMENT ON COLUMN public.comparison_light.iee IS 'Impuesto Especial Electricidad aplicado en la factura (porcentaje en decimal, e.g. 0.05113 = 5.113%, 0.005 = 0.5%).';
COMMENT ON COLUMN public.comparison_gas.iee   IS 'Impuesto sobre Hidrocarburos aplicado a la factura de gas (€/kWh, e.g. 0.00234).';
