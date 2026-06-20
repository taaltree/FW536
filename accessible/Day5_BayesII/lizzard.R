 
model {
#priors
a~dnorm(0,1.0E-6)
b~dnorm(0,1.0E-6)

  for(i in 1:n){
    logit(p[i])=a + b*x[i]
    y[i]~dbern(p[i])
  }
  for(j in 1:length(x.tot)){
    p.out[j]<-ilogit(a + b*x.tot[j])
  }
} 

