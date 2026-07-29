# Panel Stata + Matriz Fajnzylber Chile–India

This repository is a git mirror of the Google Drive project `Panel_Stata_Fajnzylber_2026`.

**Proyecto:** Economía Internacional · Acuerdo de Alcance Parcial (AAP) Chile–India
**Datos:** BACI-CEPII HS 2012, versión 202601 (2012–2024) · anexos del AAP (original 2007 y ampliación 2017)
**Salida principal:** Matriz Fajnzylber–CEPAL de las exportaciones de Chile a India, comparando los trienios 2015–2017 y 2022–2024, **excluyendo cobre (HS6 260300)**.

## Resultado central (verificado en Python y en StataMP 17)

Matriz sin cobre, 5.165 productos HS6: **219 estrellas nacientes**, **1.905 oportunidades perdidas**, **228 estrellas menguantes**, **2.791 en retirada**, 22 sin demanda. El cobre 260300 (~US$950 M/año en 2022–24, cerca de la mitad del total Chile→India) se aísla en una fila de sensibilidad.

## Estructura de carpetas

```
STATA-PEI/
├── code/               do-files 00–14 + verify_pipeline.do + aux_filter_baci.py + aux_wdi.py
├── raw_baci_csv/       country_codes, product_codes (CSV oficiales CEPII)
├── crosswalk/          crosswalk de anexos, coberturas AAP, revisión manual
├── intermediate/       bases intermedias del pipeline (baci_relevant_all.dta excluido, ver abajo)
├── output/             panels .dta, matriz Fajnzylber (.dta/.xlsx/.csv), agregados, gráfico
├── excel_reports/      auditoría, matriz formateada, QA, codebook, aranceles (plantilla)
├── documentation/      README de replicación + minuta metodológica
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
| `panel_bilateral_balanced_full_2012_2024.dta` | `output/` | 46 MB | `code/08_build_balanced_panel.do` en adelante |
| `panel_bilateral_balanced_noncopper_2012_2024.dta` | `output/` | 46 MB | ídem, sin cobre |
| `chile_exports_world_hs6_year.dta` | `output/` | 14 MB | `code/03_build_baci_aggregates.do` |
| `india_imports_world_hs6_year.dta` | `output/` | 18 MB | `code/03_build_baci_aggregates.do` |

También se omitió `logs/verify_pipeline.log` (log de ejecución de referencia) y `documentation/minuta_construccion_panel.docx` (versión editable de Word) por restricciones de transferencia en esta migración; su contenido está íntegro en `documentation/minuta_construccion_panel.md`, `excel_reports/qa_report.xlsx` y `excel_reports/codebook.xlsx`.
