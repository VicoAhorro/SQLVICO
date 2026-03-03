-- Limpieza de Triggers obsoletos migrados a Celery
-- Este script elimina los triggers que ejecutaban lógica pesada directamente en Supabase
-- y que ahora son gestionados de forma asíncrona por Celery.

-- 1. Eliminar triggers de la tabla users
DROP TRIGGER IF EXISTS trg_refresh_supervisors_all ON public.users;
DROP TRIGGER IF EXISTS trg_refresh_users_supervisors_racc ON public.users;
DROP TRIGGER IF EXISTS trg_update_users_racc ON public.users;
DROP TRIGGER IF EXISTS trigger_refresh_on_users ON public.users;

-- 2. Eliminar las funciones asociadas para limpiar el esquema
-- (Solo si no se usan en otros lugares)
DROP FUNCTION IF EXISTS public.refresh_supervisors_all_on_insert();
DROP FUNCTION IF EXISTS public.refresh_users_supervisors_racc();
DROP FUNCTION IF EXISTS public.update_users_racc_trigger();
DROP FUNCTION IF EXISTS public.refresh_users_supervisors_view();

-- NOTA: MANTENEMOS el trigger 'user_changes_notify_trigger' y la función 'notify_user_changes()'
-- ya que son necesarios para que el postgres_listener de la API detecte cambios
-- y envíe las tareas a Celery.

-- Opcional: Verificar que el trigger de notificación sigue activo
-- SELECT trigger_name FROM information_schema.triggers WHERE event_object_table = 'users' AND trigger_name = 'user_changes_notify_trigger';
