library(rjags)
library(MCMCvis)
library(HDInterval)

#install.packages("~/Dropbox/Taal/courses/quantitative and computational course/ExampleCourses/Hobbs Course/SESYNCBayes_0.6.0.tar.gz", repos = NULL, type = "source")

Logistic=read.csv("data/Logistic.csv",header=T)

#########################
#Let's try least squares#
#########################
View(Logistic)
reg=lm(GrowthRate~PopulationSize,data=Logistic)
summary(reg)

coef(reg)
rmax=coef(reg)[1]
K=-coef(reg)[1]/coef(reg)[2]

# OK...but now what can you say about K?
# K/2?
# MSY?

vcov(reg)
summary(reg)
#########################

# Derived quantities with the logistic
# One of the most useful features of MCMC is that any quantity that is a function of a random variable in the MCMC algorithm becomes a random variable. 
# Consider two quantities of interest that are functions of our estimates of the random variables r and K:
#   
#   The population size where the population growth rate is maximum, K/2
# The rate of population growth, dNdt=rN(1−NK)
# You will now estimate these quantities of interest. Some hints for the problems below:
#   
#   Include expressions for each derived quantity in your JAGS code.
# You will need to give JAGS a vector of N values to plot dNdt vs N.
# Use a JAGS object for plotting the rate of population growth.
# Look into using the ecdf() function on a JAGS object. 

#Approximate the marginal posterior distribution the population size where the population growth rate is maximum and plot its posterior density. 

#[r, K, tau, y] is proportional 

