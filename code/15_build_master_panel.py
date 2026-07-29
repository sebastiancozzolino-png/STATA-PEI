#!/usr/bin/env python3
"""15_build_master_panel.py — panel balanceado año x direccion x HS6, con dummies AAP
calzadas por año (regimen vigente en cada año), replicando exactamente la logica de
08_build_balanced_panel.do.

Por que existe este script en Python: el entorno de replicacion de este repositorio no
tiene Stata instalado. panel_bilateral_balanced_full_2012_2024.dta (la salida nativa de
08_build_balanced_panel.do) fue excluido del repositorio por tamano (~46 MB) y nunca se
comiteo con las dummies calzadas por año. Este script reconstruye esa misma tabla desde
los insumos que SI estan versionados (output/panel_bilateral_observed_full_2012_2024,
intermediate/product_codes_hs12, intermediate/aap_by_direction) para poder versionar el
resultado con los dummies correctos.

Uso: python3 code/15_build_master_panel.py
Salida: output/panel_master_chile_india_2012_2024.csv (y .dta si pandas lo soporta)
"""
import pandas as pd

INTER = "intermediate"
OUTPUT = "output"

YEARS = list(range(2012, 2025))          # 2012..2024 (13 años)
DIRECTIONS = ["CHL_IND", "IND_CHL"]

# ---- 1. universo: 5202 HS6 x 13 años x 2 direcciones ----
codes = pd.read_stata(f"{INTER}/product_codes_hs12.dta")
assert len(codes) == 5202, f"esperaba 5202 HS6, obtuve {len(codes)}"

grid = codes[["hs6"]].merge(pd.DataFrame({"year": YEARS}), how="cross")
grid = grid.merge(pd.DataFrame({"direction": DIRECTIONS}), how="cross")
assert len(grid) == 5202 * 13 * 2

# ---- 2. comercio observado (bilateral, disperso) ----
observed = pd.read_stata(f"{OUTPUT}/panel_bilateral_observed_full_2012_2024.dta")
panel = grid.merge(observed, on=["year", "direction", "hs6"], how="left")
panel["trade_value_usd"] = panel["trade_value_usd"].fillna(0.0)
panel["quantity_tons"] = panel["quantity_tons"].fillna(0.0)
panel["positive_trade"] = (panel["trade_value_usd"] > 0).astype("int8")
panel["zero_trade"] = 1 - panel["positive_trade"]

# ---- 3. dummies AAP direccionales (lista del pais IMPORTADOR de esa direccion) ----
aap_dir = pd.read_stata(f"{INTER}/aap_by_direction.dta")
panel = panel.merge(aap_dir, on=["direction", "hs6"], how="left")
panel["d_aap_original"] = panel["d_aap_original"].fillna(0).astype("int8")
panel["d_aap_expanded"] = panel["d_aap_expanded"].fillna(0).astype("int8")

panel["d_added_2017"] = ((panel["d_aap_expanded"] == 1) & (panel["d_aap_original"] == 0)).astype("int8")
panel["d_maintained_2017"] = ((panel["d_aap_expanded"] == 1) & (panel["d_aap_original"] == 1)).astype("int8")
panel["d_removed_2017"] = ((panel["d_aap_original"] == 1) & (panel["d_aap_expanded"] == 0)).astype("int8")

# ---- 4. EL FIX: dummies de cobertura calzadas por año (regimen vigente en cada año) ----
# La ampliacion del AAP entro en vigor el 16-05-2017. Dos convenciones, ambas utiles:
#  - regime_calendar:  original 2012-2016 | expanded 2017-2024 (trata 2017 ya como ampliado)
#  - regime_full_year: original 2012-2017 | expanded 2018-2024 (trata 2017 como transicion,
#    dentro del regimen original por default; es la convencion usada por la matriz P0/P1)
panel["regime_calendar"] = panel["year"].apply(lambda y: "original" if y <= 2016 else "expanded")
panel["regime_full_year"] = panel["year"].apply(lambda y: "original" if y <= 2017 else "expanded")

panel["d_covered_current_calendar"] = panel.apply(
    lambda r: r["d_aap_original"] if r["year"] <= 2016 else r["d_aap_expanded"], axis=1
).astype("int8")
panel["d_covered_current_full_year"] = panel.apply(
    lambda r: r["d_aap_original"] if r["year"] <= 2017 else r["d_aap_expanded"], axis=1
).astype("int8")

panel["d_copper_260300"] = ((panel["direction"] == "CHL_IND") & (panel["hs6"] == "260300")).astype("int8")

# ---- 5. NO se denormaliza description_hs12 aca a proposito: repetirla en las 135,252
# filas infla el archivo ~2.5x sin agregar informacion (depende solo de hs6). Para texto
# descriptivo, cruzar por hs6 con intermediate/product_codes_hs12.dta (5,202 filas, ya
# versionado) o con excel_reports/codebook.xlsx.

# ---- 6. orden final ----
panel = panel.sort_values(["hs6", "year", "direction"]).reset_index(drop=True)
cols = [
    "hs6", "year", "direction",
    "trade_value_usd", "quantity_tons", "positive_trade", "zero_trade",
    "regime_calendar", "regime_full_year",
    "d_aap_original", "d_aap_expanded",
    "d_covered_current_calendar", "d_covered_current_full_year",
    "d_added_2017", "d_maintained_2017", "d_removed_2017",
    "d_copper_260300",
]
panel = panel[cols]

assert len(panel) == 5202 * 13 * 2, "el panel balanceado debe tener 135,252 filas"

out_csv = f"{OUTPUT}/panel_master_chile_india_2012_2024.csv"
panel.to_csv(out_csv, index=False)
print(f"CSV guardado: {out_csv} ({len(panel):,} filas)")

try:
    out_dta = f"{OUTPUT}/panel_master_chile_india_2012_2024.dta"
    panel.to_stata(out_dta, write_index=False, version=118)
    print(f"DTA guardado: {out_dta}")
except Exception as e:
    print(f"[WARN] no se pudo escribir .dta ({e}); el CSV es la fuente canonica.")

# ---- 7. controles de calidad ----
chk_copper = panel.loc[panel["d_copper_260300"] == 1, "hs6"].unique()
assert list(chk_copper) == ["260300"], chk_copper

exp_chl_ind = panel.loc[panel["direction"] == "CHL_IND"].groupby("year")["trade_value_usd"].sum()
print("\nExportaciones Chile->India por año (USD, control de coherencia):")
print(exp_chl_ind.map(lambda v: f"{v:,.0f}"))

print("\nDistribucion regime_full_year (para contraste con P0=2015-17 / P1=2022-24 de la matriz):")
print(panel.drop_duplicates(["hs6", "year"])[["year", "regime_full_year", "regime_calendar"]]
      .drop_duplicates().sort_values("year").to_string(index=False))

n_covered_p0_calendar = panel.loc[(panel.year.between(2015, 2017)) & (panel.direction == "CHL_IND"),
                                   "d_covered_current_calendar"].groupby(panel["year"]).sum()
print("\nHS6 cubiertos (Chile->India, d_covered_current_calendar==1) por año, 2015-2017:")
print(n_covered_p0_calendar)
