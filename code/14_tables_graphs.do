*== 14_tables_graphs.do — tablas y gráficos principales (sin cobre) ==*
cap log close tg
log using "$LOGS/14_tables_graphs.log", replace text
use "$OUTPUT/matriz_fajnzylber_chile_india_noncopper.dta", clear
* distribución de cuadrantes
table quadrant_name, statistic(frequency) statistic(sum avg_india_imports_p1 avg_exports_p1)
* dispersión Fajnzylber (ejes en puntos porcentuales)
twoway (scatter delta_chile_share_product delta_product_share_india if quadrant_code>0, ///
        msize(vsmall) mcolor(%40)), ///
    xline(0) yline(0) ytitle("Δ cuota de Chile en el producto") ///
    xtitle("Δ participación del producto en importaciones de India") ///
    title("Matriz Fajnzylber Chile→India (2015-17 vs 2022-24, sin cobre)") ///
    subtitle("Cuadrantes: I naciente · II oportunidad perdida · III menguante · IV retirada")
graph export "$OUTPUT/fajnzylber_scatter.png", replace width(1600)
log close tg
