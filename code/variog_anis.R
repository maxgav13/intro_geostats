
library(gstat)
library(sf)
library(sp)
library(tidyverse)

datos <- data.table::fread("BroomsBarn.txt", data.table = F)
myvar = 'logK'
datos_sf = st_as_sf(datos, coords = 1:2)
datos_sp = as(datos_sf, 'Spatial')
var.f = as.formula(paste(myvar,'~1'))
g = gstat(formula = var.f, data = datos_sp)
plot(variogram(g))

# initial parameters
meseta = 0.013
mod = "Sph"
a = 10 # effective range
rango = ifelse(mod == 'Sph', a, 
               ifelse(mod == 'Exp', a/3, 
                      ifelse(mod == 'Gau', a/sqrt(3))))
pep = 0.005

# combination of major direction and anisotropy ratio
anis_df = expand.grid(dir = seq(0,180,10),
                      r = seq(0.05, 1, .15),
                      n = nrow(datos))

# iteration over anisotropy parameters
pmap_dbl(anis_df, 
         function(dir, r, n) {
           fit.variogram(variogram(g, alpha = dir, tol.hor = 22.5),
                         vgm(meseta, mod, rango, pep, anis = c(dir, r))) %>% 
             attributes(.) %>% 
             pluck(5) %>% 
             '/'(n) %>% 
             sqrt()
           }
         ) %>% 
  tibble::enframe(name = NULL, value = 'RMSE') %>% 
  cbind.data.frame(anis_df, mod) -> ans

# finds "best" anisotropy parameters based on lower RMSE
ans %>% 
  slice(which.min(.$RMSE))

