*== 09_tariffs.do — aranceles MFN y preferencial (PENDIENTE: descarga manual) ==*
* Chile→India: arancel que INDIA aplica a Chile (reporter=India 356, partner=Chile 152).
* India→Chile: arancel que CHILE aplica a India. NO usar el código BACI 699 fuera de BACI.
* Fuentes: WITS/TRAINS, MacMap (macmap.org, reporter=356), CBIC (arancel oficial de India).
* Todas requieren registro/descarga manual → se prepara el esquema e importador exacto.
cap log close tr
log using "$LOGS/09_tariffs.log", replace text
cap confirm file "$RAW_EXT/tariffs_india_chile.csv"
if _rc==0 {
    import delimited using "$RAW_EXT/tariffs_india_chile.csv", varnames(1) clear
    * variables esperadas: hs6 year mfn_rate preferential_rate_observed annex_concession_pct ...
    gen double preferential_rate_implied = mfn_rate*(1-annex_concession_pct/100) if !missing(mfn_rate,annex_concession_pct)
    gen double preference_margin_pp = mfn_rate - preferential_rate_observed
    gen byte imputation_flag = 0
    save "$INTER/tariffs.dta", replace
}
else {
    di as error "ARANCELES PENDIENTES: falta $RAW_EXT/tariffs_india_chile.csv"
    di as txt   "Ver plantilla output/tariff_coverage_report.xlsx y §12 del prompt."
    clear
    save "$INTER/tariffs.dta", replace emptyok
}
log close tr
