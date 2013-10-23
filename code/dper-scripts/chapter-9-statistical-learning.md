---
title: Statistical Learning in Palaeolimnology
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
- "Statistical learning"
category: R
active: code
---

Whilst I'm preparing an annotated set of scripts for the Statistical Learning chapter of DPER5, you can access the updated R code used for the chapter via my [**dper5** github repository](https://github.com/gavinsimpson/dper5/tree/master/chpt-9-statistical-learning-in-palaeolimnology). The following scripts cover the examples from the chapter

 1. Univariate trees
 2. Multivariate regression trees
 3. Multivariate adaptive regression splines (MARS)
 4. Principal curves
 5. Self-organising maps (SOMs)
 6. Shrinkage methods in regression (ridge, LASSO, elastic net)

The boosted tree example is not yet posted, partly because I need to get permission to upload the EDDI diatom data used in the example.

The *principal curves* script requires the development version of my [**analogue**]({{ site.url }}/code/r-packages/analogue.html) package. Unfortunately, R-Forge is not building the package at the moment (there is an issue with the installation of the **rgl** package on their build servers). If you are using Linux then you can grab the source code and compile yourself. For MS Windows users, a version that works for the script, has been built using Uwe Ligge's WinBuilder service. Download the [zipfile]({{ site.url }}/assets/materials/r-packages/binaries/analogue_0.11-6.zip), which was built using R 3.0.2-patched.
