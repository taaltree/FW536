##############################################
# Lab: Understanding Interaction Terms in R  #
##############################################

# Load packages
library(ggplot2)
library(dplyr)
library(tidyr)
library(plotly)

set.seed(123)

#############################################
# Part 1: No interaction is present?
#############################################

data2 <- data.frame(
  x1 = runif(200, -2, 2),
  x2 = runif(200, -2, 2)
)
data2$y <- 1 + 1.5*data2$x1 - 1*data2$x2 + rnorm(200, 0, 1)

m2 <- lm(y ~ x1 * x2, data = data2)
summary(m2)

# Visualize heatmap
grid2 <- expand.grid(x1 = seq(-2, 2, length=50),
                     x2 = seq(-2, 2, length=50))
grid2$yhat <- predict(m2, newdata=grid2)
zmat <- matrix(grid2$yhat, nrow = 50, ncol = 50)

p3 <- ggplot(grid2, aes(x1, x2, fill=yhat)) +
  geom_tile() +
  scale_fill_viridis_c() +
  labs(title="Heatmap of Predicted y (no true interaction)")

p3



# 3D interactive surface plot
p4 <- plot_ly(
  x = seq(-2, 2, length = 50),
  y = seq(-2, 2, length = 50),
  z = zmat,
  type = "surface"
) %>%
  layout(
    title = list(text = "3D Surface: y ~ x1 + x2"),
    scene = list(
      xaxis = list(title = "x1", range = c(-2, 2)),
      yaxis = list(title = "x2", range = c(-2, 2)),
      zaxis = list(title = "yhat")
    )
  )

p4


#Question 1 - what is the algebra and geometry of this model?

#Question 2 - Write out the full statistical model in mathematical terms.

#############################
# Part 2: Linear interactions
#############################

# Simulate data with a true interaction
data1 <- data.frame(
  x1 = runif(200, -2, 2),
  x2 = runif(200, -2, 2)
)
data1$y <- 2 + 1.5*data1$x1 - 1*data1$x2 + 2*data1$x1*data1$x2 + rnorm(200, 0, 1)

# Fit model
m1 <- lm(y ~ x1 * x2, data = data1)
summary(m1)

# Visualize fitted surface
grid1 <- expand.grid(x1 = seq(-2, 2, length=50),
                     x2 = seq(-2, 2, length=50))
grid1$yhat <- predict(m1, newdata=grid1)
zmat <- matrix(grid1$yhat, nrow = 50, ncol = 50)

p1 <- ggplot(grid1, aes(x1, x2, fill=yhat)) +
  geom_tile() +
  scale_fill_viridis_c() +
  labs(title="Heatmap of Predicted y with Interaction")

# 3D interactive surface plot
p2 <- plot_ly(
  x = seq(-2, 2, length = 50),
  y = seq(-2, 2, length = 50),
  z = zmat,
  type = "surface"
) %>%
  layout(
    title = list(text = "3D Surface: y ~ x1 * x2"),
    scene = list(
      xaxis = list(title = "x1", range = c(-2, 2)),
      yaxis = list(title = "x2", range = c(-2, 2)),
      zaxis = list(title = "yhat")
    )
  )


p1
p2
  
#Question 3 - what is the algebra and geometry of this model?


#Question 4 - Write out the full statistical model in mathematical terms.


########################################
# Part 3: Generalized Linear Models (GLM)
########################################

# Simulate binary outcome with interaction
xb <- -1 + 1.2*data1$x1 - 0.8*data1$x2 + 1.5*data1$x1*data1$x2
data1$ybin <- rbinom(200, 1, plogis(xb))

m_glm <- glm(ybin ~ x1 * x2, data=data1, family=binomial)
summary(m_glm)

# Predicted probability grid
grid_glm <- grid1
grid_glm$phat <- predict(m_glm, newdata=grid_glm, type="response")

p4 <- ggplot(grid_glm, aes(x1, x2, fill=phat)) +
  geom_tile() +
  scale_fill_viridis_c() +
  labs(title="Predicted Probability (GLM with interaction)")

p4


#Question 5 - what is the algebra and geometry of this model?


#Question 6 - Write out the full statistical model in mathematical terms.


