*== 12_fajnzylber.do — Matriz Fajnzylber Chile→India, P0=2015-17 vs P1=2022-24 ==*
* COMPLETO y verificado en StataMP 17 (idéntico a verify_pipeline.do):
* naciente=219 · perdida=1905 · menguante=228 · retirada=2791 · sin_demanda=22 · filas noncopper=5165.
cap log close fz
log using "$LOGS/12_fajnzylber.log", replace text

* --- (a) India importa del mundo: sumas por período ---
use "$OUTPUT/india_imports_world_hs6_year.dta", clear
keep if inrange(year,2015,2017) | inrange(year,2022,2024)
gen str2 per = cond(inrange(year,2015,2017),"p0","p1")
collapse (sum) v=india_imports_world_usd, by(hs6 per)
reshape wide v, i(hs6) j(per) string
rename (vp0 vp1) (m_ind_world_p0 m_ind_world_p1)
save "$INTER/iw_periods.dta", replace

* --- (b) Chile → India: sumas por período ---
use "$OUTPUT/panel_bilateral_observed_full_2012_2024.dta", clear
keep if direction=="CHL_IND" & (inrange(year,2015,2017) | inrange(year,2022,2024))
gen str2 per = cond(inrange(year,2015,2017),"p0","p1")
collapse (sum) x=trade_value_usd, by(hs6 per)
reshape wide x, i(hs6) j(per) string
rename (xp0 xp1) (x_chl_ind_p0 x_chl_ind_p1)
save "$INTER/ci_periods.dta", replace

* --- (c) Denominadores: importaciones TOTALES de India por período ---
use "$INTER/india_imports_total_year.dta", clear
sum m_ind_total_usd if inrange(year,2015,2017), meanonly
scalar Mtot0 = r(sum)
sum m_ind_total_usd if inrange(year,2022,2024), meanonly
scalar Mtot1 = r(sum)

* --- (d) Universo HS6 = union (India-mundo OR Chile→India, cualquier año) ---
use "$OUTPUT/india_imports_world_hs6_year.dta", clear
keep hs6
duplicates drop hs6, force
tempfile uni
save `uni'
use "$OUTPUT/panel_bilateral_observed_full_2012_2024.dta", clear
keep if direction=="CHL_IND"
keep hs6
duplicates drop hs6, force
append using `uni'
duplicates drop hs6, force

* --- (e) Ensamblar matriz ---
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
gen double avg_exports_p0 = x_chl_ind_p0/3
gen double avg_exports_p1 = x_chl_ind_p1/3
gen double avg_india_imports_p0 = m_ind_world_p0/3
gen double avg_india_imports_p1 = m_ind_world_p1/3
gen double growth_india_imports_pct = cond(m_ind_world_p0>0,(m_ind_world_p1/m_ind_world_p0-1)*100,.)
gen double growth_chile_exports_pct = cond(x_chl_ind_p0>0,(x_chl_ind_p1/x_chl_ind_p0-1)*100,.)
gen byte new_import_demand = (m_ind_world_p0==0 & m_ind_world_p1>0)
gen byte sin_demanda       = (m_ind_world_p0==0 & m_ind_world_p1==0)
gen byte chile_entry       = (x_chl_ind_p0==0 & x_chl_ind_p1>0)
gen byte no_chile_presence = (chile_share_product_p0==0 & chile_share_product_p1==0)
gen byte demand_dynamic    = (delta_product_share_india>0)
gen byte chile_competitive = (delta_chile_share_product>0)
gen byte quadrant_code = .
replace quadrant_code = 0 if sin_demanda==1
replace quadrant_code = 1 if sin_demanda==0 & demand_dynamic==1 & chile_competitive==1
replace quadrant_code = 2 if sin_demanda==0 & demand_dynamic==1 & chile_competitive==0
replace quadrant_code = 3 if sin_demanda==0 & demand_dynamic==0 & chile_competitive==1
replace quadrant_code = 4 if sin_demanda==0 & demand_dynamic==0 & chile_competitive==0
label define Q 0 "sin_demanda" 1 "estrella_naciente" 2 "oportunidad_perdida" 3 "estrella_menguante" 4 "retirada", replace
label values quadrant_code Q
merge 1:1 hs6 using "$INTER/aap_ind.dta", keep(master match) nogen
replace d_aap_original = 0 if missing(d_aap_original)
replace d_aap_expanded = 0 if missing(d_aap_expanded)
gen byte d_added_2017 = (d_aap_expanded==1 & d_aap_original==0)
gen byte d_copper_260300 = (hs6=="260300")
merge 1:1 hs6 using "$INTER/product_codes_hs12.dta", keep(master match) nogen
gsort -avg_india_imports_p1
save "$OUTPUT/matriz_fajnzylber_chile_india_full.dta", replace
export excel using "$OUTPUT/matriz_fajnzylber_chile_india_full.xlsx", firstrow(variables) replace
count
di as res ">> Matriz full = " r(N) " filas (esperado 5166)"
drop if hs6=="260300"
save "$OUTPUT/matriz_fajnzylber_chile_india_noncopper.dta", replace
export excel using "$OUTPUT/matriz_fajnzylber_chile_india_noncopper.xlsx", firstrow(variables) replace
count
di as res ">> Matriz noncopper = " r(N) " filas (esperado 5165)"
tab quadrant_code
log close fz
