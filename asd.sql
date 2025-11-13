INSERT INTO public.comparison_rates_numeric (
  company,
  rate_name,
  price_pp1,
  price_pp2,
  price_pp3,
  price_pp4,
  price_pp5,
  price_pp6,
  price_cp1,
  price_cp2,
  price_cp3,
  price_cp4,
  price_cp5,
  price_cp6,
  type,
  selfconsumption,
  price_surpluses,
  invoice_month,
  invoice_year,
  subrate_name,
  cif,
  region,
  has_maintenance,
  daily_maintenance_with_vat,
  has_permanence,
  rate_mode,
  last_update,
  deleted,
  tenant_id
) VALUES (
  'GALP',                -- company
  'INDEX 15',                   -- rate_name
  0.053859,                          -- price_pp1
  0.028087,                          -- price_pp2
  0.011678,                          -- price_pp3
  0.010086,                          -- price_pp4
  0.006379,                          -- price_pp5
  0.003716,                          -- price_pp6
  0.20                          -- price_cp1
  0.18,                          -- price_cp2
  0.16,                          -- price_cp3
  0.14,                          -- price_cp4
  0.12,                          -- price_cp5
  0.10,                          -- price_cp6
  '3_0',                 -- type
  false,                         -- selfconsumption
  0,                          -- price_surpluses
  100,                            -- invoice_month
  2025,                          -- invoice_year
  '3.0',                -- subrate_name
  false,                         -- cif
  ARRAY['PENINSULA','CANARIAS','BALEARES'],                   -- region
  false,                         -- has_maintenance
  0,                             -- daily_maintenance_with_vat
  false,                         -- has_permanence
  'Indexada',                        -- rate_mode  (debe existir en rate_mode_type)
  NOW(),                         -- last_update
  false,                         -- deleted
  '{0,1,2,3}'                    -- tenant_id
);
