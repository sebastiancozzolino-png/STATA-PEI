#!/usr/bin/env python3
"""16_enrich_matriz_aap_periods.py — agrega a la matriz Fajnzylber las dummies de
cobertura AAP calzadas por periodo (P0=2015-2017 vs P1=2022-2024), en vez de dejar
d_aap_original y d_aap_expanded como dos columnas estaticas sin relacion explicita
con que periodo de la matriz corresponde a cada regimen.

Convencion (misma que regime_full_year en panel_master_chile_india_2012_2024 y en
08_build_balanced_panel.do): la ampliacion del AAP entro en vigor el 16-05-2017, asi
que P0 (2015-2017) queda bajo el regimen ORIGINAL y P1 (2022-2024) bajo el AMPLIADO.
2017 es un año de transicion (compartido con P0) — ver advertencia en el diccionario.

Uso: python3 code/16_enrich_matriz_aap_periods.py
Modifica en el lugar: output/matriz_fajnzylber_chile_india_full.{dta,csv,xlsx}
                      output/matriz_fajnzylber_chile_india_noncopper.{dta,csv,xlsx}
"""
import pandas as pd

OUTPUT = "output"

for suffix in ["full", "noncopper"]:
    path = f"{OUTPUT}/matriz_fajnzylber_chile_india_{suffix}.dta"
    df = pd.read_stata(path)

    if "d_aap_covered_p0" in df.columns:
        print(f"{path}: ya tiene las columnas de periodo, se omite.")
        continue

    # --- EL FIX: dummy de cobertura vigente en cada periodo de la matriz ---
    df["d_aap_covered_p0"] = df["d_aap_original"]
    df["d_aap_covered_p1"] = df["d_aap_expanded"]
    # newly covered heading into P1 pero no vigente en P0 (subset de d_added_2017,
    # ya presente, se deja explicito para lectura directa de la matriz)
    df["d_aap_covered_only_p1"] = ((df["d_aap_covered_p1"] == 1) & (df["d_aap_covered_p0"] == 0)).astype("int8")
    df["d_aap_covered_only_p0"] = ((df["d_aap_covered_p0"] == 1) & (df["d_aap_covered_p1"] == 0)).astype("int8")

    # reordenar: insertar las columnas de periodo justo despues de d_aap_expanded
    cols = list(df.columns)
    insert_at = cols.index("d_aap_expanded") + 1
    new_cols = ["d_aap_covered_p0", "d_aap_covered_p1", "d_aap_covered_only_p1", "d_aap_covered_only_p0"]
    rest = [c for c in cols if c not in new_cols]
    ordered = rest[:insert_at] + new_cols + rest[insert_at:]
    df = df[ordered]

    df.to_stata(path, write_index=False, version=118)
    df.to_csv(f"{OUTPUT}/matriz_fajnzylber_chile_india_{suffix}.csv", index=False)
    df.to_excel(f"{OUTPUT}/matriz_fajnzylber_chile_india_{suffix}.xlsx", index=False)
    print(f"{path}: agregadas d_aap_covered_p0 / d_aap_covered_p1 / d_aap_covered_only_p1 / d_aap_covered_only_p0")
    print(f"  filas={len(df)}  cubiertos_p0={df.d_aap_covered_p0.sum()}  cubiertos_p1={df.d_aap_covered_p1.sum()}  "
          f"nuevos_en_p1={df.d_aap_covered_only_p1.sum()}  perdidos_en_p1={df.d_aap_covered_only_p0.sum()}")
