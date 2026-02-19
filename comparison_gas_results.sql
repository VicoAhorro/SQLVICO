-- Tabla para persistir los resultados de las comparativas de gas (Rank 1)
-- Replicando la estructura de light_results adaptada a gas

CREATE TABLE IF NOT EXISTS public.comparison_gas_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comparison_gas_id UUID NOT NULL REFERENCES public.comparison_gas(id) ON DELETE CASCADE,
    comparison_id UUID REFERENCES public.comparisons(id) ON UPDATE CASCADE ON DELETE CASCADE,
    created_at TIMESTAMP WITHOUT TIME ZONE,
    inserted_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    
    -- Datos del Asesor y Cliente
    advisor_id UUID REFERENCES public.users(user_id),
    client_email TEXT,
    tenant_id INTEGER,
    
    -- Snapshot de datos del cliente en el momento del cálculo
    company TEXT,
    rate_name TEXT,
    cups TEXT,
    current_total_invoice DOUBLE PRECISION,
    consumption_p1 DOUBLE PRECISION,
    anual_consumption_p1 DOUBLE PRECISION,
    days INTEGER,
    vat DOUBLE PRECISION,
    selfconsumption BOOLEAN DEFAULT FALSE,
    tarifa_plana BOOLEAN,
    cif BOOLEAN,
    region TEXT,
    wants_gdo BOOLEAN,
    
    -- Datos de la Nueva Tarifa Ofertada
    new_company TEXT,
    new_rate_name TEXT,
    new_subrate_name TEXT,
    new_rate_id UUID,
    rate_mode TEXT,
    
    -- Precios de la nueva tarifa
    price_pp1 DOUBLE PRECISION,
    price_cp1 DOUBLE PRECISION,
    
    -- Resultados del Cálculo
    total_power_price DOUBLE PRECISION,
    total_consumption_price DOUBLE PRECISION,
    
    new_total_price DOUBLE PRECISION, -- Mensual pre-IVA
    new_total_price_with_vat DOUBLE PRECISION, -- Mensual final con IVA e impuestos
    new_total_yearly_price_with_vat DOUBLE PRECISION,
    
    iee_monthly DOUBLE PRECISION DEFAULT 0.0,
    iee DOUBLE PRECISION DEFAULT 0.0,
    
    savings DOUBLE PRECISION,
    savings_yearly DOUBLE PRECISION,
    saving_percentage DOUBLE PRECISION,
    
    -- Rentabilidad (CRS)
    total_crs DOUBLE PRECISION,
    crs_id UUID,
    ranked_crs DOUBLE PRECISION,
    
    -- Metadatos
    type TEXT DEFAULT 'gas',
    has_permanence BOOLEAN,
    term_month INTEGER,
    excluded_company_ids UUID[]
);

CREATE INDEX IF NOT EXISTS idx_gas_results_comparison_id ON public.comparison_gas_results(comparison_id);
CREATE INDEX IF NOT EXISTS idx_gas_results_advisor_id ON public.comparison_gas_results(advisor_id);
CREATE INDEX IF NOT EXISTS idx_gas_results_inserted_at ON public.comparison_gas_results(inserted_at);

COMMENT ON TABLE public.comparison_gas_results IS 'Almacena el resultado Rank 1 de las comparativas de gas calculadas por el servicio Python.';
