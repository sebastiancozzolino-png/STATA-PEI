*== 05_extract_annexes.do — importa el crosswalk de los 4 anexos del AAP ==*
* Las tablas de los 4 PDF se extraen con el parser Python (aux, reproducible):
*   raw_annexes/crosswalk_annexes_hs12.csv  (una fila por código de anexo → hs6)
* Recuentos seriales verificados: India 178 / India-2017 1.110 / Chile 296 / Chile-2017 2.099.
cap log close ax
log using "$LOGS/05_extract_annexes.log", replace text
import delimited using "$RAW_ANNEX/crosswalk_annexes_hs12.csv", varnames(1) clear encoding(UTF-8) stringcols(_all)
* tipos
destring serial_no concession_pct_min concession_pct_max coverage_partial review_required, replace force
replace hs6 = substr("000000"+hs6,-6,6) if hs6!=""
save "$INTER/crosswalk_annexes_raw.dta", replace
* control de recuentos seriales
foreach combo in "IND original 178" "IND expanded_2017 1110" "CHL original 296" "CHL expanded_2017 2099" {
    tokenize "`combo'"
    count if schedule_country=="`1'" & regime=="`2'"
    * (cada serial puede generar >1 fila si tiene rango/alternativa)
    quietly levelsof serial_no if schedule_country=="`1'" & regime=="`2'", local(ss)
    di as txt "`1' `2': seriales distintos = " `: word count `ss'' " (esperado `3')"
}
log close ax
