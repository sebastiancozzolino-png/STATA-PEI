#!/usr/bin/env python3
"""17_build_base_maestra.py — UNA sola base consolidada: panel año x direccion x HS6
(con las dummies AAP calzadas por año) MAS las variables de la matriz Fajnzylber
(P0/P1, shares, crecimiento, cuadrante, dummies AAP calzadas por periodo) fusionadas
en las mismas filas, para el subconjunto Chile->India donde la matriz aplica.

Por que hace falta: panel_master_chile_india_2012_2024 (año a año) y
matriz_fajnzylber_chile_india_full (P0/P1) quedaron como dos archivos separados.
Esta base junta ambos en una sola tabla, sin perder ninguna variable de ninguno.

Grano: hs6 x year x direction (135,252 filas, panel balanceado).
- Las columnas de la matriz (m_ind_world_p0, x_chl_ind_p0, quadrant_code, etc.) son
  valores de PERIODO (P0=2015-17 o P1=2022-24), no de año calendario: por eso se repiten
  idénticas en las 13 filas-año de cada hs6 dentro de direction=="CHL_IND" (la matriz solo
  existe para esa dirección). Para direction=="IND_CHL" quedan vacías (la matriz Fajnzylber
  de este proyecto es unidireccional Chile->India).

Uso: python3 code/17_build_base_maestra.py
Salida: output/base_maestra_chile_india_2012_2024.csv (y .dta si el tamaño lo permite)
"""
import pandas as pd

OUTPUT = "output"
INTER = "intermediate"

panel = pd.read_csv(f"{OUTPUT}/panel_master_chile_india_2012_2024.csv", dtype={"hs6": str})
matrix = pd.read_csv(f"{OUTPUT}/matriz_fajnzylber_chile_india_full.csv", dtype={"hs6": str, "hs2": str, "hs4": str})

# columnas de la matriz que van a fusionarse (excluye hs6 llave, hs2/hs4/description_hs12
# que ya se traen del panel para no duplicar)
matrix_cols = [c for c in matrix.columns if c not in ("hs6", "hs2", "hs4", "description_hs12")]
# prefijo claro para que no se confundan con las columnas año-a-año del panel
matrix_renamed = matrix[["hs6"] + matrix_cols].rename(columns={c: f"mtz_{c}" for c in matrix_cols})

# NO se denormaliza description_hs12 aca (mismo motivo que en panel_master_chile_india_2012_2024):
# repetir el texto en las 135,252 filas casi duplica el tamaño del archivo sin agregar
# informacion nueva (depende solo de hs6). Cruzar con intermediate/product_codes_hs12.dta.
base = panel.copy()
base["hs2"] = base["hs6"].str[:2]
base["hs4"] = base["hs6"].str[:4]
# la matriz solo aplica al sentido Chile->India: se fusiona solo en esas filas
base = base.merge(
    matrix_renamed,
    on="hs6",
    how="left",
)
# anular (poner en NA) las columnas de matriz en las filas IND_CHL, donde no corresponden
mtz_cols_final = [c for c in base.columns if c.startswith("mtz_")]
base.loc[base["direction"] != "CHL_IND", mtz_cols_final] = pd.NA

base = base.sort_values(["hs6", "year", "direction"]).reset_index(drop=True)

# orden de columnas: identificadores, luego año/valor/dummies del panel, luego matriz
front = ["hs6", "hs2", "hs4", "year", "direction"]
panel_cols = [c for c in panel.columns if c not in ("hs6",)]
ordered = front + [c for c in panel_cols if c not in front] + mtz_cols_final
base = base[ordered]

assert len(base) == 135252, f"esperaba 135,252 filas, obtuve {len(base)}"

out_csv = f"{OUTPUT}/base_maestra_chile_india_2012_2024.csv"
base.to_csv(out_csv, index=False)
print(f"CSV guardado: {out_csv}  filas={len(base):,}  columnas={base.shape[1]}")

try:
    out_dta = f"{OUTPUT}/base_maestra_chile_india_2012_2024.dta"
    base.to_stata(out_dta, write_index=False, version=118)
    print(f"DTA guardado: {out_dta}")
except Exception as e:
    print(f"[WARN] no se pudo escribir .dta ({e}); el CSV es la fuente canonica.")

print("\nColumnas de la base maestra:")
for c in base.columns:
    print(" -", c)

# controles de calidad
chl = base[base.direction == "CHL_IND"]
print("\nFilas CHL_IND con datos de matriz (deberian ser todas, 5,202*13=67,626):",
      chl["mtz_quadrant_code"].notna().sum())
ind = base[base.direction == "IND_CHL"]
print("Filas IND_CHL con datos de matriz (deberian ser 0):", ind["mtz_quadrant_code"].notna().sum())
print("\nEjemplo cobre 260300, CHL_IND, año 2013:")
print(base[(base.hs6 == "260300") & (base.direction == "CHL_IND") & (base.year == 2013)]
      [["hs6", "year", "direction", "trade_value_usd", "d_covered_current_calendar",
        "mtz_quadrant_name", "mtz_d_aap_covered_p0", "mtz_d_aap_covered_p1"]].to_string(index=False))
