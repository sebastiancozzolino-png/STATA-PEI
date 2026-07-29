*=================================================================================*
* 00_master.do  —  Panel Stata + Matriz Fajnzylber Chile–India
* Proyecto: Economía Internacional · AAP Chile–India · BACI HS12 v202601
* Ejecuta todo el pipeline desde cero. Requiere Stata 16+ y Python integrado
* (para el filtrado eficiente de los CSV grandes de BACI).
*==============================================================================*
clear all
set more off
version 16

* ---- RUTAS (editar solo esta sección) ----
global ROOT      "CAMBIAR/RUTA/Construir panel stata"
global RAW_USER  "$ROOT/raw_originales_usuario"   // Excel truncados originales (evidencia)
global RAW_BACI  "$ROOT/raw_baci_csv"             // CSV oficiales completos de CEPII
global RAW_ANNEX "$ROOT/raw_annexes"              // 4 PDF / tablas extraídas de los anexos
global RAW_CONC  "$ROOT/raw_concordancias"         // concordancias oficiales HS
global RAW_EXT   "$ROOT/raw_external"             // WDI, WITS, ITC
global INTER     "$ROOT/intermediate"
global OUTPUT    "$ROOT/output"
global CODE      "$ROOT/code"
global LOGS      "$ROOT/logs"
global DOC       "$ROOT/documentation"
foreach d in "$INTER" "$OUTPUT" "$LOGS" { cap mkdir "`d'" }

cap log close _all
log using "$LOGS/master.log", replace text

di as txt "== Pipeline Chile–India · inicio: $S_DATE $S_TIME =="
do "$CODE/01_inventory_audit.do"
do "$CODE/02_import_baci.do"
do "$CODE/03_build_baci_aggregates.do"
do "$CODE/04_prepare_codes.do"
do "$CODE/05_extract_annexes.do"
do "$CODE/06_hs_concordances.do"
do "$CODE/07_build_aap_flags.do"
do "$CODE/08_build_balanced_panel.do"
do "$CODE/09_tariffs.do"
do "$CODE/10_macro_controls.do"
do "$CODE/11_merge_final.do"
do "$CODE/12_fajnzylber.do"
do "$CODE/13_quality_assurance.do"
do "$CODE/14_tables_graphs.do"
do "$CODE/15_build_master_panel.do"
do "$CODE/16_enrich_matriz_aap_periods.do"
do "$CODE/17_build_base_maestra.do"
di as txt "== Pipeline terminado: $S_DATE $S_TIME =="
log close
