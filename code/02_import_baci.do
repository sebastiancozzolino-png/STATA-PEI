*== 02_import_baci.do — importa los CSV oficiales de BACI (flujos relevantes) ==*
* Los Excel están truncados (ver 01). Descarga previa manual del ZIP oficial:
*   https://www.cepii.fr/DATA_DOWNLOAD/baci/data/BACI_HS12_V202601.zip  (1,27 GB)
* Descomprimir en $RAW_BACI. Este do-file llama al auxiliar Python que filtra
* por bloques (no depende de Excel) y luego importa los CSV compactos a Stata.
cap log close imp
log using "$LOGS/02_import_baci.log", replace text
* --- filtrado eficiente vía Python/DuckDB ---
shell python3 "$CODE/aux_filter_baci.py" "$RAW_BACI" "$INTER"
forvalues y=2012/2024 {
    import delimited using "$INTER/baci_relevant_`y'.csv", varnames(1) clear encoding(UTF-8)
    assert year==`y'
    * hs6 como string de 6 dígitos con ceros iniciales
    tostring hs6, replace force
    replace hs6 = substr("000000"+hs6,-6,6) if length(hs6)<6
    assert length(hs6)==6
    compress
    save "$INTER/baci_relevant_`y'.dta", replace
    di as txt "importado `y': " _N " obs"
}
* apilar
clear
forvalues y=2012/2024 {
    append using "$INTER/baci_relevant_`y'.dta"
}
label var trade_value_usd "Valor comercio (USD)"
label var quantity_tons   "Cantidad (toneladas)"
save "$INTER/baci_relevant_all.dta", replace
isid year exporter_baci importer_baci hs6
di as txt "BACI relevante apilado: " _N " obs"
log close imp
