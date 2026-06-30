-- Modalidad (Fija / Indexada) para comparativas de GAS, en paridad con luz/3.0.
-- Columnas aditivas y nullable: retrocompatibles, no rompen filas existentes.
--
-- comparison_gas_results: variantes precomputadas + cuál está activa
-- (mismo patrón que comparison_light_results / comparison_3_0_results).
ALTER TABLE public.comparison_gas_results
    ADD COLUMN IF NOT EXISTS variants JSONB,
    ADD COLUMN IF NOT EXISTS selected_variant TEXT;

-- Nota: la tabla base `comparison_gas` ya dispone de `prefered_rate_type`,
-- `wants_permanence` y `term_month_i_want`, así que NO necesita columnas nuevas:
-- el endpoint /gas/select-variant persiste la modalidad sobre `prefered_rate_type`.
