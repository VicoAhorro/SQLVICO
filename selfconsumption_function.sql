DECLARE
  v_totalconsumo NUMERIC := 0;
  v_totalpotencia NUMERIC := 0;
  v_vat NUMERIC := 0;
  v_equipment NUMERIC := 0;
  v_total_final NUMERIC := 0;
  v_power_1 NUMERIC := 0;
  v_power_2 NUMERIC := 0;
  v_days INTEGER := 0;
  v_cons1 NUMERIC := 0;
  v_cons2 NUMERIC := 0;
  v_cons3 NUMERIC := 0;
v_autoconsumption_price NUMERIC := 0;
v_surpluses NUMERIC := 0;
BEGIN
  SELECT
    COALESCE(c.totalconsumo, 0),
    COALESCE(c.totalpotencia, 0),
    COALESCE(c."VAT", 0),
    COALESCE(c.equipment_rental, 0),
    COALESCE(c.power_p1, 0),
    COALESCE(c.power_p2, 0),
    COALESCE(c.power_days, 0),
    COALESCE(c.consumption_p1, 0),
    COALESCE(c.consumption_p2, 0),
    COALESCE(c.consumption_p3, 0),
    COALESCE(c.autoconsumo_precio, 0),
    COALESCE(c.surpluses, 0)
  INTO
    v_totalconsumo, v_totalpotencia, v_vat, v_equipment,
    v_power_1, v_power_2, v_days,
    v_cons1, v_cons2, v_cons3,
    v_autoconsumption_price, v_surpluses
  FROM public.comparison_light c
  WHERE c.id = _id AND NOT c.deleted;

  v_total_final := ROUND((((v_totalconsumo + v_totalpotencia) * 1.0511) + v_equipment) * (1 + v_vat), 2);

  UPDATE public.comparison_light
  SET
    "precio_kw_P1" = CASE 
                      WHEN (v_power_1 + v_power_2) <> 0 AND v_days <> 0 
                      THEN (v_totalpotencia / (v_power_1 + v_power_2)) / v_days
                      ELSE 0 
                    END,
    "precio_kw_P2" = CASE 
                      WHEN (v_power_1 + v_power_2) <> 0 AND v_days <> 0 
                      THEN (v_totalpotencia / (v_power_1 + v_power_2)) / v_days
                      ELSE 0 
                    END,
    "precio_kwh_P1" = CASE 
                      WHEN (v_cons1 + v_cons2 + v_cons3) <> 0 
                      THEN v_totalconsumo / (v_cons1 + v_cons2 + v_cons3)
                      ELSE 0 
                    END,
    "precio_kwh_P2" = CASE 
                      WHEN (v_cons1 + v_cons2 + v_cons3) <> 0 
                      THEN v_totalconsumo / (v_cons1 + v_cons2 + v_cons3)
                      ELSE 0 
                    END,
    "precio_kwh_P3" = CASE 
                      WHEN (v_cons1 + v_cons2 + v_cons3) <> 0 
                      THEN v_totalconsumo / (v_cons1 + v_cons2 + v_cons3)
                      ELSE 0 
                    END,

    "autoconsumo_precio" = CASE
                            WHEN v_surpluses <> 0
                            THEN v_autoconsumption_price / v_surpluses
                            ELSE 0
                          END,

    current_total_invoice = v_total_final
  WHERE id = _id AND NOT deleted;
END;