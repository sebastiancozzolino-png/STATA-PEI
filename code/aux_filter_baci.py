#!/usr/bin/env python3
"""aux_filter_baci.py — filtrado reproducible de los CSV grandes de BACI.
Llamado por 02_import_baci.do (o ejecutable a mano). Lee los CSV anuales
oficiales de CEPII y conserva SOLO los flujos relevantes para el proyecto:
  - j == 699           India importa del mundo (demanda + cuota de Chile)
  - i == 152           Chile exporta al mundo (oferta, RCA, Chile->India)
  - i == 699 & j==152  India -> Chile (panel recíproco)
Salida: un parquet/CSV compacto por año en INTERMEDIATE. Usa DuckDB (bajo uso de RAM).
Uso:  python3 aux_filter_baci.py RAW_BACI_DIR OUT_DIR [años...]
"""
import sys, os, glob, duckdb
RAW, OUT = sys.argv[1], sys.argv[2]
years = [int(y) for y in sys.argv[3:]] or list(range(2012, 2025))
os.makedirs(OUT, exist_ok=True)
con = duckdb.connect(); con.execute("PRAGMA threads=4; PRAGMA memory_limit='2GB';")
COLS="{'t':'VARCHAR','i':'VARCHAR','j':'VARCHAR','k':'VARCHAR','v':'VARCHAR','q':'VARCHAR'}"
for y in years:
    src = f"{RAW}/BACI_HS12_Y{y}_V202601.csv"
    if not os.path.exists(src):
        print(f"[WARN] falta {src}"); continue
    out = f"{OUT}/baci_relevant_{y}.csv"
    con.execute(f"""COPY (SELECT CAST(t AS INT) year, CAST(i AS INT) exporter_baci,
        CAST(j AS INT) importer_baci, lpad(CAST(CAST(k AS BIGINT) AS VARCHAR),6,'0') hs6,
        TRY_CAST(v AS DOUBLE)*1000 trade_value_usd, TRY_CAST(q AS DOUBLE) quantity_tons
      FROM read_csv('{src}',header=true,columns={COLS})
      WHERE CAST(j AS INT)=699 OR CAST(i AS INT)=152
         OR (CAST(i AS INT)=699 AND CAST(j AS INT)=152))
      TO '{out}' (HEADER, DELIMITER ',');""")
    print(f"{y}: -> {out}")
print("aux_filter_baci: done")
