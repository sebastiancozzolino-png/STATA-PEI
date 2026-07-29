*== 10_macro_controls.do — controles WDI 2012–2024 (Banco Mundial, API sin registro) ==*
* Variables país–año comunes a todos los HS6; NO determinan los cuadrantes Fajnzylber.
cap log close mc
log using "$LOGS/10_macro_controls.log", replace text
cap confirm file "$RAW_EXT/wdi_controls_chile_india_2012_2024.csv"
if _rc {
    * descarga reproducible vía API (requiere conexión):
    shell python3 "$CODE/aux_wdi.py" "$RAW_EXT"
}
import delimited using "$RAW_EXT/wdi_controls_chile_india_2012_2024.csv", varnames(1) clear
save "$INTER/wdi_controls.dta", replace
di as txt "WDI: " _N " filas (país×año)"
log close mc
