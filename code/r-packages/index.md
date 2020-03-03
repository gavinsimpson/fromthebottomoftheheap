---
title: R packages
status: publish
layout: page
published: true
type: page
tags:
- R
active: code
---

I've been using [R](http://www.r-project.org) since the first few months of my PhD. R is a great language for working with and analysing data, has a vibrant community around it and packages to do just about anything you might want to do with data. During that time I've written a few R packages and contributed to some others.

## R packages I wrote and maintain
My R packages implement methods commonly used in community ecology, and palaeolimnology and palaeoecology.

 * **[analogue]({{ site.url }}/code/r-packages/analogue/)** contains functions for analogue methods used in palaeoecology, as well as a variety of techniques useful for analysing sediment core data and fitting transfer functions
 * **[permute]({{ site.url }}/code/r-packages/permute/)** implements the full range of restricted permutation designs present in the commercial software Canoco for use in evaluating multivariate ordinations and other techniques common to ecology
 * **[cocorresp]({{ site.url }}/code/r-packages/cocorresp/)** is an R implementation of co-correspondence analysis, an ordination technique for finding common patterns of covariance in two community matrices
 * **[gratia]({{ site.url }}/code/r-packages/gratia/)** provides **ggplot2**-based plots for GAMs fitted using the **mgcv** package
 * **[ggvegan]({{ site.url }}/code/r-packages/ggvegan/)** provides **ggplot2** versions of plotting methods available in the **vegan** package
 * **[temporalEF]({{ site.url }}/code/r-packages/temporalEF/)** generates temporal eigenfunctions through the use of 1-dimensional <acronym title="Principal Coordinates of Neighbour Matrices">PCNMs</acronym> and <acronym title="Asymmetric Eigenvector Maps">AEMs</acronym>
 * **[canadaHCD]({{ site.url }}/code/r-packages/canadaHCD/)** is an R-based interface to the Government of Canada's Historical Climate Data [website](http://climate.weather.gc.ca/index_e.html), which provides access to hourly, daily, and monthly weather records for stations throughout Canada.

## R packages I contribute to
I contribute code and either maintain or help maintain the following R packages

 * **[vegan]({{ site.url }}/code/r-packages/vegan/)** is a large package for community ecology with a wide range of multivariate methods including common ordination methods, diversity measures, Null models and much more
 * **[pcurve]({{ site.url }}/code/r-packages/pcurve/)** is an R port of Glenn De'Ath's **pcurve** library for S-Plus, which is an implementation of the method of principal curves with a focus on their application in identifying long ecological gradients

I am also the maintainer of the [**Environmetrics**](http://cran.r-project.org/web/views/Environmetrics.html) Task View on CRAN.
