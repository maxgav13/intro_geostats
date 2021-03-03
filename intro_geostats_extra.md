---
title: "Material extra: Análisis geoestadístico resumido mostrando todo el código empleado en R"
author: 
  - name: "Maximiliano Garnier-Villarreal"
    affiliation: 'Escuela Centroamericana de Geología, Universidad de Costa Rica'
    email: 'maximiliano.garniervillarreal@ucr.ac.cr'
# date: "03 March 2021"
lang: es
bibliography: ["bib/all.bib"]
# biblio-style: apalike2
csl: csl/apa6.csl
css: css/style.css
# documentclass: "apa6"
# classoption: "man"
link-citations: true
output:
  bookdown::html_document2:
    toc: true
    toc_depth: 3
    toc_float: true
    theme: cosmo
    number_sections: true
    code_download: true
    keep_md: true
    # dev: "tiff"
  bookdown::pdf_document2:
    df_print: kable
    number_sections: false
    toc: false
    includes:
      in_header: header.tex
always_allow_html: true
---




# Introducción

Este material extra muestra todo el código en **R** [@R-base] que se usó en la sección Análisis geoestadístico del artículo principal. Se limita únicamente a la explicación básica de cuál código se usó para qué, y de cómo se usa. Para la base teórica, interpretación y análisis se remite al lector al artículo principal.

# Análisis geoestadístico {#geostats-analisis}

Se va a hacer uso del paquete **gstat** [@R-gstat; @gstat2004; @gstat2016] para la parte geoestadística, y para la manipulación de los datos se usan **dplyr** [@R-dplyr], **tidyr** [@R-tidyr] y **broom** [@R-broom], para los gráficos se usa **ggplot2** [@R-ggplot2; @ggplot22016], para las tablas se usa **kableExtra** [@R-kableExtra], y para la creación y manipulación de objetos espaciales se usan **sf** [@R-sf; @sf2018], **sp** [@R-sp; @sp2005; @sp2013], y **stars** [@R-stars].

## Análisis Exploratorio de Datos

Para importar los datos ("datos.csv") en el objeto denominado `datos` (un data frame) se usa `import` del paquete **rio** [@R-rio]. Como aquí se trabaja desde un proyecto de **R** (que es recomendado) se usa el paquete **here** [@R-here] para hacer referencia a archivos dentro del sistema de archivos del proyecto. Se usa la función `here` donde la dirección del archivo a buscar se separa en sus partes por comas, donde en este caso busca en la carpeta "data" el archivo "datos.csv". Esto hace que sea más fácil de usar en diferentes computadoras con diferentes sistemas operativos.

La tabla contiene 3 columnas: "x", "y", "z", donde las dos primeras corresponden con las coordenadas y la tercera corresponde con la variable de interés. Para mayor facilidad se define la variable en un objeto `myvar`, que podrá ser reutilizado.

Se puede obtener un resumen estadístico de la variable por medio de la función `descr` del paquete **summarytools** [@R-summarytools], el cual es trabajado para mostrar solo lo necesario. El Cuadro \@ref(tab:AED) se genera con la función `kable` del paquete **kableExtra**, donde se pueden modificar aspectos como los nombres de las columnas, la cantidad de dígitos a usar, el alineado de las columnas, y el encabezado de la tabla. Adicionalmente se guarda la varianza de la variable en el objeto `S`.


```r
datos = import(here('data','datos.csv'), setclass = 'tbl')

myvar = 'z' # variable a modelar

descr(datos[myvar],style = 'rmarkdown',transpose = T) %>% 
  select(-c(12,13,15)) %>% 
  relocate(N.Valid) %>% 
  kable(col.names = c('N','Media','Desv. Est.','Min','Q1','Mediana',
                      'Q3','Max','MAD','IQR','CV','Asimetría'),
        digits = 2,
        # format = 'simple',
        align = 'c',
        caption = 'Resumen estadístico de la variable "z".') %>% 
  kable_styling(full_width = F)
```

