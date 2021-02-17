# unconditional simulations on a 100 x 100 grid using gstat
library(gstat)
library(sp)
library(sf)
library(tidyverse)

x <- 1:100 # x coordinates
y <- 1:100 # y coordinates
dat <- expand.grid(x = x, y = y) # create data frame with all combinations
dat$z <- 1 # initialize z variable
coordinates(dat) <- ~x + y # set coordinates
gridded(dat) <- TRUE # specify data is gridded

modelo = vgm(psill = 0.9, model = 'Sph', range = 30,
             nugget = 0.1, anis = c(35,.4)) # model to simulate
beta.mod = 5 # mean of the random field
var.mod = sum(modelo$psill) # variance of the random field
nsim = 4 # number of simulations

g1 <- gstat(id = 'z', formula = z~1, model = modelo,
           data = dat, dummy = TRUE, beta = beta.mod, nmax = 50) # create gstat object
dat.1 <- predict(g1, newdata = dat, nsim = 1) # simulate 1 random field
dat.1.df = data.frame(dat.1) # converts simulation to data frame
dat.sim = krige(z ~ 1, locations = dat, newdata = dat, model = modelo,
                nmax = 50, dummy = T, beta = beta.mod, nsim = nsim) # simulate N random fields

dat.sim.df = data.frame(dat.sim) %>% gather('sim', 'z' , 3:(nsim+2)) # tidy N random fields
dat.sim.sf = st_as_sf(dat.sim.df, coords = 1:2) # spatial random fields
head(dat.1.df) # show first lines of the data frame
head(dat.sim.df)

dat.sim.df %>% 
  group_nest(x, y) %>% 
  mutate(mu = map_dbl(data, ~mean(.x$z)),
         s = map_dbl(data, ~sd(.x$z)),
         MoE = qt(.975, nsim-1) * s/sqrt(nsim)) # averaged simulations

major = modelo$ang1[2] # major direction of anisotropy
minor = ifelse(major < 90, major + 90, major - 90) # minor direction of anisotropy

expvar <- variogram(sim1 ~ 1, data = dat.1, 
                    alpha = c(major, minor)) # variogram for single realization
head(expvar) # show first lines of the variogram
plot(expvar)

ggplot(dat.1.df,aes(x = x, y = y, fill = sim1)) + 
  geom_raster() + 
  coord_equal() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  scale_fill_distiller(palette = 'YlOrRd', direction = 1)
  # scale_fill_gradientn(colours=rainbow(50)) # map of single random field

dat.1.df %>% 
ggplot(aes(x = x, y = y, z = sim1)) + 
  geom_contour(aes(col = stat(level)), binwidth = 2) + 
  coord_equal() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  scale_color_distiller(palette = 'YlOrRd', direction = 1) # contour map of single random field

dat.sim.df %>% 
  ggplot(aes(x = x, y = y, fill = z)) + 
  geom_raster() + 
  coord_equal() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  scale_fill_distiller(palette = 'YlOrRd', direction = 1) +
  # scale_fill_gradientn(colours=rainbow(50)) + 
  facet_wrap(~sim, nrow = 1) # maps of N random fields

dat.sim.df %>% 
  ggplot(aes(x = x, y = y, z = z)) + 
  geom_contour(aes(col = stat(level)), binwidth = 2) + 
  coord_equal() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  scale_color_distiller(palette = 'YlOrRd', direction = 1) + 
  facet_wrap(~sim, nrow = 1) # contour maps of N random fields

dat.sim.variog = dat.sim.sf %>% 
  group_by(sim) %>% 
  group_modify(~variogram(z ~ 1, data = .x, alpha = c(major, minor))) %>% 
  mutate(dir.hor = as.factor(dir.hor)) # variogram for each random field realization

dat.sim.variog %>% 
  ggplot(aes(dist, gamma, col = dir.hor)) + 
  geom_point(size = 2) +
  scale_color_brewer(palette = 'Set1') +
  labs(x = 'Distance', y = 'Semivariance', col = 'Direction') +
  facet_wrap(~sim, nrow = 2) # variogram plot for each realization

# calculates unit vector for variogram line
unit_vector = function(th) {
  if (th == 0) {
    uv = c(0,1,0)
  } else if (th == 90) {
    uv = c(1,0,0)
  } else if (th == 180) {
    uv = c(0,-1,0)
  } else if (between(th,0,90)) {
    uv = c(sin(th*pi/180),cos(th*pi/180),0)
  } else if (between(th,90,180)) {
    uv = c(cos((th-90)*pi/180),-1*sin((th-90)*pi/180),0)
  }
  return(uv)
}

# variogram lines for major and minor anisotropy directions
vm.major <- variogramLine(object = modelo, maxdist = max(dat.sim.variog$dist),
                        min = 0.001, n = 100, dir = unit_vector(major))
vm.minor <- variogramLine(object = modelo, maxdist = max(dat.sim.variog$dist),
                        min = 0.001, n = 100, dir = unit_vector(minor))
vm.lines = rbind.data.frame(cbind.data.frame(vm.major,dir.hor = major),
                            cbind.data.frame(vm.minor,dir.hor = minor)) %>% 
  mutate(dir.hor = as.factor(dir.hor))

dat.sim.variog %>% 
  ggplot(aes(dist, gamma, col = dir.hor)) + 
  geom_point(size = 2) +
  geom_line(data = vm.lines) +
  scale_color_brewer(palette = 'Set1') +
  labs(x = 'Distance', y = 'Semivariance', col = 'Direction') +
  facet_wrap(~sim, nrow = 2) # variogram plot for each realization with model superimposed

dat.sim.variog %>% 
  ggplot(aes(dist, gamma, col = dir.hor)) + 
  geom_point(size = 2) +
  geom_line(data = vm.lines) +
  scale_color_brewer(palette = 'Set1') +
  labs(x = 'Distance', y = 'Semivariance', col = 'Direction') +
  facet_wrap(~dir.hor)

# variogram lines for different directions
d = c(0,45,90,135)
map_dfr(d, ~variogramLine(object = modelo, maxdist = max(dat.sim.variog$dist),
                          min = 0.001, n = 100, dir = unit_vector(.x)), .id = 'dir') %>% 
  as_tibble() %>% 
  mutate(dir = factor(dir, labels = as.character(d))) %>% 
  ggplot(aes(dist,gamma,col=dir)) + 
  geom_line(size=1.25) + 
  scale_color_brewer(palette = 'Set1') +
  labs(x = 'Distance', y = 'Semivariance', col = 'Direction')
