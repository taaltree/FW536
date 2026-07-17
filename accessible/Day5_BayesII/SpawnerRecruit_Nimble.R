# =============================================================================
# SpawnerRecruit_Nimble.R
# -----------------------------------------------------------------------------
# Beverton-Holt spawner-recruit analysis in NIMBLE.
#
# What this script teaches:
#   1. Simulating a 20-year spawner-recruit dataset under a known process.
#   2. Translating the JAGS Beverton-Holt model to nimbleCode().
#   3. Defining DERIVED quantities of management interest inside the model:
#        Neq  = equilibrium population size
#        Smsy = spawners that produce maximum sustainable yield
#        Hmsy = harvest rate at MSY
#   4. Letting MCMC propagate parameter uncertainty into the derived
#      management quantities for free.
#   5. Posterior predictive plotting of the fitted curve through the data.
#
# This is THE classic Bayesian sales pitch for fisheries: uncertainty in
# (a, b) flows naturally into uncertainty in Smsy and Hmsy.
#
# Author: FW 536 (Day 5 — Bayes II), Oregon State University.
# =============================================================================

# ----- Packages -------------------------------------------------------------
library(nimble)
library(MCMCvis)
library(coda)
library(HDInterval)

set.seed(2025)

# =============================================================================
# 1. Simulate "truth" so we know what we're trying to recover
# =============================================================================
# Beverton-Holt:  R = (a * S) / (1 + (a / b) * S)
#   a = intrinsic productivity at low spawners (recruits per spawner)
#   b = asymptotic recruitment (the ceiling as S -> infinity)
a.true     <- 5      # intrinsic productivity
b.true     <- 5000   # asymptote
Nyears     <- 20
sigma.true <- 0.2    # SD of lognormal multiplicative error on R

# Lognormal spawner abundances over 20 years
S <- rlnorm(Nyears, meanlog = 7.5, sdlog = 0.8)

# Generate recruits with lognormal process noise
R <- numeric(Nyears)
for (t in 1:Nyears) {
  mu.R <- (a.true * S[t]) / (1 + (a.true / b.true) * S[t])
  R[t] <- mu.R * exp(rnorm(1, mean = 0, sd = sigma.true))
}

plot(S, R, xlim = c(0, max(c(R, S))), ylim = c(0, max(c(R, S))),
     pch = 19, xlab = "Spawners", ylab = "Recruits",
     main = "Simulated Beverton-Holt data")
abline(0, 1, col = "blue", lwd = 2)             # replacement line
curve((a.true * x) / (1 + (a.true / b.true) * x),
      add = TRUE, lwd = 2)

# =============================================================================
# 2. Beverton-Holt model in NIMBLE
# =============================================================================
# Likelihood is on the log scale (lognormal observation noise on R).
# Note dnorm in nimble is parameterised by precision (tau = 1/sigma^2).
BHcode <- nimbleCode({

  # ----- Likelihood ------------------------------------------------------
  for (t in 1:Nyears) {
    # Deterministic BH expectation, taken to log scale
    log.mu[t] <- log(a) + log(S[t]) - log(1 + (a / b) * S[t])
    log.R[t]  ~ dnorm(log.mu[t], tau)
  }

  # ----- Priors ---------------------------------------------------------
  a     ~ dunif(1, 10)          # productivity
  b     ~ dunif(1000, 10000)    # asymptote
  sigma ~ dunif(0, 1)           # process SD
  tau  <- 1 / (sigma * sigma)   # precision used by dnorm

  # ----- Derived management quantities ----------------------------------
  # These are deterministic functions of (a, b), so uncertainty in (a, b)
  # propagates automatically into the posterior of each.
  Neq  <- b * (a - 1) / a
  Smsy <- b * sqrt(1 / a) - b / a
  Hmsy <- 1 - sqrt(1 / a)
})

# Split into constants vs. data
# In JAGS we'd have one big `data=` list. Here:
#   - Nyears and S (covariates) are constants (no `~`)
#   - log.R (observed RV) is data
constants <- list(
  Nyears = Nyears,
  S      = S
)
data <- list(
  log.R = log(R)
)

# Initial values for each chain
inits <- list(
  list(a = 3, b = 4000, sigma = 0.3),
  list(a = 5, b = 6000, sigma = 0.2),
  list(a = 7, b = 8000, sigma = 0.1)
)

# Run MCMC
samples <- nimbleMCMC(
  code      = BHcode,
  constants = constants,
  data      = data,
  inits     = inits,
  monitors  = c("a", "b", "sigma", "Neq", "Smsy", "Hmsy"),
  nchains   = 3,
  niter     = 10000,
  nburnin   = 1000,
  thin      = 1,
  samplesAsCodaMCMC = TRUE
)

# =============================================================================
# 3. Inspect & summarise
# =============================================================================
MCMCsummary(samples, round = 3)
MCMCtrace(samples, params = c("a", "b", "sigma"), pdf = FALSE)

# R-hat / effective sample size
gelman.diag(samples)
effectiveSize(samples)

# =============================================================================
# 4. Posterior-predictive curve through data
# =============================================================================
post <- as.matrix(samples)
Sx   <- seq(1, max(S), length.out = 200)

# Build a posterior distribution of BH curves
n.draw <- 500
draws  <- post[sample(seq_len(nrow(post)), n.draw), c("a", "b")]
curves <- sapply(seq_len(n.draw), function(k) {
  ak <- draws[k, "a"]; bk <- draws[k, "b"]
  (ak * Sx) / (1 + (ak / bk) * Sx)
})

med <- apply(curves, 1, median)
lo  <- apply(curves, 1, quantile, 0.025)
hi  <- apply(curves, 1, quantile, 0.975)

plot(S, R, pch = 19, xlim = c(0, max(c(S, R))),
     ylim = c(0, max(c(S, R, hi))),
     xlab = "Spawners", ylab = "Recruits",
     main = "Posterior median (line) + 95% CI (shading)")
polygon(c(Sx, rev(Sx)), c(lo, rev(hi)),
        col = rgb(0, 0, 1, 0.15), border = NA)
lines(Sx, med, lwd = 2, col = "blue")
abline(0, 1, col = "red", lwd = 1, lty = 2)  # 1:1 replacement line

# =============================================================================
# 5. Management quantities with uncertainty
# =============================================================================
mgt <- post[, c("Neq", "Smsy", "Hmsy")]
apply(mgt, 2, function(z) c(median = median(z), hdi(z, 0.95)))

par(mfrow = c(1, 3))
hist(mgt[, "Neq"],  main = "Neq (equilibrium pop)", xlab = "Neq",  col = "grey80")
hist(mgt[, "Smsy"], main = "Smsy",                  xlab = "Smsy", col = "grey80")
hist(mgt[, "Hmsy"], main = "Hmsy (MSY harvest rate)",xlab = "Hmsy", col = "grey80")
par(mfrow = c(1, 1))

# =============================================================================
# Teaching takeaways
# =============================================================================
# - Defining Neq/Smsy/Hmsy *inside* the model (between priors and the closing
#   brace) means nimble tracks them at every MCMC iteration. Their posteriors
#   automatically inherit uncertainty from (a, b). No delta-method needed.
# - This is the central Bayesian advantage for fisheries management: any
#   function of parameters has an honest, fully propagated uncertainty.
# - Compare to a maximum-likelihood fit: you'd need bootstrap or delta-method
#   approximations to get the same uncertainty bands.
# =============================================================================
