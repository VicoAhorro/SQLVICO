# Optimización de valuation_detailed_optimized

## 🎯 Problema Original

La vista `valuation_detailed_optimized` estaba causando un alto uso de CPU en Supabase debido a:

1. **Subquery en SELECT** (líneas 21-26): Se ejecutaba para CADA fila donde `u.racc = true`
2. **Sin índices apropiados**: Los JOINs no estaban optimizados
3. **Concatenación de strings ineficiente**: `concat_ws` con muchos campos
4. **DISTINCT ON sin ORDER BY**: Comportamiento impredecible

## ✅ Optimizaciones Aplicadas

### 1. **Uso de vista materializada _users_supervisors_racc** ⭐ (CLAVE)
```sql
-- ANTES: Subquery que se ejecutaba N veces
CASE
  WHEN u.racc = true THEN (
    SELECT array_cat(us.supervisors, array_agg(ur.user_id))
    FROM users_racc ur  -- ❌ Se ejecutaba para CADA fila con racc=true
  )
  ELSE us.supervisors
END

-- DESPUÉS: Usar la vista materializada existente
LEFT JOIN _users_supervisors_racc usr ON v.advisor_id = usr.user_id
...
COALESCE(usr.supervisors, ARRAY[]::uuid[]) AS supervisors
```

**Impacto**: 
- ✅ **Eliminación COMPLETA** del subquery costoso
- ✅ La vista materializada ya pre-calcula todos los supervisores (RACC y no-RACC)
- ✅ Reduce de O(n) a O(1) - simple lookup en tabla materializada
- ✅ **Esta es la optimización más importante**

### 2. **Eliminación de CTEs innecesarios**
```sql
-- ANTES: CTEs para calcular supervisores
WITH racc_supervisors AS (...), base_data AS (...)

-- DESPUÉS: Query directo usando la vista materializada
SELECT DISTINCT ON (v.id) ...
FROM clients_valuations v
LEFT JOIN _users_supervisors_racc usr ON v.advisor_id = usr.user_id
```

**Beneficios**:
- Código más simple y legible
- Menos overhead de procesamiento
- El optimizador de PostgreSQL trabaja mejor

### 3. **Simplificación de CASE statements**
```sql
-- ANTES: Dos condiciones separadas
CASE
  WHEN v.client_email is null OR v.client_email = ''::text 
  THEN v.temp_client_name
  ELSE COALESCE(cl.name, v.temp_client_name)
END

-- DESPUÉS: Más eficiente
COALESCE(
  CASE WHEN bd.client_email IS NOT NULL AND bd.client_email <> '' 
       THEN cl.name 
       ELSE NULL 
  END,
  bd.temp_client_name
)
```

### 4. **Campo de búsqueda optimizado**
```sql
-- ANTES: concat_ws (más lento)
concat_ws(' '::text, v.client_email, v.temp_client_name, ...)

-- DESPUÉS: Concatenación directa + LOWER
LOWER(
  COALESCE(bd.client_email, '') || ' ' ||
  COALESCE(bd.temp_client_name, '') || ' ' ||
  ...
)
```

**Beneficio**: Búsquedas case-insensitive más eficientes

### 5. **ORDER BY explícito para DISTINCT ON**
```sql
SELECT DISTINCT ON (bd.id)
  ...
FROM base_data bd
...
ORDER BY bd.id;
```

**Beneficio**: Comportamiento consistente y predecible

## 📊 Mejoras de Rendimiento Esperadas

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Subqueries por fila | N (donde N = filas con racc=true) | 0 | 100% |
| Complejidad supervisores | O(n) | O(1) | ~99% |
| Uso de CPU | Alto | Bajo-Medio | 60-80% |
| Tiempo de respuesta | Variable | Consistente | 50-70% |

## 🔧 Pasos Siguientes Recomendados

### 1. Aplicar la vista optimizada
```sql
-- Ejecutar el archivo valuation_detailed_optimized.sql en Supabase
```

### 2. Crear índices (IMPORTANTE)
```sql
-- Ejecutar valuation_detailed_optimized_indexes.sql
-- Esto creará los índices necesarios para maximizar el rendimiento
```

### 3. Crear índices (IMPORTANTE)
```sql
-- Ejecutar valuation_detailed_optimized_indexes.sql
-- Esto creará los índices necesarios para maximizar el rendimiento
```

### 4. ⭐ Configurar refresh de _users_supervisors_racc (CRÍTICO)
La vista `_users_supervisors_racc` es materializada, lo que significa que necesita refrescarse cuando cambien usuarios o supervisores.

**Opción recomendada: Trigger automático**
```sql
-- Ejecutar refresh_users_supervisors_racc.sql
-- Esto configurará un trigger que refresca automáticamente la vista
```

**Alternativa: Job programado (si hay muchos cambios)**
```sql
-- Refrescar cada hora usando pg_cron
SELECT cron.schedule(
  'refresh-users-supervisors-racc',
  '0 * * * *',  -- cada hora
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY _users_supervisors_racc$$
);
```

### 5. Monitorear el rendimiento
```sql
-- Ver el plan de ejecución
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM _valuations_detailed_optimized 
LIMIT 100;
```

### 4. Considerar vista materializada (opcional)
Si los datos no cambian muy frecuentemente pero la vista se consulta mucho:

```sql
CREATE MATERIALIZED VIEW _valuations_detailed_optimized_mat AS
SELECT * FROM _valuations_detailed_optimized;

-- Refrescar periódicamente (ej: cada hora)
REFRESH MATERIALIZED VIEW CONCURRENTLY _valuations_detailed_optimized_mat;
```

## ⚠️ Notas Importantes

1. **Backup**: Antes de aplicar, haz backup de la vista original
2. **Testing**: Prueba en desarrollo antes de producción
3. **Índices**: Los índices son CRÍTICOS para el rendimiento óptimo
4. **Monitoreo**: Observa las métricas de CPU en Supabase después de aplicar

## 🔍 Diagnóstico Adicional

Si después de aplicar estas optimizaciones el CPU sigue alto:

1. **Verificar índices**:
```sql
SELECT * FROM pg_indexes 
WHERE tablename IN ('clients_valuations', 'clients', 'users');
```

2. **Ver queries lentas**:
```sql
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
WHERE query LIKE '%valuations_detailed%'
ORDER BY total_time DESC;
```

3. **Analizar tamaño de tabla**:
```sql
SELECT 
  pg_size_pretty(pg_total_relation_size('clients_valuations')) as size,
  (SELECT count(*) FROM clients_valuations) as rows;
```

## 📈 Alternativas Adicionales

Si el problema persiste, considera:

1. **Particionamiento**: Si hay muchos registros históricos
2. **Archivado**: Mover registros antiguos a tabla de archivo
3. **Caché**: Implementar caché en la aplicación
4. **Paginación**: Limitar resultados por defecto
