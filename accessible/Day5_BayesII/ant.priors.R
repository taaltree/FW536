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
    y[i] ~ dpois(lam[i])
    log(lam[i]) <- b0+b1*forest[i]+b2*latitude[i]+b3*elevation[i]
  }
  b0 ~ dnorm(mu,tau)
  b1 ~ dnorm(mu,tau)
  b2 ~ dnorm(mu,tau)
  b3 ~ dnorm(mu,tau)
})
#mu and tau will be passed as constants so that we can set them outside this function.
#NOTE the constants/data split. `y` (the richness counts) is the only thing in the
#model that appears on the LHS of a `~` and is observed, so it is the ONLY thing that
#belongs in data=. The covariates, the sample size, and the prior settings mu/tau never
#appear on the LHS of a `~`, so they are constants=. Passing the whole ants matrix as a
#constant and writing `ants[i,1] ~ dpois(...)` would put an observed random variable in
#constants=. Nimble does rescue that -- it reclassifies the node as data -- but it tells
#you so, printing:
#    [Note] Using 'ants' (given within 'constants') as data.
#    [Warning] dimensions specified are larger than model specification
#              for variable `ants`.
#That Note is the signal you were sloppy. It is the wrong mental model and it will bite
#you in a model where you need to modify or predict the response.
inits <- list(list(b0 = 1, b1 = 0, b2 = 0, b3 = 0),
              list(b0 = 1, b1 = 0, b2 = 0, b3 = 0),
              list(b0 = 1, b1 = 0, b2 = 0, b3 = 0))

inits <- list(
  as.list(freq_glm),
  as.list(freq_glm + runif(4, -1, 1)),
  as.list(freq_glm + runif(4, -1, 1))
)

constants=list(
  'n' = nrow(ants),
  'forest' = ants$forest,
  'latitude' = ants$latitude,
  'elevation' = ants$elevation,
  'mu' = 0,
  'tau' = 1/10000)#Assume vague prior. tau is a PRECISION, so sigma = 100 here.
                  #Try changing and rerunning.
data=list('y' = ants$richness)   #the observed random variable -- the only data=


n.mcmc=10000
samples.ants=nimbleMCMC(code=ant,constants=constants, data=data, inits=inits,monitors= c('b0', 'b1', 'b2', 'b3'),nchains=3,nburnin=500,niter=n.mcmc)

MCMCsummary(samples.ants)
MCMCtrace(samples.ants, pdf = FALSE)   #pdf=FALSE keeps the plot in the R session
                                       #instead of dumping MCMCtrace.pdf into your wd

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
#View(ants)   #(interactive only)

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
  'n' = nrow(ants),
  'forest' = ants$forest,
  'latitude' = ants$latitude,
  'elevation' = ants$elevation,
  'mu' = 0,
  'tau' = 1/10000)
data=list('y' = ants$richness)

#Pass inits= here too. Part I passes inits, so if we omitted them here the only
#difference between the two runs would no longer be "scaled vs unscaled predictors" --
#we would be changing two things at once and could not attribute the improvement.
samples.ants=nimbleMCMC(code=ant,constants=constants, data=data, inits=inits, monitors= c('b0', 'b1', 'b2', 'b3'),nchains=3,nburnin=500,niter=n.mcmc)

MCMCsummary(samples.ants)


#Question 3 - how do the frequentist and Bayesian output compare? Are the estimates similar?



#Question 4 - Try changing the priors to observe the sensitivity

