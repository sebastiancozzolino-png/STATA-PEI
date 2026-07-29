#!/usr/bin/env python3
"""Descarga reproducible de controles WDI (Banco Mundial, sin registro)."""
import sys, urllib.request, json, csv, os
OUT=sys.argv[1]; os.makedirs(OUT,exist_ok=True)
IND={"NY.GDP.MKTP.CD":"gdp_current_usd","NY.GDP.MKTP.KD":"gdp_constant_usd","SP.POP.TOTL":"population",
 "NY.GDP.PCAP.CD":"gdp_per_capita_usd","PA.NUS.FCRF":"official_exchange_rate","FP.CPI.TOTL":"cpi_index",
 "NE.TRD.GNFS.ZS":"trade_openness_pct_gdp"}
rows={}
for code,name in IND.items():
    url=f"https://api.worldbank.org/v2/country/CHL;IND/indicator/{code}?date=2012:2024&format=json&per_page=2000"
    d=json.load(urllib.request.urlopen(url,timeout=30))
    for r in (d[1] or []): rows.setdefault((r['countryiso3code'],int(r['date'])),{})[name]=r['value']
with open(f"{OUT}/wdi_controls_chile_india_2012_2024.csv","w",newline='') as f:
    w=csv.writer(f); w.writerow(["iso3","year"]+list(IND.values()))
    for (iso,yr),v in sorted(rows.items()): w.writerow([iso,yr]+[v.get(n) for n in IND.values()])
print("WDI guardado")
