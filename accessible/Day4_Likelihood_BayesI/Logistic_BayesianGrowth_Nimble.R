# ==============================================================================
# Logistic_BayesianGrowth_Nimble.R
# ------------------------------------------------------------------------------
# FW599 - Day 4 (Bayesian I, Afternoon)
#
# Bayesian fit of the logistic growth model
#
#     dN/dt = r * N * (1 - N/K)
#
# expressed in per-capita form
#
#     (1/N) * dN/dt = r - (r/K) * N
#
# so that the (per-capita) growth rate y = (1/N)*dN/dt is a LINEAR function of
# population size N with intercept r and slope -r/K. The observed per-capita
# growth rate is modeled as
#
#     y[i] ~ Normal( r - (r/K) * x[i], sigma )
#
# We translate the original JAGS code (Jags_logistic_rK_Lab1.R) into NIMBLE.
# The biological model is IDENTICAL. What changes is:
#
#   * the model is defined inside `nimbleCode({...})` instead of being written
#     to a text file and read back by `jags.model()`,
#   * data are split into TWO lists: `constants` (sizes, indices, predictors
#     that are NOT random variables) and `data` (observed random variables),
#   * `nimbleMCMC(...)` replaces the jags.model + update + coda.samples trio,
#   * the body of the model (priors, likelihood, derived quantities) is the
#     SAME, including BUGS-style precision (tau = 1/sigma^2) in dnorm.
#
# Heavily commented for graduate students seeing NIMBLE for the first time.
# ==============================================================================

# ---- 0. Packages -------------------------------------------------------------
# nimble       : core MCMC engine (compiles model + samplers)
# MCMCvis      : works directly with nimble output - summaries, trace, chains
# HDInterval   : highest posterior density intervals (HPDI)
# coda         : the mcmc.list class (nimble can return it; MCMCvis expects it)
library(nimble)
library(MCMCvis)
library(HDInterval)
library(coda)

# Optional, used in the original Nimble script
# library(basicMCMCplots)

# ---- 1. Read the data --------------------------------------------------------
# The CSV has two columns: PopulationSize (N) and GrowthRate (per-capita 1/yr).
# Data file lives in the data/ subfolder of this Day's directory.
Logistic <- read.csv("data/Logistic.csv", header = TRUE)

# Sort by population size so that "lines(x, ...)" plots later actually draw
# a line, not a tangled scribble.
Logistic <- Logistic[order(Logistic$PopulationSize), ]

# A vector of population sizes at which we'll evaluate dN/dt for plotting.
# We include this AS DATA (a constant) so Nimble can compute dNdt[j] for j=1..length(N).
N_grid <- seq(0, 1500, by = 10)
N_grid[1] <- 1   # avoid plotting at exactly zero

# ---- 2. The Nimble model code ------------------------------------------------
# `nimbleCode({ ... })` returns an unevaluated BUGS-style model. The body is
# IDENTICAL to the JAGS version - same distribution names, same precision
# parameterization (dnorm uses tau = 1/sigma^2), same loops.
logistic_code <- nimbleCode({

  # ---- priors --------------------------------------------------------------
  # Flat priors on biological scales we believe are wide enough to contain the truth.
  K     ~ dunif(0, 4000)   # carrying capacity (individuals)
  r     ~ dunif(0, 2)      # intrinsic per-capita growth rate (1/yr)
  sigma ~ dunif(0, 2)      # observation SD on per-capita growth rate
  tau  <- 1 / sigma^2      # BUGS-style precision for dnorm

  # ---- likelihood ----------------------------------------------------------
  # n observations of per-capita growth rate y[i] at population size x[i].
  for (i in 1:n) {
    mu[i] <- r - (r / K) * x[i]
    y[i]  ~ dnorm(mu[i], tau)
  }

  # ---- derived quantities --------------------------------------------------
  # Any deterministic function of monitored random variables becomes a
  # random variable with its own posterior. This is one of the great
  # advantages of Bayesian / MCMC inference.
  N_at_maxdNdt <- K / 2          # population size where dN/dt is maximized
  MSY          <- r * K / 4      # maximum sustainable yield (logistic theory)

  # Population-level growth rate over a grid of N values, for plotting.
  for (j in 1:nN) {
    dNdt[j] <- r * N[j] * (1 - N[j] / K)
  }
})

# ---- 3. Constants vs. data ---------------------------------------------------
# Nimble distinguishes:
#   * constants : everything that defines the SHAPE of the model and is NOT
#                 itself a random variable (sample sizes, loop bounds, fixed
#                 covariates, prediction grids).
#   * data      : the observed values of stochastic nodes (the y[i]'s here).
#
# JAGS lumps both into a single `data` list. The split is a minor source of
# confusion for JAGS users; just remember "anything that appears on the LHS
# of `~` and was actually observed is data; everything else is a constant".
constants <- list(
  n  = nrow(Logistic),
  x  = as.double(Logistic$PopulationSize),
  N  = N_grid,
  nN = length(N_grid)
)

data <- list(
  y = as.double(Logistic$GrowthRate)
)

# ---- 4. Initial values for 3 chains ------------------------------------------
# Always run multiple chains from DIFFERENT starts to assess convergence.
# Each chain's inits is a named list; the outer list is one entry per chain.
inits_list <- list(
  list(K = 1500, r = 0.20, sigma = 1.0),
  list(K = 1000, r = 0.15, sigma = 0.1),
  list(K =  900, r = 0.30, sigma = 0.01)
)

