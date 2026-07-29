*== 04_prepare_codes.do — country_codes y product_codes (padding HS6) ==*
cap log close pc
log using "$LOGS/04_prepare_codes.log", replace text
import delimited using "$RAW_BACI/country_codes_V202601.csv", varnames(1) clear encoding(UTF-8)
keep country_code country_name country_iso2 country_iso3
save "$INTER/country_codes.dta", replace
assert country_iso3=="CHL" if country_code==152
assert country_iso3=="IND" if country_code==699
import delimited using "$RAW_BACI/product_codes_HS12_V202601.csv", varnames(1) clear encoding(UTF-8) stringcols(1)
gen str6 hs6 = substr("000000"+code,-6,6)
assert length(hs6)==6
rename description description_hs12
keep hs6 description_hs12
duplicates drop hs6, force
count
assert r(N)==5202
save "$INTER/product_codes_hs12.dta", replace
di as txt "Diccionario HS12: " r(N) " productos"
log close pc
