*== 17_build_base_maestra.do — UNA sola base consolidada: panel año x direccion x HS6
*   (con las dummies AAP calzadas por año) MAS las variables de la matriz Fajnzylber
*   (P0/P1, shares, crecimiento, cuadrante, dummies AAP calzadas por periodo) fusionadas
*   en las mismas filas, para el subconjunto Chile->India donde la matriz aplica.
*
*   Grano: hs6 x year x direction (135,252 filas, panel balanceado). Las columnas de la
*   matriz (prefijo mtz_) son valores de PERIODO, no de año calendario: se repiten
*   identicas en las 13 filas-año de cada hs6 dentro de direction=="CHL_IND" (la matriz
*   Fajnzylber de este proyecto es unidireccional Chile->India) y quedan vacias (missing)
*   para direction=="IND_CHL".
*
*   Requiere: 15_build_master_panel.do y 16_enrich_matriz_aap_periods.do ya corridos.
*==================================================================================*
cap log close bm
log using "$LOGS/17_build_base_maestra.log", replace text

* --- matriz con prefijo mtz_ para no chocar con las columnas año-a-año del panel ---
use "$OUTPUT/matriz_fajnzylber_chile_india_full.dta", clear
drop hs2 hs4 description_hs12
ds hs6, not
local mtzvars `r(varlist)'
foreach v of local mtzvars {
    rename `v' mtz_`v'
}
tempfile matriz_pref
save `matriz_pref'

* --- panel maestro (año x direccion x hs6) ---
use "$OUTPUT/panel_master_chile_india_2012_2024.dta", clear
gen str2 hs2 = substr(hs6,1,2)
gen str4 hs4 = substr(hs6,1,4)

* la matriz solo aplica a CHL_IND: merge m:1 trae los mismos valores de periodo a las
* 13 filas-año de cada hs6 en esa direccion; para IND_CHL se limpian a continuacion.
merge m:1 hs6 using `matriz_pref', keep(master match) nogen
ds mtz_*
local mtzvars `r(varlist)'
foreach v of local mtzvars {
    local vtype : type `v'
    if substr("`vtype'",1,3)=="str" {
        quietly replace `v' = "" if direction != "CHL_IND"
    }
    else {
        quietly replace `v' = . if direction != "CHL_IND"
    }
}

order hs6 hs2 hs4 year direction
sort hs6 year direction

save "$OUTPUT/base_maestra_chile_india_2012_2024.dta", replace
export delimited using "$OUTPUT/base_maestra_chile_india_2012_2024.csv", replace

count
di as res ">> base_maestra_chile_india_2012_2024: " r(N) " filas (esperado 135,252)"
assert r(N) == 5202*13*2

count if direction=="CHL_IND" & !missing(mtz_quadrant_code)
di as res ">> filas CHL_IND con datos de matriz: " r(N) " (union HS6 de la matriz = 5,166; esperado 5,166*13=67,158)"
count if direction=="IND_CHL" & !missing(mtz_quadrant_code)
assert r(N)==0
di as res ">> filas IND_CHL con datos de matriz: " r(N) " (esperado 0, la matriz es solo Chile->India)"

log close bm
