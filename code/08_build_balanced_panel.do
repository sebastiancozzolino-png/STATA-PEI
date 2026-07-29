*== 08_build_balanced_panel.do — panel observado y balanceado 5202×13×2 ==*
* Verificado: 135.252 filas; cobre 260300 (CHL_IND) presente en full, ausente en noncopper.
cap log close bp
log using "$LOGS/08_build_balanced_panel.log", replace text
use "$INTER/product_codes_hs12.dta", clear
expand 13
bysort hs6: gen year = 2011 + _n
expand 2
bysort hs6 year: gen str7 direction = cond(_n==1,"CHL_IND","IND_CHL")
merge 1:1 year direction hs6 using "$OUTPUT/panel_bilateral_observed_full_2012_2024.dta", keep(master match) nogen
replace trade_value_usd = 0 if missing(trade_value_usd)
replace quantity_tons   = 0 if missing(quantity_tons)
gen byte positive_trade = trade_value_usd>0
gen byte zero_trade = 1-positive_trade
* dummies AAP por dirección (lista del país importador): aap_by_direction.dta
merge m:1 direction hs6 using "$INTER/aap_by_direction.dta", keep(master match) nogen
replace d_aap_original = 0 if missing(d_aap_original)
replace d_aap_expanded = 0 if missing(d_aap_expanded)
gen byte d_added_2017     = (d_aap_expanded==1 & d_aap_original==0)
gen byte d_maintained_2017= (d_aap_expanded==1 & d_aap_original==1)
gen byte d_removed_2017   = (d_aap_original==1 & d_aap_expanded==0)
gen str8 regime_calendar  = cond(year<=2016,"original","expanded")
gen str8 regime_full_year = cond(year<=2017,"original","expanded")
gen byte d_covered_current_calendar  = cond(year<=2016,d_aap_original,d_aap_expanded)
gen byte d_covered_current_full_year = cond(year<=2017,d_aap_original,d_aap_expanded)
gen byte d_copper_260300 = (direction=="CHL_IND" & hs6=="260300")
save "$OUTPUT/panel_bilateral_balanced_full_2012_2024.dta", replace
count
assert r(N)==5202*13*2
drop if d_copper_260300==1
save "$OUTPUT/panel_bilateral_balanced_noncopper_2012_2024.dta", replace
log close bp
