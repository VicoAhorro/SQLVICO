CREATE OR REPLACE VIEW public.v_clients_contracts_payments_historic AS
SELECT
  p.id,
  p.fecha_pago,
  p.contract_id,
  p.tipo_pago,
  c.crs AS crs_total,
  p."crs cobrado" AS crs_cobrado,
  (c.crs - p."crs cobrado") AS crs_pendiente,
  p.cups,
  c.new_company
FROM public.clients_contracts_payments p
INNER JOIN public.clients_contracts c
  ON p.cups = c."CUPS";
