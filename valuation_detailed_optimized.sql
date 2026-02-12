-- ====================================================================
-- Vista optimizada de valoraciones detalladas
-- Optimizaciones aplicadas:
-- 1. Usa la vista materializada _users_supervisors_racc (pre-calculada)
-- 2. Elimina completamente el cálculo de supervisores RACC en tiempo real
-- 3. Simplificación de CASE statements
-- 4. Uso de COALESCE más eficiente
-- 5. Campo de búsqueda optimizado con LOWER
-- ====================================================================

CREATE OR REPLACE VIEW public._valuations_detailed_optimized AS
SELECT DISTINCT ON (v.id)
  v.id,
  v.contract_id,
  v.contract_type,
  
  -- Nombre del cliente (simplificado)
  COALESCE(
    CASE WHEN v.client_email IS NOT NULL AND v.client_email <> '' 
         THEN cl.name 
         ELSE NULL 
    END,
    v.temp_client_name
  ) AS temp_client_name,
  
  -- Apellido del cliente (simplificado)
  COALESCE(
    CASE WHEN v.client_email IS NOT NULL AND v.client_email <> '' 
         THEN cl.last_name 
         ELSE NULL 
    END,
    v.temp_client_last_name
  ) AS temp_client_last_name,
  
  v."CUPS",
  v.saving_percentage,
  v.crs,
  v.deleted,
  
  -- ✅ Supervisores: usar directamente la vista materializada _users_supervisors_racc
  -- Esta vista ya calcula correctamente los supervisores para usuarios RACC y no-RACC
  COALESCE(usr.supervisors, ARRAY[]::uuid[]) AS supervisors,
  
  -- Filtros
  ARRAY[v.contract_type, 'All'::text] AS contract_type_filter,
  ARRAY[v.advisor_id::text, 'All'::text] AS advisor_filter,
  ARRAY[v.new_company, 'All'::text] AS new_company_filter,
  
  -- Campo de búsqueda optimizado con LOWER para búsquedas case-insensitive
  LOWER(
    COALESCE(v.client_email, '') || ' ' ||
    COALESCE(v.temp_client_name, '') || ' ' ||
    COALESCE(v.temp_client_last_name, '') || ' ' ||
    COALESCE(v.contract_type, '') || ' ' ||
    COALESCE(u.email, '') || ' ' ||
    COALESCE(v."CUPS", '') || ' ' ||
    COALESCE(cl.name, '') || ' ' ||
    COALESCE(cl.last_name, '') || ' ' ||
    COALESCE(cl."DNI", '') || ' ' ||
    COALESCE(cl.phone_number, '') || ' ' ||
    COALESCE(v.temp_mobile_number, '')
  ) AS search,
  
  -- Fechas
  TO_CHAR(v.created_at, 'MM') AS created_month,
  TO_CHAR(v.created_at, 'YYYY') AS created_year,
  v.created_at,
  v.client_email,
  v.deleted_reason

FROM clients_valuations v
-- ✅ JOIN con la vista materializada que ya tiene los supervisores pre-calculados
LEFT JOIN _users_supervisors_racc usr ON v.advisor_id = usr.user_id
LEFT JOIN users u ON v.advisor_id = u.user_id
LEFT JOIN clients cl ON v.client_email = cl.email 
                     AND v.client_email <> ''

-- Ordenar para DISTINCT ON (consistencia)
ORDER BY v.id;