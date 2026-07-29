# Diccionario de variables — Panel y Matriz Fajnzylber Chile–India

Este diccionario documenta **todas las variables resultantes** del proyecto, con foco
especial en `matriz_fajnzylber_chile_india_full` (la salida analítica principal) y en el
nuevo panel maestro `panel_master_chile_india_2012_2024` (que corrige el problema de que
las dummies de cobertura AAP no estaban calzadas por año/período).

> **Qué cambió respecto a la versión anterior del repositorio:** las dummies `d_aap_original`
> y `d_aap_expanded` existían como dos columnas estáticas de elegibilidad, sin conectarlas
> explícitamente con qué régimen estaba realmente vigente en cada año o período de análisis.
> Se agregaron:
> - `d_covered_current_calendar` / `d_covered_current_full_year` al panel año-a-año
>   (`panel_master_chile_india_2012_2024`), y
> - `d_aap_covered_p0` / `d_aap_covered_p1` / `d_aap_covered_only_p1` / `d_aap_covered_only_p0`
>   a la matriz (`matriz_fajnzylber_chile_india_full` y `..._noncopper`),
>
> generadas por `code/15_build_master_panel.py` y `code/16_enrich_matriz_aap_periods.py`
> (Python, porque este entorno de replicación no tiene Stata instalado; la lógica replica
> exactamente la de `08_build_balanced_panel.do` y extiende la de `12_fajnzylber.do`).

---

## 1. `matriz_fajnzylber_chile_india_full` (output/, formatos .dta/.csv/.xlsx)

**Unidad de observación:** un producto HS6 (5.166 filas; 5.165 en `..._noncopper`, que excluye
HS6 260300 — mineral de cobre).
**Cobertura temporal:** compara dos promedios trienales — **P0 = 2015–2017** y **P1 = 2022–2024**.
**Fuente:** BACI-CEPII v202601 (comercio) + anexos SUBREI del AAP (cobertura/concesión).
**Valores monetarios:** USD corrientes (BACI reporta miles de USD; aquí ya convertidos a USD).

