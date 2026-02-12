# 🚀 Optimización valuation_detailed_optimized

## 📋 Archivos Necesarios (en orden de ejecución)

### 1️⃣ `valuation_detailed_optimized.sql` 
**Vista optimizada** - Ejecutar primero
- Reemplaza la vista actual con la versión optimizada
- Usa `_users_supervisors_racc` (vista materializada existente)
- Elimina el subquery costoso

### 2️⃣ `valuation_detailed_optimized_indexes.sql`
**Índices** - Ejecutar segundo
- Crea índices necesarios para máximo rendimiento
- El más importante: `idx_users_supervisors_racc_user_id`

### 3️⃣ `refresh_users_supervisors_racc.sql`
**Mantenimiento** - Ejecutar tercero (opcional pero recomendado)
- Configura trigger o job para mantener `_users_supervisors_racc` actualizada
- Elige OPCIÓN 1 (trigger) o OPCIÓN 2 (job programado)

---

## ⚡ Ejecución Rápida

```sql
-- 1. Aplicar vista optimizada
\i valuation_detailed_optimized.sql

-- 2. Crear índices
\i valuation_detailed_optimized_indexes.sql

-- 3. Configurar mantenimiento (ejecutar solo la sección OPCIÓN 1 o OPCIÓN 2)
\i refresh_users_supervisors_racc.sql
```

---

## 📊 Mejora Esperada

- **CPU**: ↓ 70-85%
- **Tiempo**: ↓ 60-75%
- **Problema resuelto**: Subquery que se ejecutaba N veces → ahora usa vista materializada

---

## ⚠️ Importante

La vista `_users_supervisors_racc` ya existe en tu BD y es la clave de la optimización. Solo necesita:
1. Índice único (se crea en paso 2)
2. Mantenerse actualizada (se configura en paso 3)

---

## 📖 Documentación Completa

Ver `OPTIMIZACION_VALUATION.md` para detalles técnicos (opcional)
