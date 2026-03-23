-- Tabla para persistir los resultados de las comparativas 3.0 (Rank 1)
-- Replicando la estructura de light_results adaptada a 6 periodos

CREATE TABLE IF NOT EXISTS public.comparison_3_0_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comparison_3_0_id UUID NOT NULL REFERENCES public.comparison_3_0(id) ON DELETE CASCADE,
    comparison_id UUID REFERENCES public.comparisons(id) ON UPDATE CASCADE ON DELETE CASCADE,
    created_at TIMESTAMP WITHOUT TIME ZONE,
    inserted_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    
    -- Datos del Asesor y Cliente
    advisor_id UUID REFERENCES public.users(user_id),
    client_email TEXT,
    tenant_id INTEGER,
    
    -- Snapshot de datos del cliente en el momento del cálculo (6 periodos)
    company TEXT,
    rate_name TEXT,
    cups TEXT,
    current_total_invoice DOUBLE PRECISION,
    
    consumption_p1 DOUBLE PRECISION,
    consumption_p2 DOUBLE PRECISION,
    consumption_p3 DOUBLE PRECISION,
    consumption_p4 DOUBLE PRECISION,
    consumption_p5 DOUBLE PRECISION,
    consumption_p6 DOUBLE PRECISION,
    
    anual_consumption_p1 DOUBLE PRECISION,
    anual_consumption_p2 DOUBLE PRECISION,
    anual_consumption_p3 DOUBLE PRECISION,
    anual_consumption_p4 DOUBLE PRECISION,
    anual_consumption_p5 DOUBLE PRECISION,
    anual_consumption_p6 DOUBLE PRECISION,
    max_power DOUBLE PRECISION,
    
    power_p1 DOUBLE PRECISION,
    power_p2 DOUBLE PRECISION,
    power_p3 DOUBLE PRECISION,
    power_p4 DOUBLE PRECISION,
    power_p5 DOUBLE PRECISION,
    power_p6 DOUBLE PRECISION,
    
    power_days INTEGER,
    vat DOUBLE PRECISION,
    surpluses DOUBLE PRECISION,
    selfconsumption BOOLEAN DEFAULT FALSE,
    cif BOOLEAN,
    region TEXT,
    wants_gdo BOOLEAN,
    ssaa_preference TEXT,
    rate_i_have TEXT,
    rate_i_want TEXT,
    
    -- Datos de la Nueva Tarifa Ofertada
    new_company TEXT,
    new_rate_name TEXT,
    new_subrate_name TEXT,
    new_ssaa TEXT,
    new_rate_id UUID,
    rate_mode TEXT,
    
    -- Precios de la nueva tarifa (Potencia)
    price_pp1 DOUBLE PRECISION,
    price_pp2 DOUBLE PRECISION,
    price_pp3 DOUBLE PRECISION,
    price_pp4 DOUBLE PRECISION,
    price_pp5 DOUBLE PRECISION,
    price_pp6 DOUBLE PRECISION,
    
    -- Precios de la nueva tarifa (Energía)
    price_cp1 DOUBLE PRECISION,
    price_cp2 DOUBLE PRECISION,
    price_cp3 DOUBLE PRECISION,
    price_cp4 DOUBLE PRECISION,
    price_cp5 DOUBLE PRECISION,
    price_cp6 DOUBLE PRECISION,
    
    price_surpluses DOUBLE PRECISION,
    
    -- Resultados del Cálculo
    total_power_price DOUBLE PRECISION,
    total_consumption_price DOUBLE PRECISION,
    total_surpluses_price DOUBLE PRECISION,
    total_consumption DOUBLE PRECISION,
    total_anual_consumption DOUBLE PRECISION,
    
    new_total_price DOUBLE PRECISION, -- Mensual pre-IVA
    new_total_price_with_vat DOUBLE PRECISION, -- Mensual final con IVA e impuestos
    new_total_yearly_price_with_vat DOUBLE PRECISION,
    
    iee_monthly DOUBLE PRECISION,
    iee DOUBLE PRECISION, -- IEE Anual projected
    
    savings DOUBLE PRECISION,
    savings_yearly DOUBLE PRECISION,
    saving_percentage DOUBLE PRECISION,
    
    -- Rentabilidad (CRS)
    total_crs DOUBLE PRECISION,
    crs_id UUID,
    ranked_crs DOUBLE PRECISION,
    
    -- Metadatos
    type TEXT DEFAULT '3_0',
    has_permanence BOOLEAN,
    term_month INTEGER,
    excluded_company_ids UUID[]
);

CREATE INDEX IF NOT EXISTS idx_3_0_results_comparison_id ON public.comparison_3_0_results(comparison_id);
CREATE INDEX IF NOT EXISTS idx_3_0_results_advisor_id ON public.comparison_3_0_results(advisor_id);
CREATE INDEX IF NOT EXISTS idx_3_0_results_inserted_at ON public.comparison_3_0_results(inserted_at);

COMMENT ON TABLE public.comparison_3_0_results IS 'Almacena el resultado Rank 1 de las comparativas 3.0 calculadas por el servicio Python.';
