---
title: "Introducción al análisis geoestadístico de datos en geociencias: teoría y aplicación"
author: 
  - name: "Maximiliano Garnier-Villarreal"
    affiliation: 'Escuela Centroamericana de Geología, Universidad de Costa Rica'
    email: 'maximiliano.garniervillarreal@ucr.ac.cr'
affiliation:
  - id            : "1"
    institution   : "Escuela Centroamericana de Geología, Universidad de Costa Rica"
keywords: ['Geoestadística','Kriging','R','Variograma','Interpolación','Validación cruzada']
abstract: |
  Kriging, el método de interpolación asociado a geoestadística, se ha usado y ha sido propuesto como el mejor método de interpolación, muchas veces sin realmente entender cómo es que se usa adecuadamente y dejando que el software que lo brinda decida cómo implementarlo. Esta aseveración tiene fundamento cuando se procede de la manera correcta, realizando los pasos necesarios durante el análisis y modelado geoestadístico, por lo que es necesario entender cómo aplicar Kriging correctamente para que los resultados obtenidos sean relevantes y confiables. Estos pasos se detallan en este trabajo, abordando la teoría, y mediante un ejemplo se pone en práctica el método usando el software estadístico libre **R**. Adicionalmente, se presenta una aplicación web de libre acceso para quienes no se sientan cómodos usando lenguajes de programación.
# date: "11 March 2021"
lang: es
bibliography: ["bib/all.bib"]
# biblio-style: apalike2
csl: csl/apa6.csl
css: css/style.css
link-citations: true
# documentclass: "apa6"
# classoption: "man"
output:
  bookdown::html_document2:
    toc: true
    toc_depth: 3
    toc_float: true
    theme: cosmo
    number_sections: true
    keep_md: true
    # dev: "pdf"
  bookdown::word_document2:
    reference_docx: 'template_RGAC.docx'
    df_print: kable
    toc: false
    toc_depth: 2
  bookdown::pdf_document2:
    df_print: kable
    number_sections: false
    toc: false
    includes:
      in_header: header.tex
  distill::distill_article:
    toc: true
    toc_depth: 3
    toc_float: true
    df_print: kable
  papaja::apa6_word: default
always_allow_html: true
---



# Introducción {#geostats-intro}

En las ciencias que tienen una fuerte componente espacial (dentro de ellas geología) es común recolectar muestras, describirlas y tener la ubicación de dónde se recolectaron. En muchos casos el muestreo se hace con el fin de caracterizar una variable o proceso en el espacio, con lo que se tiene en mente pasar de puntos a una superficie (mapa). 

Para poder generar estas superficies se pueden emplear diferentes [Métodos de interpolación], donde comúnmente se ha dado a entender que Kriging es el método por excelencia a usar (casi que indiscriminadamente), pero no se ha profundizado en cómo usar el método apropiadamente y cuándo es adecuado o no utilizarlo. 

La facilidad que brindan programas de cómputo comerciales (Surfer, ArcGIS), con sus interfaces "point & click", de implementar éste y otros métodos hace creer al usuario que es simplemente de escoger un método y decirle que lo ejecute, sin guiar al usuario de manera apropiada en el proceso necesario para obtener resultados significativos, confiables, y reproducibles. Cabe mencionar que el procedimiento y los pasos que se van a mostrar acá están disponibles en estos softwares pero no de manera frontal para el usuario.

El objetivo principal de este trabajo es de índole educativo/informativo y corresponde con introducir al lector en qué es la geoestadística y cómo realizar un análisis geoestadístico básico de manera apropiada. La idea es brindar una base y guía de cómo hacer una interpolación de los datos de interés y en español, ya que la mayoría de los textos (libros y artículos) están en inglés, y a veces se enfocan únicamente en los resultados (mapas) y no tanto en el proceso.

Para el procesamiento de los datos y la implementación de la geoestadística se va a utilizar el software estadístico libre multi-plataforma **R** [@R-base] así como diferentes paquetes, que va a permitir el desarrollo de rutinas que se pueden reutilizar para análisis futuros. Adicionalmente se presentará una aplicación web, desarrollada en **R** y de libre acceso, que hace uso de lo expuesto aquí. Se recomienda al lector, si no está familiarizado con **R** o quiere profundizar más en su uso, consultar @garnier-villarreal2020.

# Métodos de interpolación {#geostats-met-interp}

De manera resumida y sin entrar en mucho detalle se mencionan diferentes métodos de interpolación comúnmente usados, para ellos se puede consultar @webster2007. De manera general se tienen: Polígonos de Thiessen, Triangulación, Vecinos naturales (natural neighbours), Inverso de la distancia (inverse distance), Superficies de tendencia (trend surface), Ajuste polinomial (splines), y **Kriging**.

El método de Kriging es lo que más se asocia con la geoestadística, y va a ser el énfasis de lo aquí presentado. El Kriging es considerado como el método más robusto y preciso, de ahí que en inglés es conocido como **blue** que quiere decir **b**est **l**inear **u**nbiased **e**stimator, y se puede traducir como **mejor estimador lineal insesgado** [@isaaks1989; @webster2007].

Una ventaja de Kriging con respecto a otros métodos de interpolación más populares, es que a parte de estimar el valor de la variable de interés, estima además un error de la interpolación, lo que permite tener una idea de la calidad (incertidumbre) de los resultados [@isaaks1989; @webster2007]. El método ha sido utilizado para predecir la intensidad sísmica [@linkimer2008rgac], el nivel de agua subterránea [@varouchakis2012hsj], pérdida de suelo [@wang2003pers], y temperatura del aire [@wang2017rs], entre otras.

# Geoestadística {#geostats-basico}

La geoestadística no es estadística (clásica) aplicada a datos geológicos, es un tipo de estadística que hace uso de la componente espacial de los datos y pretende caracterizar sistemas distribuidos en el espacio los cuales no se conocen por completo [@davis2002; @isaaks1989; @webster2007]. Hay que resaltar que Kriging es un método de interpolación (uno de los usos de la geoestadística) que corresponde con uno de los pasos en el análisis y modelado geoestadístico [@oliver2014c], no hay que confundir o pensar que geoestadística es lo mismo que Kriging, que es un error común.

