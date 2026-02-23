-- Tabla para persistir los resultados de las comparativas de luz (Rank 1)
-- Permite mantener un histórico de lo ofrecido al cliente sin depender de la vista SQL volátil

CREATE TABLE IF NOT EXISTS public.comparison_light_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comparison_light_id UUID NOT NULL REFERENCES public.comparison_light(id) ON DELETE CASCADE,
    comparison_id UUID REFERENCES public.comparisons(id) ON UPDATE CASCADE ON DELETE CASCADE,
    created_at TIMESTAMPTZ, -- Fecha de creación de la comparativa original
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Fecha en la que se guardó este resultado
    
    -- Datos del Asesor y Cliente
    advisor_id UUID REFERENCES public.users(user_id),
    client_email TEXT,
    tenant_id INTEGER,
    
    -- Snapshot de datos del cliente en el momento del cálculo
    company TEXT, -- Compañía actual
    rate_name TEXT, -- Tarifa actual
    cups TEXT,
    current_total_invoice DOUBLE PRECISION,
    consumption_p1 DOUBLE PRECISION,
    consumption_p2 DOUBLE PRECISION,
    consumption_p3 DOUBLE PRECISION,
    anual_consumption_p1 DOUBLE PRECISION,
    anual_consumption_p2 DOUBLE PRECISION,
    anual_consumption_p3 DOUBLE PRECISION,
    max_power DOUBLE PRECISION,
    power_p1 DOUBLE PRECISION,
    power_p2 DOUBLE PRECISION,
    power_days INTEGER,
    vat DOUBLE PRECISION,
    surpluses DOUBLE PRECISION,
    selfconsumption BOOLEAN,
    tarifa_plana BOOLEAN,
    cif BOOLEAN,
    region TEXT,
    wants_gdo BOOLEAN,
    
    -- Datos de la Nueva Tarifa Ofertada
    new_company TEXT,
    new_rate_name TEXT,
    new_subrate_name TEXT,
    new_rate_id UUID, -- Referencia a comparison_rates(id)
    rate_mode TEXT, -- Fija / Indexada
    
    -- Precios de la nueva tarifa (Snapshot para evitar cambios futuros)
    price_pp1 DOUBLE PRECISION,
    price_pp2 DOUBLE PRECISION,
    price_cp1 DOUBLE PRECISION,
    price_cp2 DOUBLE PRECISION,
    price_cp3 DOUBLE PRECISION,
    price_surpluses DOUBLE PRECISION,
    
    -- Resultados del Cálculo
    total_power_price DOUBLE PRECISION,
    total_consumption_price DOUBLE PRECISION,
    total_surpluses_price DOUBLE PRECISION,
    total_consumption DOUBLE PRECISION,
    total_anual_consumption DOUBLE PRECISION,
    
    new_total_price DOUBLE PRECISION, -- Precio mensual pre-IVA y sin mantenimiento
    new_total_price_with_vat DOUBLE PRECISION, -- Precio mensual final (IVA + IEE + Mant incl)
    new_total_yearly_price_with_vat DOUBLE PRECISION,

    iee_monthly DOUBLE PRECISION,
    iee DOUBLE PRECISION, -- IEE Anual
    
    savings DOUBLE PRECISION, -- Ahorro mensual
    savings_yearly DOUBLE PRECISION, -- Ahorro anual
    saving_percentage DOUBLE PRECISION,
    
    -- Rentabilidad (CRS)
    total_crs DOUBLE PRECISION,
    crs_id UUID,
    ranked_crs DOUBLE PRECISION, -- Score de ordenación: ahorro_anual + crs * 4
    
    -- Metadatos adicionales
    type TEXT DEFAULT 'light',
    has_permanence BOOLEAN,
    term_month INTEGER,
    excluded_company_ids UUID[]
);

-- Índices para optimizar búsquedas
CREATE INDEX IF NOT EXISTS idx_light_results_comparison_id ON public.comparison_light_results(comparison_id);
CREATE INDEX IF NOT EXISTS idx_light_results_advisor_id ON public.comparison_light_results(advisor_id);
CREATE INDEX IF NOT EXISTS idx_light_results_inserted_at ON public.comparison_light_results(inserted_at);

COMMENT ON TABLE public.comparison_light_results IS 'Almacena el resultado Rank 1 de las comparativas de luz calculadas por el servicio Python.';
