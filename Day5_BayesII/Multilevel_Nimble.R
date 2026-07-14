# =============================================================================
# Multilevel_Nimble.R
# -----------------------------------------------------------------------------
# Bayesian multilevel models for soil N2O emissions.
# Five nested versions covering the "pooling spectrum":
#   Model 1: Complete pooling      -- one alpha for all sites
#   Model 2: No pooling            -- independent alpha[j] per site
#   Model 3: Partial pooling       -- alpha[j] ~ Normal(mu_alpha, sigma_alpha)
#   Model 4: Partial pooling, alpha[j] modeled by site-level covariate w[j]
#   Model 5: Random intercept + random slope by fertilizer type
#
# Data: N2OEmission.csv (rows are measurements; columns include
#       emission, n.input, group.index [site], fert.index [fertilizer type]).
# SiteCarbon (a site-level covariate) is used in Models 4-5.
#
# What this script teaches:
#   1. The full pooling spectrum, with explicit shrinkage demonstration.
#   2. NIMBLE patterns for hierarchical priors:
#        alpha[j] ~ dnorm(mu_alpha, tau_alpha)
#   3. Group-level regression on a random intercept ("modeled intercept").
#   4. Separating constants (sizes, indices) from data (observed RVs).
#
# Author: FW599 Enhanced (Day 5 -- Bayes II), Oregon State University.
# =============================================================================

# ----- Packages -------------------------------------------------------------
library(nimble)
library(MCMCvis)
library(coda)
library(HDInterval)
library(ggplot2)
library(dplyr)
library(tidyr)

set.seed(10)

# ----- Data ----------------------------------------------------------------
N2OEmission <- read.csv("data/N2OEmission.csv")
head(N2OEmission)
# Site-level summary: mean soil organic carbon (%) per site. The N2OEmission
# file carries a `carbon` column, so we use it directly as the group-level
# covariate w[j] in Models 4-5.
if (!exists("SiteCarbon")) {
  SiteCarbon <- N2OEmission %>% group_by(group.index) %>%
    summarise(mean = mean(carbon))
}

# Center the predictor on the log scale (centering improves MCMC mixing).
y     <- log(N2OEmission$emission)
x     <- log(N2OEmission$n.input) - mean(log(N2OEmission$n.input))
group <- N2OEmission$group.index
fert  <- N2OEmission$fert.index
nobs   <- length(y)
nsites <- length(unique(group))
nferts <- length(unique(fert))

# A grid of new n.input values for prediction
n.input.pred <- seq(min(N2OEmission$n.input), max(N2OEmission$n.input), 10)
N.pred       <- log(n.input.pred) - mean(log(N2OEmission$n.input))
nout         <- length(N.pred)

# =============================================================================
# MODEL 1: COMPLETE POOLING
# =============================================================================
mod1 <- nimbleCode({
  alpha ~ dnorm(0, 1/10000)
  beta  ~ dnorm(0, 1/10000)
  sigma ~ dunif(0, 100)
  tau  <- 1 / sigma^2

  for (i in 1:n) {
    mu[i] <- alpha + beta * x[i]
    y[i]  ~ dnorm(mu[i], tau)
  }
  for (j in 1:n2) {
    log_mu_pred[j] <- alpha + beta * N[j]
    mu_pred[j]     <- exp(log_mu_pred[j])
  }
})

data1     <- list(y = y)
const1    <- list(n = nobs, n2 = nout, x = x, N = N.pred)
inits1    <- list(
  list(alpha = 0, beta = 0.5, sigma = 50),
  list(alpha = 1, beta = 1.5, sigma = 10),
  list(alpha = 2, beta = 0.75, sigma = 20)
)
samples1 <- nimbleMCMC(mod1, constants = const1, data = data1, inits = inits1,
                       monitors = c("alpha", "beta", "sigma"),
                       nchains = 3, niter = 10000, nburnin = 1000,
                       samplesAsCodaMCMC = TRUE)
MCMCsummary(samples1, round = 3)

# =============================================================================
# MODEL 2: NO POOLING (independent alpha per site)
# =============================================================================
mod2 <- nimbleCode({
  for (k in 1:n.sites) {
    alpha[k] ~ dnorm(0, 1/10000)    # NOTE: each site's alpha is independent
  }
  beta  ~ dnorm(0, 1/10000)
  sigma ~ dunif(0, 100)
  tau  <- 1 / sigma^2

  for (i in 1:n) {
    mu[i] <- alpha[group[i]] + beta * x[i]
    y[i]  ~ dnorm(mu[i], tau)
  }
})

