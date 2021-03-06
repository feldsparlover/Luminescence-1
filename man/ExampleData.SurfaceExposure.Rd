% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Luminescence-package.R
\name{ExampleData.SurfaceExposure}
\alias{ExampleData.SurfaceExposure}
\title{Example OSL surface exposure dating data}
\format{
A \link{list} with 4 elements:

\tabular{ll}{
\strong{Element} \tab \strong{Content} \cr
\verb{$sample_1} \tab A \link{data.frame} with 3 columns (depth, intensity, error) \cr
\verb{$sample_2} \tab A \link{data.frame} with 3 columns (depth, intensity, error) \cr
\verb{$set_1} \tab A \link{list} of 4 \link{data.frame}s, each representing a sample with different ages \cr
\verb{$set_2} \tab A \link{list} of 5 \link{data.frame}s, each representing a sample with different ages \cr
}
}
\source{
See examples for the code used to create the data sets.
}
\description{
A set of synthetic OSL surface exposure dating data to demonstrate the
\link{fit_SurfaceExposure} functionality. See examples to reproduce the data
interactively.
}
\details{
\strong{\verb{$sample_1}}

\tabular{ccc}{
\strong{mu} \tab \strong{sigmaphi} \tab \strong{age} \cr
0.9 \tab 5e-10 \tab 10000 \cr
}

\strong{\verb{$sample_2}}

\tabular{ccccc}{
\strong{mu} \tab \strong{sigmaphi} \tab \strong{age} \tab \strong{Dose rate} \tab \strong{D0} \cr
0.9 \tab 5e-10 \tab 10000 \tab 2.5 \tab 40 \cr
}

\strong{\verb{$set_1}}

\tabular{ccc}{
\strong{mu} \tab \strong{sigmaphi} \tab \strong{ages} \cr
0.9 \tab 5e-10 \tab 1e3, 1e4, 1e5, 1e6 \cr
}

\strong{\verb{$set_2}}

\tabular{ccccc}{
\strong{mu} \tab \strong{sigmaphi} \tab \strong{ages} \tab \strong{Dose rate} \tab \strong{D0} \cr
0.9 \tab 5e-10 \tab 1e2, 1e3, 1e4, 1e5, 1e6 \tab 1.0 \tab 40 \cr
}
}
\examples{

## ExampleData.SurfaceExposure$sample_1
sigmaphi <- 5e-10
age <- 10000
mu <- 0.9
x <- seq(0, 10, 0.1)
fun <- exp(-sigmaphi * age * 365.25*24*3600 * exp(-mu * x))

set.seed(666)
synth_1 <- data.frame(depth = x,
                      intensity = jitter(fun, 1, 0.1),
                      error = runif(length(x), 0.01, 0.2))

## VALIDATE sample_1
fit_SurfaceExposure(synth_1, mu = mu, sigmaphi = sigmaphi)




## ExampleData.SurfaceExposure$sample_2
sigmaphi <- 5e-10
age <- 10000
mu <- 0.9
x <- seq(0, 10, 0.1)
Ddot <- 2.5   / 1000 / 365.25 / 24 / 60 / 60 # 2.5 Gy/ka in Seconds
D0 <- 40
fun <- (sigmaphi * exp(-mu * x) *
          exp(-(age * 365.25*24*3600) *
                (sigmaphi * exp(-mu * x) + Ddot/D0)) + Ddot/D0) /
  (sigmaphi * exp(-mu * x) + Ddot/D0)

set.seed(666)
synth_2 <- data.frame(depth = x,
                      intensity = jitter(fun, 1, 0.1),
                      error = runif(length(x), 0.01, 0.2))

## VALIDATE sample_2
fit_SurfaceExposure(synth_2, mu = mu, sigmaphi = sigmaphi, Ddot = 2.5, D0 = D0)



## ExampleData.SurfaceExposure$set_1
sigmaphi <- 5e-10
mu <- 0.9
x <- seq(0, 15, 0.2)
age <- c(1e3, 1e4, 1e5, 1e6)
set.seed(666)

synth_3 <- vector("list", length = length(age))

for (i in 1:length(age)) {
  fun <- exp(-sigmaphi * age[i] * 365.25*24*3600 * exp(-mu * x))
  synth_3[[i]] <- data.frame(depth = x,
                             intensity = jitter(fun, 1, 0.05))
}


## VALIDATE set_1
fit_SurfaceExposure(synth_3, age = age, sigmaphi = sigmaphi)



## ExampleData.SurfaceExposure$set_2
sigmaphi <- 5e-10
mu <- 0.9
x <- seq(0, 15, 0.2)
age <- c(1e2, 1e3, 1e4, 1e5, 1e6)
Ddot <- 1.0 / 1000 / 365.25 / 24 / 60 / 60 # 2.0 Gy/ka in Seconds
D0 <- 40
set.seed(666)

synth_4 <- vector("list", length = length(age))

for (i in 1:length(age)) {
  fun <- (sigmaphi * exp(-mu * x) *
            exp(-(age[i] * 365.25*24*3600) *
                  (sigmaphi * exp(-mu * x) + Ddot/D0)) + Ddot/D0) /
    (sigmaphi * exp(-mu * x) + Ddot/D0)

  synth_4[[i]] <- data.frame(depth = x,
                             intensity = jitter(fun, 1, 0.05))
}


## VALIDATE set_2
fit_SurfaceExposure(synth_4, age = age, sigmaphi = sigmaphi, D0 = D0, Ddot = 1.0)

\dontrun{
ExampleData.SurfaceExposure <- list(
  sample_1 = synth_1,
  sample_2 = synth_2,
  set_1 = synth_3,
  set_2 = synth_4
)
}

}
\references{
Unpublished synthetic data
}
\keyword{datasets}
