create table public.users_racc (
  user_id uuid not null,
  constraint users_racc_pkey primary key (user_id)
) TABLESPACE pg_default;