-- 1. Función de apoyo para el trigger (sin cambios, usa OR REPLACE)
CREATE OR REPLACE FUNCTION public.set_contract_id_from_cups()
 RETURNS trigger
 LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.cups IS NOT NULL THEN
    SELECT id INTO NEW.contract_id
    FROM public.clients_contracts
    WHERE cups = NEW.cups
    LIMIT 1;
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION public.set_contract_id_from_cups() OWNER TO postgres;

-- 2. Asegurar limpieza antes de restaurar para evitar colisiones de índices/constraints
-- ATENCIÓN: Esto borrará los datos actuales de la tabla si existen.
DROP TABLE IF EXISTS public.clients_contracts_payments CASCADE;

-- 3. Creación de la tabla desde cero
CREATE TABLE public.clients_contracts_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    "crs cobrado" real,
    contract_id uuid,
    cups text,
    tipo_pago text,
    fecha_pago date,
    colaborador text,
    CONSTRAINT clients_contracts_payments_pkey PRIMARY KEY (id)
);

ALTER TABLE public.clients_contracts_payments OWNER TO postgres;

-- 4. Restricciones de Clave Foránea
ALTER TABLE public.clients_contracts_payments
    ADD CONSTRAINT clients_contracts_payments_contract_id_fkey 
    FOREIGN KEY (contract_id) REFERENCES public.clients_contracts(id) ON DELETE CASCADE;

-- 5. Trigger para auto-asignar contract_id basado en el CUPS
CREATE TRIGGER before_insert_clients_contracts_payments 
BEFORE INSERT ON public.clients_contracts_payments 
FOR EACH ROW EXECUTE FUNCTION public.set_contract_id_from_cups();

-- 6. Habilitar Seguridad (RLS)
ALTER TABLE public.clients_contracts_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients_contracts_payments FORCE ROW LEVEL SECURITY;
