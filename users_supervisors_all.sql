DROP MATERIALIZED VIEW IF EXISTS public._users_supervisors_all;

CREATE MATERIALIZED VIEW public._users_supervisors_all AS
WITH RECURSIVE
  supervisor_chain AS (
    SELECT
      u1.user_id,
      u1.supervisor_id,
      ARRAY[u1.user_id, u1.supervisor_id] AS all_supervisors
    FROM users u1
    WHERE u1.supervisor_id IS NOT NULL
    UNION ALL
    SELECT
      sc.user_id,
      u1.supervisor_id,
      sc.all_supervisors || u1.supervisor_id
    FROM supervisor_chain sc
    JOIN users u1 ON u1.user_id = sc.supervisor_id
    WHERE u1.supervisor_id IS NOT NULL
  ),
  admins AS (
    SELECT COALESCE(array_agg(u_1.user_id), ARRAY[]::uuid[]) AS ids
    FROM users u_1
    WHERE u_1.is_admin = TRUE
  ),
  racc_group AS (
    SELECT COALESCE(array_agg(u_1.user_id), ARRAY[]::uuid[]) AS ids
    FROM users u_1
    WHERE u_1.racc = TRUE
  )
SELECT
  u.tenant,
  u.user_id,
  CASE
    WHEN u.racc = TRUE THEN (
      SELECT ARRAY(SELECT DISTINCT x.x FROM unnest(rg.ids || a.ids) AS x(x))
      FROM racc_group rg, admins a
    )
    ELSE (
      SELECT ARRAY(
        SELECT DISTINCT x.x
        FROM unnest(
          COALESCE(
            (
              SELECT sc2.all_supervisors
              FROM supervisor_chain sc2
              WHERE sc2.user_id = u.user_id
              ORDER BY array_length(sc2.all_supervisors, 1) DESC
              LIMIT 1
            ),
            ARRAY[u.user_id]
          ) || a.ids
        ) AS x(x)
      )
      FROM admins a
    )
  END AS supervisors,
  u.email,
  CONCAT(u.name, ' ', u.last_name) AS display_name,
  CASE
    WHEN u.tenant = 1 THEN u.email
    ELSE
      COALESCE(
        NULLIF(BTRIM(CONCAT(u.name, ' ', COALESCE(u.last_name, ''))), ''),
        CASE WHEN u.name = '-' THEN NULL ELSE NULL END,
        u.email
      )
  END AS flutter_name
FROM users u;

CREATE UNIQUE INDEX ON public._users_supervisors_all (user_id);