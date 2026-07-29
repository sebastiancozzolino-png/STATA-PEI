*== 11_merge_final.do — integra BACI + AAP + aranceles + controles ==*
cap log close mf
log using "$LOGS/11_merge_final.log", replace text
use "$OUTPUT/panel_bilateral_balanced_full_2012_2024.dta", clear
merge m:1 hs6 using "$INTER/product_codes_hs12.dta", keep(master match) nogen
cap merge 1:1 year direction hs6 using "$INTER/tariffs.dta", keep(master match) nogen
* controles país-año se unen por el país correspondiente a la dirección (capa complementaria)
save "$OUTPUT/panel_final_2012_2024.dta", replace
log close mf
