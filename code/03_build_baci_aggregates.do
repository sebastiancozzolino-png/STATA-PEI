*== 03_build_baci_aggregates.do — India-mundo, Chile-mundo y bilateral ==*
cap log close agg
log using "$LOGS/03_build_baci_aggregates.log", replace text
* India importa del mundo, por hs6 y año
use "$INTER/baci_relevant_all.dta", clear
keep if importer_baci==699
collapse (sum) india_imports_world_usd=trade_value_usd (sum) q_india=quantity_tons, by(year hs6)
save "$OUTPUT/india_imports_world_hs6_year.dta", replace
* Chile exporta al mundo, por hs6 y año
use "$INTER/baci_relevant_all.dta", clear
keep if exporter_baci==152
collapse (sum) chile_exports_world_usd=trade_value_usd (sum) q_chile=quantity_tons, by(year hs6)
save "$OUTPUT/chile_exports_world_hs6_year.dta", replace
* Bilateral observado (ambas direcciones)
use "$INTER/baci_relevant_all.dta", clear
keep if (exporter_baci==152 & importer_baci==699) | (exporter_baci==699 & importer_baci==152)
gen str7 direction = cond(exporter_baci==152,"CHL_IND","IND_CHL")
collapse (sum) trade_value_usd (sum) quantity_tons, by(year direction hs6)
save "$OUTPUT/panel_bilateral_observed_full_2012_2024.dta", replace
isid year direction hs6
* Importaciones TOTALES de India por año (denominador Fajnzylber)
use "$INTER/baci_relevant_all.dta", clear
keep if importer_baci==699
collapse (sum) m_ind_total_usd=trade_value_usd, by(year)
save "$INTER/india_imports_total_year.dta", replace
log close agg
