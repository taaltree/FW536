# =============================================================================
# NMixture_Nimble.R
# -----------------------------------------------------------------------------
# N-mixture (Royle 2004) abundance models from repeated counts.
# Four nested versions, all translated from JAGS to NIMBLE:
#   Model 1: constant lambda, constant p (basic)
#   Model 2: covariate on abundance (env)
#   Model 3: covariates on BOTH abundance (env) and detection (obs)
#   Model 4: basic + overdispersion + Bayesian p-value GOF
#
# Latent process:   N[i] ~ Poisson(lambda[i])     -- true abundance at site i
# Observation:      y[i, j] ~ Binomial(N[i], p[i]) -- repeated counts
#
# What this script teaches:
#   1. Translating Royle's N-mixture from JAGS to NIMBLE.
#   2. Initialising the latent N vector at max(y[i, ]) -- another classic trick.
#   3. Stepping up complexity by adding covariates one at a time.
#   4. Posterior-predictive Bayesian p-value as a goodness-of-fit check.
#
# Author: FW599 Enhanced (Day 5 -- Bayes II), Oregon State University.
# =============================================================================

library(nimble)
library(MCMCvis)
library(MASS)   # rnegbin for overdispersion sim

set.seed(2025)

# =============================================================================
# MODEL 1: Basic N-mixture
# =============================================================================
# Simulate
lambda <- 6
sites  <- 20
reps   <- 3
p.true <- 0.8

N1 <- rpois(sites, lambda)
y1 <- matrix(NA, sites, reps)
for (i in 1:sites) y1[i, ] <- rbinom(reps, N1[i], p.true)

# NIMBLE model
Nmix1Code <- nimbleCode({
  for (i in 1:Nsites) {
    N[i] ~ dpois(lambda)
    for (j in 1:Nreps) {
      y[i, j] ~ dbinom(prob = p, size = N[i])   # arg order: prob then size
    }
  }
  p      ~ dbeta(1, 1)
  lambda ~ dgamma(0.001, 0.001)
})

# Initialise N at the per-site max count -- otherwise nimble may pick N[i]
# smaller than some y[i, j], which is impossible (binomial RV > size).
Ninit <- apply(y1, 1, max)

constants <- list(Nsites = sites, Nreps = reps)
data      <- list(y = y1)
inits     <- list(
  list(N = Ninit, lambda = 3, p = 0.5),
  list(N = Ninit, lambda = 5, p = 0.4),
  list(N = Ninit, lambda = 8, p = 0.6)
)

samples1 <- nimbleMCMC(
  code      = Nmix1Code,
  constants = constants,
  data      = data,
  inits     = inits,
  monitors  = c("lambda", "p"),
  nchains   = 3,
  niter     = 10000,
  nburnin   = 1000,
  thin      = 5,
  samplesAsCodaMCMC = TRUE
)
MCMCsummary(samples1, round = 3)


# =============================================================================
# MODEL 2: Covariate on abundance
# =============================================================================
sites <- 50
reps  <- 5
b0 <- 3; b1 <- 1
env <- rnorm(sites, 0, 1)
N2  <- rpois(sites, exp(b0 + b1 * env))
y2  <- matrix(NA, sites, reps)
for (i in 1:sites) y2[i, ] <- rbinom(reps, N2[i], 0.8)

Nmix2Code <- nimbleCode({
  for (i in 1:Nsites) {
    log(lambda[i]) <- b0 + b1 * env[i]
    N[i]           ~ dpois(lambda[i])
    for (j in 1:Nreps) {
      y[i, j] ~ dbinom(prob = p, size = N[i])
    }
  }
  p  ~ dunif(0, 1)
  b0 ~ dunif(-5, 5)
  b1 ~ dunif(-5, 5)
})

constants2 <- list(Nsites = sites, Nreps = reps, env = env)
data2      <- list(y = y2)
Ninit2     <- apply(y2, 1, max)
inits2     <- list(
  list(N = Ninit2, b0 = 0, b1 = 0, p = 0.5),
  list(N = Ninit2, b0 = 2, b1 = 1, p = 0.4),
  list(N = Ninit2, b0 = 4, b1 = -1, p = 0.6)
)

samples2 <- nimbleMCMC(
  code      = Nmix2Code,
  constants = constants2,
  data      = data2,
  inits     = inits2,
  monitors  = c("b0", "b1", "p"),
  nchains   = 3,
  niter     = 10000,
  nburnin   = 1000,
  thin      = 5,
  samplesAsCodaMCMC = TRUE
)
MCMCsummary(samples2, round = 3)


# =============================================================================
# MODEL 3: Covariates on abundance AND detection
# =============================================================================
# Same abundance setup
N3   <- rpois(sites, exp(b0 + b1 * env))
obs  <- rnorm(sites, 0, 1)
a0 <- 1; a1 <- 1
p3 <- plogis(a0 + a1 * obs)
y3 <- matrix(NA, sites, reps)
for (i in 1:sites) y3[i, ] <- rbinom(reps, N3[i], p3[i])

