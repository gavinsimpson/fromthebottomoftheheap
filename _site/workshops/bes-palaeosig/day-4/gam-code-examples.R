## GAM example model fitting code

## Packages
pkgs <- c('readr', 'ggplot2', 'mgcv', 'gratia', 'dplyr', 'readxl', 'cowplot',
          'tibble', 'tidyr')
vapply(pkgs, library, logical(1), character.only = TRUE, logical.return = TRUE)

##------------------------------------------------------------------------------
## WAIS Divide Ice Core Atmospheric CO2 record
uri <- 'https://www.ncei.noaa.gov/pub/data/paleo/icecore/antarctica/wais2021co2.txt'
ice_core <- read_tsv(uri,
                     na = c('', 'NA', 'NaN'),
                     comment = '#',
                     col_types = 'dddddc') %>%
  rename(depth = depth_m, # renames some variables
         age = age_calBP,
         co2_raw = CO2_blank_corrected,
         co2 = CO2_blank_gravity_corrected,
         std_err = CO2_se_1sigma,
         notes = notes) %>%
  mutate(neg_age = -age, # negative of age for getting time in right direction
         wts = 1/std_err, # we have a std. error for each observation
         wts = wts / mean(wts, na.rm = TRUE)) # convert to weights for gam()

## Plot
ice_core %>%
  ggplot(aes(x = neg_age, y = co2)) +
  geom_line() +
  labs(x = 'Calibrated years BP',
       y = expression(CO[2] ~ (ppm)))

## Model
ctrl <- gam.control(nthreads = 3, maxit = 500)
m1 <- gam(co2 ~ s(neg_age, k = 200), data = ice_core, method = 'REML',
          family = gaussian, weights = wts, control = ctrl)

## model summary
summary(m1)

## plot the fitted smooth
draw(m1, n = 500)

## look at model diagnostics
appraise(m1, method = 'simulate')

## check basis dimension
k.check(m1) # looks good

## heavy tails and variance isn't constant - try a Gaussian LS model
m2 <- gam(list(co2 ~ s(neg_age, k = 200), # model for the mean
               ~ s(wts) + s(neg_age, k = 30)), # model for variance
          data = ice_core, method = 'REML',
          family = gaulss(), control = ctrl)

draw(m2, n = 500)
appraise(m2)
k.check(m2)

## still some issues with data distribution
## technically CO2 can;t be negative so we can try a Gamma
m3 <- gam(co2 ~ s(neg_age, k = 200), data = ice_core, method = 'REML',
          family = Gamma(link = 'log'), weights = wts, control = ctrl)

draw(m3, n = 500)
appraise(m3, method = "simulate")
k.check(m3)

## is wiggliness the same on average over the series? try adaptive smooth
m4 <- gam(co2 ~ s(neg_age, k = 200, bs = 'ad', m = 10),
          data = ice_core, method = 'REML',
          family = Gamma(link = 'log'), weights = wts, control = ctrl)

AIC(m1, m2, m3, m4)

draw(m4, n = 500, residuals = TRUE)

appraise(m4, method = 'simulate')

k.check(m4)

##------------------------------------------------------------------------------
## Lake 227 example

## Load data
lake227 <- read_excel('CONC227.xlsx')

## Peter higlighted Fuco, Allox, Lutzeax, Pheo_b, Bcarot
## take only those variables and year
vars <- c('YEAR', 'FUCO', 'ALLOX', 'LUTZEAX', 'PHEO_B', 'BCAROT')
lake227 <- lake227 %>% select(all_of(vars))

## want nice names
names(lake227) <- c('Year', 'Fucoxanthin', 'Alloxanthin', 'LuteinZeaxanthin',
                    'Pheophytinb', 'BetaCarotene')

## take data from 1943 onward - replciate Cottingahm et al
lake227 <- lake227 %>% filter(Year >= 1943)

## to long format for modeling
lake227 <- lake227 %>%
  gather(key = Pigment, value = Concentration, - Year) %>%
  mutate(Pigment = factor(Pigment), cYear = (Year - mean(Year)) / 1000)

ctrl <- gam.control(nthreads = 2) # set up some control parameters

## fit the first model - intercept only for power
## single smooth for the scale
## Pigment specific smooths for for mean
mtwlss0 <- gam(list(Concentration ~ s(Year, Pigment, bs = 'fs', k = 10), # mean
                    ~ 1, # power, intercept only
                    ~ s(Year, k = 10)), # scale
               data = lake227,
               family = twlss,
               optimizer = 'efs', # twlss can be more stable with a the Extended Fellner Schall fit
               method = 'REML', # REML smoothness selection
               control = ctrl)

