-- ====================================================================
-- Script para automatizar el refresh de _users_supervisors_racc
-- ====================================================================
-- Esta vista materializada es CRÍTICA para el rendimiento de valuation_detailed_optimized
-- Debe refrescarse cuando cambien usuarios o supervisores

-- ====================================================================
-- OPCIÓN 1: Trigger automático (RECOMENDADO)
-- ====================================================================
-- Este trigger refrescará automáticamente la vista cuando cambien usuarios

CREATE OR REPLACE FUNCTION refresh_users_supervisors_racc()
RETURNS TRIGGER AS $$
BEGIN
  -- Refrescar la vista materializada
  -- Nota: Esto puede ser lento si hay muchos usuarios
  -- Considera usar un job programado en su lugar si tienes muchos cambios
  REFRESH MATERIALIZED VIEW CONCURRENTLY _users_supervisors_racc;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger cuando se inserta, actualiza o elimina un usuario
DROP TRIGGER IF EXISTS trigger_refresh_supervisors_on_user_change ON users;
CREATE TRIGGER trigger_refresh_supervisors_on_user_change
AFTER INSERT OR UPDATE OF supervisor_id, racc, is_admin OR DELETE ON users
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_users_supervisors_racc();

-- ====================================================================
-- OPCIÓN 2: Job programado (para sistemas con muchos cambios)
-- ====================================================================
-- Si tienes muchos cambios de usuarios, es mejor refrescar periódicamente
-- Requiere la extensión pg_cron (disponible en Supabase)

-- Habilitar pg_cron (solo una vez)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Refrescar cada hora (ajusta según tus necesidades)
/*
SELECT cron.schedule(
  'refresh-users-supervisors-racc',  -- nombre del job
  '0 * * * *',                       -- cada hora en el minuto 0
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY _users_supervisors_racc$$
);
*/

-- Ver jobs programados
-- SELECT * FROM cron.job;

-- Eliminar un job si es necesario
-- SELECT cron.unschedule('refresh-users-supervisors-racc');

-- ====================================================================
-- OPCIÓN 3: Refresh manual (para desarrollo/testing)
-- ====================================================================

-- Verificar si el índice único existe (necesario para CONCURRENTLY)
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = '_users_supervisors_racc'
  AND indexdef LIKE '%UNIQUE%';

-- Si no existe, créalo
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_supervisors_racc_user_id_unique
ON _users_supervisors_racc(user_id);

-- Refrescar la vista (sin bloquear lecturas)
REFRESH MATERIALIZED VIEW CONCURRENTLY _users_supervisors_racc;

-- ====================================================================
-- Monitoreo y diagnóstico
-- ====================================================================

-- Ver tamaño y estadísticas de la vista materializada
SELECT 
  schemaname,
  matviewname,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) as size,
  (SELECT count(*) FROM _users_supervisors_racc) as row_count
FROM pg_matviews
WHERE matviewname = '_users_supervisors_racc';

-- Ver última actualización
SELECT 
  schemaname,
  tablename as matviewname,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze,
  n_live_tup as rows,
  n_dead_tup as dead_rows
FROM pg_stat_user_tables
WHERE tablename = '_users_supervisors_racc';

-- Ver si hay queries bloqueadas esperando el refresh
SELECT 
  pid,
  usename,
  state,
  wait_event_type,
  wait_event,
  query
FROM pg_stat_activity
WHERE query LIKE '%_users_supervisors_racc%'
  AND state != 'idle';

-- ====================================================================
-- Notas importantes
-- ====================================================================

/*
1. CONCURRENTLY vs normal:
   - CONCURRENTLY: No bloquea lecturas, pero requiere índice único y es más lento
   - Normal: Bloquea lecturas durante el refresh, pero es más rápido
   
2. Frecuencia de refresh:
   - Si cambias usuarios raramente: Trigger automático (Opción 1)
   - Si cambias usuarios frecuentemente: Job programado cada hora (Opción 2)
   - Para desarrollo: Manual cuando sea necesario (Opción 3)

3. Impacto en rendimiento:
   - El refresh puede tardar varios segundos si tienes muchos usuarios
   - Usa CONCURRENTLY para no bloquear la aplicación
   - Considera hacerlo en horas de bajo tráfico si es muy lento

4. Supabase específico:
   - Supabase tiene pg_cron disponible por defecto
   - Puedes configurar jobs desde el dashboard de Supabase
   - Los triggers funcionan automáticamente
*/
