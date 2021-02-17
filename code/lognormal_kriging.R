
# paquetes -----
library(gstat)
library(sp)
library(sf)
library(stars)
library(ggspatial)
library(raster)
library(viridis)
library(rgeos)
library(DescTools)
library(mapview)

# load data and grid
data("meuse")
coordinates(meuse) = ~x+y
data("meuse.grid")
coordinates(meuse.grid) = ~x+y
gridded(meuse.grid) = TRUE

# plot data
ggplot() + 
  layer_spatial(meuse,aes(col=zinc)) + 
  scale_colour_viridis_c() + 
  theme_void()

# variogram
variog = variogram(log(zinc)~1,meuse)
plot(variog)

# model
c0 = 0; c1 = .6; a = 1000
mod = vgm(psill = c1, model = 'Sph', range = a, nugget = c0)
plot(variog, mod)

mod.fit = fit.variogram(variog, mod)
mod.fit
plot(variog, mod.fit)

# kriging
ok.log = krige(formula = log(zinc)~1, locations = meuse,
               newdata = meuse.grid, model = mod.fit)
ok = krigeTg(formula = zinc~1, locations = meuse,
             newdata = meuse.grid, model = mod.fit, lambda = 0)

# backtransformation
ok.log$var1BT.pred = exp(ok.log$var1.pred + ok.log$var1.var/2)
ok.log$var1BT.var = (exp(ok.log$var1.var) - 1) * exp(2 * ok.log$var1.pred + ok.log$var1.var)

# summary
summary(ok$var1TG.pred)
summary(meuse$zinc)
summary(ok.log$var1BT.pred)

# stacked predictions
preds = utils::stack(list(Original = meuse$zinc,
                          BT = ok.log$var1BT.pred,
                          TG = ok$var1TG.pred))

varis = utils::stack(list(BT = ok.log$var1BT.var,
                          TG = ok$var1TG.var))

# comparison plot
ggplot(preds, aes(values, fill=ind)) + 
  geom_density(alpha=.5) + 
  facet_wrap(~ ind, ncol=3)

ggplot(varis, aes(values, fill=ind)) + 
  geom_density(alpha=.5) + 
  facet_wrap(~ ind, ncol=3)

# plot predicitions
spplot(ok,'var1TG.pred',col.regions=viridis(100))
spplot(ok.log,'var1BT.pred',col.regions=viridis(100))

spplot(ok,'var1TG.var',col.regions=plasma(100))
spplot(ok.log,'var1BT.var',col.regions=plasma(100))

