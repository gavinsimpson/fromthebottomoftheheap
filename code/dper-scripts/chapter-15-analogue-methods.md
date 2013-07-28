---
title: Analogue Methods in Palaeolimnology
subtitle: R script for examples
status: publish
layout: page
published: true
type: page
tags:
- R
- "DPER 5"
- Palaeolimnology
- Palaeoecology
- "Modern analogues"
- analogue
category: R
active: code
---

This is an annotated version of the R code used to perform the examples in my chapter *Analogue Methods in Palaeolimnology*. The latest version of the script can be found on [github](https://github.com/gavinsimpson/dper5).

## Preliminaries

{% highlight r %}
## load the analogue package
require(analogue)
## if that fails, install analogue:
## install.packages("analogue", depend = TRUE)

## load the example data
data(swapdiat, swappH, rlgh, package = "analogue")

## load in the sample ages for the RLGH samples
age <- read.csv("rlgh.age.csv", header = FALSE)
age <- as.numeric(age[,1])

{% endhighlight %}

## Modern analogue technique

{% highlight r %}
## merge the data to common set of taxa...
dat <- join(swapdiat, rlgh, verbose = TRUE)
## ...and split apart converting to %
swapdiat <- dat$swapdiat / 100
rlgh <- dat$rlgh / 100

## Fit the MAT model using Chord distance
swap.mat <- mat(swapdiat, swappH, method = "chord")

## Bootstrap the model
set.seed(1234) ## make this reproducible
swap.boot <- bootstrap(swap.mat, n.boot = 1000)
swap.boot

## RMSEP of the model
RMSEP(swap.boot)

## Optimal value of `k` derived from bootstrap
K <- getK(swap.boot)
K

## get predictions for the RLGH data for the optimal `k` using
## the MAT model...
rlgh.mat <- predict(swap.mat, rlgh, k = K)

## ..and bootstrap derived sample-specific predictions
rlgh.boot <- predict(swap.mat, rlgh, k = K, bootstrap = TRUE)

## produce fig 1 - MAT reconstruction with sample-specific errors on
## age and depth scales -----------------------------------------------
reconPlot(rlgh.boot, depths = age, ylab = "pH", xlab = "Age (yr. BP)",
          display.error = "bars", predictions = "bootstrap")
par(new = TRUE)
depths <- as.numeric(rownames(rlgh))
plot(rlgh.mat$predictions$model$predicted[K, ] ~ depths, type = "n",
     axes = FALSE, ann = FALSE, xlim = rev(range(depths)))
axis(3, at = pretty(depths), labels = pretty(depths))
mtext("Depth (cm.)", side = 3, line = 2.5)
## --------------------------------------------------------------------

## reproduce figure 2 - left hand panel -------------------------------
## form a new data object on fusion of RLGH and SWAP
dat <- join(swapdiat, rlgh, split = FALSE)
max.abb <- apply(dat, 2, max) ## maximum abundance per species
n.occ <- colSums(dat > 0)     ## number of occurrences per taxon

## select only taxa with max abundance greater than 5% and present
## in 40 or more samples
spp.want <- which(max.abb >= 0.05 & n.occ >= 40)

## subset out this smaller data set
diat2 <- swapdiat[, spp.want]

## extract the dissimilarity matrix for the full SWAP MAT model
Dij <- as.dist(swap.mat$Dij)

## compute the kernel density estimate of the dissimilarities
dens <- density(Dij, from = 0, to = sqrt(2))

## extract the low quantiles of this density estimate
quant <- quantile(Dij, probs = c(0.01, 0.02, 0.025, 0.05, 0.1))

## Fit a MAT to this smaller data set
swap.mat2 <- mat(diat2, swappH, method = "chord")

## extract the dissimilarity matrix from the MAT model
Dij2 <- as.dist(swap.mat2$Dij)

## compute the kernel density estimate of the dissimilarities
## for the smaller data set
dens2 <- density(Dij2, from = 0, to = sqrt(2))

## extract the low quantiles of this new density estimate
quant2 <- quantile(Dij2, probs = c(0.01, 0.02, 0.025, 0.05, 0.1))

## Do the plotting
plot(dens, main = "", type = "n", bty = "n", xlab = "")
abline(h = 0, col = "grey")
lines(dens, col = "red", lwd = 2)
lines(dens2, col = "blue", lwd = 2, lty = "dashed")
rug(dens$x[which.max(dens$y)], col = "red", lwd = 2,
    side = 1, ticksize = 0.03)
rug(dens$x[which.max(dens$y)], col = "red", lwd = 2,
    side = 3, ticksize = 0.02)
rug(dens2$x[which.max(dens2$y)], col = "blue", lwd = 2,
    side = 1, ticksize = 0.03)
rug(dens2$x[which.max(dens2$y)], col = "blue", lwd = 2,
    side = 3, ticksize = 0.02)
abline(v = quant[1], lwd = 2, col = "red")
abline(v = quant2[1], lwd = 2, col = "blue", lty = "dashed")
legend("topleft", legend = paste("m =", c(NCOL(swapdiat), length(spp.want))),
       lty = c("solid","dashed"), lwd = 2, col = c("red","blue"),
       bty = "n", inset = 0.02)
axis(3, at = quant[1], label = round(quant[1], 3), las = 2)
axis(3, at = quant2[1], label = round(quant2[1], 3), las = 2)
box()
## --------------------------------------------------------------------

## reproduce right hand panel of figure 2 -----------------------------
## uses objects computed above
plot(dens, main = "", type = "n")
abline(h = 0, col = "grey")
abline(v = quant[-2], lty = "dashed", lwd = 2)
lines(dens, col = "red", lwd = 2)
axis(3, at = quant[-2], labels = names(quant[-2]), las = 2)
## --------------------------------------------------------------------

## reproduce figure 3
## Screeplot of LOO and bootstrap RMSEP as a function of the number of
## `k` closest analogue used
screeplot(swap.boot, sub = "", ylab = "RMSEP", main = "",
          col = rep("black", 2))

## Monte Carlo resampling, via
##  * usual pairwise random selections
swap.paired.mc <- mcarlo(swap.mat, nsamp = 10000, type = "paired")

##  * pairwise sampling but with replacement
swap.boot.mc <- mcarlo(swap.mat, nsamp = 10000,
                       type = "paired", replace = TRUE)

## plot the observed and resampled distributions
plot(swap.paired.mc, which = 1)
lines(dens, col = "red", lwd = 2, lty = "dashed")
legend("topleft", legend = c("Observed","Resampled"),
       lty = c("dashed","solid"), lwd = 2:1, col = c("red","black"),
       bty = "n", inset = 0.02)

## Reproduce Figure 4 in its entirety ---------------------------------
layout(matrix(1:2, ncol = 2))
plot(swap.boot.mc, which = 1, caption = "")
lines(dens, col = "black", lwd = 2, lty = "dashed")
legend("topleft", legend = c("Observed","Resampled"),
       lty = c("dashed","solid"), lwd = 2:1, col = rep("black",2),
       bty = "n", inset = 0.02)
crit <- plot(swap.boot.mc, which = 2, caption = "", alpha = 0.05)
legend("topleft", legend = expression(alpha == 0.05),
       fill = "grey", bty = "n", inset = 0.02, box.lwd = 0)
layout(1)
## --------------------------------------------------------------------
{% endhighlight %}

## North American Pollen Database example

### ROC Curves

{% highlight r %}
## ROC - North American Modern Pollen after Whitmore et al 2005
data(Pollen, Biome, package = "analogue")

## load in the pollen sample type information
pinfo <- read.csv("nampdb_sample_type.csv")

## identify which are from lacustrine environments == "LACU"
pol.want <- with(pinfo, which(KGDISCR == "LACU"))

## then select only those samples from the Pollen and Biome objects
Pollen <- Pollen[pol.want, ]
Biome <- Biome[pol.want, , drop = FALSE]

## select all sites with a Biome & Correct spelling of
## Mediterranian -> Mediterranean
fed <- as.character(Biome$Fedorova)
want <- fed == "Mediterranian"
fed[want] <- "Mediterranean"
Nas <- with(Biome, is.na(Fedorova))
pollen <- Pollen[!Nas, ]
fedorova <- factor(fed[!Nas])

## convert the Pollen data to proportions
pollen <- tran(pollen, method = "proportion")

## compute the dissimilarity matrix for the pollen
dis.pollen <- distance(pollen, method = "chord")

## compute the ROC curves
roc.pollen <- roc(dis.pollen, group = fedorova)

## investigate the results
roc.pollen
summary(roc.pollen) ## this is effectively Table 2

## plot the ROC curve and associated output ---------------------------
## reproduces figure 5
layout(matrix(1:4, ncol = 2, byrow = TRUE))

## extract prior probability of analogue for use in producing the plots
roc.prior <- roc.pollen$statistics["Combined", c("In", "Out")]
roc.prior <- roc.prior[,1] / roc.prior[,2]

## plot the ROC model output using the observed prior prob.
plot(roc.pollen, prior = c(roc.prior, 1 - roc.prior),
     lty = c("solid","dashed"), inGroup.col = "black",
     outGroup.col = "black")

layout(1)
## --------------------------------------------------------------------

## look at the range of Optimal Dij over the different biomes
range(summary(roc.pollen)[[3]])
{% endhighlight %}

### Logistic regression modelling

{% highlight r %}
## logistic regression models
lrm.pollen <- logitreg(dis.pollen, group = fedorova)
lrm.pollen

## more of a summary
summary(lrm.pollen)

## plot the logit models, reproducing figure 6 ------------------------
layout(matrix(1:2, ncol = 2))
plot(lrm.pollen, group = "Combined",
     conf.type = "polygon", conf.int = 0.95,, xlab = expression(d[jk]),
     col = "black")
plot(lrm.pollen, group = "Desert",
     conf.type = "polygon", conf.int = 0.95, xlab = expression(d[jk]),
     col = "black")
layout(1)
## --------------------------------------------------------------------
{% endhighlight %}

### Comparison of ROC curves and logistic regression

{% highlight r %}
## compute the posterior probability for the optimal cutoff in ROC
bf.pollen <- bayesF(roc.pollen)
max.roc <- sapply(roc.pollen$roc, function(x) which.max(x$TPF - x$FPE))
posterior.prob <- numeric(length = length(max.roc))
names(posterior.prob) <- names(max.roc)
for(i in names(max.roc)) {
    prior <- with(roc.pollen$statistics[i,, drop = FALSE], In / Out)
    bf <- bayesF(roc.pollen, prior = c(prior, 1 - prior))
    posterior.prob[i] <- bf[[i]]$posterior.odds$pos[max.roc[i]] /
                           (1 + bf[[i]]$posterior.odds$pos[max.roc[i]])
}

## show the posterior probs for the ROC dissimilarity
posterior.prob

## now use dose.p to compute the dose to get p = 0.9
lrm.prob <- numeric(length = length(max.roc))
names(lrm.prob) <- names(max.roc)
opti <- roc.pollen$statistics$`Opt. Dis.`
for(i in seq_along(opti)) {
    lrm.prob[i] <- predict(lrm.pollen[[i]],
                           newdata = data.frame(Dij = opti[i]),
                           type = "response")
}

## show the posterior probs for the lrm dissimilarity
lrm.prob

## produce table 3
## bind results together for tabulation in LaTeX
res <- data.frame(`Opt. Dij` = opti,
                  `Prob. (ROC)` = posterior.prob,
                  `Prob. (LRM)` = lrm.prob,
                  `Dij (p=0.9)` = summary(lrm.pollen, p = 0.9)$`Dij(p=0.9)`,
                  check.names = FALSE)
res
{% endhighlight %}

## Analogue methods as reconstruction diagnostics

{% highlight r %}
## Minimum dissimilarity between fossil samples and training set
min.dij <- minDC(rlgh.mat)

## plot this minimum dissimilarity ------------------------------------
## reproduces figure 7
plot(min.dij, depths = age, xlab = "Age", lty.quantile = "dashed",
     col.q = "black")
par(new = TRUE)
plot(min.dij$minDC ~ depths, type = "n", axes = FALSE, ann = FALSE,
     xlim = rev(range(depths)))
axis(3, at = pretty(depths), labels = pretty(depths))
mtext("Depth (cm.)", side = 3, line = 2.5)
## --------------------------------------------------------------------
{% endhighlight %}
