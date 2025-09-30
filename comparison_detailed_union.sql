create or replace view public._comparisons_detailed_union as
SELECT * FROM public._comparisons_detailed_gas
UNION ALL
SELECT * FROM public._comparisons_detailed_3_0
UNION ALL
SELECT * FROM public._comparisons_detailed_phone
UNION ALL
SELECT * FROM public._comparisons_detailed_light;