# ---- 5. Run MCMC -------------------------------------------------------------
# `nimbleMCMC` does everything in one call: build the model, configure default
# samplers, compile, run, return samples. For more control (custom samplers,
# WAIC, etc.) you'd use nimbleModel() -> configureMCMC() -> buildMCMC() ->
# compileNimble() -> runMCMC().
#
# monitors  : which nodes to save posterior samples for
# nchains   : number of independent chains
# nburnin   : iterations discarded at the start of each chain
# niter     : TOTAL iterations per chain (including burn-in)
# thin      : keep every `thin`-th sample (1 = keep all)
# samplesAsCodaMCMC : return as coda mcmc.list so MCMCvis works directly
set.seed(10)
samples <- nimbleMCMC(
  code      = logistic_code,
  constants = constants,
  data      = data,
  inits     = inits_list,
  monitors  = c("K", "r", "sigma", "tau", "mu",
                "N_at_maxdNdt", "MSY", "dNdt"),
  nchains   = 3,
  nburnin   = 5000,
  niter     = 25000,
  thin      = 1,
  samplesAsCodaMCMC = TRUE
)

# ---- 6. Diagnostics ----------------------------------------------------------
# Trace plots + density estimates for the four main parameters.
# Look for: (a) chains overlapping, (b) caterpillar-like trace with no trend.
MCMCtrace(samples,
          params = c("K", "r", "sigma"),
          pdf    = FALSE,
          Rhat   = TRUE,
          n.eff  = TRUE)

# Numerical summary table - posterior mean/median, SD, 95% BCI, Rhat, n.eff.
MCMCsummary(samples, params = c("K", "r", "sigma", "N_at_maxdNdt", "MSY"),
            round = 3)

# ---- 7. Posterior predictive plot --------------------------------------------
# For each observed x[i], extract the posterior of mu[i] and plot:
#   * the data points,
#   * the posterior median of mu (solid line),
#   * 95% equal-tailed Bayesian credible interval (BCI) in red dashed,
#   * 95% highest-posterior-density interval (HPDI) in blue dashed.
BCI  <- MCMCpstr(samples, params = "mu",
                 func = function(x) quantile(x, c(.025, .50, .975)))
HPDI <- MCMCpstr(samples, params = "mu",
                 func = function(x) hdi(x, .95))

plot(constants$x, data$y, pch = 19,
     xlab = "Population size N",
     ylab = "Per-capita growth rate (1/yr)",
     main = "Logistic per-capita growth: posterior fit")
lines(constants$x, BCI$mu[, 2], lwd = 2)
lines(constants$x, BCI$mu[, 1], lty = "dashed", col = "red")
lines(constants$x, BCI$mu[, 3], lty = "dashed", col = "red")
lines(constants$x, HPDI$mu[, 1], lty = "dashed", col = "blue")
lines(constants$x, HPDI$mu[, 2], lty = "dashed", col = "blue")
legend("topright", lty = c(1, 2, 2), col = c("black", "red", "blue"),
       legend = c("Median", "95% BCI", "95% HPDI"), bty = "n", cex = 0.85)

# ---- 8. Posterior of derived quantities --------------------------------------
N_at_maxdNdt_chain <- MCMCchains(samples, params = "N_at_maxdNdt")
MSY_chain          <- MCMCchains(samples, params = "MSY")

par(mfrow = c(1, 2))
plot(density(N_at_maxdNdt_chain), main = "N at max dN/dt",
     xlab = "Population size", ylab = "Posterior density")
rug(N_at_maxdNdt_chain[sample(length(N_at_maxdNdt_chain), 1000)], col = "red")

plot(density(MSY_chain), main = "Maximum sustainable yield",
     xlab = "MSY", ylab = "Posterior density")
rug(MSY_chain[sample(length(MSY_chain), 1000)], col = "red")
par(mfrow = c(1, 1))

# ---- 9. Population-level growth curve ----------------------------------------
# Posterior median and 95% HPDI of dN/dt as a function of N.
HPDI_dNdt <- MCMCpstr(samples, params = "dNdt",
                      func = function(x) hdi(x, .95))
med_dNdt  <- MCMCpstr(samples, params = "dNdt", func = median)

plot(N_grid, med_dNdt$dNdt, type = "l", lwd = 2,
     xlab = "Population size N", ylab = "Population growth rate dN/dt",
     ylim = c(-40, 80),
     main = "Posterior median (and 95% HPDI) of dN/dt vs N")
abline(h = 0, col = "grey")
lines(N_grid, HPDI_dNdt$dNdt[, 1], lty = "dashed")
lines(N_grid, HPDI_dNdt$dNdt[, 2], lty = "dashed")

# ---- 10. Direct posterior probabilities --------------------------------------
# One of the great strengths of Bayes: any tail probability is a simple
# operation on the posterior draws.
r_chain <- MCMCchains(samples, params = "r")

prob_r_gt_022 <- mean(r_chain > 0.22)
prob_r_in_18_22 <- mean(r_chain > 0.18 & r_chain < 0.22)

cat("P(r > 0.22 | data) =", round(prob_r_gt_022, 3), "\n")
cat("P(0.18 < r < 0.22 | data) =", round(prob_r_in_18_22, 3), "\n")

# Compare BCI vs HPDI on sigma to make the asymmetric-posterior point.
sigma_chain <- MCMCchains(samples, params = "sigma")
hist(sigma_chain, breaks = 80, freq = FALSE,
     xlab = expression(sigma), main = "Posterior of sigma: BCI (red) vs HPDI (blue)")
abline(v = quantile(sigma_chain, c(.025, .975)), col = "red", lwd = 2)
abline(v = hdi(sigma_chain, .95),                col = "blue", lwd = 2)

# ==============================================================================
# End of file.
# ==============================================================================