<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>(\#tab:AED)Resumen estadístico de la variable "z".</caption>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:center;"> N </th>
   <th style="text-align:center;"> Media </th>
   <th style="text-align:center;"> Desv. Est. </th>
   <th style="text-align:center;"> Min </th>
   <th style="text-align:center;"> Q1 </th>
   <th style="text-align:center;"> Mediana </th>
   <th style="text-align:center;"> Q3 </th>
   <th style="text-align:center;"> Max </th>
   <th style="text-align:center;"> MAD </th>
   <th style="text-align:center;"> IQR </th>
   <th style="text-align:center;"> CV </th>
   <th style="text-align:center;"> Asimetría </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> z </td>
   <td style="text-align:center;"> 60 </td>
   <td style="text-align:center;"> 29.9 </td>
   <td style="text-align:center;"> 0.86 </td>
   <td style="text-align:center;"> 28.19 </td>
   <td style="text-align:center;"> 29.2 </td>
   <td style="text-align:center;"> 29.86 </td>
   <td style="text-align:center;"> 30.38 </td>
   <td style="text-align:center;"> 31.95 </td>
   <td style="text-align:center;"> 0.94 </td>
   <td style="text-align:center;"> 1.15 </td>
   <td style="text-align:center;"> 0.03 </td>
   <td style="text-align:center;"> 0.47 </td>
  </tr>
</tbody>
</table>

```r
S = var(datos[[myvar]]) # varianza de la variable
S
```

```
## [1] 0.7452631
```

```r
gg.hist = ggplot(datos, aes_string(myvar)) + 
  geom_histogram(aes(y = stat(density)), bins = 10, 
                 col = 'black', fill = 'orange') + 
  geom_vline(xintercept = mean(datos[[myvar]]), col = 'red', size=1.25) +
  geom_density(col = 'blue', size=1.25) +
  labs(y = 'Densidad')
gg.hist
```

<div class="figure" style="text-align: center">
<img src="figures/extra/AED-1.png" alt="Histograma de la variable. La línea roja corresponde con la media, y la curva azul con la curva de densidad empírica." width="90%" />
<p class="caption">(\#fig:AED)Histograma de la variable. La línea roja corresponde con la media, y la curva azul con la curva de densidad empírica.</p>
</div>

El histograma (Figura \@ref(fig:AED)) se construye con **ggplot2**, donde se remite al lector a consultar @garnier-villarreal2020 (Capítulo 4) para una guía de como usar este paquete de una forma más amplia. De manera general, hace uso de data frames (tablas) y sus variables de una forma directa, donde dependiendo de lo que se quiere graficar se emplean diferentes geomestrías (`geom_*`), y tiene otra serie de funciones para personalizar el gráfico.

El primer paso es generar un objeto espacial. Para pasar los datos a formato espacial se usa la función `st_as_sf` del paquete **sf**, donde se definen las columnas donde se ubican las coordenadas (`coords`, siempre primero 'x' y luego 'y'), y el sistema de referencia (`crs`), donde en este caso no corresponde a ninguno entonces se usa `NA`, pero sino se usaria el código *epsg* respectivo. El resto de acciones son para pasos posteriores y no es necesario modificarlas. Se crean dos objetos espaciales, uno tipo **sf** y uno **sp** ya que a veces es necesario uno sobre otro, dependiendo de la función, pero en general se trabaja con el **sf**.


```r
datos_sf = st_as_sf(datos, coords = 1:2, crs = NA) %>% 
  mutate(X = st_coordinates(.)[,1], Y = st_coordinates(.)[,2]) %>% 
  relocate(X, Y)
datos_sp = as(datos_sf, 'Spatial')
coordnames(datos_sp) = c('X','Y')
```

Las distancias se determinan una vez se tiene el objeto espacial, usando `st_distance` de **sf**. El resto del código es simple manipulación para obtener un vector con las distancias mínima, media, y máxima.


```r
dists = st_distance(datos_sf) %>% .[lower.tri(.)] %>% unclass()
distancias = signif(c(min(dists), mean(dists), max(dists)),6) # rango de distancias
names(distancias) = c('min', 'media', 'max') 
distancias
```

```
##       min     media       max 
##   1.41421  51.09850 128.03500
```

Una forma de mostrar el área de influencia de los resultados es tener un polígono que encierra a los datos, ya que sería esta el área donde los resultados son realmente válidos. El siguiente código realiza el cálculo de dicho polígono.


```r
outline = st_convex_hull(st_union(datos_sf))
```

La grilla a interpolar se crea con el siguiente código, generando objetos `stars` que son similares a objetos `raster` [@R-raster] pero más versátiles ya que permiten tener arreglos espaciales más complejos y diversos. Primeramente se genera una grilla regular (`datosint`) y a partir del polígono que encierra los datos (obtenido arriba) se recorta esta grilla en una grilla irregular (`datosint2`).


```r
bb = st_bbox(datos_sf)
dint = max(c(bb[3]-bb[1],bb[4]-bb[2])/nrow(datos_sf))
dx = seq(bb[1],bb[3],dint) # coordenadas x
dy = seq(bb[4],bb[2],-dint) # coordenadas y
st_as_stars(matrix(0, length(dx), length(dy))) %>%
  st_set_dimensions(1, dx) %>%
  st_set_dimensions(2, dy) %>%
  st_set_dimensions(names = c("X", "Y")) %>% 
  st_set_crs(st_crs(datos_sf)) -> datosint

datosint2 = st_crop(datosint, outline)
```

La distribución en el espacio de los datos se muestra en la Figura \@ref(fig:dist-espacial), donde los puntos se encuentran rellenados de acuerdo al valor de la variable (`aes_string(col = myvar)`), de nuevo haciendo uso de **ggplot2** y una geometría específica para datos **sf** (`geom_sf`).


```r
gg.map.pts = ggplot() + 
  geom_sf(data = outline, col = 'cyan', alpha = .1, size = .75) + 
  geom_sf(data = datos_sf, aes_string(col = myvar), size = 3, alpha = 0.6) + 
  scale_color_viridis_c() + 
  labs(x = x_map, y = y_map) +
  if (!is.na(st_crs(datos_sf))) {
    coord_sf(datum = st_crs(datos_sf))
  }
gg.map.pts
```

<div class="figure" style="text-align: center">
<img src="figures/extra/dist-espacial-1.png" alt="Mapa de puntos mostrando la distribución espacial de la variable." width="90%" />
<p class="caption">(\#fig:dist-espacial)Mapa de puntos mostrando la distribución espacial de la variable.</p>
</div>

El siguiente código genera un mapa interactivo (que no se incluye en el artículo principal porque no se puede desplegar adecuadamente, pero se incluye aquí ya que el formato *html* sí permite interactividad). Para este mapa se usa el paquete **mapview** [@R-mapview] y para los colores se usa el paquete **RColorBrewer** [@R-RColorBrewer]. Consultar @garnier-villarreal2020 (Capítulo 6) para más información sobre el uso de **R** para datos espaciales.


```r
mapview(outline, alpha.regions = 0, layer.name='Borde', 
        homebutton = F, legend = F, native.crs = F) + 
  mapview(datos_sf, zcol = myvar, alpha=0.1, 
          layer.name = myvar, native.crs = F, 
          col.regions = brewer.pal(9,'YlOrRd'))
```

<!--html_preserve--><div id="htmlwidget-c3993b22fd21ef937a34" style="width:90%;height:296.64px;" class="leaflet html-widget"></div>
<script type="application/json" data-for="htmlwidget-c3993b22fd21ef937a34">{"x":{"options":{"minZoom":-1000,"crs":{"crsClass":"L.CRS.Simple","code":null,"proj4def":null,"projectedBounds":null,"options":{}},"preferCanvas":false},"calls":[{"method":"createMapPane","args":["polygon",420]},{"method":"addPolygons","args":[[[[{"lng":[15,10,1,11,21,98,99,98,15],"lat":[2,4,15,79,94,97,19,2,2]}]]],null,"Borde",{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}},"pane":"polygon","stroke":true,"color":"#333333","weight":1,"opacity":0.9,"fill":true,"fillColor":"#6666ff","fillOpacity":0,"smoothFactor":1,"noClip":false},null,{"maxWidth":800,"minWidth":50,"autoPan":true,"keepInView":false,"closeButton":true,"closeOnClick":true,"className":""},"1",{"interactive":false,"permanent":false,"direction":"auto","opacity":1,"offset":[0,0],"textsize":"10px","textOnly":false,"className":"","sticky":true},{"stroke":true,"weight":2,"opacity":0.9,"fillOpacity":0,"bringToFront":false,"sendToBack":false}]},{"method":"createMapPane","args":["point",440]},{"method":"addCircleMarkers","args":[[78,33,92,76,48,66,47,91,82,15,62,76,82,71,79,57,25,23,13,38,48,86,87,20,4,46,45,53,13,93,39,37,2,93,40,25,97,88,18,45,16,48,2,58,2,71,11,19,46,69,30,33,62,94,88,39,7,80,33,55],[77,79,49,28,44,40,97,78,45,1,80,49,58,91,11,74,38,19,67,25,73,88,18,48,10,30,86,45,79,52,13,24,98,63,86,4,98,60,27,6,33,75,15,71,86,13,47,99,41,69,58,43,51,21,53,74,28,33,68,67],6,null,"z",{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}},"pane":"point","stroke":true,"color":"#333333","weight":2,"opacity":[0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1],"fill":true,"fillColor":["#FD943F","#FEDB7A","#FC7735","#FD9E43","#FC6F33","#FEC763","#FEE38B","#FEB752","#F84627","#FDA345","#FEE896","#FC552C","#980026","#EE3022","#FD8F3D","#FEDB7A","#FECD69","#FECD69","#FD943F","#FC7735","#FEE085","#FC5E2E","#FEB24C","#FD8F3D","#FD9E43","#FD9941","#FED774","#FC883A","#FC883A","#EE3022","#FD8F3D","#FC6F33","#FED26E","#FDAD4A","#FFF7BA","#FEB752","#FEBD58","#FD943F","#FD9E43","#E31B1C","#FEB24C","#FEDB7A","#FECD69","#FEE085","#A90026","#FEC763","#F13724","#FEE38B","#FC6631","#FECD69","#B90026","#C50523","#EA2920","#FDAD4A","#CA0922","#FEE085","#FEB24C","#FD943F","#FD943F","#EA2920"],"fillOpacity":[0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6]},null,null,["<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>1&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>77&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>78&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.932312129403&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>2&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>79&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>33&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.9868516569848&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>3&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>49&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>92&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.2478622072745&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>4&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>28&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>76&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.8426073842386&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>5&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>44&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>48&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.3404914607854&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>6&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>40&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>66&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.2231065523208&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>7&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>97&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>47&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.7476840460364&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>8&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>78&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>91&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.4664035162964&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>9&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>45&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>82&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.6826255928166&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>10&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>1&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>15&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.7403325883819&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>11&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>80&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>62&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.5939262979717&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>12&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>49&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>76&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.5049027284254&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>13&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>58&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>82&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>31.9536782994429&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>14&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>91&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>71&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.8882826751354&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>15&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>11&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>79&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.0662741066625&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>16&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>74&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>57&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.9961000126862&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>17&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>38&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>25&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.2036285187457&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>18&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>19&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>23&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.2045892531115&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>19&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>67&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>13&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.9774656066419&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>20&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>25&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>38&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.2849033252549&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>21&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>73&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>48&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.8476255959374&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>22&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>88&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>86&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.4740461804753&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>23&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>18&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>87&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.5213638986964&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>24&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>48&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>20&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.0511668490398&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>25&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>10&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>4&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.8343105017248&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>26&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>30&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>46&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.8796304846859&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>27&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>86&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>45&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.0402644279405&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>28&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>45&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>53&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.0878265690296&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>29&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>79&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>13&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.1388762357053&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>30&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>52&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>93&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.911179365503&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>31&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>13&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>39&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.0309408506894&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>32&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>24&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>37&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.3317627678735&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>33&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>98&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>2&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.0832961059587&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>34&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>63&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>93&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.6324223062088&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>35&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>86&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>40&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.1887886810174&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>36&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>4&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>25&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.4601902746714&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>37&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>98&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>97&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.3755851121228&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>38&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>60&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>88&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.9705466414291&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>39&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>27&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>18&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.8486506212703&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>40&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>6&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>45&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>31.1297829413424&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>41&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>33&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>16&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.5255402377545&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>42&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>75&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>48&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.9487822215965&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>43&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>15&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>2&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.1435564222781&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>44&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>71&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>58&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.8087328451617&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>45&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>86&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>2&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>31.8164520876527&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>46&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>13&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>71&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.2423069521053&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>47&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>47&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>11&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.8039089486277&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>48&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>99&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>19&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.7770656139345&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>49&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>41&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>46&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.4112414483193&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>50&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>69&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>69&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.1938538199166&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>51&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>58&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>30&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>31.6648661345006&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>52&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>43&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>33&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>31.5097916869497&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>53&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>51&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>62&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.9918006096027&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>54&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>21&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>94&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.5885130743666&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>55&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>53&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>88&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>31.4892144436236&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>56&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>74&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>39&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>28.8402074292649&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>57&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>28&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>7&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.5229923529456&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>58&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>33&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>80&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.969552984372&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>59&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>68&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>33&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>29.9960049113326&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>","<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"lib/popup/popup.css\"><\/head><body><div class=\"scrollableContainer\"><table class=\"popup scrollable\" id=\"popup\"><tr class='coord'><td><\/td><td><b>Feature ID<\/b><\/td><td align='right'>60&emsp;<\/td><\/tr><tr class='alt'><td>1<\/td><td><b>X&emsp;<\/b><\/td><td align='right'>67&emsp;<\/td><\/tr><tr><td>2<\/td><td><b>Y&emsp;<\/b><\/td><td align='right'>55&emsp;<\/td><\/tr><tr class='alt'><td>3<\/td><td><b>z&emsp;<\/b><\/td><td align='right'>30.9485958452758&emsp;<\/td><\/tr><tr><td>4<\/td><td><b>geometry&emsp;<\/b><\/td><td align='right'>sfc_POINT&emsp;<\/td><\/tr><\/table><\/div><\/body><\/html>"],{"maxWidth":800,"minWidth":50,"autoPan":true,"keepInView":false,"closeButton":true,"closeOnClick":true,"className":""},["29.932312129403","28.9868516569848","30.2478622072745","29.8426073842386","30.3404914607854","29.2231065523208","28.7476840460364","29.4664035162964","30.6826255928166","29.7403325883819","28.5939262979717","30.5049027284254","31.9536782994429","30.8882826751354","30.0662741066625","28.9961000126862","29.2036285187457","29.2045892531115","29.9774656066419","30.2849033252549","28.8476255959374","30.4740461804753","29.5213638986964","30.0511668490398","29.8343105017248","29.8796304846859","29.0402644279405","30.0878265690296","30.1388762357053","30.911179365503","30.0309408506894","30.3317627678735","29.0832961059587","29.6324223062088","28.1887886810174","29.4601902746714","29.3755851121228","29.9705466414291","29.8486506212703","31.1297829413424","29.5255402377545","28.9487822215965","29.1435564222781","28.8087328451617","31.8164520876527","29.2423069521053","30.8039089486277","28.7770656139345","30.4112414483193","29.1938538199166","31.6648661345006","31.5097916869497","30.9918006096027","29.5885130743666","31.4892144436236","28.8402074292649","29.5229923529456","29.969552984372","29.9960049113326","30.9485958452758"],{"interactive":false,"permanent":false,"direction":"auto","opacity":1,"offset":[0,0],"textsize":"10px","textOnly":false,"className":"","sticky":true},null]},{"method":"addHomeButton","args":[1,2,99,97,"z","Zoom to z","<strong> z <\/strong>","bottomright"]},{"method":"addLayersControl","args":[[],["Borde","z"],{"collapsed":true,"autoZIndex":true,"position":"topleft"}]},{"method":"addLegend","args":[{"colors":["#FFFFCC , #FFF2AF 8.26614723203362%, #FEDE81 21.5467490736648%, #FEBA55 34.8273509152961%, #FD923E 48.1079527569273%, #FC532B 61.3885545985586%, #E31B1C 74.6691564401898%, #BA0026 87.949758281821%, #800026 "],"labels":["28.5","29.0","29.5","30.0","30.5","31.0","31.5"],"na_color":null,"na_label":"NA","opacity":1,"position":"topright","type":"numeric","title":"z","extra":{"p_1":0.0826614723203362,"p_n":0.87949758281821},"layerId":null,"className":"info legend","group":"z"}]},{"method":"addHomeButton","args":[1,2,99,97,null,"Zoom to full extent","<strong>Zoom full<\/strong>","bottomleft"]}],"limits":{"lat":[2,97],"lng":[1,99]},"fitBounds":[2,1,97,99,[]]},"evals":[],"jsHooks":{"render":[{"code":"function(el, x, data) {\n  return (\n      function(el, x, data) {\n      // get the leaflet map\n      var map = this; //HTMLWidgets.find('#' + el.id);\n      // we need a new div element because we have to handle\n      // the mouseover output separately\n      // debugger;\n      function addElement () {\n      // generate new div Element\n      var newDiv = $(document.createElement('div'));\n      // append at end of leaflet htmlwidget container\n      $(el).append(newDiv);\n      //provide ID and style\n      newDiv.addClass('lnlt');\n      newDiv.css({\n      'position': 'relative',\n      'bottomleft':  '0px',\n      'background-color': 'rgba(255, 255, 255, 0.7)',\n      'box-shadow': '0 0 2px #bbb',\n      'background-clip': 'padding-box',\n      'margin': '0',\n      'padding-left': '5px',\n      'color': '#333',\n      'font': '9px/1.5 \"Helvetica Neue\", Arial, Helvetica, sans-serif',\n      'z-index': '700',\n      });\n      return newDiv;\n      }\n\n\n      // check for already existing lnlt class to not duplicate\n      var lnlt = $(el).find('.lnlt');\n\n      if(!lnlt.length) {\n      lnlt = addElement();\n\n      // grab the special div we generated in the beginning\n      // and put the mousmove output there\n\n      map.on('mousemove', function (e) {\n      if (e.originalEvent.ctrlKey) {\n      if (document.querySelector('.lnlt') === null) lnlt = addElement();\n      lnlt.text(\n                           ' x: ' + (e.latlng.lng).toFixed(5) +\n                           ' | y: ' + (e.latlng.lat).toFixed(5) +\n                           ' | epsg: NA ' +\n                           ' | proj4: NA ' +\n                           ' | zoom: ' + map.getZoom() + ' ');\n      } else {\n      if (document.querySelector('.lnlt') === null) lnlt = addElement();\n      lnlt.text(\n                      ' lon: ' + (e.latlng.lng).toFixed(5) +\n                      ' | lat: ' + (e.latlng.lat).toFixed(5) +\n                      ' | zoom: ' + map.getZoom() + ' ');\n      }\n      });\n\n      // remove the lnlt div when mouse leaves map\n      map.on('mouseout', function (e) {\n      var strip = document.querySelector('.lnlt');\n      strip.remove();\n      });\n\n      };\n\n      //$(el).keypress(67, function(e) {\n      map.on('preclick', function(e) {\n      if (e.originalEvent.ctrlKey) {\n      if (document.querySelector('.lnlt') === null) lnlt = addElement();\n      lnlt.text(\n                      ' lon: ' + (e.latlng.lng).toFixed(5) +\n                      ' | lat: ' + (e.latlng.lat).toFixed(5) +\n                      ' | zoom: ' + map.getZoom() + ' ');\n      var txt = document.querySelector('.lnlt').textContent;\n      console.log(txt);\n      //txt.innerText.focus();\n      //txt.select();\n      setClipboardText('\"' + txt + '\"');\n      }\n      });\n\n      }\n      ).call(this.getMap(), el, x, data);\n}","data":null}]}}</script><!--/html_preserve-->

