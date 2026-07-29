*== 06_hs_concordances.do — HS2002/HS2017 → HS2012 ==*
* BACI usa HS2012. Las listas originales son HS2002; las ampliadas, HS2017.
* Estrategia: (1) match EXACTO del hs6 contra el universo HS2012 de BACI
* (correcto para la mayoría de los códigos, estables entre revisiones);
* (2) los códigos que NO existen en HS2012 se marcan match_method="pending_concordance"
* y se envían a annex_manual_review para aplicar la tabla de correlación oficial
* (UN Stats / WCO: HS2002-HS2007-HS2012 y HS2012-HS2017). No se inventan concordancias.
cap log close cc
log using "$LOGS/06_hs_concordances.log", replace text
use "$INTER/crosswalk_annexes_raw.dta", clear
merge m:1 hs6 using "$INTER/product_codes_hs12.dta", keep(master match) keepusing(description_hs12)
gen match_method = cond(_merge==3,"exact","pending_concordance")
drop _merge
* Si existen tablas oficiales en $RAW_CONC, aplicarlas aquí (opcional):
*   import delimited "$RAW_CONC/HS2017_HS2012.csv" ... ; merge y reasignar hs6.
preserve
    keep if match_method=="pending_concordance" | review_required==1
    export excel using "$OUTPUT/annex_manual_review.xlsx", firstrow(variables) replace
restore
save "$INTER/crosswalk_annexes_hs12.dta", replace
export excel using "$OUTPUT/crosswalk_annexes_hs12.xlsx", firstrow(variables) replace
tab schedule_country match_method
log close cc