#sink will write the model to file to be read in by jags. 
#You can also just read in the file made elsewhere
  sink("LogisticJAGS.R")
  cat(" 
model {

  # priors

  K ~ dunif(0, 4000)
  r ~ dunif (0, 2)
  sigma ~ dunif(0, .5) 
  tau <- 1/sigma^2
  
  # likelihood
  
  for(i in 1:n) {
    mu[i] <- r - r/K * x[i]
    y[i] ~ dnorm(mu[i], tau)
  }

  # derived quantities  

  N_at_maxdNdt <- K/2
  MSY <- r*K/4
  
  # derived quantity for population growth rate over range of N values. 
  # N must be read in as data:
  for (j in 1:length(N)) {
    dNdt[j] <- r * N[j] * (1 - N[j]/K)
  }
} 
",fill = TRUE)
  sink()

set.seed(10) #so we all get the same result

Logistic <- Logistic[order(Logistic$PopulationSize),] #sorting by population size. Try not doing it and plotting and see what you get

#let's initialize 3 MCMC chains at different places.
# Initial conditions must be specified as as “list of lists”
#even if only one chain
inits = list(
  list(K = 1500, r = .2, sigma = .01),
  list(K = 1000, r = .15, sigma = .5),
  list(K = 900, r = .3, sigma = .01))

N <- seq(0,1500,10) # let's include population size as data so we can estimate dN/dt at all these populations
N[1] <- 1

#Notice that you can assign data vectors on the R side to different names on the JAGS side
#The jags code above uses x and y. RHS of "=" is the R name. LHS is jags name.
data = list(
  n = nrow(Logistic), #you need this in the for loop!
  x = as.double(Logistic$PopulationSize), #execution of JAGS is about 5 times faster on doubles than on integers
  y = as.double(Logistic$GrowthRate), #We also want to make sure this isn't read in as a character but as a number. In this case not necessary
  N = N)#N included as data

n.adapt = 5000   #number of iterations for adaptation
n.update = 10000 #number of iterations for burn in
n.iter = 20000  #number of iterations to actually keep

#jags has to figure out how to sample. This sets up the MCMC chain
jm = jags.model("LogisticJAGS.R", data = data, inits = inits, n.chains = length(inits), n.adapt = n.adapt)

#update the model but don't store anything. This is "burn in"
update(jm, n.iter = n.update)

#in rjags, we will then sample from the posterior. 
#The library jagsUI is a wrapper for rjags So is package R2jags. 
#It allows this to all be done in one step using the jags() function
library(jagsUI)
?jags
#compare with
?jags.model

#sample n.iter times from the posterior and store as MCMC list
#variable.names tells jags which variables to monitor
#thin specifies how many posterior draws to keep. 
#Successive draws are correlated, so you can keep fewer draws as "independent" samples form posterior

#################################################
# #
# Exercise 1: For the logistic model
# #
#################################################
#For now, let's just sample a few quantities (not the derived ones)

zm.short = coda.samples(jm, variable.names = c("K", "r", "sigma"), n.iter = n.iter, n.thin = 1)
MCMCtrace(zm.short, pdf = FALSE) 
MCMCsummary(zm.short)

#this lets us see a trace plot of the MCMC (samples values for each iteration)
#you also see the density of each parameter specified by "variable.names"


# Plot the observations of growth rate as a function of observed population size.
# Overlay the median of the model predictions as a solid line.
# Overlay the 95% equal-tailed credible intervals as dashed lines in red.
# Overlay the 95% highest posterior density intervals as dashed lines in blue.
# What do you note about these two intervals? Will this always be the case? Why or why not?
# What do the dashed lines represent? What inferential statement can we make about relative these lines?
#   #

#now we keep track of mu. What is mu again?
zm = coda.samples(jm, variable.names = c("K", "r", "sigma", "mu"),  n.iter = 10000)
MCMCsummary(zm)

#Two different types of credible intervals.
#Use MCMCpstr() "Summarize and extract posterior chains from MCMC output while preserving parameter structure"
BCI <- MCMCpstr(zm, params = "mu", func = function(x) quantile(x, c(.025, .5, .975)))
HPDI <-  MCMCpstr(zm, params = "mu", func = function(x) hdi(x, .95))

plot(data$x, data$y, pch = 19, xlab = "Population size", ylab = "Per-capita grwoth rate (1/year)" )
lines(data$x,BCI$mu[,2], typ = "l")
lines(data$x, BCI$mu[,1], lty = "dashed", col = "red")
lines(data$x, BCI$mu[,3], lty = "dashed", col = "red")
lines(data$x, HPDI$mu[,1], lty = "dashed", col = "blue") 
lines(data$x, HPDI$mu[,2], lty = "dashed", col = "blue")  


#plot parameter estimates with CI
MCMCplot(zm, params = c("sigma"))
MCMCplot(zm, params = c("r"))
MCMCplot(zm, params = c("K"))
MCMCplot(zm, params = c("mu"))



#################################################
# #
# Exercise 2: Understanding coda objects and derived quantities
# #
#################################################


zm = coda.samples(jm, variable.names = c("K", "r", "sigma", "N_at_maxdNdt","MSY", "dNdt"), n.iter = n.iter, n.thin = 1)
df = as.data.frame(rbind(zm[[1]], zm[[2]], zm[[3]])) #each chain
dim(df)

library(mcmcplots)
mcmcplot(zm.short)

# 1. (done) Convert the coda object zm, into a data frame using df = as.data.frame(rbind(zm[[1]], zm[[2]], zm[[3]])) Note the double brack- ets, which effectively unlist each element of zm, allowing them to be combined. Another way to do this is do.call(rbind,zm).
# 2. Look at the first six rows of the data frame.
# 3. Find the maximum value of sigma.
# 4. Find the mean of r for the first 1000 iterations.
# 5. Find the mean of r after the last 1000 iterations.
# 6. Make two publication quality plots of the marginal posterior density of K, one as a smooth curve and the other as a histogram.
# 7. Compute the probability that K > 1600. Hint: what type of probability distribution would you use for this computation? Investigate the the dramatically useful R function ecdf().
# 8. Compute the probability that 1000 < K < 1300.
# 9. Compute the .025 and .975 quantiles of K. Hint–use the R quantile() function. This is an equal-tailed Bayesian credible interval on K.


#Extract posterior chains from MCMC output. These are derived quantities
N_at_maxdNdt = MCMCchains(zm, params = c("N_at_maxdNdt"))
MSY = MCMCchains(zm, params = c("MSY"))

plot(density(N_at_maxdNdt), main = "", xlab ="Population size with maximum growth rate", ylab = "Proability density")
rug(N_at_maxdNdt, col = "red")

plot(density(MSY), main = "", xlab ="Maximum Sustainable Yield", ylab = "Proability density")
rug(MSY, col = "red")

# Plot the median growth rate of the population (not the per-capita rate) rate and a 95% highest posterior density interval as a function of N. What does this curve tell you about the difficulty of sustaining harvest of populations?

HPDI <-  MCMCpstr(zm, params = c("dNdt"), func = function(x) hdi(x, .95))#Note hdi() is highest density interval
medN <- MCMCpstr(zm, params = c("dNdt"), func = median)
plot(N, medN$dNdt,  ylab = "Population growth rate dN/dt", xlab = "Population size N", type = "l", ylim = c(-40, 80))
abline(h=0)
lines(N, HPDI$dNdt[,1], lty = "dashed")
lines(N, HPDI$dNdt[,2], lty = "dashed")

# 
# 
# What is the probability that the intrinsic rate of increase (r) exceeds 0.22? 
#What is the probability that r falls between 0.18 and 0.22?
#   Answers
r = MCMCchains(zm, "r")
1 - ecdf(r)(.22)
#or
1- mean(r<0.22)

ecdf(r)(.22) - ecdf(r)(.18)
mean(r<0.22) - mean(r<0.18)


ex = as.data.frame(MCMCchains(zm, params = c("r", "sigma")))
hist(ex$sigma,xlab = expression(sigma), ylab = "Probability density", freq = FALSE, breaks = 100, main = "")
abline(v = quantile(ex$sigma, c(.025, .975)), col = "red", lwd = 2)
abline(v = hdi(ex$sigma, .95), lwd = 2, col = "blue")

#################################################
# #
# Exercise 2: For the logistic model
# #
#################################################

# Plot the observations of growth rate as a function of observed population size.
# Overlay the median of the model predictions as a solid line.
# Overlay the 95% equal-tailed credible intervals as dashed lines in red.
# Overlay the 95% highest posterior density intervals as dashed lines in blue.
# What do you note about these two intervals? Will this always be the case? Why or why not?
# What do the dashed lines represent? What inferential statement can we make about relative these lines?
#   #


zm = coda.samples(jm, variable.names = c("K", "r", "sigma", "mu"),  n.iter = 10000)


BCI <- MCMCpstr(zm, params = "mu", func = function(x) quantile(x, c(.025, .5, .975)))
HPDI <-  MCMCpstr(zm, params = "mu", func = function(x) hdi(x, .95))

plot(data$x, data$y, pch = 19, xlab = "Population size", ylab = "Per-capita grwoth rate (1/year)" )
lines(data$x,BCI$mu[,2], typ = "l")
lines(data$x, BCI$mu[,1], lty = "dashed", col = "red")
lines(data$x, BCI$mu[,3], lty = "dashed", col = "red")
lines(data$x, HPDI$mu[,1], lty = "dashed", col = "blue") 
lines(data$x, HPDI$mu[,2], lty = "dashed", col = "blue")  


#plot parameter estimates with CI
MCMCplot(zm, params = c("sigma"))
MCMCplot(zm, params = c("r"))
MCMCplot(zm, params = c("K"))
MCMCplot(zm, params = c("mu"))