## Modelado geoestadístico 

Se va a usar el Kriging Ordinario ya que no se necesitó transformar los datos.

### Variograma experimental

A partir de aquí se va a usar **gstat**, donde lo primero es crear un objeto `gstat` donde se definen los datos (en formato espacial) a usar y la variable de interés. Para definir la variable de interés se usa la sintaxis de fórmula de la siguiente forma: `variable ~ 1`, donde se define la fórmula como un objeto (`as.formula`) haciendo uso del objeto `myvar`, donde se guardó el nombre de la variable ('z') a estudiar.

Con el objeto `gstat` se construye el variograma experimental usando la función `variogram`. Esta función tiene como argumentos el objeto `gstat`, el intervalo de distancia deseado (`width`) y la distancia máxima a la cual calcular la semivarianza (`cutoff`). La distancia máxima era 128.03, de ahí que se escoge un valor ligeramente inferior a la mitad. El resultado de `variogram` es un data frame por lo que se puede usar **ggplot2** para crear la Figura \@ref(fig:variog-omni).


```r
myformula = as.formula(paste(myvar,'~1'))
g = gstat(formula = myformula, 
          data = datos_sf) # objeto gstat para hacer geoestadistica

# variograma experimental cada cierta distancia (width), y hasta cierta distancia (cutoff)
dat.vgm = variogram(g, 
                    width = 5,
                    cutoff = 60) 
```


