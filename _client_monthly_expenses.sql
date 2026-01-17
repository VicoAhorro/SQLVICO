create or replace view public._clients_monthly_expenses as
select
  c.client_email,
  c.client_address_id,
  to_char(
    make_date(ci.invoice_year, ci.invoice_month, 1)::timestamp with time zone,
    'YYYY-MM'::text
  ) as month_year,
  COALESCE(
    sum(
      case
        when c.contract_type = any (array['light'::text, '3_0'::text]) then ci.total_invoice
        else 0::real
      end
    ),
    0::real
  ) as luz_spent,
  COALESCE(
    sum(
      case
        when c.contract_type = 'gas'::text then ci.total_invoice
        else 0::real
      end
    ),
    0::real
  ) as gas_spent,
  COALESCE(
    sum(
      case
        when c.contract_type = 'phone'::text then ci.total_invoice
        else 0::real
      end
    ),
    0::real
  ) as phone_spent,
  COALESCE(
    sum(
      case
        when c.contract_type = 'seguros'::text then ci.total_invoice
        else 0::real
      end
    ),
    0::real
  ) as seguros_spent,
  COALESCE(
    sum(
      case
        when c.contract_type = any (array['light'::text, '3_0'::text, 'gas'::text]) then ci.total_invoice
        else 0::real
      end
    ),
    0::real
  ) as energia_spent,
  COALESCE(sum(ci.total_invoice), 0::real) as total_spent
from
  _contracts_detailed c
  left join clients_invoices ci on c."CUPS" = ci."CUPS"
where
  ci.invoice_year is not null
  and ci.invoice_month is not null
group by
  c.client_email,
  c.client_address_id,
  (
    to_char(
      make_date(ci.invoice_year, ci.invoice_month, 1)::timestamp with time zone,
      'YYYY-MM'::text
    )
  )
order by
  c.client_email,
  (
    to_char(
      make_date(ci.invoice_year, ci.invoice_month, 1)::timestamp with time zone,
      'YYYY-MM'::text
    )
  ) desc;