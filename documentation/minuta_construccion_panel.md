# Minuta metodológica — Construcción del panel y la matriz Fajnzylber Chile–India

**Curso:** Economía Internacional · **Objeto:** Acuerdo de Alcance Parcial (AAP) Chile–India
**Datos:** BACI-CEPII HS 2012, versión 202601 · **Fecha:** julio de 2026

## 1. Objetivo

Construir una infraestructura de datos anual 2012–2024 del comercio Chile–India a nivel de producto HS6 y, como salida principal, una matriz Fajnzylber–CEPAL de las exportaciones de Chile hacia India que compare los promedios trienales 2015–2017 y 2022–2024, identificando productos cubiertos por el AAP, excluyendo el cobre de los resultados principales y sin confundir cobertura del acuerdo con utilización aduanera efectiva.

## 2. El problema de los archivos originales

Los trece archivos Excel de BACI presentes en la carpeta de trabajo están truncados: todos terminan exactamente en la fila 1.048.576, que es el límite de filas de Excel. Un año completo de BACI HS12 tiene del orden de diez millones de registros, de modo que el Excel conserva apenas la primera décima parte. Como el archivo viene ordenado por código de exportador, ese recorte deja únicamente a los países con códigos bajos: en el archivo de 2012 el exportador máximo presente es el 124, por lo que Chile (152) e India (699) ni siquiera aparecen. En consecuencia, los Excel son inservibles para este proyecto y se descargaron los CSV oficiales completos desde CEPII (BACI_HS12_V202601.zip, 1,27 GB), cuyo rango real de países va de 4 a 894 e incluye tanto a Chile como a India.

## 3. Procesamiento de BACI

Dado el tamaño de los CSV, se filtró cada año conservando solo los flujos relevantes: las importaciones de India desde el mundo (importador 699), las exportaciones de Chile al mundo (exportador 152) y el flujo bilateral inverso India→Chile. Se preservó el código HS6 como texto de seis dígitos con ceros iniciales y se convirtió el valor de miles a dólares. El resultado, cerca de dos millones de observaciones, alimenta todos los agregados posteriores. Como control de coherencia, las exportaciones de Chile a India rondan los US$1.300 a 3.000 millones anuales y el producto dominante en 2022–2024 es el mineral de cobre (HS6 260300), con unos US$950 millones al año; las importaciones totales de India crecen de US$386 mil millones en 2015 a US$666 mil millones en 2023. Todas estas cifras son consistentes con las estadísticas conocidas.

## 4. Anexos del AAP y armonización de nomenclaturas

Se procesaron los cuatro anexos del acuerdo: la lista original de India (178 ítems, HS2002), la lista india ampliada de 2017 (1.110 ítems, HS2017), la lista original de Chile (296 ítems, HS2002) y la lista chilena ampliada de 2017 (2.099 ítems, HS2017). El parser reconstruye cada ítem por número serial y extrae el código, el margen de preferencia y la descripción, reconociendo casos complejos como códigos de ocho dígitos, subpartidas de seis, rangos y alternativas. Los recuentos seriales coinciden exactamente con los declarados en los anexos.

La lista de India se aplica a las exportaciones de Chile hacia India y la lista de Chile a las exportaciones de India hacia Chile. Para las dummies de cobertura se emparejó cada código HS6 contra el universo HS2012 de BACI. El emparejamiento es exacto para la mayoría de los códigos, estables entre revisiones; los códigos que cambiaron de revisión —27 en la lista original de India, 59 en la ampliada, 14 y 98 en las de Chile— quedaron marcados como pendientes de concordancia y enviados a la tabla de revisión manual, a la espera de la correlación oficial de UN Stats/WCO. No se inventaron concordancias. La cobertura exacta resultante es de 81 productos HS6 en la lista original de India y 458 en la ampliada; 254 y 1.428 en las de Chile. El cobre 260300 aparece en ambas listas indias, con una concesión del 10% en la original y del 100% en la ampliada, tal como indica la documentación del acuerdo.

## 5. La matriz Fajnzylber

La matriz se construye para Chile→India con una fila por HS6 y dos trienios: P0 = 2015–2017 y P1 = 2022–2024. El eje de dinamismo de la demanda es la variación de la participación del producto en las importaciones totales de India; el eje de competitividad es la variación de la cuota de Chile dentro de las importaciones indias de ese producto. El cruce de ambos ejes define cuatro cuadrantes: estrellas nacientes (la demanda gana peso y Chile gana cuota), oportunidades perdidas (la demanda gana peso pero Chile no), estrellas menguantes (Chile gana cuota en un mercado que pierde peso) y retirada (ni lo uno ni lo otro). Los productos sin demanda india en ambos trienios se apartan sin forzar cuadrante, y se distingue la entrada de Chile desde cero de la pérdida de cuota.

Excluido el cobre, la matriz clasifica 5.165 productos: 219 estrellas nacientes, 1.905 oportunidades perdidas, 228 estrellas menguantes y 2.791 en retirada. Entre las estrellas nacientes destacan, por valor exportado, los ánodos de cobre (740200), el molibdeno (261310, con una cuota chilena del 42% del mercado indio), las nueces (080231, con un 70% de cuota), la pulpa de madera (470200) y los kiwis (081050, 43%). Entre las oportunidades perdidas cubiertas por el AAP y con fuerte crecimiento de la demanda india aparecen la chatarra de aluminio (760200), los cátodos de cobre refinado (740311) y la chatarra inoxidable (720421), mercados donde India compra cada vez más pero Chile mantiene cuotas cercanas a cero.

Esta lectura es descriptiva: no debe atribuirse causalmente a la ampliación del AAP, y las dummies de cobertura no equivalen a utilización efectiva del acuerdo.

## 6. Verificación

El pipeline se implementó de forma independiente en Python (pandas/DuckDB) y en Stata. Ejecutado en StataMP 17, el do-file reproduce exactamente los mismos resultados: 5.166 filas en la matriz completa, 5.165 sin cobre, y la misma distribución de cuadrantes (219 / 1.905 / 228 / 2.791 / 22). Se verificaron además el diccionario de 5.202 productos HS12, el panel balanceado de 135.252 filas (5.202 × 13 × 2), la unicidad año × dirección × HS6 y la presencia del cobre en la base completa junto con su ausencia en la base principal.

## 7. Pendientes reales

Quedan pendientes de descarga manual, por requerir registro, los aranceles NMF y preferenciales (WITS/TRAINS, Market Access Map con India=356, y el arancel oficial de India de CBIC), para los cuales se dejó preparada la plantilla con el esquema de variables y el importador exacto. La validación secundaria con el ITC Export Potential Map también requiere registro y no bloquea la construcción de la base. Finalmente, la concordancia oficial de los 198 códigos que cambiaron de revisión HS permitiría cerrar por completo la cobertura del AAP.
