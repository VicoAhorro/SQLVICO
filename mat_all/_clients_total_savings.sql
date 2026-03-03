create materialized view public._clients_total_savings as
select
  c.client_email,
  COALESCE(SUM(ci.total_invoice * c.saving_percentage), 0)::double precision as total_savings
from
  public.clients_contracts c
  join public.clients_invoices ci on ci."CUPS" = c."CUPS"
where
  c.deleted = false
group by
  c.client_email;

CREATE INDEX IF NOT EXISTS idx_clients_total_savings_email ON public._clients_total_savings (client_email);

REFRESH MATERIALIZED VIEW public._clients_total_savings;