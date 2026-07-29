# Panel Stata + Matriz Fajnzylber Chile–India

This repository is a git mirror of the Google Drive project `Panel_Stata_Fajnzylber_2026`.

**Proyecto:** Economía Internacional · Acuerdo de Alcance Parcial (AAP) Chile–India
**Datos:** BACI-CEPII HS 2012, versión 202601 (2012–2024) · anexos del AAP (original 2007 y ampliación 2017)
**Salida principal:** Matriz Fajnzylber–CEPAL de las exportaciones de Chile a India, comparando los trienios 2015–2017 y 2022–2024, **excluyendo cobre (HS6 260300)**.

## Resultado central (verificado en Python y en StataMP 17)

Matriz sin cobre, 5.165 productos HS6: **219 estrellas nacientes**, **1.905 oportunidades perdidas**, **228 estrellas menguantes**, **2.791 en retirada**, 22 sin demanda. El cobre 260300 (~US$950 M/año en 2022–24, cerca de la mitad del total Chile→India) se aísla en una fila de sensibilidad.

## Diccionario de variables, panel maestro y base consolidada

- **`documentation/diccionario_variables.md`** documenta variable por variable:
  `matriz_fajnzylber_chile_india_full` (y `..._noncopper`), el panel año-a-año
  `output/panel_master_chile_india_2012_2024` (135.252 filas = 5.202 HS6 × 13 años ×
  2 direcciones) y la base consolidada `output/base_maestra_chile_india_2012_2024`
  (el panel anterior + todas las columnas de la matriz fusionadas en las mismas filas,
  con prefijo `mtz_`, solo para `direction=="CHL_IND"`).
- Los tres incorporan dummies de cobertura AAP **calzadas por año/período** (antes solo
  existían `d_aap_original`/`d_aap_expanded` como columnas estáticas, sin indicar qué
  régimen regía en cada año o en cada trienio P0/P1 de la matriz): `d_covered_current_calendar`
  / `d_covered_current_full_year` en el panel, y `d_aap_covered_p0` / `d_aap_covered_p1` /
  `d_aap_covered_only_p1` / `d_aap_covered_only_p0` en la matriz (y replicadas con
  prefijo `mtz_` en la base consolidada).
- **Generados en dos versiones equivalentes:**
  - Nativa en **Stata**: `code/15_build_master_panel.do`, `code/16_enrich_matriz_aap_periods.do`,
    `code/17_build_base_maestra.do` (ya integradas a `code/00_master.do`). Correrlas requiere
    Stata instalado **en tu propio computador** — no se pueden ejecutar desde este entorno
    de replicación en la nube, que no tiene Stata ni acceso a tu máquina.
  - En **Python** (`code/15_build_master_panel.py`, `code/16_enrich_matriz_aap_periods.py`,
    `code/17_build_base_maestra.py`): misma lógica exacta, usadas para generar los archivos
    ya versionados en este repositorio (dado que este entorno no tiene Stata).

## Estructura de carpetas

```
STATA-PEI/
├── code/               do-files 00–17 (Stata, correr en tu Stata local) + verify_pipeline.do
│                       + aux_filter_baci.py + aux_wdi.py + 15/16/17_*.py (equivalentes Python)
├── raw_baci_csv/       country_codes, product_codes (CSV oficiales CEPII)
├── crosswalk/          crosswalk de anexos, coberturas AAP, revisión manual
├── intermediate/       bases intermedias del pipeline (baci_relevant_all.dta excluido, ver abajo)
├── output/             base maestra consolidada, panel año-a-año, matriz Fajnzylber (.dta/.xlsx/.csv), gráfico
├── excel_reports/      auditoría, matriz formateada, QA, codebook, aranceles (plantilla)
├── documentation/      README de replicación + minuta metodológica + diccionario de variables
└── logs/               logs de ejecución (ver nota abajo)
```

## Cómo reproducir

1. **Descargar BACI** (una vez): `BACI_HS12_V202601.zip` (1,27 GB) desde
   https://www.cepii.fr/DATA_DOWNLOAD/baci/data/BACI_HS12_V202601.zip y descomprimir en `raw_baci_csv/`.
   *No usar los Excel de la carpeta original: están truncados en la fila 1.048.576 (límite de Excel) y ni siquiera contienen a Chile ni a India en los años tempranos.*
