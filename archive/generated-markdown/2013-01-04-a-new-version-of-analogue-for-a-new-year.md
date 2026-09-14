--- 
title: A new version of analogue for a new year
status: publish
layout: post
published: true
type: post
tags: 
- analogue
- Palaeoecology
- Palaeolimnology
- R
- Statistics
category: R
excerpt: "Yesterday I rolled up a new version (0.10-0) of [analogue](http://cran.r-project.org/web/packages/analogue/index.html), my R package for analysing palaeoecological data. It is now available from CRAN. There were lots of incremental changes to `Stratiplot()` to improve the quality of the stratigraphic diagrams produced and fix several annoying bugs. Also the definition of the standard error of MAT reconstructions was fixed; it is essentially a weighted variance but the original version assumed the weights summed to 1, which is not the case for dissimilarities of the *k*-NN. Several new functions and additional functionality were added to the package."
active: blog
---

{{ page.excerpt | markdownify }}

-   `caterpillarPlot()` produces caterpillar plots showing species WA optima and tolerance ranges
-   `splitSample()` is a convenience function for sampling a subset of training set samples whilst ensuring that the entire environmental gradient of interest in the training set is evenly sampled.
-   The `wa()` function received a lot of love in this iteration. The main addition is to allow non-linear deshrinking of the raw WA estimates alongside the more common inverse and classical deshrinking techniques. The deshrinking is achieved using a cubic regression spline fitted using the `gam()` function in package [mgcv](http://cran.r-project.org/web/packages/mgcv/index.html). The spline is constrained to be monotonic to make sure that the deshrunk values for increasing raw values are likewise increasing. Small tolerance handling in `wa()` with tolerance downweighting gained the option to replace small tolerances with the mean of all taxon tolerances.
-   `logitreg()`, which applies a logistic regression to the problem of identifying a critical threshold in compositional dissimilarity for MAT models, saw a major update. The returned object was substantially altered to allow for a wider amount of information to be supplied to the user. `fitted()` and `predict()` methods for class `"logitreg"` were also added. These compute the fitted probabilities for the training set samples and for new (e.g. fossil) samples respectively. The probabilities are in respect to the analogue-ness of samples to the groups in the training set (e.g. vegetation biomes in the case of pollen data). These changes allow an analysis similar in spirit to that of [Gavin et al (2003, Quaternary Research 60; 356–367)](http://dx.doi.org/10.1016/S0033-5894(03)00088-7) in their Figure 8. Here though logistic regression fits are used and not the ROC method they use.

I'll be writing more on these ideas, especially the monotonic deshrinking and the logistic regression approach to dissimilarity threshold choice in future posts.