La geoestadística (Kriging) se ha utilizado más para la interpolación (estimación - Kriging) de variables en el espacio, pero también se puede utilizar para la simulación (Simulación Gaussiana Secuencial) de la variable de interés (otra forma de usar geoestadística que no es Kriging). El resultado de la interpolación es la distribución del valor promedio de la variable (cuál sería el valor más probable de encontrar), la simulación genera una cantidad definida de realizaciones (N) de la variable, que pueden estar condicionadas o no a datos observados, y presentan una distribución más heterogénea que la interpolación [@chiles1999; @goovaerts1997; @pebesma2020; @pyrcz2014; @webster2007]. En este trabajo el enfoque va a ser en el uso más común y sencillo que es la interpolación (estimación) de una variable en el espacio.

La base de lo que se va a exponer corresponde con capítulos de @davis2002, @swan1995, @borradaile2003, y @mckillup2010, y textos más detallados y exclusivos en la materia de @chiles1999, @cressie1993, @goovaerts1997, @isaaks1989, @pyrcz2014, @webster2007, y @wackernagel2003, los cuales corresponden con referencias clásicas y actualizadas. Para la implementación en **R** y más base teórica y práctica se puede consultar @nowosad2019 y @pebesma2020.

A continuación se definen algunos conceptos fundamentales en geoestadística, que forman las bases teórica y práctica para el análisis geoestadístico.

## Correlación espacial

El concepto fundamental en geoestadística y la estadística espacial en general, es que las observaciones son dependientes de la distancia entre ellas, donde hay más similitud (relación) conforme más cercanas estén las observaciones y esa similitud o relación es más débil conforme la distancia incrementa [@chiles1999; @cressie1993; @goovaerts1997; @isaaks1989; @webster2007].

## Semivarianza

Esta es la medida que se usa para determinar la disimilitud (relación) entre observaciones que varían con la distancia, y se representa mediante la Ecuación \@ref(eq:semivarianza), donde $Z(x_i)$ es el valor de la variable en la posición $x_i$, $Z(x_i+h)$ es el valor de la variable a una distancia $h$, $N$ es el número total de puntos (observaciones), y $N(h)$ es el número de pares de puntos que se encuentran a una distancia $h$ específica. **Se recomienda tener más de 30 pares de puntos por cada distancia $h$, y no calcular la semivarianza más allá de la mitad de la máxima distancia entre observaciones** [@chiles1999; @goovaerts1997; @isaaks1989; @webster2007]. 