| # | Variable | Tipo | Definición / fórmula |
|---|---|---|---|
| 1 | `hs6` | str6 | Producto HS 2012, seis dígitos, ceros iniciales preservados. |
| 2 | `m_ind_world_p0` | double | Importaciones de India desde el mundo de este HS6, suma de 2015+2016+2017, USD. |
| 3 | `m_ind_world_p1` | double | Ídem, suma de 2022+2023+2024. |
| 4 | `x_chl_ind_p0` | double | Exportaciones de Chile a India de este HS6, suma P0, USD. |
| 5 | `x_chl_ind_p1` | double | Ídem P1. |
| 6 | `m_ind_total_p0` | double | Importaciones **totales** de India (todos los HS6), suma P0, USD. Denominador común — constante en todas las filas del período. |
| 7 | `m_ind_total_p1` | double | Ídem P1. |
| 8 | `product_share_india_p0` | double | `m_ind_world_p0 / m_ind_total_p0`. Peso del producto en la canasta importadora total de India, P0. |
| 9 | `product_share_india_p1` | double | Ídem P1. |
| 10 | `chile_share_product_p0` | double | `x_chl_ind_p0 / m_ind_world_p0` (0 si `m_ind_world_p0==0`). Cuota de Chile dentro de las importaciones indias de ese producto, P0. |
| 11 | `chile_share_product_p1` | double | Ídem P1. |
| 12 | `delta_product_share_india` | double | `product_share_india_p1 − product_share_india_p0`. **Eje X de la matriz** (dinamismo de la demanda). `>0` ⇒ India compra relativamente más de ese producto. |
| 13 | `delta_chile_share_product` | double | `chile_share_product_p1 − chile_share_product_p0`. **Eje Y de la matriz** (competitividad de Chile). `>0` ⇒ Chile gana cuota. |
| 14 | `avg_exports_p0` | double | `x_chl_ind_p0 / 3`. Exportación anual promedio Chile→India, P0. |
| 15 | `avg_exports_p1` | double | `x_chl_ind_p1 / 3`. |
| 16 | `avg_india_imports_p0` | double | `m_ind_world_p0 / 3`. |
| 17 | `avg_india_imports_p1` | double | `m_ind_world_p1 / 3`. |
| 18 | `growth_india_imports_pct` | double | `(m_ind_world_p1/m_ind_world_p0 − 1)×100` si `m_ind_world_p0>0`; vacío si la demanda entra desde cero (ver `new_import_demand`). |
| 19 | `growth_chile_exports_pct` | double | `(x_chl_ind_p1/x_chl_ind_p0 − 1)×100` si `x_chl_ind_p0>0`; vacío si Chile entra desde cero (ver `chile_entry`). |
| 20 | `new_import_demand` | 0/1 | 1 si India no importaba el producto en P0 y sí en P1. |
| 21 | `sin_demanda` | 0/1 | 1 si India no importó el producto en **ningún** período. Estas filas se apartan sin forzar cuadrante (`quadrant_code=0`). |
| 22 | `chile_entry` | 0/1 | 1 si Chile no exportaba el producto en P0 y sí en P1. |
| 23 | `no_chile_presence` | 0/1 | 1 si la cuota de Chile es 0 en **ambos** períodos (ausencia total — distinto de "perdió cuota"). |
| 24 | `demand_dynamic` | 0/1 | 1 si `delta_product_share_india > 0`. |
| 25 | `chile_competitive` | 0/1 | 1 si `delta_chile_share_product > 0`. |
| 26 | `quadrant_code` | 0–4 | `0` sin_demanda · `1` estrella_naciente (demanda↑, Chile↑) · `2` oportunidad_perdida (demanda↑, Chile no↑) · `3` estrella_menguante (demanda no↑, Chile↑) · `4` retirada (demanda no↑, Chile no↑). |
| 27 | `quadrant_name` | str | Etiqueta textual de `quadrant_code`. |
| 28 | `d_aap_original` | 0/1 | 1 si el HS6 está en la lista **ORIGINAL** de India para el AAP (HS2002, vigente desde 2007). Cobertura/elegibilidad, **no** utilización aduanera efectiva. |
| 29 | `d_aap_expanded` | 0/1 | 1 si está en la lista **AMPLIADA** de India (HS2017, vigente desde 16‑05‑2017). |
| 30 | **`d_aap_covered_p0`** ⭐ | 0/1 | **[Nueva]** Cobertura AAP calzada al período **P0** (2015–2017) = `d_aap_original`, porque P0 transcurre íntegramente bajo el régimen original (convención `regime_full_year`, ver §4). |
| 31 | **`d_aap_covered_p1`** ⭐ | 0/1 | **[Nueva]** Cobertura calzada a **P1** (2022–2024) = `d_aap_expanded`, período íntegramente bajo el régimen ampliado. |
| 32 | **`d_aap_covered_only_p1`** ⭐ | 0/1 | **[Nueva]** 1 si el producto **no** estaba cubierto en P0 pero **sí** en P1 — entró a la cobertura por la ampliación de 2017, leído directamente sobre los períodos de la matriz (subconjunto informativo de `d_added_2017`). |
| 33 | **`d_aap_covered_only_p0`** ⭐ | 0/1 | **[Nueva]** 1 si estaba cubierto en P0 y salió de la cobertura en P1 (poco frecuente; ver `d_removed_2017`). |
| 34 | `d_added_2017` | 0/1 | 1 si `d_aap_expanded==1 & d_aap_original==0` (agregado en la ampliación; no atado a período). |
| 35 | `d_maintained_2017` | 0/1 | 1 si cubierto en ambas listas. |
| 36 | `d_removed_2017` | 0/1 | 1 si estaba en la original y salió de la ampliada. |
| 37 | `concession_pct_min` / `concession_pct_max` | double | Rango de % de concesión arancelaria del anexo de India para este HS6 (cuando hay líneas de ocho dígitos con distinta concesión dentro del mismo HS6). Vacío si no cubierto por ninguna lista. Concesión ≠ arancel preferencial observado. |
| 38 | `d_partial_coverage` | 0/1 | 1 si dentro del HS6 hay líneas nacionales de ocho dígitos con elegibilidad o tasa distinta (cobertura no homogénea a nivel del HS6 completo). |
| 39 | `d_copper_260300` | 0/1 | 1 solo para HS6 `260300` (minerales de cobre), aislado por dominar el valor exportado (~US$950 M/año en 2022–24, ~mitad del total Chile→India). |
| 40 | `hs2` | str2 | Capítulo HS (2 dígitos), para agregaciones. |
| 41 | `hs4` | str4 | Partida HS (4 dígitos). |
| 42 | `description_hs12` | str | Descripción oficial BACI del producto HS12. |

