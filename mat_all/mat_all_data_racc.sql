drop materialized view if exists public.mat_all_data_racc cascade;
create materialized view public.mat_all_data_racc as
select
  mat_all_data.source,
  mat_all_data.id,
  mat_all_data.created_at,
  mat_all_data.activation_date,
  mat_all_data.client_email,
  mat_all_data.advisor_id,
  mat_all_data.advisor_email,
  mat_all_data.name,
  mat_all_data.last_name,
  mat_all_data."DNI",
  mat_all_data.address,
  mat_all_data.phone,
  mat_all_data.client_type,
  mat_all_data.contract_type,
  mat_all_data.new_company,
  mat_all_data.new_rate_name,
  mat_all_data.new_subrate,
  mat_all_data.saving_percentage,
  mat_all_data.pdf_invoice,
  mat_all_data.total_savings,
  mat_all_data."CUPS",
  mat_all_data.status,
  mat_all_data.subestadocompanias,
  mat_all_data.last_update,
  mat_all_data.fecha_baja,
  mat_all_data.baja_firma_delegada,
  mat_all_data.firma_date,
  mat_all_data.valuation_id,
  mat_all_data.valuation_created_at,
  mat_all_data.pdf_proposal,
  mat_all_data.comparison_id,
  mat_all_data.comparison_created_at,
  mat_all_data.deleted,
  mat_all_data.deleted_reason,
  mat_all_data.deleted_at,
  mat_all_data.incident_date,
  mat_all_data.incident_type,
  mat_all_data.rate_type,
  mat_all_data.rejected_type,
  mat_all_data.proposed_company,
  mat_all_data.proposed_rate_type,
  mat_all_data.changed_by,
  mat_all_data.changed_by_email
from
  mat_all_data
where
  mat_all_data.tenant = 1;

-- Índices para mat_all_data_racc
CREATE UNIQUE INDEX IF NOT EXISTS mat_all_data_racc_unique_idx ON public.mat_all_data_racc (source, id);
CREATE INDEX IF NOT EXISTS mat_all_data_racc_cups_idx ON public.mat_all_data_racc ("CUPS");
CREATE INDEX IF NOT EXISTS mat_all_data_racc_email_idx ON public.mat_all_data_racc (client_email);
CREATE INDEX IF NOT EXISTS mat_all_data_racc_dni_idx ON public.mat_all_data_racc ("DNI");
CREATE INDEX IF NOT EXISTS mat_all_data_racc_advisor_idx ON public.mat_all_data_racc (advisor_id);
CREATE INDEX IF NOT EXISTS mat_all_data_racc_status_idx ON public.mat_all_data_racc (status);
CREATE INDEX IF NOT EXISTS mat_all_data_racc_created_at_idx ON public.mat_all_data_racc (created_at DESC);
CREATE INDEX IF NOT EXISTS mat_all_data_racc_valuation_id_idx ON public.mat_all_data_racc (valuation_id);
