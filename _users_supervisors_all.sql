create materialized view public._users_supervisors_all as
with recursive
  -- 1. Construcción de la cadena jerárquica con protección contra bucles infinitos
  supervisor_chain as (
    -- Caso base: Cada usuario y su supervisor inmediato
    select
      user_id,
      supervisor_id,
      array[user_id] || case when supervisor_id is not null then array[supervisor_id] else array[]::uuid[] end as chain
    from
      users
    union all
    -- Paso recursivo: Subir niveles en la jerarquía
    select
      sc.user_id,
      u.supervisor_id,
      sc.chain || u.supervisor_id
    from
      supervisor_chain sc
      join users u on u.user_id = sc.supervisor_id
    where
      u.supervisor_id is not null
      and not (u.supervisor_id = any(sc.chain))
  ),
  -- 2. Identificamos la cadena de mando más larga para cada usuario
  longest_chains as (
    select distinct on (user_id)
      user_id,
      chain
    from supervisor_chain
    order by user_id, array_length(chain, 1) desc
  ),
  -- 3. Identificamos administradores y grupo RACC para permisos especiales
  admins as (
    select COALESCE(array_agg(user_id), array[]::uuid[]) as ids
    from users
    where is_admin = true
  ),
  racc_all_group as (
    select array_agg(distinct user_id) as ids
    from users
    where tenant = 1 or racc = true or is_admin = true
  )
select
  u.tenant,
  u.user_id,
  -- Lógica de permisos: RACC (tenant 1) ve todo su grupo; el resto ve su jerarquía + admins
  case
    when u.tenant = 1 or u.racc = true then (select ids from racc_all_group)
    else COALESCE(lc.chain, array[u.user_id]) || COALESCE(a.ids, array[]::uuid[])
  end as supervisors,
  u.email,
  concat(u.name, ' ', u.last_name) as display_name,
  (u.tenant = 1 or u.racc = true) as racc,
  case
    when u.tenant = 1 then u.email
    else COALESCE(
      NULLIF(
        btrim(
          concat(u.name, ' ', COALESCE(u.last_name, ''::text))
        ),
        ''::text
      ),
      u.email
    )
  end as flutter_name
from
  users u
  left join longest_chains lc on lc.user_id = u.user_id
  cross join admins a
with no data;

-- Índice para búsquedas rápidas por ID de usuario
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_supervisors_all_user_id ON public._users_supervisors_all (user_id);

-- Refresco inicial de datos
REFRESH MATERIALIZED VIEW public._users_supervisors_all;