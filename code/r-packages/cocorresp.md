---
title: cocorresp
subtitle: an R implementation of co-correspondence analysis
status: publish
layout: page
published: true
type: page
tags: []
active: code
---
## What is cocorresp?
**cocorresp** is a small R package that implements the co-correspondence analysis (CoCA) method of ter Braak and Schaffers (2004). CoCA adresses the data analysis problem of relating two species community matrices (count or proportional abundances, or presence/absence) to one another. In symmetric CoCA neither community matrix is the response and hence common patterns of covariance between the two matrices are extracted as the CoCA axes. In predictive CoCA, one matrix is the response and the other the predictor and a true multivariate regression is applied to predict the species abundances of the response from the abundances of the predictor species. predictive CoCA is particularly useful when you wish to specifically investigate how  well one species groups can predict another.

CoCA's response model is the same as that of correspondence analysis (CA) and hence is particularly suited to species abundance data. Symmetric CoCA is closely related to the technique of coinertia analysis, whilst predictive CoCA employs partial least squares to handle the case of a large number of predictor variables.

**cocorresp** is a more or less direct port of Cajo ter Braak and Andre Schaffer's MATLAB code supplied as supplementary material to ter Braak and Schaffers (2004), with a little bit of R-ification. I am grateful that Cajo and Andre allowed me permission to port their code and make the resulting R package available under a open source licence.

### Features

 * Co-correspondence analysis (CoCA)
     * Symmetric CoCA
     * Predictive CoCA
 * Significance testing
     * Leave-one-out cross-validation
     * Permutation tests
 * CoCA ordination diagrams
 * Aim to emulate **vegan** functions but for CoCA ordinations
     * Experimental `envfit()` method for `coca` objects

## Bugs, feature requests
Bug reports and feature requests should be filed on [R-forge](http://r-forge.r-project.org/tracker/?group_id=181).

## Licence
cocorresp is released under the [GNU General Public Licence Version 2](http://www.gnu.org/licenses/gpl-2.0.html).

## Links

 * [CRAN page](http://cran.r-project.org/package=cocorresp)
 * [Development site](http://r-forge.r-project.org/projects/cocorresp/) on R-Forge

## References

ter Braak, C.J.F and Schaffers, A.P. (2004) Co-Correspondence Analysis: a new ordination method to relate two community compositions. *Ecology* **85(3)**, 834&ndash;846