data2  <- list(y = y)
const2 <- list(n = nobs, x = x, n.sites = nsites, group = group)
inits2 <- list(
  list(alpha = rep( 0, nsites), beta = 0.5, sigma = 50),
  list(alpha = rep( 1, nsites), beta = 1.5, sigma = 10),
  list(alpha = rep(-1, nsites), beta = 0.75,sigma = 20)
)
samples2 <- nimbleMCMC(mod2, constants = const2, data = data2, inits = inits2,
                       monitors = c("alpha", "beta", "sigma"),
                       nchains = 3, niter = 10000, nburnin = 1000,
                       samplesAsCodaMCMC = TRUE)
MCMCsummary(samples2, params = c("beta", "sigma"))

# =============================================================================
# MODEL 3: PARTIAL POOLING -- random intercept
# =============================================================================
mod3 <- nimbleCode({
  # Hierarchical prior on site intercepts
  for (j in 1:n.sites) {
    alpha[j] ~ dnorm(mu_alpha, tau_alpha)
  }
  mu_alpha    ~ dnorm(0, 1/10000)
  sigma_alpha ~ dunif(0, 100)
  tau_alpha  <- 1 / sigma_alpha^2

  beta  ~ dnorm(0, 1/10000)
  sigma ~ dunif(0, 100)
  tau  <- 1 / sigma^2

  for (i in 1:n) {
    mu[i] <- alpha[group[i]] + beta * x[i]
    y[i]  ~ dnorm(mu[i], tau)
  }
})

inits3 <- list(
  list(alpha = rep( 0, nsites), beta = 0.5, sigma = 50, mu_alpha =  0, sigma_alpha = 10),
  list(alpha = rep( 1, nsites), beta = 1.5, sigma = 10, mu_alpha =  2, sigma_alpha = 20),
  list(alpha = rep(-1, nsites), beta = 0.75,sigma = 20, mu_alpha = -1, sigma_alpha = 12)
)
samples3 <- nimbleMCMC(mod3, constants = const2, data = data2, inits = inits3,
                       monitors = c("alpha", "beta", "sigma",
                                    "mu_alpha", "sigma_alpha"),
                       nchains = 3, niter = 10000, nburnin = 1000,
                       samplesAsCodaMCMC = TRUE)
MCMCsummary(samples3, params = c("beta", "sigma", "mu_alpha", "sigma_alpha"))

# Shrinkage demo: compare per-site alpha[j] from Model 2 (no pooling) vs
# Model 3 (partial pooling). Partial-pooling estimates pull toward mu_alpha.
a.no   <- MCMCpstr(samples2, params = "alpha", func = median)$alpha
a.part <- MCMCpstr(samples3, params = "alpha", func = median)$alpha
plot(a.no, a.part, pch = 19,
     xlab = "alpha[j] (no pooling)", ylab = "alpha[j] (partial pooling)",
     main = "Shrinkage: partial pooling pulls site intercepts toward mu_alpha")
abline(0, 1, col = "grey")
abline(h = mean(a.part), col = "red", lty = 2)

# =============================================================================
# MODEL 4: PARTIAL POOLING with site-level covariate w[j] on random intercept
# =============================================================================
# w[j] = logit-percent of soil organic carbon for site j
w <- log(SiteCarbon$mean / (100 - SiteCarbon$mean))

mod4 <- nimbleCode({
  kappa ~ dnorm(0, 1/10000)
  eta   ~ dnorm(0, 1/10000)
  sigma_alpha ~ dunif(0, 100)
  tau_alpha  <- 1 / sigma_alpha^2

  beta  ~ dnorm(0, 1/10000)
  sigma ~ dunif(0, 100)
  tau  <- 1 / sigma^2

  for (j in 1:n.sites) {
    mu_alpha[j] <- kappa + eta * w[j]    # group-level regression
    alpha[j]    ~ dnorm(mu_alpha[j], tau_alpha)
  }
  for (i in 1:n) {
    mu[i] <- alpha[group[i]] + beta * x[i]
    y[i]  ~ dnorm(mu[i], tau)
  }
})