2. **Filtrar** los CSV grandes: `python3 code/aux_filter_baci.py raw_baci_csv intermediate`
   (conserva solo India-importa-del-mundo, Chile-exporta-al-mundo y el bilateral India→Chile).
3. **Ejecutar el pipeline** en Stata: abrir `code/00_master.do`, ajustar el `global ROOT` y correr.
   Alternativa rápida ya probada: `do code/verify_pipeline.do` reconstruye y valida el núcleo
   (agregados → matriz → QA) desde `intermediate/baci_relevant_all.dta`, sin necesidad de la descarga.
4. **Controles WDI** (opcional, sin registro): `python3 code/aux_wdi.py raw_external`.
5. **Base consolidada con dummies calzadas por año** (pasos 15–17, ya incluidos en
   `00_master.do`): si tienes Stata instalado en tu computador, simplemente correr el
   pipeline completo del paso 3 ya te deja `output/base_maestra_chile_india_2012_2024.dta`.
   Este entorno de replicación en la nube no tiene Stata, así que aquí esos tres pasos se
   corrieron con sus equivalentes en Python (`code/15_build_master_panel.py`,
   `code/16_enrich_matriz_aap_periods.py`, `code/17_build_base_maestra.py`) sobre los
   archivos que ya estaban en `intermediate/`/`output/`, sin necesidad de la descarga de BACI.

## Fuentes de datos

- **BACI-CEPII** v202601 (comercio bilateral HS6): https://www.cepii.fr/DATA_DOWNLOAD/baci/doc/baci_webpage.html
- **Anexos del AAP** (SUBREI): listas de India y de Chile, original (HS2002) y ampliación 2017 (HS2017).
- **WDI / Banco Mundial** (controles macro): https://api.worldbank.org/
- **Aranceles (PENDIENTE, descarga manual):** WITS/TRAINS, Market Access Map (macmap.org, India=356), CBIC.

## Convenciones y advertencias

- Códigos país en BACI: **Chile = 152, India = 699**. Fuera de BACI (WITS/MacMap/OMC), **India = 356**.
- Las dummies `d_aap_*` miden **cobertura/elegibilidad**, no utilización aduanera efectiva.
- La comparación 2015–17 vs 2022–24 es **descriptiva**; no atribuir causalidad a la ampliación del AAP.
- **Concordancia HS:** el emparejamiento anexo→HS2012 es exacto para la mayoría de los códigos;
  198 códigos que cambiaron de revisión quedan marcados `pending_concordance` en `annex_manual_review`
  (requieren la tabla de correlación oficial UN Stats/WCO). No se inventaron concordancias.

## Archivos intencionalmente excluidos de este repositorio

Los siguientes archivos derivados son grandes y completamente regenerables ejecutando el pipeline; no están versionados aquí:

| Archivo | Carpeta | Tamaño aprox. | Cómo regenerarlo |
|---|---|---|---|
| `baci_relevant_all.dta` | `intermediate/` | 68 MB | `code/aux_filter_baci.py` sobre la descarga cruda de BACI |
| `panel_bilateral_balanced_full_2012_2024.dta` | `output/` | 46 MB | `code/08_build_balanced_panel.do` en adelante — o usar `panel_master_chile_india_2012_2024` (sí versionado, ver arriba), que trae la misma información más las dummies calzadas por año |
| `panel_bilateral_balanced_noncopper_2012_2024.dta` | `output/` | 46 MB | ídem, sin cobre — filtrar `panel_master_chile_india_2012_2024` con `d_copper_260300==0` |
| `chile_exports_world_hs6_year.dta` | `output/` | 14 MB | `code/03_build_baci_aggregates.do` |
| `india_imports_world_hs6_year.dta` | `output/` | 18 MB | `code/03_build_baci_aggregates.do` |

También se omitió `logs/verify_pipeline.log` (log de ejecución de referencia) y `documentation/minuta_construccion_panel.docx` (versión editable de Word) por restricciones de transferencia en esta migración; su contenido está íntegro en `documentation/minuta_construccion_panel.md`, `excel_reports/qa_report.xlsx` y `excel_reports/codebook.xlsx`.
