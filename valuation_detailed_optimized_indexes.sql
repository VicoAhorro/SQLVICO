-- ====================================================================
-- Índices recomendados para optimizar valuation_detailed_optimized
-- ====================================================================
-- Ejecuta estos índices en Supabase para mejorar el rendimiento de la vista
-- IMPORTANTE: Ejecuta uno por uno y monitorea el impacto en CPU

-- 1. Índice en advisor_id (usado en múltiples JOINs) - CRÍTICO
CREATE INDEX IF NOT EXISTS idx_clients_valuations_advisor_id 
ON clients_valuations(advisor_id) 
WHERE deleted = FALSE OR deleted IS NULL;

-- 2. Índice en client_email (usado en JOIN con clients)
CREATE INDEX IF NOT EXISTS idx_clients_valuations_client_email 
ON clients_valuations(client_email) 
WHERE client_email IS NOT NULL AND client_email <> '';

-- 3. Índice compuesto para filtrado común
CREATE INDEX IF NOT EXISTS idx_clients_valuations_deleted_created 
ON clients_valuations(deleted, created_at DESC);

-- 4. Índice en clients.email para el JOIN
CREATE INDEX IF NOT EXISTS idx_clients_email 
ON clients(email) 
WHERE email IS NOT NULL AND email <> '';

-- 5. Índice en users.user_id para el JOIN
CREATE INDEX IF NOT EXISTS idx_users_user_id 
ON users(user_id);

-- 6. ⭐ NUEVO: Índice en _users_supervisors_racc (vista materializada) - MUY IMPORTANTE
CREATE INDEX IF NOT EXISTS idx_users_supervisors_racc_user_id 
ON _users_supervisors_racc(user_id);

-- NOTA: Los índices 7 y 8 originales ya no son necesarios porque usamos _users_supervisors_racc

-- 7. Índice en _users_supervisors para el JOIN
CREATE INDEX IF NOT EXISTS idx_users_supervisors_user_id 
ON _users_supervisors(user_id);

-- ====================================================================
-- Análisis de rendimiento (ejecutar después de crear índices)
-- ====================================================================

-- Ver el plan de ejecución de la vista
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT * FROM _valuations_detailed_optimized 
LIMIT 100;

-- Ver estadísticas de la tabla principal
SELECT 
  schemaname,
  tablename,
  n_live_tup as "Filas vivas",
  n_dead_tup as "Filas muertas",
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables 
WHERE tablename = 'clients_valuations';

-- ====================================================================
-- Mantenimiento recomendado
-- ====================================================================

-- ⭐ CRÍTICO: Mantener actualizada la vista materializada _users_supervisors_racc
-- Esta vista es la clave del rendimiento de valuation_detailed_optimized

-- Ver cuándo fue la última actualización
SELECT 
  schemaname,
  matviewname,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) as size,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables 
WHERE tablename = '_users_supervisors_racc';

-- Refrescar la vista materializada (ejecutar cuando cambien usuarios/supervisores)
REFRESH MATERIALIZED VIEW CONCURRENTLY _users_supervisors_racc;

-- Si no existe índice en la vista materializada, créalo primero para poder usar CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_supervisors_racc_user_id_unique
ON _users_supervisors_racc(user_id);

-- Ahora sí puedes refrescar concurrentemente (sin bloquear lecturas)
REFRESH MATERIALIZED VIEW CONCURRENTLY _users_supervisors_racc;

-- ====================================================================
-- Ejecutar VACUUM ANALYZE después de crear los índices
VACUUM ANALYZE clients_valuations;
VACUUM ANALYZE clients;
VACUUM ANALYZE users;
VACUUM ANALYZE _users_supervisors_racc;

-- ====================================================================
-- Opcional: Materializar la vista si los datos no cambian frecuentemente
-- ====================================================================

-- Si la vista se consulta mucho pero los datos no cambian tan seguido,
-- considera crear una vista materializada:

/*
CREATE MATERIALIZED VIEW IF NOT EXISTS _valuations_detailed_optimized_mat AS
SELECT * FROM _valuations_detailed_optimized;

-- Crear índice en la vista materializada
CREATE INDEX idx_valuations_mat_id ON _valuations_detailed_optimized_mat(id);
CREATE INDEX idx_valuations_mat_advisor ON _valuations_detailed_optimized_mat(advisor_id);
CREATE INDEX idx_valuations_mat_created ON _valuations_detailed_optimized_mat(created_at DESC);

-- Refrescar la vista materializada (ejecutar periódicamente o con trigger)
REFRESH MATERIALIZED VIEW CONCURRENTLY _valuations_detailed_optimized_mat;
*/
