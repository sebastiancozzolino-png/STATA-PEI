*==============================================================================*
* verify_pipeline.do — reproduce el nucleo del pipeline en Stata y valida
* resultados contra la implementacion Python (BACI HS12 v202601, Chile-India).
* Autocontenido: usa intermediate/baci_relevant_all.dta + insumos ya producidos.
* Resultados esperados (matriz SIN cobre): naciente=219, perdida=1905,
* menguante=228, retirada=2791, sin_demanda=22, filas=5165.
*==============================================================================*
clear all
set more off
version 16
global ROOT "/Users/rcurinanco/Library/CloudStorage/GoogleDrive-ro.curinanco@gmail.com/Mi unidad/IEI 2026-2027/Trabajos Grupal: La Dictadura del IE/Economía Internacional/CARPETA DE TRABAJO/Panel_Stata_Fajnzylber_2026"
global INTER  "$ROOT/intermediate"
global OUTPUT "$ROOT/output"
global RAW    "$ROOT/raw_baci_csv"
global ANNEX  "$ROOT/crosswalk"
global LOGS   "$ROOT/logs"
cap mkdir "$LOGS"
cap log close _all
log using "$LOGS/verify_pipeline.log", replace text
di as txt "== VERIFY START $S_DATE $S_TIME =="

*---- 1. Diccionario de productos (assert 5202) ----
import delimited "$RAW/product_codes_HS12_V202601.csv", varnames(1) clear stringcols(1)
gen str6 hs6 = substr("000000"+code,-6,6)
rename description description_hs12
keep hs6 description_hs12
duplicates drop hs6, force
count
assert r(N)==5202
save "$INTER/product_codes_hs12.dta", replace
di as res ">> product_codes: 5202 OK"

*---- 2. Agregados desde BACI relevante ----
use "$INTER/baci_relevant_all.dta", clear
assert length(hs6)==6
* India importa del mundo (por hs6, año)
preserve
  keep if importer_baci==699
  collapse (sum) v=trade_value_usd, by(year hs6)
  save "$INTER/iw_year.dta", replace
restore
* India importa del mundo, total por año (denominador)
preserve
  keep if importer_baci==699
  collapse (sum) m_ind_total_usd=trade_value_usd, by(year)
  save "$INTER/itot.dta", replace
restore
* Chile -> India (por hs6, año)
preserve
  keep if exporter_baci==152 & importer_baci==699
  collapse (sum) x=trade_value_usd, by(year hs6)
  save "$INTER/ci_year.dta", replace
restore

*---- 3. Universo de HS6 (union: India-mundo OR Chile->India, cualquier año) ----
use "$INTER/iw_year.dta", clear
keep hs6
append using "$INTER/ci_year.dta", keep(hs6)
duplicates drop hs6, force
save "$INTER/universe_hs6.dta", replace

*---- 4. Sumas por periodo P0=2015-17, P1=2022-24 ----
* India-mundo
use "$INTER/iw_year.dta", clear
keep if inrange(year,2015,2017) | inrange(year,2022,2024)
gen str2 per = cond(inrange(year,2015,2017),"p0","p1")
collapse (sum) v, by(hs6 per)
reshape wide v, i(hs6) j(per) string
rename vp0 m_ind_world_p0
rename vp1 m_ind_world_p1
save "$INTER/iw_periods.dta", replace
* Chile->India
use "$INTER/ci_year.dta", clear
keep if inrange(year,2015,2017) | inrange(year,2022,2024)
gen str2 per = cond(inrange(year,2015,2017),"p0","p1")
collapse (sum) x, by(hs6 per)
reshape wide x, i(hs6) j(per) string
rename xp0 x_chl_ind_p0
rename xp1 x_chl_ind_p1
save "$INTER/ci_periods.dta", replace

*---- 5. Denominadores totales (importaciones totales de India por periodo) ----
use "$INTER/itot.dta", clear
sum m_ind_total_usd if inrange(year,2015,2017), meanonly
scalar Mtot0 = r(sum)
sum m_ind_total_usd if inrange(year,2022,2024), meanonly
scalar Mtot1 = r(sum)
di as res ">> Mtot0=" %15.0f Mtot0 "  Mtot1=" %15.0f Mtot1