Nmix3Code <- nimbleCode({
  for (i in 1:Nsites) {
    logit(p[i])    <- a0 + a1 * obs[i]
    log(lambda[i]) <- b0 + b1 * env[i]
    N[i] ~ dpois(lambda[i])
    for (j in 1:Nreps) {
      y[i, j] ~ dbinom(prob = p[i], size = N[i])
    }
  }
  a0 ~ dunif(-5, 5);   a1 ~ dunif(-5, 5)
  b0 ~ dunif(-5, 5);   b1 ~ dunif(-5, 5)
})

constants3 <- list(Nsites = sites, Nreps = reps, env = env, obs = obs)
data3      <- list(y = y3)
Ninit3     <- apply(y3, 1, max)
inits3     <- list(
  list(N = Ninit3, b0 = 0, b1 = 0, a0 = 0, a1 = 0),
  list(N = Ninit3, b0 = 2, b1 = 1, a0 = 1, a1 = 1),
  list(N = Ninit3, b0 = 4, b1 = -1, a0 = -1, a1 = -1)
)

samples3 <- nimbleMCMC(
  code      = Nmix3Code,
  constants = constants3,
  data      = data3,
  inits     = inits3,
  monitors  = c("a0", "a1", "b0", "b1"),
  nchains   = 3,
  niter     = 10000,
  nburnin   = 1000,
  thin      = 5,
  samplesAsCodaMCMC = TRUE
)
MCMCsummary(samples3, round = 3)


# =============================================================================
# MODEL 4: Basic N-mixture but data are OVERDISPERSED
#          -- fit the wrong (Poisson) model on purpose & detect via Bayes-p
# =============================================================================
lambda <- 6
sites  <- 200            # need many sites to detect overdispersion
reps   <- 3
N4 <- rnegbin(sites, mu = lambda, theta = 3)   # NB instead of Poisson
y4 <- matrix(NA, sites, reps)
for (i in 1:sites) y4[i, ] <- rbinom(reps, N4[i], 0.8)

Nmix4Code <- nimbleCode({
  for (i in 1:Nsites) {
    N[i] ~ dpois(lambda)                 # WRONG by construction
    for (j in 1:Nreps) {
      y[i, j]        ~ dbinom(prob = p, size = N[i])
      y.pred[i, j]   ~ dbinom(prob = p, size = N[i])  # posterior replicate
      e[i, j]       <- p * lambda
      resid[i, j]      <- pow(pow(y[i, j],      0.5) - pow(e[i, j], 0.5), 2)
      resid.pred[i, j] <- pow(pow(y.pred[i, j], 0.5) - pow(e[i, j], 0.5), 2)
    }
  }
  fit.data <- sum(resid[1:Nsites, 1:Nreps])
  fit.pred <- sum(resid.pred[1:Nsites, 1:Nreps])

  p      ~ dbeta(1, 1)
  lambda ~ dgamma(0.001, 0.001)
})

constants4 <- list(Nsites = sites, Nreps = reps)
data4      <- list(y = y4)
Ninit4     <- apply(y4, 1, max)
inits4     <- list(
  list(N = Ninit4, lambda = 3, p = 0.5),
  list(N = Ninit4, lambda = 5, p = 0.4),
  list(N = Ninit4, lambda = 8, p = 0.6)
)

samples4 <- nimbleMCMC(
  code      = Nmix4Code,
  constants = constants4,
  data      = data4,
  inits     = inits4,
  monitors  = c("lambda", "p", "fit.data", "fit.pred"),
  nchains   = 3,
  niter     = 10000,
  nburnin   = 1000,
  thin      = 5,
  samplesAsCodaMCMC = TRUE
)

post <- as.matrix(samples4)
bayes.p <- mean(post[, "fit.pred"] > post[, "fit.data"])
cat("Bayesian p-value =", round(bayes.p, 3),
    "  (closer to 0.5 = better fit; far from 0.5 = misfit)\n")

# A Bayesian p-value far from 0.5 indicates the Poisson-only model fails to
# capture the variance pattern in the data. The fix is to add a random effect
# on log(lambda[i]) (a Poisson-lognormal or NB N-mixture).

# =============================================================================
# Teaching takeaways
# =============================================================================
# - dbinom in NIMBLE/JAGS takes (prob, size) in that order -- a common
#   silent bug when porting from R, which uses (size, prob).
# - Initialise N[i] at max(y[i, ]) so the Bayesian model can start.
# - Build complexity additively: constant -> covariates on abundance ->
#   covariates on both -> overdispersion. Each step is testable.
# - The Bayesian p-value is the simplest GOF check for hierarchical models;
#   pick a discrepancy (sum-of-squared-roots here) that you understand.
# =============================================================================
