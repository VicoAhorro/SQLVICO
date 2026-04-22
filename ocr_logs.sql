-- Tabla de logs de OCR: registra cada llamada a los endpoints de LIA,
-- tanto si tiene éxito como si falla, guardando el resultado completo en JSONB.

create table vico.ocr_logs (
  id            uuid                     not null default gen_random_uuid(),
  created_at    timestamp with time zone not null default now(),

  -- Contexto de la llamada
  endpoint      text                     not null,  -- '/lia', '/lia/light', '/lia/gas', '/lia/3.0'
  service_type  text                     null,      -- 'light', 'gas', '3_0'
  pdf_url       text                     null,
  advisor_email text                     null,      -- email del asesor que subió la factura

  -- Resultado del procesamiento
  success       boolean                  not null default true,
  error_type    text                     null,      -- 'refusal' | 'runtime' | 'unexpected'
  error_message text                     null,

  -- Campos extraídos principales (para búsquedas rápidas sin tocar el JSONB)
  cups          text                     null,
  company       text                     null,
  total_invoice numeric(10, 2)           null,
  invoice_month text                     null,      -- '01'..'12'
  invoice_year  text                     null,      -- '2025'
  cups_valid    boolean                  null,      -- si el CUPS pasó el checksum

  -- Resultado completo del OCR
  raw_result    jsonb                    null,

  -- Timing
  duration_ms   integer                  null,

  -- Modelo OpenAI utilizado para la extracción principal
  model_used    text                     null,

  constraint ocr_logs_pkey primary key (id)
) tablespace pg_default;

-- Índices para consultas frecuentes
create index ocr_logs_created_at_idx  on vico.ocr_logs (created_at desc);
create index ocr_logs_success_idx     on vico.ocr_logs (success);
create index ocr_logs_cups_idx        on vico.ocr_logs (cups) where cups is not null;
create index ocr_logs_endpoint_idx    on vico.ocr_logs (endpoint);
create index ocr_logs_raw_result_gin  on vico.ocr_logs using gin (raw_result);

comment on table vico.ocr_logs is 'Log de todas las llamadas al OCR de LIA (éxitos y fallos).';
