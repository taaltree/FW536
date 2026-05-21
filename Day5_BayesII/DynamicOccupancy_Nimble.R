# =============================================================================
# DynamicOccupancy_Nimble.R
# -----------------------------------------------------------------------------
# Dynamic (multi-season) occupancy model in NIMBLE.
#   - Sites i = 1..Nsites
#   - Years  t = 1..Nyears
#   - Replicate visits j = 1..Nreps within each (site, year)
#
# Latent process model:
#   z[i, 1] ~ Bernoulli(psi)
#   z[i, t] ~ Bernoulli(z[i,t-1]*phi[t-1] + (1-z[i,t-1])*gamma[t-1])
# where phi[t]   = patch persistence (year t -> t+1 if currently occupied)
#       gamma[t] = patch colonization (year t -> t+1 if currently empty)
#
# Observation model:
#   y[i, j, t] ~ Bernoulli(z[i, t] * p)
#
# Derived ecology:
#   psi.t[t] = expected occupancy in year t
#   tau[t-1] = turnover (fraction of occupied sites that are NEW colonisers)
#   eq[t]    = colonization-extinction equilibrium occupancy
#
# What this script teaches:
#   1. Simulating data from a dynamic occupancy model.
#   2. Translating the JAGS model to nimbleCode().
#   3. The "z initialization trick": initialize the entire latent z matrix
#      at 1 so that y == 1 observations are never impossible (otherwise the
#      sampler is stuck with log-density = -Inf).
#   4. Using `monitors` to track latent occupancy across years.
#   5. Comparing recovered (phi, gamma) to truth.
#
# Author: FW599 Enhanced (Day 5 — Bayes II), Oregon State University.
# =============================================================================

# ----- Packages -------------------------------------------------------------
library(nimble)
library(MCMCvis)
library(coda)

set.seed(2025)

# =============================================================================
# 1. Simulate truth
# =============================================================================
Nyears <- 8
Nsites <- 30
Nreps  <- 3       # site visits per year
p.true <- 0.6     # detection probability per visit

# True latent occupancy z[i, t]
z <- matrix(NA_integer_, nrow = Nsites, ncol = Nyears)
z[, 1] <- rbinom(Nsites, 1, 0.3)   # baseline occupancy psi = 0.3

phi.true   <- rbeta(Nyears - 1, 2, 5)  # persistence each transition
gamma.true <- rbeta(Nyears - 1, 3, 3)  # colonization each transition

for (i in 1:Nsites) {
  for (t in 2:Nyears) {
    mu.z   <- z[i, t - 1] * phi.true[t - 1] +
              (1 - z[i, t - 1]) * gamma.true[t - 1]
    z[i, t] <- rbinom(1, 1, mu.z)
  }
}

# Observed detections y[i, j, t]
y <- array(NA_integer_, dim = c(Nsites, Nreps, Nyears))
for (t in 1:Nyears) for (i in 1:Nsites) for (j in 1:Nreps) {
  y[i, j, t] <- rbinom(1, 1, p.true) * z[i, t]
}

# =============================================================================
# 2. NIMBLE model
# =============================================================================
DynOccCode <- nimbleCode({

  # ----- Process model --------------------------------------------------
  for (i in 1:Nsites) {
    z[i, 1] ~ dbern(psi)
    for (t in 2:Nyears) {
      muZ[i, t] <- z[i, t - 1] * phi[t - 1] +
                   (1 - z[i, t - 1]) * gamma[t - 1]
      z[i, t]   ~ dbern(muZ[i, t])
    }
  }

  # ----- Observation model ---------------------------------------------
  for (t in 1:Nyears) {
    for (i in 1:Nsites) {
      for (j in 1:Nreps) {
        Py[i, j, t]  <- z[i, t] * p   # 0 if site empty, else p
        y[i, j, t]   ~ dbern(Py[i, j, t])
      }
    }
  }

  # ----- Derived ecology ------------------------------------------------
  psi.t[1] <- psi
  for (t in 2:Nyears) {
    psi.t[t] <- psi.t[t - 1] * phi[t - 1] +
                (1 - psi.t[t - 1]) * gamma[t - 1]
    tau[t - 1] <- (gamma[t - 1] * (1 - psi.t[t - 1])) /
                  (gamma[t - 1] * (1 - psi.t[t - 1]) +
                     phi[t - 1] * psi.t[t - 1])
    eq[t]      <- gamma[t - 1] / (gamma[t - 1] + (1 - phi[t - 1]))
  }

  # ----- Priors ---------------------------------------------------------
  psi ~ dunif(0, 1)
  p   ~ dunif(0, 1)
  for (t in 1:(Nyears - 1)) {
    gamma[t] ~ dunif(0, 1)
    phi[t]   ~ dunif(0, 1)
  }
})

