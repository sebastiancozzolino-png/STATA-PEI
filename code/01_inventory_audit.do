*== 01_inventory_audit.do — inventario y detección de truncamiento de los Excel ==*
* REGLA DE DETENCIÓN: un Excel BACI con dimensión que termina en la fila 1.048.576
* está truncado por el límite de Excel. Un año completo de BACI HS12 tiene ~10M filas.
* Además, como el archivo está ordenado por exportador (i), el truncado deja solo
* códigos de país bajos: en 2012 el exportador máximo presente es 124, por lo que
* Chile (152) e India (699) NO aparecen. => Los Excel son inservibles.
cap log close audit
log using "$LOGS/01_inventory_audit.log", replace text
tempname M
postfile `M' str40 archivo double filas str12 trunc using "$INTER/audit_baci.dta", replace
forvalues y=2012/2024 {
    local f "$RAW_USER/BACI_HS12_Y`y'_V202601.xlsx"
    cap import excel using "`f'", clear
    if _rc==0 {
        local n=_N
        local t = cond(`n'>=1048575,"TRUNCADO","ok")
        post `M' ("`f'") (`n') ("`t'")
        di as txt "`y': `n' filas -> `t'"
    }
}
postclose `M'
* Los CSV oficiales completos deben quedar en $RAW_BACI (ver 02).
log close audit