### Advertencia sobre el año 2017 (transición del AAP)

La ampliación del AAP entró en vigor el **16 de mayo de 2017**. La matriz usa la convención
`regime_full_year` (todo 2017 dentro del régimen "original") porque P0 = 2015–2017 completo.
Esto significa que `d_aap_covered_p0` trata el año 2017 como si aún rigiera la lista original
durante los doce meses, cuando en realidad ~7 meses de 2017 ya estaban bajo la ampliación.
Es una simplificación **necesaria** porque la matriz agrega por trienio, no por año — para
análisis que necesiten precisión año a año, usar `panel_master_chile_india_2012_2024`
(sección 2), que sí distingue 2017 explícitamente en `regime_calendar` vs `regime_full_year`.

### Interpretación causal

La comparación P0 vs P1 es **descriptiva**. No atribuir causalmente los cambios en
`delta_product_share_india` / `delta_chile_share_product` a la ampliación del AAP: hay
múltiples factores (precios, demanda agregada, sustitución de proveedores) que también
mueven estos ejes. Las dummies `d_aap_*` sirven para **cruzar** cobertura con desempeño,
no para inferir causalidad.

---

## 2. `panel_master_chile_india_2012_2024` (output/, formatos .dta/.csv) — NUEVO

**Unidad de observación:** producto HS6 × año × dirección (panel **balanceado**: 5.202
HS6 × 13 años (2012–2024) × 2 direcciones = **135.252 filas**, con relleno de ceros donde
no hubo comercio observado).
**Por qué se agregó:** es la base año-a-año con las dummies de cobertura AAP **correctamente
calzadas al año de cada fila** — el punto que faltaba en la versión anterior del repositorio.
Reconstruye la lógica de `code/08_build_balanced_panel.do` (cuya salida nativa de Stata,
`panel_bilateral_balanced_full_2012_2024.dta`, no se pudo versionar por tamaño) usando
`code/15_build_master_panel.py`.

| Variable | Tipo | Definición |
|---|---|---|
| `hs6` | str6 | Producto HS 2012. Cruzar con `intermediate/product_codes_hs12.dta` para la descripción textual (no se denormaliza aquí para no inflar el archivo ~2.5×). |
| `year` | int | Año, 2012–2024. |
| `direction` | str | `CHL_IND` (Chile exporta a India, i=152, j=699) o `IND_CHL` (India exporta a Chile, i=699, j=152). |
| `trade_value_usd` | double | Valor del flujo, USD (BACI en miles → ×1000). **0** si no hubo comercio observado ese año/HS6/dirección (celda rellenada del panel balanceado). |
| `quantity_tons` | double | Cantidad en toneladas métricas (0 cuando BACI no informa cantidad o no hubo comercio). |
| `positive_trade` | 0/1 | 1 si `trade_value_usd>0` (observación real de BACI, no un relleno). |
| `zero_trade` | 0/1 | `1 − positive_trade`. |
| `regime_calendar` | str | `"original"` (2012–2016) o `"expanded"` (2017–2024). Trata 2017 ya como año de la ampliación. |
| `regime_full_year` | str | `"original"` (2012–2017) o `"expanded"` (2018–2024). Trata 2017 completo como transición dentro del régimen original — es la convención usada por P0/P1 de la matriz. |
| `d_aap_original` | 0/1 | Cobertura AAP bajo la lista original, **estática** (según `direction`: para `CHL_IND` es la lista de India; para `IND_CHL` es la lista de Chile — ver §3). |
| `d_aap_expanded` | 0/1 | Cobertura bajo la lista ampliada. |
| **`d_covered_current_calendar`** ⭐ | 0/1 | **[El fix]** Dummy de cobertura AAP **calzada al año de esta fila** según `regime_calendar`: `= d_aap_original` si `year≤2016`, `= d_aap_expanded` si `year≥2017`. Responde "¿estaba este producto realmente cubierto por el AAP en ESTE año?". |
| **`d_covered_current_full_year`** ⭐ | 0/1 | Ídem, con la convención `regime_full_year` (`year≤2017` → original). |
| `d_added_2017` | 0/1 | 1 si `d_aap_expanded==1 & d_aap_original==0` (estático, no atado a año). |
| `d_maintained_2017` | 0/1 | 1 si cubierto en ambas listas. |
| `d_removed_2017` | 0/1 | 1 si estaba en la original y salió de la ampliada. |
| `d_copper_260300` | 0/1 | 1 solo si `direction=="CHL_IND" & hs6=="260300"`. |

