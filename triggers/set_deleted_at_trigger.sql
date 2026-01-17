-- =====================================================
-- Función trigger para establecer deleted_at automáticamente
-- cuando deleted cambia a TRUE
-- =====================================================

CREATE OR REPLACE FUNCTION public.set_deleted_at_on_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Si deleted cambia de FALSE/NULL a TRUE y deleted_at es NULL
  IF NEW.deleted = TRUE 
     AND (OLD.deleted IS NULL OR OLD.deleted = FALSE)
     AND NEW.deleted_at IS NULL THEN
    NEW.deleted_at := NOW();
  END IF;
  
  -- Si deleted vuelve a FALSE, limpiar deleted_at
  IF NEW.deleted = FALSE AND OLD.deleted = TRUE THEN
    NEW.deleted_at := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Aplicar el trigger a todas las tablas de comparación
-- =====================================================

-- Trigger para comparison_light
DROP TRIGGER IF EXISTS trg_set_deleted_at ON public.comparison_light;
CREATE TRIGGER trg_set_deleted_at
  BEFORE UPDATE ON public.comparison_light
  FOR EACH ROW
  EXECUTE FUNCTION public.set_deleted_at_on_delete();

-- Trigger para comparison_3_0
DROP TRIGGER IF EXISTS trg_set_deleted_at ON public.comparison_3_0;
CREATE TRIGGER trg_set_deleted_at
  BEFORE UPDATE ON public.comparison_3_0
  FOR EACH ROW
  EXECUTE FUNCTION public.set_deleted_at_on_delete();

-- Trigger para comparison_gas
DROP TRIGGER IF EXISTS trg_set_deleted_at ON public.comparison_gas;
CREATE TRIGGER trg_set_deleted_at
  BEFORE UPDATE ON public.comparison_gas
  FOR EACH ROW
  EXECUTE FUNCTION public.set_deleted_at_on_delete();

-- Trigger para comparison_phone
DROP TRIGGER IF EXISTS trg_set_deleted_at ON public.comparison_phone;
CREATE TRIGGER trg_set_deleted_at
  BEFORE UPDATE ON public.comparison_phone
  FOR EACH ROW
  EXECUTE FUNCTION public.set_deleted_at_on_delete();

-- Trigger para clients_contracts
DROP TRIGGER IF EXISTS trg_set_deleted_at ON public.clients_contracts;
CREATE TRIGGER trg_set_deleted_at
  BEFORE UPDATE ON public.clients_contracts
  FOR EACH ROW
  EXECUTE FUNCTION public.set_deleted_at_on_delete();

-- Trigger para clients_valuations
DROP TRIGGER IF EXISTS trg_set_deleted_at ON public.clients_valuations;
CREATE TRIGGER trg_set_deleted_at
  BEFORE UPDATE ON public.clients_valuations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_deleted_at_on_delete();

-- =====================================================
-- Comentarios
-- =====================================================

COMMENT ON FUNCTION public.set_deleted_at_on_delete() IS 
  'Función trigger que establece deleted_at automáticamente cuando deleted cambia a TRUE, y lo limpia cuando vuelve a FALSE';