# Constants: integers, indices, sizes
constants <- list(
  Nsites = Nsites,
  Nreps  = Nreps,
  Nyears = Nyears
)

# Data: the observed random variables
data <- list(
  y = y
)

# =============================================================================
# 3. The z-initialization trick (READ THIS)
# =============================================================================
# If any y[i, j, t] = 1, then z[i, t] must be 1 (because P(y=1 | z=0) = 0).
# Random initial z values risk z = 0 where y = 1, which gives log-density
# = -Inf and the MCMC will refuse to start. The classic safe trick:
#
#     z.init <- matrix(1, Nsites, Nyears)   # ALL z = 1
#
# This guarantees consistency with all observed 1's. The sampler will quickly
# learn (from the data) that some sites/years are actually empty.
zst <- matrix(1L, nrow = Nsites, ncol = Nyears)

init.fun <- function() {
  list(
    z     = zst,
    phi   = runif(Nyears - 1, 0.1, 0.9),
    gamma = runif(Nyears - 1, 0.1, 0.9),
    p     = runif(1, 0.3, 0.9),
    psi   = runif(1, 0.2, 0.6)
  )
}
inits <- list(init.fun(), init.fun(), init.fun())

# =============================================================================
# 4. Fit
# =============================================================================
samples <- nimbleMCMC(
  code      = DynOccCode,
  constants = constants,
  data      = data,
  inits     = inits,
  monitors  = c("phi", "gamma", "p", "psi", "psi.t", "tau", "eq"),
  nchains   = 3,
  niter     = 20000,
  nburnin   = 10000,
  thin      = 5,
  samplesAsCodaMCMC = TRUE
)

MCMCsummary(samples, params = c("phi", "gamma", "p", "psi"), round = 3)

# =============================================================================
# 5. Compare to truth
# =============================================================================
phi.post   <- MCMCpstr(samples, params = "phi",   func = median)$phi
gamma.post <- MCMCpstr(samples, params = "gamma", func = median)$gamma
psi.t.post <- MCMCpstr(samples, params = "psi.t", func = median)$psi.t

par(mfrow = c(1, 3))
plot(phi.true, phi.post, pch = 19, xlim = c(0,1), ylim = c(0,1),
     xlab = "True phi", ylab = "Posterior median phi"); abline(0,1,col=2)
plot(gamma.true, gamma.post, pch = 19, xlim = c(0,1), ylim = c(0,1),
     xlab = "True gamma", ylab = "Posterior median gamma"); abline(0,1,col=2)
plot(colMeans(z), psi.t.post, pch = 19, xlim = c(0,1), ylim = c(0,1),
     xlab = "True occupancy each year", ylab = "Posterior median psi.t");
abline(0,1,col=2)
par(mfrow = c(1, 1))

# =============================================================================
# Teaching takeaways
# =============================================================================
# - Latent-state models separate two layers: process (z) and observation (y).
# - The z initialization trick is THE most common reason a nimble dynamic-
#   occupancy model "won't start". Always initialize z = 1 everywhere.
# - With only 30 sites, 8 years, and 3 visits, year-specific phi/gamma have
#   huge posterior intervals -- that's a feature, not a bug. Bayes is being
#   honest about what such a small dataset actually tells you.
# =============================================================================
