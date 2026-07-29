*== 16_enrich_matriz_aap_periods.do — agrega a la matriz Fajnzylber las dummies AAP
*   calzadas por periodo (P0=2015-17 vs P1=2022-24), en vez de dejar d_aap_original y
*   d_aap_expanded como dos columnas estaticas sin relacion explicita con el periodo.
*
*   Convencion (misma que regime_full_year en 08/15): la ampliacion del AAP entro en
*   vigor el 16-05-2017, asi que P0 (2015-2017) queda bajo el regimen ORIGINAL y P1
*   (2022-2024) bajo el AMPLIADO. 2017 es un año de transicion, compartido con P0.
*
*   Requiere haber corrido 12_fajnzylber.do antes (matriz ya construida).
*==================================================================================*
cap log close ep
log using "$LOGS/16_enrich_matriz_aap_periods.log", replace text

foreach suf in full noncopper {
    use "$OUTPUT/matriz_fajnzylber_chile_india_`suf'.dta", clear
    capture confirm variable d_aap_covered_p0
    if _rc == 0 {
        di as txt "matriz_fajnzylber_chile_india_`suf': ya tiene las columnas de periodo, se omite."
        continue
    }

    gen byte d_aap_covered_p0 = d_aap_original
    gen byte d_aap_covered_p1 = d_aap_expanded
    gen byte d_aap_covered_only_p1 = (d_aap_covered_p1==1 & d_aap_covered_p0==0)
    gen byte d_aap_covered_only_p0 = (d_aap_covered_p0==1 & d_aap_covered_p1==0)

    order d_aap_covered_p0 d_aap_covered_p1 d_aap_covered_only_p1 d_aap_covered_only_p0, ///
          after(d_aap_expanded)

    save "$OUTPUT/matriz_fajnzylber_chile_india_`suf'.dta", replace
    export delimited using "$OUTPUT/matriz_fajnzylber_chile_india_`suf'.csv", replace
    export excel using "$OUTPUT/matriz_fajnzylber_chile_india_`suf'.xlsx", firstrow(variables) replace

    count
    di as res ">> matriz_fajnzylber_chile_india_`suf': " r(N) " filas"
    tab d_aap_covered_p0
    tab d_aap_covered_p1
    tab d_aap_covered_only_p1
    tab d_aap_covered_only_p0
}

log close ep
