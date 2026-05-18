-- =============================================================
-- Tabla de plataformas de streaming
-- Catálogo de plataformas (Netflix, Disney+, HBO, etc.) con su
-- precio mensual estándar para sumar al cálculo del pack +TV.
-- =============================================================

create table if not exists public.streaming_platforms (
  id uuid not null default gen_random_uuid (),
  name text not null,
  slug text not null,
  monthly_price numeric(8, 2) not null default 0,
  logo_url text null,
  description text null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint streaming_platforms_pkey primary key (id),
  constraint streaming_platforms_slug_key unique (slug)
) TABLESPACE pg_default;

create index if not exists idx_streaming_platforms_active
  on public.streaming_platforms using btree (is_active, sort_order) TABLESPACE pg_default;


-- =============================================================
-- Tabla pivote: plataformas seleccionadas en cada comparativa phone
-- =============================================================

create table if not exists public.comparison_phone_streaming_platforms (
  id uuid not null default gen_random_uuid (),
  comparison_phone_id uuid not null,
  streaming_platform_id uuid not null,
  monthly_price numeric(8, 2) not null default 0, -- snapshot del precio al guardar
  created_at timestamp with time zone not null default now(),
  constraint comparison_phone_streaming_pkey primary key (id),
  constraint comparison_phone_streaming_unique
    unique (comparison_phone_id, streaming_platform_id),
  constraint comparison_phone_streaming_phone_fk
    foreign key (comparison_phone_id) references comparison_phone (id) on delete cascade,
  constraint comparison_phone_streaming_platform_fk
    foreign key (streaming_platform_id) references streaming_platforms (id) on delete restrict
) TABLESPACE pg_default;

create index if not exists idx_comparison_phone_streaming_comparison
  on public.comparison_phone_streaming_platforms using btree (comparison_phone_id) TABLESPACE pg_default;

create index if not exists idx_comparison_phone_streaming_platform
  on public.comparison_phone_streaming_platforms using btree (streaming_platform_id) TABLESPACE pg_default;


-- =============================================================
-- Seed inicial de plataformas
-- ON CONFLICT (slug) garantiza idempotencia: puede re-ejecutarse.
-- Los precios son orientativos (suscripción individual estándar).
-- =============================================================

insert into public.streaming_platforms (name, slug, monthly_price, sort_order, logo_url) values
  ('Netflix Estándar',     'netflix-estandar',     13.99,  10, null),
  ('Netflix Premium',      'netflix-premium',      19.99,  11, null),
  ('Disney+ Estándar',     'disney-plus-estandar', 9.99,   20, null),
  ('Disney+ Premium',      'disney-plus-premium',  13.99,  21, null),
  ('HBO Max',              'hbo-max',              9.99,   30, null),
  ('Amazon Prime Video',   'amazon-prime-video',   4.99,   40, null),
  ('Apple TV+',            'apple-tv-plus',        9.99,   50, null),
  ('YouTube Premium',      'youtube-premium',      12.99,  60, null),
  ('Movistar Plus+',       'movistar-plus',        14.00,  70, null),
  ('DAZN',                 'dazn',                 14.99,  80, null),
  ('SkyShowtime',          'skyshowtime',          5.99,   90, null),
  ('Filmin',               'filmin',               7.99,   100, null),
  ('Crunchyroll',          'crunchyroll',          5.99,   110, null),
  ('Spotify Premium',      'spotify-premium',      10.99,  120, null)
on conflict (slug) do update
  set name = excluded.name,
      monthly_price = excluded.monthly_price,
      sort_order = excluded.sort_order,
      updated_at = now();


-- =============================================================
-- Trigger para mantener updated_at en streaming_platforms
-- =============================================================

create or replace function public.set_streaming_platforms_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_streaming_platforms_updated_at on public.streaming_platforms;

create trigger trg_streaming_platforms_updated_at
  before update on public.streaming_platforms
  for each row
  execute function public.set_streaming_platforms_updated_at();
