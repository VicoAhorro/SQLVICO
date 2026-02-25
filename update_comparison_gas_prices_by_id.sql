DECLARE
  v_totalfijo NUMERIC := 0;
  v_totalconsumo NUMERIC := 0;
  v_days INTEGER := 0;
  v_consumption NUMERIC := 0;
  v_vat NUMERIC := 0;
  v_equipment NUMERIC := 0;
  v_impuesto_gas NUMERIC := 0;
  v_total_final NUMERIC := 0;
BEGIN
  SELECT 
    COALESCE(c.totalfijo, 0),
    COALESCE(c.totalconsumo, 0),
    COALESCE(c.days, 0),
    COALESCE(c.consumption, 0),
    COALESCE(c."VAT", 0),
    COALESCE(c.equipment_rental, 0)
  INTO 
    v_totalfijo, v_totalconsumo, v_days, v_consumption, v_vat, v_equipment
  FROM public.comparison_gas c
  WHERE c.id = _id AND NOT c.deleted;

  -- Cálculo del impuesto especial sobre hidrocarburos
  v_impuesto_gas := v_consumption * 0.00234;

  -- Cálculo del total estimado incluyendo impuesto antes del IVA
  v_total_final := ROUND((v_totalconsumo + v_totalfijo + v_equipment + v_impuesto_gas) * (1 + v_vat), 2);

  UPDATE public.comparison_gas
  SET
    "precio fijo actual dia" = CASE 
                                 WHEN v_days <> 0 
                                 THEN v_totalfijo / v_days
                                 ELSE 0 
                               END,
    "precio actual kw" = CASE 
                           WHEN v_consumption <> 0 
                           THEN v_totalconsumo / v_consumption
                           ELSE 0 
                         END,
    "current_total_invoice" = v_total_final
  WHERE id = _id AND NOT deleted;
END;