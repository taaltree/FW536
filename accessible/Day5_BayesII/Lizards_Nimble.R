# =============================================================================
# Lizards_Nimble.R
# -----------------------------------------------------------------------------
# Bayesian logistic regression: island lizard occupancy ~ perimeter:area ratio.
#
# What this script teaches:
#   1. Translating a JAGS model into nimbleCode()
#   2. Splitting JAGS' single `data=` list into nimble's `constants=` (sizes,
#      indices, fixed covariate grids) and `data=` (observed random variables).
#   3. The "init gotcha" of logistic regression: bad starts on the logit scale
#      can yield p = 0 or p = 1, making the likelihood numerically singular.
#   4. Convergence diagnostics with coda (gelman.diag, heidel.diag).
#   5. Prediction onto a regular x-grid for plotting the fitted curve.
#   6. Re-fitting with a *tighter* prior dnorm(0, 1/2.71) and comparing the
#      posterior to the vague-prior fit.
#
# Data: IslandsLizards.csv (columns: presence {0,1}, perimeterAreaRatio).
# The CSV should be co-located with this script.
#
# Author: FW 536 (Day 5 — Bayes II), Oregon State University.
# =============================================================================

# ----- Packages -------------------------------------------------------------
library(nimble)     # Bayesian model fitting
library(MCMCvis)    # MCMCsummary / MCMCtrace / MCMCpstr / MCMCplot
library(coda)       # gelman.diag, heidel.diag
library(HDInterval) # hdi() for highest-density intervals

# ----- Read data ------------------------------------------------------------
# Data file lives in the data/ subfolder of this Day's directory.
liz <- read.csv("data/IslandsLizards.csv")
str(liz)
table(liz$presence)

# Standardise the predictor (perimeterAreaRatio).
# Centering+scaling avoids weak identifiability between intercept and slope
# and lets us put sensible priors on the same scale for both.
x.scaled <- as.numeric(scale(liz$perimeterAreaRatio))

# A regular grid in scaled units for posterior prediction (plot the curve).
x.grid <- seq(-2, 2, by = 0.01)

# Targets for "what is P(presence) at PA = 10 vs 20?" (raw scale).
x10 <- (10 - mean(liz$perimeterAreaRatio)) / sd(liz$perimeterAreaRatio)
x20 <- (20 - mean(liz$perimeterAreaRatio)) / sd(liz$perimeterAreaRatio)

# =============================================================================
# Model 1: VAGUE prior (sigma = 1000 on logit scale)
# =============================================================================
# Body translates verbatim from the JAGS model in lizzard.R.
# Note: dnorm is parameterised by precision (tau = 1/sigma^2), like JAGS.
lizardCode <- nimbleCode({
  # Priors (vague)
  a ~ dnorm(0, 1e-6)   # intercept on logit scale
  b ~ dnorm(0, 1e-6)   # slope on logit scale

  # Likelihood
  for (i in 1:n) {
    logit(p[i]) <- a + b * x[i]
    y[i] ~ dbern(p[i])
  }

  # Derived: prediction onto x.grid for plotting
  for (j in 1:ngrid) {
    p.out[j] <- ilogit(a + b * x.grid[j])
  }
})

# Split JAGS-style data into constants + data
constants <- list(
  n     = nrow(liz),
  ngrid = length(x.grid),
  x     = x.scaled,    # fixed covariate
  x.grid = x.grid      # fixed prediction grid
)
data <- list(
  y = as.integer(liz$presence)  # observed random variable
)

# Init gotcha: do NOT use random starts that would produce p = 0 or p = 1
# for any observation. A clean pattern is small absolute starting values.
inits <- list(
  list(a = 0.0, b =  0.0),
  list(a = 1.0, b = -1.0),
  list(a = -1.0, b =  0.5)
)

# Fit with nimbleMCMC (the friendly one-liner).
# For latent-state models we'll show the longer nimbleModel/configureMCMC dance.
samples1 <- nimbleMCMC(
  code      = lizardCode,
  constants = constants,
  data      = data,
  inits     = inits,
  monitors  = c("a", "b", "p", "p.out"),
  nchains   = 3,
  nburnin   = 1000,
  niter     = 6000,
  samplesAsCodaMCMC = TRUE   # so coda diagnostics work
)