*---- 6. Ensamblar matriz sobre el universo ----
use "$INTER/universe_hs6.dta", clear
merge 1:1 hs6 using "$INTER/iw_periods.dta", nogen
merge 1:1 hs6 using "$INTER/ci_periods.dta", nogen
foreach v in m_ind_world_p0 m_ind_world_p1 x_chl_ind_p0 x_chl_ind_p1 {
    replace `v' = 0 if missing(`v')
}
gen double product_share_india_p0 = m_ind_world_p0/Mtot0
gen double product_share_india_p1 = m_ind_world_p1/Mtot1
gen double chile_share_product_p0 = cond(m_ind_world_p0>0, x_chl_ind_p0/m_ind_world_p0, 0)
gen double chile_share_product_p1 = cond(m_ind_world_p1>0, x_chl_ind_p1/m_ind_world_p1, 0)
gen double delta_product_share_india = product_share_india_p1 - product_share_india_p0
gen double delta_chile_share_product = chile_share_product_p1 - chile_share_product_p0
gen double avg_exports_p1 = x_chl_ind_p1/3
gen double avg_india_imports_p1 = m_ind_world_p1/3
* flags
gen byte new_import_demand = (m_ind_world_p0==0 & m_ind_world_p1>0)
gen byte sin_demanda       = (m_ind_world_p0==0 & m_ind_world_p1==0)
gen byte chile_entry       = (x_chl_ind_p0==0 & x_chl_ind_p1>0)
gen byte no_chile_presence = (chile_share_product_p0==0 & chile_share_product_p1==0)
gen byte demand_dynamic    = (delta_product_share_india>0)
gen byte chile_competitive = (delta_chile_share_product>0)
* cuadrantes
gen byte quadrant_code = .
replace quadrant_code = 0 if sin_demanda==1
replace quadrant_code = 1 if sin_demanda==0 & demand_dynamic==1 & chile_competitive==1
replace quadrant_code = 2 if sin_demanda==0 & demand_dynamic==1 & chile_competitive==0
replace quadrant_code = 3 if sin_demanda==0 & demand_dynamic==0 & chile_competitive==1
replace quadrant_code = 4 if sin_demanda==0 & demand_dynamic==0 & chile_competitive==0
label define Q 0 "sin_demanda" 1 "estrella_naciente" 2 "oportunidad_perdida" 3 "estrella_menguante" 4 "retirada"
label values quadrant_code Q
* dummies AAP (Chile->India => lista de India)
merge 1:1 hs6 using "$INTER/aap_ind.dta", keep(master match) nogen
replace d_aap_original = 0 if missing(d_aap_original)
replace d_aap_expanded = 0 if missing(d_aap_expanded)
gen byte d_added_2017 = (d_aap_expanded==1 & d_aap_original==0)
gen byte d_copper_260300 = (hs6=="260300")
merge 1:1 hs6 using "$INTER/product_codes_hs12.dta", keep(master match) nogen
gsort -avg_india_imports_p1
save "$OUTPUT/matriz_fajnzylber_stata_full.dta", replace

*---- 7. Asserts + comparacion con Python ----
count
di as res ">> Matriz full filas = " r(N) "  (Python=5166)"
preserve
  drop if hs6=="260300"
  count
  di as res ">> Matriz noncopper filas = " r(N) "  (Python=5165)"
  save "$OUTPUT/matriz_fajnzylber_stata_noncopper.dta", replace
  di as txt "---- Distribucion de cuadrantes (sin cobre) vs Python ----"
  di as txt "   Python: naciente=219 perdida=1905 menguante=228 retirada=2791 sin_demanda=22"
  tab quadrant_code
restore
* copper checks
count if hs6=="260300"
assert r(N)==1
di as res ">> cobre 260300 presente en full: OK; se excluye en noncopper"
di as txt "== VERIFY END $S_DATE $S_TIME =="
log close
di as res "PIPELINE_VERIFY_OK"
