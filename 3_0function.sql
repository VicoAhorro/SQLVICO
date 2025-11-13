DECLARE
  totalfijo NUMERIC := 0;
  totalvariable NUMERIC := 0;
  diasdefactura NUMERIC := 0;
  tarifa TEXT := '';
  potencia_1 NUMERIC := 0;
  potencia_2 NUMERIC := 0;
  potencia_3 NUMERIC := 0;
  potencia_4 NUMERIC := 0;
  potencia_5 NUMERIC := 0;
  potencia_6 NUMERIC := 0;
  consumo_1 NUMERIC := 0;
  consumo_2 NUMERIC := 0;
  consumo_3 NUMERIC := 0;
  consumo_4 NUMERIC := 0;
  consumo_5 NUMERIC := 0;
  consumo_6 NUMERIC := 0;
  vat NUMERIC := 0;
  equipment NUMERIC := 0;

  p NUMERIC[6];
  consumo NUMERIC[6];

  suma_potencia NUMERIC := 0;
  consumo_total NUMERIC := 0;
  precio_kwh_base NUMERIC := 0;
  precio_kwh NUMERIC[6] := ARRAY[0, 0, 0, 0, 0, 0];
  precio_kw NUMERIC[6] := ARRAY[0, 0, 0, 0, 0, 0];
  peajes NUMERIC[6] := ARRAY[0, 0, 0, 0, 0, 0];

  current_invoice_estimate NUMERIC := 0;
BEGIN
  SELECT 
    totalpotencia, totalconsumo, power_days, preferred_subrate,
    power_p1, power_p2, power_p3, power_p4, power_p5, power_p6,
    consumption_p1, consumption_p2, consumption_p3, consumption_p4, consumption_p5, consumption_p6,
    "VAT", COALESCE(equipment_rental, 0)
  INTO 
    totalfijo, totalvariable, diasdefactura, tarifa,
    potencia_1, potencia_2, potencia_3, potencia_4, potencia_5, potencia_6,
    consumo_1, consumo_2, consumo_3, consumo_4, consumo_5, consumo_6,
    vat, equipment
  FROM public.comparison_3_0
  WHERE id = _id;

  p := ARRAY[potencia_1, potencia_2, potencia_3, potencia_4, potencia_5, potencia_6];
  consumo := ARRAY[consumo_1, consumo_2, consumo_3, consumo_4, consumo_5, consumo_6];

  suma_potencia := p[1] + p[2] + p[3] + p[4] + p[5] + p[6];

  IF suma_potencia <> 0 AND diasdefactura <> 0 THEN
    FOR i IN 1..6 LOOP
      precio_kw[i] := totalfijo / suma_potencia / diasdefactura;
    END LOOP;
  ELSE
    FOR i IN 1..6 LOOP
      precio_kw[i] := 0;
    END LOOP;
  END IF;

  consumo_total := consumo[1] + consumo[2] + consumo[3] + consumo[4] + consumo[5] + consumo[6];

  IF consumo_total <> 0 THEN
    precio_kwh_base := totalvariable / consumo_total;
  ELSE
    precio_kwh_base := 0;
  END IF;

  IF tarifa = '3.0' THEN
    peajes := ARRAY[0, 0, 0, 0, 0, 0];
  ELSIF tarifa = '6.1' THEN
    peajes := ARRAY[0, 0, 0, 0, 0, 0];
  ELSE
    peajes := ARRAY[0, 0, 0, 0, 0, 0];
  END IF;

  FOR i IN 1..6 LOOP
    IF consumo_total = 0 THEN
      precio_kwh[i] := 0;
    ELSE
      precio_kwh[i] := precio_kwh_base + peajes[i];
    END IF;
  END LOOP;

  -- Calcular total estimado con equipment_rental (aunque sea 0)
  current_invoice_estimate := ROUND((((totalvariable + totalfijo) * 1.0511) + equipment) * (1 + vat), 2);

  UPDATE public.comparison_3_0
  SET 
    "precio_kwh_P1" = precio_kwh[1],
    "precio_kwh_P2" = precio_kwh[2],
    "precio_kwh_P3" = precio_kwh[3],
    "precio_kwh_P4" = precio_kwh[4],
    "precio_kwh_P5" = precio_kwh[5],
    "precio_kwh_P6" = precio_kwh[6],
    "precio_kw_P1" = precio_kw[1],
    "precio_kw_P2" = precio_kw[2],
    "precio_kw_P3" = precio_kw[3],
    "precio_kw_P4" = precio_kw[4],
    "precio_kw_P5" = precio_kw[5],
    "precio_kw_P6" = precio_kw[6],
    "current_total_invoice" = current_invoice_estimate
  WHERE id = _id;
END;