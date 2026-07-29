*== 13_quality_assurance.do — asserts y reporte QA (§16) ==*
cap log close qa
log using "$LOGS/13_quality_assurance.log", replace text
use "$OUTPUT/panel_bilateral_observed_full_2012_2024.dta", clear
isid year direction hs6
assert length(hs6)==6
quietly levelsof year, local(yy)
di as txt "años: `yy'"
use "$INTER/product_codes_hs12.dta", clear
count
assert r(N)==5202
use "$OUTPUT/panel_bilateral_balanced_full_2012_2024.dta", clear
count
assert r(N)==5202*13*2
* cobre presente en full, ausente en noncopper
count if direction=="CHL_IND" & hs6=="260300"
assert r(N)>0
use "$OUTPUT/panel_bilateral_balanced_noncopper_2012_2024.dta", clear
count if direction=="CHL_IND" & hs6=="260300"
assert r(N)==0
di as txt "QA: asserts OK. (No aceptar merge m:m; no reemplazar externos faltantes por cero.)"
log close qa