```r
gg.omni.exp = ggplot(dat.vgm,aes(x = dist, y = gamma)) + 
  geom_point(size = 2) + 
  labs(x = x_var, y = y_var) +
  geom_hline(yintercept = S, col = 'red', linetype = 2) +
  ylim(0, max(dat.vgm$gamma)) +
  xlim(0, max(dat.vgm$dist)) + 
  geom_text_repel(aes(label = np), size = 2)
gg.omni.exp
```

<div class="figure" style="text-align: center">
<img src="figures/extra/variog-omni-1.png" alt="Variograma experimental omnidireccional. Las etiquetas de los puntos muestran con el número de pares de puntos usados para el cálculo de la semivarianza. La línea roja punteada corresponde con la varianza de la variable, que es una aproximación a la meseta total." width="90%" />
<p class="caption">(\#fig:variog-omni)Variograma experimental omnidireccional. Las etiquetas de los puntos muestran con el número de pares de puntos usados para el cálculo de la semivarianza. La línea roja punteada corresponde con la varianza de la variable, que es una aproximación a la meseta total.</p>
</div>

Para el mapa de la superficie de variograma de nuevo se usa la función `variogram`, con los argumentos de la extensión (`cutoff`, misma que el variograma experimental), el ancho del pixel (`width`, no es el mismo que para el variograma, por lo general mayor), y definir que se quiere un mapa (`map=TRUE`). De nuevo, como el resultado es un data frame se usa **ggplot2** para visualizar el mapa (Figura \@ref(fig:variog-map)).


```r
map.vgm <- variogram(g, 
                     width = 10, 
                     cutoff = 60, 
                     map = TRUE)
```


```r
gg.map.exp = ggplot(data.frame(map.vgm), aes(x = map.dx, y = map.dy, fill = map.var1)) +
  geom_raster() + 
  scale_fill_gradientn(colours = plasma(20)) +
  labs(x = x_vmap, y = y_vmap, fill = "Semivarianza") +
  coord_equal()
gg.map.exp
```

<div class="figure" style="text-align: center">
<img src="figures/extra/variog-map-1.png" alt="Mapa de la superficie de variograma. No se observa un patrón o tendencia o dirección preferncial." width="90%" />
<p class="caption">(\#fig:variog-map)Mapa de la superficie de variograma. No se observa un patrón o tendencia o dirección preferncial.</p>
</div>

Para los variogramas direccionales, de nuevo con la función `variogram`, hay que definir adicionalmente las direcciones (`alpha`) y la tolerancia angular (`tol.hor`), donde se definen las direcciones en un vector `d`. Lo típico es definir las direcciones en el rango de 0 a 180, ya que para efectos prácticos direcciones mayores a 180 son simplemente el opuesto de direcciones menores a 180 (ejemplo: 210 es el opuesto de 30), por tratarse de un elipse donde lo que interesa es la tendencia general de los ejes mayor y menor. Por lo anterior es que 180 se excluye, ya que es el opuesto de 0.


```r
# con direcciones y tolerancia angular
d = c(0,45,90,135) # direcciones
dat.vgm2 = variogram(g, 
                     alpha = d,
                     tol.hor = 22.5, 
                     cutoff = 60) 
```

Para visualizar de manera apropiada los variogramas direccionales con **ggplot2** (Figura \@ref(fig:variog-dir)) es necesaria una pequeña modificación de los datos, pasando las direcciones (`dir.hor`) de una variable numérica a una categórica por medio de la función `factor`.


```r
dat.vgm2.gg = dat.vgm2 %>% 
  mutate(dir.hor = factor(dir.hor, labels = as.character(d)))
```


```r
gg.dir.exp = ggplot(dat.vgm2.gg,aes(x = dist, y = gamma,
                       col = dir.hor, shape = dir.hor)) + 
  geom_point(size = 2) + 
  labs(x = x_var, y = y_var, col = "Dirección", shape = 'Dirección') +
  geom_hline(yintercept = S, col = 'red', linetype = 2) +
  ylim(0, max(dat.vgm2$gamma)) +
  xlim(0, max(dat.vgm2$dist)) + 
  scale_color_brewer(palette = 'Dark2') +
  facet_wrap(~dir.hor) + 
  geom_text_repel(aes(label = np), size = 2, show.legend = F) +
  theme(legend.position = 'top')
gg.dir.exp
```

<div class="figure" style="text-align: center">
<img src="figures/extra/variog-dir-1.png" alt="Variogramas experimentales direccionales cada 45°. La línea roja punteada representa la varianza de la variable, lo que se aproxima a la meseta total." width="90%" />
<p class="caption">(\#fig:variog-dir)Variogramas experimentales direccionales cada 45°. La línea roja punteada representa la varianza de la variable, lo que se aproxima a la meseta total.</p>
</div>

### Ajuste de modelo de variograma

Para ajustar un modelo de variograma hay que definir valores iniciales de las partes, que se obtienen a partir de un análisis rápido del variograma experimental omnidireccional (Figura \@ref(fig:variog-omni)), y se definen en objetos como se muestra a continuación:


```r
pep = .25 # pepita
meseta = .5 # meseta parcial
mod = "Sph" # modelo a ajustar (esférico)
rango = 30 # rango
```

El paquete **gstat** ya viene con modelos definidos, por lo que el usuario debe seleccionar el modelo que considera apropiado. La Figura \@ref(fig:gstat-mods) muestra los diferentes modelos disponibles (nombre en comillas). Para los modelos mencionados en la parte de teoría los nombres usados por **gstat** serían: 'Sph' para esférico, 'Exp' para exponencial, 'Gau' para gaussiano, y 'Pot' para potencia.


```r
show.vgms()
```

(ref:gstat-mods) Modelos disponibles en **gstat**.

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/gstat-mods.png" alt="(ref:gstat-mods)" width="100%" />
<p class="caption">(\#fig:gstat-mods)(ref:gstat-mods)</p>
</div>

Se usa la función `fit.variogram`, que realiza un ajuste automático, con los argumentos del variograma experimental y el modelo (`model`) que se define por medio de la función `vgm`, usando los valores iniciales definidos arriba.


```r
dat.fit = fit.variogram(dat.vgm, 
                        model = vgm(psill = meseta, 
                                    model = mod, 
                                    range = rango, 
                                    nugget = pep))

fit.rmse = sqrt(attributes(dat.fit)$SSErr/(nrow(datos))) # error del ajuste
fit.rmse
```

```
## [1] 0.01287286
```

Un error de ajuste inicial y optimista se obtiene calculando "manualmente" el $RMSE$, a como se muestra arriba (`fit.rmse`).

El resultado del ajuste es un data frame, mostrado a conitunación:


```r
varmod = dat.fit # modelo ajustado
varmod
```

```
##   model     psill    range
## 1   Nug 0.3363590  0.00000
## 2   Sph 0.5334709 44.83848
```

Para crear el Cuadro \@ref(tab:ajuste-tab) de nuevo se hace uso de la función `kable` con sus respectivos argumentos.


```r
varmod %>% 
  select(1:3) %>% 
  kable(col.names = c('Modelo','Meseta','Rango'),
        # format = 'simple',
        align = 'c',
        digits = 3,
        caption = 'Modelo ajustado al variograma experimental') %>% 
  kable_styling(full_width = F)
```

<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>(\#tab:ajuste-tab)Modelo ajustado al variograma experimental</caption>
 <thead>
  <tr>
   <th style="text-align:center;"> Modelo </th>
   <th style="text-align:center;"> Meseta </th>
   <th style="text-align:center;"> Rango </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> Nug </td>
   <td style="text-align:center;"> 0.336 </td>
   <td style="text-align:center;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> Sph </td>
   <td style="text-align:center;"> 0.533 </td>
   <td style="text-align:center;"> 44.838 </td>
  </tr>
</tbody>
</table>

Con el modelo ajustado se puede visualizar éste sobre el variograma omnidireccional (Figura \@ref(fig:ajuste-1)) y los variogramas direccionales  (Figura \@ref(fig:ajuste-2)), de nuevo usando **ggplot2**. Para estimar la semivarianza en una dirección específica se usa la función `variogramLine`, donde se define el modelo, la distancia máxima hasta la cual calcular la semivarianza (`maxdist`), la distancia mínima (`min`), el número de puntos a calcular (`n`), y la dirección como vector unitario (`dir`). Para simplificar la conversión de la dirección de grados a vector unitario, se creó la función `unit_vector`, que es simplemente una serie de declaraciones condicionales.

El objeto `variog.dir` va a contener la semivarianza ajustada para las direcciones definidas. Este objeto se crea de manera iterativa para cada una de las distancias del vector `d`, haciendo uso de la función `map_dfr` del paquete **purrr**, la cual crea un data frame.


```r
unit_vector = function(th) {
  th = if_else(th>=180, th-180, th)
  uv = case_when(
    th == 0 ~ c(0,1,0),
    th == 90 ~ c(1,0,0),
    th == 180 ~ c(0,-1,0),
    between(th,0,90) ~ c(sin(th*pi/180),cos(th*pi/180),0),
    between(th,90,180) ~ c(cos((th-90)*pi/180),-1*sin((th-90)*pi/180),0)
  )
  return(uv)
}

variog.dir = map_dfr(d, ~variogramLine(object = varmod, 
                                       maxdist = max(dat.vgm$dist),
                                       min = 0.001, n = 100, 
                                       dir = unit_vector(.x)), 
                     .id = 'dir.hor') %>% 
  as_tibble() %>% 
  mutate(dir.hor = factor(dir.hor, labels = as.character(d)))
```


```r
# plot(dat.vgm, dat.fit, xlab = x_var, ylab = y_var) 

# omnidireccional

gg.omni.fit = variog.dir %>% 
  ggplot(aes(dist,gamma)) + 
  geom_point(data = dat.vgm,shape=3,size=2) +
  geom_line(size=1)  +
  labs(x = x_var, y = y_var) +
  coord_cartesian(ylim = c(0,max(dat.vgm$gamma)))
gg.omni.fit
```

<div class="figure" style="text-align: center">
<img src="figures/extra/ajuste-1-1.png" alt="Variograma experimental omnidireccional con el modelo esférico ajustado sobrepuesto." width="90%" />
<p class="caption">(\#fig:ajuste-1)Variograma experimental omnidireccional con el modelo esférico ajustado sobrepuesto.</p>
</div>


```r
# plot(dat.vgm2, dat.fit, as.table = T, xlab = x_var, ylab = y_var) 

# direccionales

gg.dir.fit = variog.dir %>% 
  ggplot(aes(dist,gamma,col=dir.hor)) + 
  geom_point(data = dat.vgm2.gg,shape=3,size=1.5) +
  geom_line(size=1) + 
  scale_color_brewer(palette = 'Dark2') +
  labs(x = x_var, y = y_var, col = 'Dirección') +
  facet_wrap(~dir.hor) +
  theme(legend.position = 'top')
gg.dir.fit
```

<div class="figure" style="text-align: center">
<img src="figures/extra/ajuste-2-1.png" alt="Variogramas experimentales direccionales con el modelo esférico ajustado sobrepuesto, mostrando que el modelo es válido para todas las direcciones." width="90%" />
<p class="caption">(\#fig:ajuste-2)Variogramas experimentales direccionales con el modelo esférico ajustado sobrepuesto, mostrando que el modelo es válido para todas las direcciones.</p>
</div>

### Validación cruzada

La validación cruzada se realiza por medio de la función `krige.cv`, con los argumentos siendo la fórmula, los datos espaciales (`locations`), y el modelo ajustado (`model`), donde por defecto usa el método *LOO*. Si se quisiera usar *K-fold* se puede definir el argumento `nfold = K`, donde `K` es el número de grupos a crear. El objeto resultante (`kcv.ok`) va a contener los valores predichos (`var1.pred`), la varianza de las predicciones (`var1.var`), los valores observados (`observed`), y los residuales (`residual`).


```r
kcv.ok = krige.cv(myformula, 
                  locations = datos_sf, 
                  model = varmod)
```

El siguiente bloque de código muestra cómo se calculan las diferentes métricas, ya sea usando funciones ya disponibles (objetos `xval.mape`,`correl`, usando funciones `MAPE` y `CorCI` del paquete **DescTools** [@R-DescTools]) o escribiendo la fórmula necesaria (objetos `xval.rmse`, `xval.msdr`, `xval.g`). Para el coeficiente de determinación (`xval.r2`) se ajusta un modelo lineal (`lm`) entre los valores predichos y observados, y se extrae esta métrica del objeto resultante.


```r
cl = .95 # nivel de confianza
decimales = 3 # decimales a usar

xval.rmse = sqrt(mean(kcv.ok$residual^2)) # RMSE - menor es mejor

xval.msdr = mean(kcv.ok$residual^2/kcv.ok$var1.var) # MSDR - ~1 es mejor

xval.mod = lm(observed ~ var1.pred, as.data.frame(kcv.ok))

xval.r2 = xval.mod %>% 
  broom::glance() %>% 
  pull(r.squared) # r2 - mayor es mejor

xval.g = 1 - (sum((kcv.ok$var1.pred-kcv.ok$observed)^2)/sum((kcv.ok$observed-mean(kcv.ok$observed))^2)) # G - mayor y positivo es mejor

xval.mape = MAPE(xval.mod) # MAPE - menor es mejor

correl = signif(CorCI(cor(kcv.ok$observed, 
                          kcv.ok$var1.pred), 
                      nrow(kcv.ok)),
                decimales) # r

metricas = tibble(metric = c('$RMSE$','$MSDR$','$r$','$R^2$','$MAPE$','$G$'), 
                  estimate = c(apa(xval.rmse,decimales),
                               apa(xval.msdr,decimales),
                               apa(correl[1],decimales,F),
                               apa(xval.r2,decimales,F),
                               apa(xval.mape,decimales,F),
                               apa(xval.g,decimales,F)))
```

Para dar el formato apropiado a los resultados, según los estándares de APA -@americanpsychologicalassociation2010, se usa la función `apa` del paquete **MOTE** [@R-MOTE], donde se define el valor a formatear, el número de decimales, y si se incluye el '0' al inicio. Datos que no pueden ser superiores a 1 o inferiores a -1 se reportan sin el '0' al inicio, de ahí que $r$, $R^2$, $MAPE$, y $G$ se reportan de esta forma.

Para crear el Cuadro \@ref(tab:xval-metrics-tab) de nuevo se hace uso de la función `kable` con sus respectivos argumentos.


```r
metricas %>% 
  kable(col.names = c('Métrica','Valor'),
        # format = 'simple',
        align = 'c',
        # digits = 3,
        caption = 'Métricas de ajuste para la validación cruzada') %>% 
  kable_styling(full_width = F)
```

<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>(\#tab:xval-metrics-tab)Métricas de ajuste para la validación cruzada</caption>
 <thead>
  <tr>
   <th style="text-align:center;"> Métrica </th>
   <th style="text-align:center;"> Valor </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> $RMSE$ </td>
   <td style="text-align:center;"> 0.747 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> $MSDR$ </td>
   <td style="text-align:center;"> 0.929 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> $r$ </td>
   <td style="text-align:center;"> .492 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> $R^2$ </td>
   <td style="text-align:center;"> .242 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> $MAPE$ </td>
   <td style="text-align:center;"> .019 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> $G$ </td>
   <td style="text-align:center;"> .238 </td>
  </tr>
</tbody>
</table>

Los resultados de la validación cruzada (Figura \@ref(fig:xval-plots)) se pueden visualizar con **ggplot2**, transformando el resultado en un data frame `as.data.frame(kcv.ok)`. 


```r
gg.xval1 = ggplot(as.data.frame(kcv.ok), aes(var1.pred, observed)) + 
  geom_point(col = "blue", shape = 3, size = 1.25) + 
  coord_fixed() + 
  geom_abline(slope = 1, col = "red", size = 1.25) + 
  geom_smooth(se = F, method = 'lm', col = 'green', size = 1.25) +
  labs(x = "Predichos", y = "Observados")
```


```r
gg.xval2 = ggplot(as.data.frame(kcv.ok), aes(residual)) + 
  geom_histogram(aes(y=stat(density)), bins = 8, 
                 col = 'black', fill = "orange") + 
  geom_density(col = 'blue', size=1.25) + 
  labs(x = "Residuales", y = "Densidad") + 
  geom_vline(xintercept = mean(kcv.ok$residual), col = 'red', size=1.25)
```

En este caso se generan los dos gráficos (**A** y **B**) por aparte y se ponen en uno solo usando la sintáxis del paquete **patchwork** [@R-patchwork].


```r
gg.xval = gg.xval1 + gg.xval2 + plot_annotation(tag_levels = 'A')
gg.xval
```

<div class="figure" style="text-align: center">
<img src="figures/extra/xval-plots-1.png" alt="Análisis de los resultados de validación cruzada. **A** Relación entre los valores observados y predichos por la validación cruzada. La línea roja es la línea 1:1 y la línea verde es la regresión entre los datos. **B** Histograma de los residuales de la validación cruzada. La linea roja es la media de los residuales y la curva azul la curva de densidad." width="80%" />
<p class="caption">(\#fig:xval-plots)Análisis de los resultados de validación cruzada. **A** Relación entre los valores observados y predichos por la validación cruzada. La línea roja es la línea 1:1 y la línea verde es la regresión entre los datos. **B** Histograma de los residuales de la validación cruzada. La linea roja es la media de los residuales y la curva azul la curva de densidad.</p>
</div>

## Interpolación (Kriging)

La interpolación por Kriging se realiza con la función `krige`, cuyos argumentos son la fórmula, los datos (`locations`), la grilla a interpolar (`newdata`), y el modelo ajustado seleccionado (`model`).


```r
ok = krige(myformula, 
           locations = datos_sp,
           newdata = datosint2, 
           model = varmod)
```

```
## [using ordinary kriging]
```

El resultado, objeto `stars`, va a contener dos columnas: los valores predichos (estimados) en `var1.pred` y la varianza (error) de la predicción (estimación) en `var1.var`. El argumento más importante para la visualización de los resultados (usando **ggplot2** y la geometría `geom_stars`) es el `aes(fill)` donde se define la columna (resultado) a visualizar (predicción o varianza). 


```r
gg.pred = ggplot() + 
  geom_stars(data = ok, aes(fill = var1.pred, x = x, y = y)) + 
  scale_fill_gradientn(colours = viridis(10), na.value = NA) + 
  coord_sf() + 
  labs(x = x_map, y = y_map, 
       # title = 'Predicción', 
       fill = myvar)
```


```r
gg.var = ggplot() + 
  geom_stars(data = ok, aes(fill = var1.var, x = x, y = y)) + 
  scale_fill_gradientn(colours = brewer.pal(9,'RdPu'), na.value = NA) + 
  coord_sf() + 
  labs(x = x_map, y = y_map, 
       # title = 'Varianza',
       fill = myvar)
```

De manera similar a la validación cruzada, se genera cada mapa por separado y se ponen juntos usando **patchwork**.


```r
gg.kriging = gg.pred + gg.var + plot_annotation(tag_levels = 'A')
gg.kriging
```

<div class="figure" style="text-align: center">
<img src="figures/extra/mapas-kriging-1.png" alt="Mapas de predicción (**A**) y de la varianza/error (**B**) de la variable de interés." width="100%" />
<p class="caption">(\#fig:mapas-kriging)Mapas de predicción (**A**) y de la varianza/error (**B**) de la variable de interés.</p>
</div>

# Referencias