\begin{equation}
  \gamma(h) = \frac{1}{2N(h)}\sum_{i=1}^{N(h)} [Z(x_i+h)-Z(x_i)]^2
  (\#eq:semivarianza)
\end{equation}

Si los datos se encuentran ordenados en una grilla regular se puede usar la separación entre puntos como las diferentes distancias $h$ (Figura \@ref(fig:semivar) (a) y (b)). Si los datos se encuentran irregularmente espaciados es necesario agruparlos en franjas (Figura \@ref(fig:semivar) (c)), donde se requiere definir una tolerancia de la distancia ($w$, por lo general $h/2$), y una tolerancia angular ($\alpha/2$) [@oliver2014c; @webster2007].

(ref:semivar) Esquema del calculo de la semivarianza para datos regularmente espaciados, donde los datos están completos (a) y donde hay datos faltantes (b); para datos irregularmente espaciados (c). Modificado de @webster2007.

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/F01.png" alt="(ref:semivar)" width="90%" />
<p class="caption">(\#fig:semivar)(ref:semivar)</p>
</div>

## Variograma experimental

Para visualizar la relación (o no) entre la semivarianza y la distancia (relación espacial de la variable) se usa el variograma experimental (Figura \@ref(fig:variograma)). 

El cálculo de la semivarianza y su representación por medio del variograma experimental son los primeros pasos donde el usuario/analista tiene control sobre la construcción y representación de la relación espacial de la variable, y el resultado va a ser el insumo para pasos posteriores. *Como decisiones fundamentales se tienen la escogencia de la distancia máxima y el intervalo de distancias ($h$). Conforme se varíen estos valores va a variar la semivarianza, cualquier ajuste que se le realice, y su posterior uso en la interpolación* [@isaaks1989; @oliver2014c; @webster2007].

(ref:variograma) Ejemplo de variogramas experimentales: **A** Mostrando la relación (dependencia) espacial de la variable, **B** Mostrando la ausencia de relación (dependencia) espacial de la variable.

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/F02.png" alt="(ref:variograma)" width="90%" />
<p class="caption">(\#fig:variograma)(ref:variograma)</p>
</div>

## Modelo de variograma

El variograma experimental es una representación discreta de la relación espacial ya que se cuenta solo con puntos a las distancias definidas. Para poder interpolar valores a diferentes distancias es necesario tener un modelo continuo que se ajuste a los datos. Para ajustar un modelo hay que analizar el variograma experimental y realizar una estimación inicial de las partes o parámetros que lo van a definir [@goovaerts1997; @sarma2009; @webster2007].

### Partes

La partes o parámetros que definen a un modelo de variograma se muestran en la Figura \@ref(fig:modelo-variog), y son [@isaaks1989; @sarma2009; @webster2007]:

(ref:modelo-variog) Modelo de variograma mostrando las partes: meseta, pepita, y rango. Modificado de @webster2007.

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/F03.png" alt="(ref:modelo-variog)" width="90%" />
<p class="caption">(\#fig:modelo-variog)(ref:modelo-variog)</p>
</div>

- Meseta total ($S$, sill en inglés): Valor del variograma o semivarianza cuando la distancia $h$ tiende a infinito (cuando la semivarianza se estabiliza), y por lo general es muy similar al valor de la varianza de la variable de interés.

- Meseta parcial ($C_1$, partial sill en inglés): La diferencia entre la meseta total y la pepita ($C_1 = S - C_0$). Si no hubiera pepita ($C_0=0$), entonces $C_1 = S$.

- Pepita ($C_0$, nugget en inglés): El intercepto, el valor de la semivarianza en el origen, y representa por lo general una discontinuidad del variograma en el origen, que se puede deber a la escala de muestreo o errores de medición.

- Rango ($a$, range en inglés): El límite del área de influencia, es la distancia a partir del cual el variograma se estabiliza y se alcanza la meseta; a partir de esta distancia las observaciones se consideran independientes (sin relación).

### Modelos

Aquí se exponen los principales tipos de modelos que se usan en geociencias [@goovaerts1997; @isaaks1989; @sarma2009; @webster2007]. La Figura \@ref(fig:variog-modelos) muestra la forma de estos diferentes modelos, junto con sus partes.

(ref:variog-modelos) Modelos más usados en geociencias: **A** Potencia, **B** Esférico, **C** Exponencial, **D** Gaussiano. Modificado de @sarma2009.

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/F04.png" alt="(ref:variog-modelos)" width="90%" />
<p class="caption">(\#fig:variog-modelos)(ref:variog-modelos)</p>
</div>

- Potencia

Es más usado cuando el variograma no se estabiliza o alcanza una meseta. Se calcula mediante la Ecuación \@ref(eq:variog-potencia), donde $\alpha$ es la pendiente, $0<\lambda<2$ y controla la concavidad o convexidad del modelo. Un ejemplo se muestra en la Figura \@ref(fig:variog-modelos) A.

\begin{equation}
  \gamma(h) = C_0 + \alpha h^{\lambda}
  (\#eq:variog-potencia)
\end{equation}

(ref:variog-potencia) Modelo de potencia. Tomado de @sarma2009.



- Esférico

Es de los más usados en geociencias, presenta una meseta definida, y se caracteriza por presentar un comportamiento lineal cerca del origen. Se calcula mediante la Ecuación \@ref(eq:variog-esferico), y un ejemplo se muestra en la Figura \@ref(fig:variog-modelos) B.

\begin{equation}
  \gamma(h) = 
  \begin{cases}
  C_0 + C_1 \left[ \frac{3}{2}\left( \frac{h}{a}\right) - \frac{1}{2}\left( \frac{h}{a}\right)^3 \right] & \text{para } h < a\\
  C_0 + C_1 & \text{para } h > a
  \end{cases}
  (\#eq:variog-esferico)
\end{equation}

(ref:variog-esferico) Modelo esférico. Tomado de @sarma2009.



- Exponencial

Este modelo tiene un comportamiento asintótico y no alcanza una meseta tan estable como el esférico, por esto lo que se usa en el modelo como rango es $r=a/3$, o sea, una tercera parte del rango esperado. Se calcula mediante la Ecuación \@ref(eq:variog-exp) y un ejemplo se muestra en la Figura \@ref(fig:variog-modelos) C.

\begin{equation}
  \gamma(h) = C_0 + C_1 \left[ 1 - exp\left(-\frac{h}{r}\right) \right]
  (\#eq:variog-exp)
\end{equation}

(ref:variog-exp) Modelo exponencial. Tomado de @sarma2009.



- Gaussiano

Este modelo es similar al exponencial en que no alcanza una meseta estable sino que tiene un comportamiento asintótico, y otra característica es que tiene un comportamiento suavizado cerca del origen. Como no alcanza una meseta el rango que se usa en el modelo es $r=a/\sqrt{3}$, o sea, el rango esperado entre la raíz de 3. Se calcula mediante la Ecuación \@ref(eq:variog-gaus), y un ejemplo se muestra en la Figura \@ref(fig:variog-modelos) D.

\begin{equation}
  \gamma(h) = C_0 + C_1 \left[ 1 - exp\left(-\frac{h}{r}\right)^2 \right]
  (\#eq:variog-gaus)
\end{equation}

(ref:variog-gaus) Modelo gaussiano. Tomado de @sarma2009.



La Figura \@ref(fig:variog-comparacion) es una comparación de los tres modelos más comunes en geociencias, donde todos corresponden con una estructura que presenta los siguientes parámetros: $C_0=0$, $C_1=30$, y $a=210$. Hay que resaltar que el modelo esférico tiene un comportamiento lineal cerca del origen, el modelo exponencial un comportamiento más creciente (convexo), y el modelo gaussiano un comportamiento suavizado. Adicionalmente, los modelos exponencial y gaussiano no alcanzan la meseta de la estructura, contrario al esférico que sí la alcanza.

(ref:variog-comparacion) Comparación visual de los tres modelos más usados en geociencias, todos representando la misma estructura ($C_0=0$, $C_1=30$, y $a=210$).

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/F05.png" alt="(ref:variog-comparacion)" width="90%" />
<p class="caption">(\#fig:variog-comparacion)(ref:variog-comparacion)</p>
</div>

## Anisotropía

La variable y su relación en el espacio puede no solo depender de la distancia sino también de la dirección en que se estima. Si hay una dependencia (comportamiento diferenciado) de la dirección se dice que existe una anisotropía y sino el comportamiento es isotrópico u omnidireccional. La anisotropía se representa como una elipse, donde el eje mayor va a alinearse con la dirección de mayor continuidad espacial y el eje menor con la dirección de menor continuidad espacial (perpendicular al eje mayor) [@chiles1999; @goovaerts1997; @isaaks1989; @oliver2014c; @webster2007]. Lo acostumbrado es escoger direcciones en el rango de 0 a 180, ya que al tratarse de un elipse las direcciones mayores a 180 son simplemente el opuesto de direcciones menores a 180 (ejemplo: 220 es el opuesto de 40).

La anisotropía puede ser de dos tipos: *geométrica* o *zonal.* La geométrica es la más común y la más fácil de modelar. En la anisotropía geométrica se tiene, para las diferentes direcciones, la misma meseta pero diferente rango. En la anisotropía zonal se tiene el mismo rango pero mesetas diferentes [@chiles1999; @goovaerts1997; @isaaks1989; @webster2007].

Para determinar la presencia o no de anisotropía se pueden usar el mapa de la superficie de variograma (Figura \@ref(fig:variog-anis) **A**) y/o variogramas direccionales (Figura \@ref(fig:variog-anis) **B**). La *anisotropía geométrica* va a presentar una dirección principal (eje mayor) que va a estar orientada en la dirección que presenta el mayor rango (mayor continuidad espacial), y una dirección menor (eje menor) orientada perpendicularmente a la principal [@chiles1999; @goovaerts1997; @isaaks1989; @webster2007]. 

En la Figura \@ref(fig:variog-anis) la dirección principal coincide con los 35° y la menor con los 125°. En los diferentes softwares por lo general se expresa la anisotropía como una razón y va a depender del software cuál va en el numerador y cuál en el denominador. En el caso del paquete **gstat** la razón de anisotropía va a tener en el numerador la dirección menor y en el denominador la dirección mayor, por lo que la razón va a tener un rango de 0 a 1, donde mientras más cercano a 0 el valor mayor va a ser la anisotropía.

(ref:variog-anis) **A** Ejemplo de mapa de la superficie de variograma, mostrando anisotropía donde el eje principal ocurre en la dirección 35° y el eje menor ocurre en la dirección 125°. **B** Variogramas direccionales donde se observa como en la dirección de 35 se alcanza un rango mayor ($\sim 25^\circ$), mientras que en la dirección perpendicular (125°) el rango es menor ($\sim 15^\circ$)

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/variog-anis.png" alt="(ref:variog-anis)" width="80%" />
<p class="caption">(\#fig:variog-anis)(ref:variog-anis)</p>
</div>

## Validación cruzada

Dado que que objetivo de la interpolación es predecir valores en puntos donde no se tiene información, la mejor forma de evaluar el ajuste de un modelo específico sobre el variograma experimental es por medio de la validación cruzada. De manera general lo que se hace es dejar por fuera una o varias de las observaciones, se re-ajusta el modelo seleccionado, y se predice el valor de la variable para esas observaciones que se dejaron por fuera, repitiendose el proceso hasta tener una predicción para todos los puntos [@chiles1999; @goovaerts1997; @isaaks1989; @oliver2014c; @webster2007; @hastie2008; @james2013; @kuhn2013; @witten2011]. 

El tipo de validación cruzada más usado es *LOO* (leave-one-out), donde se deja por fuera una observación a la vez, se re-ajusta el modelo y se predice el valor de la variable para cada observación por separado [@goovaerts1997; @isaaks1989; @oliver2014c; @webster2007]. El paquete **gstat** ofrece esta opción (por defecto) y la opción de *K-Fold*. En *K-Fold* se escoge una cantidad de grupos (*K*) en los que se dividen las observaciones (típicamente 5 o 10) y se deja un grupo de observaciones por fuera cada vez, se re-ajusta el modelo, se predice el valor de la variable para todas las observaciones del grupo que se dejó por fuera, y este proceso se repite *K* veces hasta tener predicciones para todos los puntos [@hastie2008; @james2013; @kuhn2013; @witten2011].

Una vez realizado el ajuste y la validación cruzada del modelo se obtienen valores predichos y observados para cada punto. Con esta información se pueden usar diferentes métricas, donde lo ideal sería comparar cada una de estas métricas para diferentes modelos ajustados, y se escogería el modelo que obtenga mejores métricas [@chiles1999; @goovaerts1997; @isaaks1989; @oliver2014c; @webster2007].

Dentro de las métrica más usadas están [@oliver2014c; @webster2007; @yao2013po]: 

En estas métricas $N$ es el total de observaciones (puntos), $Y_i$ es el valor observado en el punto $i$, $\hat{Y_i}$ es el valor predicho en el punto $i$, $s^2_{ei}$ es el error/varianza de la predicción, y $\bar{Y}$ es la media (promedio) de la variable.

- Error medio ($ME$): El error corresponde con los residuales de lo observado menos lo predicho, una vez se tienen estos valores se les calcula la media e idealmente se esperaría obtener un valor cercano a 0. Se calcula mediante la Ecuación \@ref(eq:xval-me) y al comparar modelos se escogería el modelo que presente un valor más cercano a 0.

\begin{equation}
  ME = \frac{1}{N} \sum_{i=1}^{N} (Y_i-\hat{Y_i})
  (\#eq:xval-me)
\end{equation}

- Error cuadrático medio ($RMSE$): Este valor corresponde con la desviación promedio de los errores al cuadrado. Se encuentra en la escala de la variable e idealmente se prefieren valores pequeños. Se calcula mediante la Ecuación \@ref(eq:xval-rmse) y comparando modelos se escogería el modelo que presente un $RMSE$ menor.

\begin{equation}
  RMSE = \sqrt{\frac{1}{N} \sum_{i=1}^{N} (Y_i-\hat{Y_i})^2}
  (\#eq:xval-rmse)
\end{equation}

- Razón de desviación cuadrática media ($MSDR$): Esta valor compara la diferencia entre la predicción y valor actual con respecto a la varianza (error) obtenida de la interpolación ($s^2_{ei}$). Se esperaría que este valor ande cerca de 1. Se calcula mediante la Ecuación \@ref(eq:xval-msdr) y comparando modelos se escogería el que presente un $MSDR$ más cercano a 1.

\begin{equation}
  MSDR = \frac{1}{N} \sum_{i=1}^{N} \frac{(Y_i-\hat{Y_i}^2)}{s^2_{ei}}
  (\#eq:xval-msdr)
\end{equation}

- Error Porcentual Absoluto Medio ($MAPE$): Es una medida porcentual de la diferencia entre lo observado y lo predicho, con un rango de 0 a 1 o de 0 a 100 si se multiplica por 100. Se esperaría que este valor ande cerca de 0 o lo más bajo posible. Se calcula mediante la Ecuación \@ref(eq:xval-mape) y comparando modelos se escogería el que presente el $MAPE$ más bajo.

\begin{equation}
  MAPE = \frac{1}{N} \sum_{i=1}^{N} \Big| \frac{(Y_i-\hat{Y_i})}{Y_i} \Big|
  (\#eq:xval-mape)
\end{equation}

- Estadístico de bondad de predicción ($G$): Este estadístico mide qué tan efectiva es la predicción a si se hubiera usado simplemente la media (promedio) de la variable. Valores de 1 indican una predicción perfecta, valores positivos indican que el modelo es más efectivo que usar la media, valores negativos indican que el modelo es menos efectivo que usar la media, y un valor de cero indica que sería mejor usar la media. Se calcula mediante la Ecuación \@ref(eq:xval-g) y comparando modelos se escogería el que presente el $G$ más cercano a 1 o más positivo.

\begin{equation}
  G = 1 -  \bigg[ \frac{\sum_{i=1}^{N}(Y_i-\hat{Y_i})^2}{\sum_{i=1}^{N}(Y_i-\bar{Y})^2} \bigg]
  (\#eq:xval-g)
\end{equation}

Todas estas métricas, excepto la $MSDR$, se pueden aplicar para cualquier modelo de cualquier método de interpolación. Para la $MSDR$ se ocupa que el método brinde un error (varianza) de la predicción y ésta es una de las fortalezas de Kriging sobre la mayoría de métodos. Como recomendación, al comparar modelos si hay valores muy similares de la mayoría de las métricas se recomienda usar las métricas de $MSDR$ y el estadístico $G$ como las más importantes.

## Kriging

Kriging es un método de interpolación (estimación), por lo que la idea es obtener valores de la variable en lugares donde no se pudo medir. El método hace uso del modelo ajustado para asignar pesos a los puntos a interpolar dependiendo de la distancia entre ellos. Los puntos más cercanos van a presentar valores menores de semivarianza (mayor peso) y los puntos más lejanos valores mayores de semivarianza (menor peso), y si hay puntos que caen fuera del rango estos van a tener una influencia mínima o nula [@chiles1999; @goovaerts1997; @isaaks1989; @webster2007]. Lo anterior se presenta de manera gráfica en la Figura \@ref(fig:kriging-pesos).

(ref:kriging-pesos) Visualización del proceso de interpolación mediante Kriging, donde para el punto a interpolar (D), el punto que está más cercano (C) tiene más peso (influencia, baja semivarianza), y el punto más lejano (A) prácticamente no tiene peso ya que cae fuera del rango. Tomado de @mckillup2010.

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/kriging-pesos.png" alt="(ref:kriging-pesos)" width="90%" />
<p class="caption">(\#fig:kriging-pesos)(ref:kriging-pesos)</p>
</div>

Dentro de las ventajas del Kriging están que compensa por efectos de agrupamiento (clustering) al dar menos peso individual a puntos dentro del agrupamiento que a puntos aislados, y da una estimación de la variable y del error (varianza de Kriging) [@chiles1999; @goovaerts1997; @isaaks1989; @trauth2015; @webster2007]. El resultado de la interpolación por medio Kriging, por lo general, suaviza los resultados, y sobre-estima valores pequeños y sub-estima valores grandes [@oliver2014c; @webster2007].

Kriging es un método general con diferentes variantes dependiendo de la información que se tenga, el tipo de variable, y la cantidad y tipos de variables a considerar. A manera más general también puede incorporar información temporal, por lo que se puede determinar y modelar la variación espacio-temporal de la variable o variables. **Es más recomendado usar Kriging cuando los datos están normalmente distribuidos, se tiene una buena cantidad de observaciones (depende pero 30, 40 o más es lo recomendado), son estacionarios (la media y varianza de la variable no varían significativamente, esto puede subsanarse con diferentes variantes), y hay una dependencia espacial de la variable (variograma muestra un incremento de la semivarianza con la distancia)** [@chiles1999; @goovaerts1997; @isaaks1989; @webster2007]. 

Los tipos de Kriging más comunes son [@chiles1999; @goovaerts1997; @isaaks1989; @webster2007]:

- *Simple ($SK$)*: Para esta variante se asume que se conoce la media de la variable (lo cual no es necesariamente cierto), y que la media es constante. En general no es práctico de usar.
- *Ordinario ($OK$)*: Esta variante es la más usada, donde se asume una media constante pero desconocida, y adicionalmente los datos no deben presentar una tendencia.
- *Lognormal ($OK_{log}$)*: Esta variante se usa cuando la variable tienen una fuerte asimetría positiva, donde se aplica el logaritmo a los datos, y sobre estos datos log-transformados se aplica el Kriging Ordinario; lo más común es usar el logaritmo natural. **Para obtener el resultado de la interpolación en la escala original de la variable NO es tan simple como exponenciar los resultados. @cressie1993, @webster2007, @laurent1963jasa, y @yamamoto2007cg brindan más detalles de cómo realizar la transformación inversa de la manera más apropiada.**
- *Universal ($UK$)*: Esta variante aplica cuando la media no es constante y no se conoce; se le conoce también como *Kriging con tendencia (Kriging in the presence of a trend)*. Esta es una forma de trabajar cuando los datos presentan una tendencia (típicamente en función de las coordenadas), como es el caso típico de niveles piezométricos. @lark2006ejss brinda más detalles y técnicas más actualizadas de como lidiar con este tipo de situación.
- *CoKriging  ($CK$)*: Esta variante se usa cuando se quiere utilizar la información de 2 o más variables, y corresponde con la versión multivariable de Kriging. Es necesario que haya una relación entre las variables y su relación espacial, lo que se conoce como co-regionalización.
- *Indicador ($IK$)*: Esta variante se usa cuando la variable es cualitativa (categórica) o se transforma una variable cuantitativa en cualitativa para determinar si la variable excede o no un umbral. El resultado es la probabilidad condicional de cada una de las categorías (niveles) de la variable.

@eldeiry2010jide, @kravchenko1999a, @meng2013cagis, @wang2017rs, y @yao2013po hacen uso de varios de los tipos de Kriging, así como de otros métodos de interpolación, describiendo brevemente los métodos y comparando los resultados entre ellos.

# Análisis geoestadístico {#geostats-analisis}

Una vez presentada la teoría básica de la geoestadística se va a proceder a realizar un análisis geoestadístico típico (con el objetivo de estimar la variable en el espacio). Los datos corresponden con la temperatura promedio de los últimos 10 años para el 8 de Marzo para la provincia de San José. Los datos fueron tomados de @meteomatics2021, de donde se pueden obtener diferentes parámetros meteorológicos/climáticos a nivel mundial.

Se va a hacer uso de **R** que permite manipular y analizar datos (espaciales y no espaciales), y además tiene diversos paquetes (librerías) para realizar análisis geoestadísticos [@finley2015jss; @jing2015jss; @ribeiro2003p3iwdsc; @R-gstat; @gstat2004; @gstat2016]. El código usado, así como su explicación, se pueden encontrar en el material extra disponible en el repositorio de GitHub del trabajo: https://github.com/maxgav13/intro_geostats.



## Análisis Exploratorio de Datos

Antes de iniciar con el análisis geoestadístico es necesario estudiar la variable, ver su distribución (si se aproxima a una distribución normal) para determinar si es necesaria alguna transformación, y por medio de la varianza se puede tener una idea aproximada de la meseta total del variograma.

(ref:AED) Histograma de la variable. La línea roja corresponde con la media, y la curva azul con la curva de densidad empírica.

<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<caption>(\#tab:AED)Resumen estadístico de los datos.</caption>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:center;"> N </th>
   <th style="text-align:center;"> Media </th>
   <th style="text-align:center;"> Desv. Est. </th>
   <th style="text-align:center;"> Min </th>
   <th style="text-align:center;"> Mediana </th>
   <th style="text-align:center;"> Max </th>
   <th style="text-align:center;"> MAD </th>
   <th style="text-align:center;"> CV </th>
   <th style="text-align:center;"> Asimetría </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> TempC </td>
   <td style="text-align:center;"> 178 </td>
   <td style="text-align:center;"> 16,96 </td>
   <td style="text-align:center;"> 4,39 </td>
   <td style="text-align:center;"> 2,9 </td>
   <td style="text-align:center;"> 14,1 </td>
   <td style="text-align:center;"> 20,1 </td>
   <td style="text-align:center;"> 4,23 </td>
   <td style="text-align:center;"> 5,95 </td>
   <td style="text-align:center;"> -0,73 </td>
  </tr>
</tbody>
</table>

<div class="figure" style="text-align: center">
<img src="figures/AED-1.png" alt="(ref:AED)" width="90%" />
<p class="caption">(\#fig:AED)(ref:AED)</p>
</div>

El resumen estadístico (Cuadro \@ref(tab:AED)) y el histograma (Figura \@ref(fig:AED)) de la variable muestran que tiene una distribución aproximadamente normal, donde la media y mediana son similares y el histograma presenta una forma general de campana con una asimetría inferior a 1, por lo que no es necesaria ninguna transformación. La varianza de la variable es 19,258, lo que brinda una aproximación de la meseta total del variograma.

En este caso los datos tienen coordenadas geográficas pero de manera general se recomienda trabajar los datos en sistemas de coordenadas planas (x,y) por lo que se se recomienda convertirlas a planas conforme la zona de estudio, utilizando los códigos *epsg* respectivos. En este caso el código que corresponde es el *5367* para el sistema de coordendadas *CRTM05*. Para más información al respecto se puede consultar @garnier-villarreal2020, donde el capítulo 6 está dedicado al trato de datos espaciales en **R**.





Es buena práctica determinar las distancias entre los puntos, ya que como se explicó en la parte teórica, no es recomendado calcular el variograma experimental a más de la mitad de la distancia máxima entre puntos. Haciendo este paso se obtiene que la distancia máxima es de 142,00 km. Dada la zona de estudio tan grande se van a presenta las distancias en kilómetros para mayor facilidad y legibilidad, pero hay que tener en cuenta que los datos se encuentran en metros.





Un paso inicial antes de empezar con el análisis es visualizar la distribución de la variable en el espacio, para tener una idea preliminar de patrones que pueden presentar. La Figura \@ref(fig:dist-espacial) muestra la ubicación de los datos, donde los puntos se encuentran rellenados de acuerdo al valor de la variable.

(ref:dist-espacial) Mapa de puntos mostrando la distribución espacial de la variable.

<div class="figure" style="text-align: center">
<img src="figures/dist-espacial-1.png" alt="(ref:dist-espacial)" width="90%" />
<p class="caption">(\#fig:dist-espacial)(ref:dist-espacial)</p>
</div>

## Modelado geoestadístico 

Habiendo estudiado la variable y hecho los pasos iniciales de manipulación, análisis y visualización se procede con el modelado geoestadístico, mostrando y explicando los distintos pasos. En este caso como la variable no requirió de ninguna transformación se va a usar el Kriging Ordinario.

### Variograma experimental

El primer paso es crear un variograma experimental omnidireccional (Figura \@ref(fig:variog-omni)). Se va a hacer uso del paquete **gstat** [@R-gstat; @gstat2004; @gstat2016] para la geoestadística. En la construcción del variograma expermiental se deben definir los argumentos de el intervalo de distancia deseado ($h$), y la distancia máxima a la cual calcular la semivarianza. Si recordamos la distancia máxima era 142,00 km, por lo que se escoge un valor ligeramente inferior a la mitad (70 km) para la distancia máxima y un valor de 4 km para el intervalo de distancias $h$. Es en este paso donde el usuario puede probar diferentes valores para obtener un variograma representativo, que muestre una estructura de dependencia espacial y que los puntos del variograma se hayan calculado con suficientes datos (recomendable 20 o más).



(ref:variog-omni) Variograma experimental omnidireccional. Las etiquetas de los puntos muestran con el número de pares de puntos usados para el cálculo de la semivarianza. La línea roja punteada corresponde con la varianza de la variable, que es una aproximación a la meseta total.

<div class="figure" style="text-align: center">
<img src="figures/variog-omni-1.png" alt="(ref:variog-omni)" width="90%" />
<p class="caption">(\#fig:variog-omni)(ref:variog-omni)</p>
</div>

Una vez analizado el variograma omnidireccional se procede a determinar si existe la presencia o no de anisotropía. Para esto se usan tanto el mapa de la superficie de variograma (Figura \@ref(fig:variog-map)), como los variogramas direccionales (Figura \@ref(fig:variog-dir)).



(ref:variog-map) Mapa de la superficie de variograma. Se observa una dirección preferencial a aproximadamente 135°.

<div class="figure" style="text-align: center">
<img src="figures/variog-map-1.png" alt="(ref:variog-map)" width="90%" />
<p class="caption">(\#fig:variog-map)(ref:variog-map)</p>
</div>

Para los variogramas direccionales hay que definir, adicionalmente, los argumentos de las direcciones y la tolerancia angular, donde lo más usado son direcciones cada 45° y la tolerancia angular es la mitad del intervalo entre direcciones (22,5°). De nuevo, solo es necesario definir direcciones entre 0 y 180, y 180 se excluye por ser el opuesto de 0.





(ref:variog-dir) Variogramas experimentales direccionales cada 45°. La línea roja punteada representa la varianza de la variable, lo que se aproxima a la meseta total. Se observa un mayor rango en la dirección 135° y un menor rango en la dirección 45°.

<div class="figure" style="text-align: center">
<img src="figures/variog-dir-1.png" alt="(ref:variog-dir)" width="100%" />
<p class="caption">(\#fig:variog-dir)(ref:variog-dir)</p>
</div>

Analizando el mapa y los variogramas direccionales se concluye que hay una anisotropía con dirección principal de 135° y un rango aproximado de 50 km, y un rango aproximado de 25 km en la dirección de 45°, resultando en una razón de anisotropía de 0,5. Por lo anterior el modelado se realizará con los variogramas direccionales.

### Ajuste de modelo de variograma

Una vez creado el variograma experimental es necesario ajustarle un modelo para poder obtener valores a distancias no muestreadas. Antes de ajustar un modelo al variograma experimental es necesario estimar las partes del mismo (meseta, pepita, rango, anisotropía) y determinar valores iniciales, para posteriormente realizar el ajuste.

Usando los variogramas direccionales (Figura \@ref(fig:variog-dir)), se puede estimar una pepita de aproximadamente 0, una meseta parcial de 25, un rango de 50000, una anisotropía a 135° con una razón de 0,5, y se puede usar un modelo tipo esférico ('Sph'). 





El modelo ajustado (Cuadro \@ref(tab:ajuste-tab)) se puede usar para calcular un error del ajuste inicial ($RMSE_{ajuste}=4e-04$), pero es más confiable el que se obtiene usando la validación cruzada, ya que el obtenido acá es un valor optimista. Lo anterior se da puesto que se calcula con respecto a los datos que se utilizaron para el ajuste (toda la información disponible) y esto simpre va a resultar en error menor que cuando se usa el modelo en datos no observados [@hastie2008; @james2013; @kuhn2013; @witten2011], que es el objetivo de la interpolación.




Table: (\#tab:ajuste-tab)Modelo ajustado

 Modelo    Meseta     Rango      Razón    Dirección Principal 
--------  --------  ----------  -------  ---------------------
  Nug       0,00       0,00       0,0              0          
  Sph      23,99     84672,58     0,5             135         

El modelo ajustado de la Cuadro \@ref(tab:ajuste-tab) se puede interpretar así: el efecto pepita ('Nug') (que como es el intercepto solo aporta información a la semivarianza y no al rango) aporta 0,000 a la semivarianza ($C_0=0,000$); el modelo esférico ('Sph') aporta 23,990 a la semivarianza ($C_1=23,990$), con lo que la meseta tota es $S=C_0+C_1=23,990$, y el rango mayor del modelo esférico es $a=84672,58$ en una dirección 135°, con una razón de anisotropía de 0,5.

Con el modelo ajustado se puede visualizar éste sobre el variograma omnidireccional (Figura \@ref(fig:ajuste-1)) y los variogramas direccionales  (Figura \@ref(fig:ajuste-2)). En general, para todos los casos se observa que el modelo ajustado es válido y representativo para todos los casos.





(ref:ajuste-1) Variograma experimental omnidireccional con el modelo esférico ajustado sobrepuesto.

<div class="figure" style="text-align: center">
<img src="figures/ajuste-1-1.png" alt="(ref:ajuste-1)" width="90%" />
<p class="caption">(\#fig:ajuste-1)(ref:ajuste-1)</p>
</div>

(ref:ajuste-2) Variogramas experimentales direccionales con el modelo esférico ajustado sobrepuesto, mostrando que el modelo es válido.

<div class="figure" style="text-align: center">
<img src="figures/ajuste-2-1.png" alt="(ref:ajuste-2)" width="100%" />
<p class="caption">(\#fig:ajuste-2)(ref:ajuste-2)</p>
</div>

### Validación cruzada

Para evaluar de manera más realista el ajuste de cualquier modelo es mejor usar la validación cruzada. Es en este paso que se podrían probar diferentes modelos, donde se obtienen las métricas de ajuste de un modelo, se ajusta un nuevo modelo y se obtienen sus métricas de ajuste, y así iterativamente. Una vez ajustados diferentes modelos y con sus diferentes métricas, se puede tener un criterio más robusto de cuál modelo se ajusta mejor a los datos. 

Las métricas usadas aquí son las que se introdujeron anteriormente: el error cuadrático medio ($RMSE$), la razón de desviación cuadrática media ($MSDR$), el error porcentual absoluto medio ($MAPE$), y el estadístico de bondad de predicción ($G$). Adicionalmente se estima la correlación ($r$) entre los valores observados y predichos, donde lo que se busca es determinar qué tan similares son los valores entre si (Figura \@ref(fig:xval-plots) **A**).






Table: (\#tab:xval-metrics-tab)Métricas de ajuste para la validación cruzada

 Métrica    Valor 
---------  -------
 $RMSE$     1,475 
 $MSDR$     0,758 
   $r$      .942  
  $R^2$     .887  
 $MAPE$     .085  
   $G$      .886  

Como se mencionó arriba las métricas son más útiles cuando se comparan modelos, pero para este caso, usando solo el modelo esférico, se puede decir que presentan valores aceptables (Cuadro \@ref(tab:xval-metrics-tab)): la $MSDR$ está cerca de 1, la correlación ($r$) es alta, el $RMSE$ es menor a la desviación estándar de los datos (4,388), el $MAPE$ es bajo y cercano a 0, y el estadístico $G$ es positivo y cercano a 1. Conforme APA -@americanpsychologicalassociation2010, valores que no pueden por definición ser superiores a 1 o inferiores a -1 ($r$, $R^2$, $MAPE$, y $G$) se reportan sin el '0' inicial.

Si recordamos el error del ajuste inicial sobre los datos que se realizó el ajuste fue $RMSE_{ajuste}=4e-04$, que como se puede observar es mucho menor al error de la validación cruzada $RMSE_{xval}=1,475$, de ahí que se le definiera como optimista, y sea el error de la validación cruzada un mejor indicador de la capacidad predictiva del modelo seleccionado.





(ref:xval-plots) Análisis de los resultados de validación cruzada. **A** Relación entre los valores observados y predichos por la validación cruzada. La línea roja es la línea 1:1 y la línea verde es la regresión entre los datos. **B** Histograma de los residuales de la validación cruzada. La línea roja es la media de los residuales y la curva azul la curva de densidad.

<div class="figure" style="text-align: center">
<img src="figures/xval-plots-1.png" alt="(ref:xval-plots)" width="80%" />
<p class="caption">(\#fig:xval-plots)(ref:xval-plots)</p>
</div>

Adicionalmente se pueden explorar los residuales ya que idealmente se esperaría que presenten una distribución normal. Lo anterior se puede apreciar en la Figura \@ref(fig:xval-plots) **B**, donde el histograma es aproximadamente normal, y no presenta una asimetría importante (menor a 1: -0,304) y se encuentra centrado alrededor de 0.

Las métricas tanto como los residuales indican que el modelo ajustado es un modelo apropiado para proceder con la interpolación.

## Interpolación (Kriging)

Para recalcar nuevamente, el análisis geoestadístico es un proceso que conlleva el calculo del variograma, el ajuste de un modelo, la validación del modelo a usar, y por último la interpolación mediante Kriging. Si no se realizan con cuidado los pasos el resultado de la interpolación puede no tener validez o sentido.



Los mapas finales tanto de la predicción (estimación) como de la varianza (error de estimación) se presentan en la Figura \@ref(fig:mapas-kriging). En el mapa de la predicción se observa una tendencia de valores altos hacia al SW del área y de valores bajos hacia el NE. El mapa de la varianza va a presentar los valores más bajos en los puntos de muestreo y valores mayores en puntos más distantes de los muestreados, que es un comportamiento típico de Kriging.





(ref:mapas-kriging) Mapas de predicción (**A**) y de la varianza/error (**B**) de la temperatura para la provincia de San José, para la fecha del 8 de Marzo.

<div class="figure" style="text-align: center">
<img src="figures/mapas-kriging-1.png" alt="(ref:mapas-kriging)" width="100%" />
<p class="caption">(\#fig:mapas-kriging)(ref:mapas-kriging)</p>
</div>

# Aplicación web

Lo demostrado acá se encuentra implementado en una aplicación web [@garnier-villarreal2019c], la cual puede ser usada accediendo a la siguiente dirección https://maximiliano-01.shinyapps.io/geostatistics/. La idea de la aplicación es llevar de la mano al usuario por los mismos pasos presentados acá, usando una interfaz más familiar, sin necesidad de que sepa usar **R** o lenguajes de programación, pero sí es necesario que se entienda y tenga conciencia de lo que conlleva un análisis geoestadístico de principio a fin. 

La aplicación puede leer (cargar) archivos '.txt' o '.csv', donde el archivo tiene que contener por lo menos tres columnas: coordenada-x, coordenada-y, variable de interés. La Figura \@ref(fig:webapp) muestra la interfaz de la aplicación.

(ref:webapp) Interfaz de la aplicación web para realizar análisis geoestadístico. El rectángulo amarillo encierra las viñetas (pasos) a seguir durante el análisis, incluyendo además la viñeta para desplegar los datos y la de información adicional de la aplicación.

<div class="figure" style="text-align: center">
<img src="/Users/maximiliano/Documents/UCR/Docencia/Extras/R/bookdown/intro_geostats/images/geostats-webapp.png" alt="(ref:webapp)" width="100%" />
<p class="caption">(\#fig:webapp)(ref:webapp)</p>
</div>

# Conclusiones

Kriging es un método de interpolación, de varios disponibles, para obtener predicciones (estimaciones) en puntos donde no se tienen observaciones, y adicionalmente presenta diferentes variantes, por lo que no es único y depende del objetivo de investigación el cómo se implementa. Cuando es posible y adecuado usarlo, típicamente, brinda los mejores resultados, además de proporcionar un error sobre los valores estimados.

Kriging como tal es uno de los posibles usos de la geoestadística, ya que es un paso (el último típicamente) durante un análisis geoestadístico donde el objetivo es la predicción (estimación) de una o varias variables en el espacio. Se menciona, brevemente, que otro posible producto de la geoestadística es la simulación, la cual puede ser más representativa en casos donde la heterogeneidad, y no el comportamiento promedio, de la variable es el interés principal.

La geoestadística, como rama de la estadística espacial, se enfoca en la caracterización de procesos y variables que tienen una fuerte componente espacial, por lo que existe una dependencia entre las observaciones, a diferencia de la estadística clásica. 

Este trabajo muestra los pasos, cuidados, y decisiones que hay que tomar durante un análisis geoestadístico típico, haciendo énfasis en que para obtener resultados válidos y confiables es necesario desarrollar estos pasos con criterio y no dejarlos a decisión de un programa de cómputo. Se recomienda que cuando se hace uso de Kriging se detalle el tipo, así como el modelo que se ajustó y sus parámetros. 

**R** es un lenguaje de programación muy flexible que permite crear rutinas para reusar posteriormente en análisis futuros similares. El material de este trabajo se encuentra disponible en un repositorio en GitHub (https://github.com/maxgav13/intro_geostats), que puede ser descargado para su uso. En el repositorio se puede consultar un material extra que presenta y detalla el código usado durante el análisis geoestadístico. Además se presenta de manera muy rápida una aplicación web que hace uso del mismo código, pero de una manera más amigable para quienes no se siente cómodos con lenguajes de programación.

# Referencias





