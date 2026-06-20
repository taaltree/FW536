# (working directory should be the Day5_BayesII folder)
library(GGally)
library(nimble)
library(MCMCvis)
set.seed(10)


#####Part I - Fit Poisson glm model in glm() and in Bayes. Don't scale predictors

ants <- read.csv('data/ants.csv',header=TRUE)
#GGally::ggpairs(ants)
freq_glm <- glm(richness~forest+latitude+elevation,data=ants,family=poisson())$coef
names(freq_glm) <- c('b0', 'b1', 'b2', 'b3')
freq_glm

ant = nimbleCode({
  for(i in 1:n){
    ants[i, 1] ~ dpois(lam[i])
    log(lam[i]) <- b0+b1*ants[i,2]+b2*ants[i,3]+b3*ants[i,4]
  }
  b0 ~ dnorm(mu,tau)
  b1 ~ dnorm(mu,tau)
  b2 ~ dnorm(mu,tau)
  b3 ~ dnorm(mu,tau)
})
#mu and tau will be passed as constants so that we can set them outside this function
#Look at that ants data to see that ants[i, 1] refers to richness, ants[i, 2] to forest, etc.
inits <- list(list(b0 = 1, b1 = 0, b2 = 0, b3 = 0),
              list(b0 = 1, b1 = 0, b2 = 0, b3 = 0),
              list(b0 = 1, b1 = 0, b2 = 0, b3 = 0))

inits <- list(
  as.list(freq_glm),
  as.list(freq_glm + runif(4, -1, 1)),
  as.list(freq_glm + runif(4, -1, 1))
)

constants=list(
  'ants' = as.matrix(ants),
  'n' = nrow(ants),
  'mu' = 0,
  'tau' = 1/10000)#Assume vague prior. Sigma = 100 here. Try changing and rerunning.



n.mcmc=10000
samples.ants=nimbleMCMC(code=ant,constants=constants, inits=inits,monitors= c('b0', 'b1', 'b2', 'b3'),nchains=3,nburnin=500,niter=n.mcmc)

MCMCsummary(samples.ants)
MCMCtrace(samples.ants)

#Compare to frequentist output
freq_glm

#Question 1 - how do the frequentist and Bayesian output compare? Are the estimates similar?


#Question 2 - Try changing the priors to see if this improves


######################################################################################
######################################################################################
#Something messed up. What?
#Note that (1) our prior is on the log link and so becomes exponential when backtransformed
#This is not always an problem unless it's possible that there is some likelihood at extreme values
#Note that (2) there are large positive values in ants, so it's possible to get unstable estimates due to this
View(ants)

#Scaling predictors!
#####Part II - Fit Poisson glm model in glm() and in Bayes. Scale predictors


#######GOT TO SCALE PREDICTORS
ants$forest <- as.vector(scale(ants$forest))
ants$latitude <- as.vector(scale(ants$latitude))
ants$elevation <- as.vector(scale(ants$elevation))

# frequentist glm estimation using scaled predictors
freqest_scale <- glm(richness~., data = ants, family = poisson(link = 'log'))$coef
names(freqest_scale) <- c('b0', 'b1', 'b2', 'b3')
freqest_scale

inits <- list(
  as.list(freqest_scale),
  as.list(freqest_scale + runif(4, -1, 1)),
  as.list(freqest_scale + runif(4, -1, 1))
)
constants=list(
  'ants' = as.matrix(ants),
  'n' = nrow(ants),
  'mu' = 0,
  'tau' = 1/10000)

samples.ants=nimbleMCMC(code=ant,constants=constants, monitors= c('b0', 'b1', 'b2', 'b3'),nchains=3,nburnin=500,niter=n.mcmc)

MCMCsummary(samples.ants)


#Question 3 - how do the frequentist and Bayesian output compare? Are the estimates similar?



#Question 4 - Try changing the priors to observe the sensitivity

