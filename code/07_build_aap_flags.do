*== 07_build_aap_flags.do — dummies direccionales de cobertura del AAP ==*
* Dirección CHL_IND (Chile→India): cobertura = lista de INDIA (importador que concede).
* Dirección IND_CHL (India→Chile): cobertura = lista de CHILE.
cap log close fl
log using "$LOGS/07_build_aap_flags.log", replace text
use "$INTER/crosswalk_annexes_hs12.dta", clear
keep if match_method=="exact"          // dummies sobre HS6 verificados en HS2012
* concesión por hs6 y (país, régimen)
collapse (min) concession_pct_min (max) concession_pct_max ///
         (max) d_partial_coverage=coverage_partial, by(schedule_country regime hs6)
gen byte covered=1
reshape wide covered concession_pct_min concession_pct_max d_partial_coverage, i(schedule_country hs6) j(regime) string
* -> covered original / covered expanded_2017 por país
save "$INTER/aap_by_country_hs6.dta", replace
di as txt "Cobertura por país/régimen construida (exacta HS2012)."
log close fl