const4 <- c(const2, list(w = w))
inits4 <- list(
  list(alpha = rep( 0, nsites), beta = 0.5, sigma = 50, sigma_alpha = 10,
       kappa = 0.5, eta = 0.2),
  list(alpha = rep( 1, nsites), beta = 1.5, sigma = 10, sigma_alpha = 20,
       kappa = 0.7, eta = 0.3),
  list(alpha = rep(-1, nsites), beta = 0.75,sigma = 20, sigma_alpha = 12,
       kappa = 0.3, eta = 0.1)
)
samples4 <- nimbleMCMC(mod4, constants = const4, data = data2, inits = inits4,
                       monitors = c("alpha", "beta", "sigma",
                                    "kappa", "eta", "sigma_alpha"),
                       nchains = 3, niter = 10000, nburnin = 1000,
                       samplesAsCodaMCMC = TRUE)
MCMCsummary(samples4, params = c("beta", "sigma", "kappa", "eta", "sigma_alpha"))

# =============================================================================
# MODEL 5: RANDOM INTERCEPT + RANDOM SLOPE (slope varies by fertilizer)
# =============================================================================
mod5 <- nimbleCode({
  kappa ~ dnorm(0, 1/10000)
  eta   ~ dnorm(0, 1/10000)
  sigma_alpha ~ dunif(0, 100); tau_alpha <- 1 / sigma_alpha^2
  sigma_beta  ~ dunif(0, 100); tau_beta  <- 1 / sigma_beta^2
  mu_beta ~ dnorm(0, 1/10000)
  sigma   ~ dunif(0, 100);     tau       <- 1 / sigma^2

  for (k in 1:n.ferts) {
    beta[k] ~ dnorm(mu_beta, tau_beta)         # random slope by fertilizer
  }
  for (j in 1:n.sites) {
    mu_alpha[j] <- kappa + eta * w[j]
    alpha[j]    ~ dnorm(mu_alpha[j], tau_alpha)
  }
  for (i in 1:n) {
    mu[i] <- alpha[group[i]] + beta[fertilizer[i]] * x[i]
    y[i]  ~ dnorm(mu[i], tau)
  }
})

const5 <- list(n = nobs, x = x,
               n.sites = nsites, n.ferts = nferts,
               group = group, fertilizer = fert, w = w)
inits5 <- list(
  list(alpha = rep( 0, nsites), beta = rep(0, nferts), sigma = 50,
       sigma_alpha = 10, sigma_beta = 0.2, mu_beta = 0.1,
       kappa = 0.5, eta = 0.2),
  list(alpha = rep( 1, nsites), beta = rep(2, nferts), sigma = 10,
       sigma_alpha = 20, sigma_beta = 0.1, mu_beta = 0.3,
       kappa = 0.7, eta = 0.3),
  list(alpha = rep(-1, nsites), beta = rep(1, nferts), sigma = 20,
       sigma_alpha = 12, sigma_beta = 0.3, mu_beta = -0.5,
       kappa = 0.3, eta = 0.1)
)
samples5 <- nimbleMCMC(mod5, constants = const5, data = data2, inits = inits5,
                       monitors = c("alpha", "beta", "sigma", "kappa", "eta",
                                    "mu_beta", "sigma_beta", "sigma_alpha"),
                       nchains = 3, niter = 10000, nburnin = 1000,
                       samplesAsCodaMCMC = TRUE)
MCMCsummary(samples5, params = c("beta", "mu_beta", "sigma_beta",
                                 "kappa", "eta", "sigma_alpha", "sigma"))

MCMCplot(samples5, params = "beta", horiz = FALSE,
         main = "Fertilizer-specific slopes (random slopes)")
MCMCplot(samples5, params = "alpha", horiz = FALSE,
         main = "Site-specific intercepts (random intercept + covariate)")

# =============================================================================
# Teaching takeaways
# =============================================================================
# - Complete pooling assumes one alpha for everyone; no pooling assumes every
#   site is its own universe. Partial pooling is the principled middle ground.
# - The hierarchical prior alpha[j] ~ Normal(mu_alpha, sigma_alpha) is what
#   creates SHRINKAGE: extreme per-site estimates are pulled toward mu_alpha,
#   especially for sites with little data.
# - You can model the random-intercept's MEAN with a covariate (kappa + eta*w[j])
#   without throwing away the hierarchical structure -- this is "group-level
#   regression" and is one of the most useful patterns in applied Bayes.
# - Random slopes generalise the same trick to coefficients other than the
#   intercept.
# =============================================================================