## see pigment specific smooths in scale also work, lower `k`
mtwlss <- gam(list(Concentration ~ s(Year, Pigment, bs = 'fs', k = 10),
                   ~ 1,
                   ~ s(Year, Pigment, bs = 'fs', k = 7)),
              data = lake227,
              family = twlss, optimizer = 'efs', method = 'REML',
              control = ctrl)

AIC(mtwlss0, mtwlss)

summary(mtwlss)

appraise(mtwlss)

draw(mtwlss)

k.check(mtwlss)

##------------------------------------------------------------------------------
## Braya So
## load braya so data set
braya <- read.table("DAndrea.2011.Lake Braya So.txt", skip = 84)
## clean up variable names
names(braya) <- c("Depth", "DepthUpper", "DepthLower", "Year", "YearYoung",
                  "YearOld", "UK37")
## convert to tibble
braya <- as_tibble(braya) %>% # add a variable for the amount of time per sediment sample
  mutate(sampleInterval = YearYoung - YearOld)

## label for plotting
braya_ylabel <- expression(italic(U)[37]^{italic(k)})

## plot
ggplot(braya, aes(x = Year, y = UK37)) +
  geom_line(colour = "grey") +
  geom_point() +
  labs(y = braya_ylabel, x = "Year CE")

## fit the model with a continuous time AR1 --- needs optim as this is not a stable fit!
## also needs k setting lower than default
braya.car1 <- gamm(UK37 ~ s(Year, k = 5), data = braya,
                   correlation = corCAR1(form = ~ Year),
                   method = "REML",
                   control = list(niterEM = 0, optimMethod = "BFGS",
                                  opt = "optim"))
## fit model using GCV
braya.gcv <- gam(UK37 ~ s(Year, k = 30), data = braya)

## CAR(1) parameter
brayaPhi <- intervals(braya.car1$lme)$corStruct
## fails - fit is non-positive definite

N <- 300
# number of points at which to evaluate the smooth
## data to predict at
newBraya <- with(braya, data.frame(Year = seq(min(Year), max(Year),
                                              length.out = N)))
## add predictions from GAMM + CAR(1) model
newBraya <- cbind(newBraya,
                  data.frame(predict(braya.car1$gam, newBraya,
                                     se.fit = TRUE)))
crit.t <- qt(0.975, df = df.residual(braya.car1$gam))
newBraya <- transform(newBraya,
                      upper = fit + (crit.t * se.fit),
                      lower = fit - (crit.t * se.fit))
## add GAM GCV results
fit_gcv <- predict(braya.gcv, newdata = newBraya, se.fit = TRUE)
crit.t <- qt(0.975, df.residual(braya.gcv))
newGCV <- data.frame(Year
                     = newBraya[["Year"]],
                     fit
                     = fit_gcv$fit,
                     se.fit = fit_gcv$se.fit)
newGCV <- transform(newGCV,
                    upper = fit + (crit.t * se.fit),
                    lower = fit - (crit.t * se.fit))
# bind on GCV results
newBraya <- rbind(newBraya, newGCV)
## Add indicator variable for model
newBraya <- transform(newBraya,
                      Method = rep(c("GAMM (CAR(1))", "GAM (GCV)"),
                                   each = N))

## plot CAR(1) and GCV fits
braya_fitted <- ggplot(braya, aes(y = UK37, x = Year)) +
  geom_point() +
  geom_ribbon(data = newBraya,
              mapping = aes(x = Year, ymax = upper, ymin = lower,
                            fill = Method),
              alpha = 0.3, inherit.aes = FALSE) +
  geom_line(data = newBraya,
            mapping = aes(y = fit, x = Year, colour = Method)) +
  labs(y = braya_ylabel, x = "Year CE") +
  scale_color_manual(values = c("#5e3c99", "#e66101")) +
  scale_fill_manual(values = c("#5e3c99", "#e66101")) +
  theme(legend.position = "right")
braya_fitted

## lets fit the proper model
braya_reml <- gam(UK37 ~ s(Year, k = 40), data = braya,
                  method = "REML",
                  weights = sampleInterval / mean(sampleInterval))
summary(braya_reml)

draw(braya_reml, n = 500)

appraise(braya_reml, method = "simulate")

k.check(braya_reml)

## posterior simulation --- posterior smooths
post_sm <- smooth_samples(braya_reml, term = "Year", n = 20, seed = 42,
                          unconditional = TRUE)

## plot
draw(post_sm, alpha = 0.3, colour = 'steelblue') +
  geom_line(data = smooth_estimates(braya_reml, n = 400),
            mapping = aes(x = Year, y = est, group = NULL),
            lwd = 1)

## derivatives of the smooth
dydt <- derivatives(braya_reml, term = "s(Year)", type = "central",
                    interval = "simultaneous")
dydt

draw(dydt)
