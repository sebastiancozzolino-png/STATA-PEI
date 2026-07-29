*== 15_build_master_panel.do — copia canonica del panel balanceado con dummies AAP
*   calzadas por año (regime_calendar/regime_full_year/d_covered_current_*), que ya
*   construye 08_build_balanced_panel.do. Este paso solo la deja con el nombre final
*   panel_master_chile_india_2012_2024, y exporta CSV para uso fuera de Stata.
*
*   Requiere haber corrido 01..08 antes (o el pipeline completo via 00_master.do), asi
*   que "$OUTPUT/panel_bilateral_balanced_full_2012_2024.dta" ya existe.
*==================================================================================*
cap log close mp
log using "$LOGS/15_build_master_panel.log", replace text

use "$OUTPUT/panel_bilateral_balanced_full_2012_2024.dta", clear
count
assert r(N) == 5202*13*2

* orden canonico
sort hs6 year direction
order hs6 year direction trade_value_usd quantity_tons positive_trade zero_trade ///
      regime_calendar regime_full_year d_aap_original d_aap_expanded ///
      d_covered_current_calendar d_covered_current_full_year ///
      d_added_2017 d_maintained_2017 d_removed_2017 d_copper_260300

save "$OUTPUT/panel_master_chile_india_2012_2024.dta", replace
export delimited using "$OUTPUT/panel_master_chile_india_2012_2024.csv", replace

di as res ">> panel_master_chile_india_2012_2024: " _N " filas, " c(k) " columnas"

* control de coherencia: cobertura AAP debe cambiar de regimen entre 2016 y 2017
* bajo regime_calendar (2015-16 = original, 2017 = expanded) para CHL_IND
preserve
    keep if direction=="CHL_IND" & inrange(year,2015,2017)
    collapse (sum) d_covered_current_calendar, by(year)
    di as txt "HS6 cubiertos (CHL_IND, d_covered_current_calendar==1) por año 2015-2017:"
    list, clean noobs
restore

log close mp
