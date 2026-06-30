-- Modalidad (Fija / Indexada) para comparativas de LUZ, en paridad con 3.0.
-- Columnas aditivas y nullable: retrocompatibles, no rompen filas existentes.
--
-- 1) comparison_light_results: variantes precomputadas + cuál está activa
--    (mismo patrón que comparison_3_0_results).
ALTER TABLE public.comparison_light_results
    ADD COLUMN IF NOT EXISTS variants JSONB,
    ADD COLUMN IF NOT EXISTS selected_variant TEXT;

-- 2) comparison_light: modalidad preferida, para que los recálculos (LIA /
--    recalculate) preserven la modalidad elegida por el comercial.
ALTER TABLE public.comparison_light
    ADD COLUMN IF NOT EXISTS rate_i_want TEXT;
