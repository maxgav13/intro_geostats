# generate autocorrelated data.
nLags = 30 # number of lags (size of region)
# fake, uncorrelated observations
# set.seed(101)
X = round(rnorm(nLags,5,1))
###############################################
# fake sigma... correlated decreases distance.
sigma = diag(nLags)
corr = 0.8
sigma <- corr ^ abs(row(sigma)-col(sigma))
###############################################
# Y is autocorrelated...
Y <- t(X %*% chol(sigma))
summary(Y)
dat1 = data.frame(x=1:nLags,y=0,z=Y)
coordinates(dat1) = ~x+y
plot(variogram(z~1,dat1,cutoff=nLags/2,width=1))