**Control de coherencia** (impreso por `15_build_master_panel.py` al correr): exportaciones
Chile→India entre US$0,83 mil M (2020, pandemia) y US$3,0 mil M (2014) anuales — consistente
con la magnitud reportada en la minuta metodológica. Cobertura AAP para `CHL_IND` bajo
`d_covered_current_calendar`: 81 HS6 en 2015–2016 (régimen original) → 458 HS6 en 2017
(ya bajo la convención calendario, que asigna 2017 al régimen ampliado).

---

## 3. Tablas de apoyo (ya existentes, sin cambios)

| Archivo | Grano | Contenido |
|---|---|---|
| `intermediate/product_codes_hs12.dta` | hs6 (5.202) | `description_hs12`: descripción oficial BACI por HS6. |
| `intermediate/aap_by_direction.dta` | direction × hs6 (1.895) | `d_aap_original`, `d_aap_expanded` ya orientados por dirección (la lista de India aplica a `CHL_IND`; la lista de Chile aplica a `IND_CHL`). Insumo directo de §2. |
| `intermediate/aap_ind.dta` | hs6 (461) | Cobertura AAP según la lista de **India** únicamente (insumo de la matriz, que solo mira Chile→India). |
| `crosswalk/aap_coverage_ind.csv`, `crosswalk/aap_coverage_chl.csv` | hs6 | Igual que `aap_ind.dta`, versión CSV, una tabla por país concedente. |
| `crosswalk/crosswalk_annexes_hs12.csv` | línea de anexo (4.234) | Detalle fila a fila de los 4 anexos del AAP: `schedule_country`, `regime` (`original`/`expanded_2017`), `serial_no`, `annex_code_original/clean`, `hs6`, `match_method` (`exact`/`pending_concordance`), `concession_pct_min/max`, `coverage_partial`, `review_required`, `description_annex`, `annex_file`. Es el insumo del que se agregan `d_aap_original`/`d_aap_expanded`. |
| `crosswalk/annex_manual_review.csv` | línea de anexo | Subconjunto de lo anterior con `match_method=="pending_concordance"` (198 códigos que cambiaron de revisión HS y quedan pendientes de la tabla de correlación oficial UN Stats/WCO). |
| `output/wdi_controls_chile_india_2012_2024.dta` | iso3 × year (26) | Controles macro (PIB, población, tipo de cambio, IPC, apertura comercial) para Chile e India, Banco Mundial/WDI. No cruza con hs6 — es contexto de país-año, no de producto. |
| `excel_reports/codebook.xlsx` | — | Codebook original del proyecto (previo a las columnas `d_aap_covered_p*` y a `panel_master_chile_india_2012_2024`); este documento lo reemplaza como referencia principal. |
| `excel_reports/qa_report.xlsx` | — | Reporte de controles de calidad del pipeline (conteos esperados, coherencia con Python). |

## 4. Convenciones generales

- **Códigos país en BACI:** Chile = 152, India = 699. Fuera de BACI (WITS/MacMap/OMC): India = 356.
- **Cobertura ≠ utilización:** todas las dummies `d_aap_*` miden si un HS6 está en la lista
  de un anexo (elegibilidad), no si el comercio efectivamente se benefició del arancel
  preferencial (BACI no distingue esto).
- **Unidad monetaria:** USD corrientes en todos los archivos derivados (BACI original está
  en miles de USD; ya convertido).
- **Reproducibilidad:** `code/15_build_master_panel.py` y `code/16_enrich_matriz_aap_periods.py`
  son deterministas sobre los archivos ya versionados en `intermediate/` y `output/`; no
  requieren la descarga de 1,27 GB de BACI ni Stata instalado. `code/00_master.do` (Stata)
  sigue siendo el pipeline de referencia completo si se dispone de Stata y de la descarga cruda.