# ----- Convergence diagnostics --------------------------------------------
MCMCsummary(samples1, params = c("a", "b"))
MCMCtrace(samples1, params = c("a", "b"), pdf = FALSE)

gelman.diag(samples1[, c("a", "b")])     # R-hat should be <= 1.05
heidel.diag(samples1[, c("a", "b")])     # stationarity / halfwidth checks

# ----- Inference & plotting -----------------------------------------------
# Posterior median + 95% interval for p across the grid:
p.out.summary <- MCMCpstr(samples1, params = "p.out",
                          func = function(x) quantile(x, c(0.025, 0.5, 0.975)))$p.out

plot(liz$perimeterAreaRatio, liz$presence,
     xlab = "Perimeter:area ratio", ylab = "Presence",
     main = "Vague prior — fitted occupancy curve")
# Back-transform the grid to raw units for plotting
x.grid.raw <- x.grid * sd(liz$perimeterAreaRatio) + mean(liz$perimeterAreaRatio)
lines(x.grid.raw, p.out.summary[, 2], lwd = 2)
lines(x.grid.raw, p.out.summary[, 1], lty = 2)
lines(x.grid.raw, p.out.summary[, 3], lty = 2)

# =============================================================================
# Model 2: TIGHTER prior — dnorm(0, 1/2.71)
# =============================================================================
# Why this prior?  precision = 1/2.71  =>  sigma ~ 1.65 on the logit scale.
# A standard-normal-ish prior on (a, b) implies most of the implied prior
# probability on p is spread sensibly over (0,1) rather than piled at 0 or 1.
# Compare to the vague prior with sigma = 1000, which on the logit scale
# becomes effectively Bernoulli(p ~ {0, 1}) when back-transformed.
#
# We also compute two derived quantities of management interest:
#   y10 = P(presence | PA = 10),  y20 = P(presence | PA = 20),
#   diff = y20 - y10  (probability change between two raw-scale conditions).

lizardCode2 <- nimbleCode({
  # Tighter priors on logit scale
  a ~ dnorm(0, 1 / 2.71)
  b ~ dnorm(0, 1 / 2.71)

  for (i in 1:n) {
    logit(p[i]) <- a + b * x[i]
    y[i] ~ dbern(p[i])
  }
  for (j in 1:ngrid) {
    p.out[j] <- ilogit(a + b * x.grid[j])
  }

  # Derived quantities at two specific PA values
  y10  <- ilogit(a + b * x10)
  y20  <- ilogit(a + b * x20)
  diff <- y20 - y10
})

constants2 <- c(constants, list(x10 = x10, x20 = x20))

samples2 <- nimbleMCMC(
  code      = lizardCode2,
  constants = constants2,
  data      = data,
  inits     = inits,
  monitors  = c("a", "b", "p.out", "y10", "y20", "diff"),
  nchains   = 3,
  nburnin   = 1000,
  niter     = 6000,
  samplesAsCodaMCMC = TRUE
)

MCMCsummary(samples2, params = c("a", "b", "y10", "y20", "diff"))

# Compare posterior densities of slope b under the two priors:
b1 <- as.matrix(samples1)[, "b"]
b2 <- as.matrix(samples2)[, "b"]
plot(density(b1), main = "Slope b: vague vs. tight prior",
     xlab = "b (logit-scale slope)", lwd = 2)
lines(density(b2), col = "red", lwd = 2)
legend("topright", legend = c("dnorm(0, 1e-6)", "dnorm(0, 1/2.71)"),
       col = c("black", "red"), lwd = 2)

# 95% HDI on the management-relevant difference:
hdi(as.matrix(samples2)[, "diff"], credMass = 0.95)

# =============================================================================
# Teaching takeaways
# =============================================================================
# - JAGS -> NIMBLE conversion is mostly mechanical: same distributions (with the
#   precision parameterisation), same logit/ilogit assignments.
# - The non-mechanical piece is splitting `data` into `constants` (anything that
#   doesn't appear on the LHS of `~`) and `data` (the random variables).
# - Vague priors on a link scale (here logit) are NOT noninformative; they place
#   most prior mass near p = 0 or 1. Tighter priors like dnorm(0, 1/2.71) are
#   nearly flat on the probability scale, which is what students usually intend.
# =============================================================================
