---
title: permute
subtitle: a restricted permutation generator for R
status: publish
layout: page
published: true
type: page
tags: []
active: code
---
## What is permute?
**permute** is an R package that provides functions to generate restricted and unrestricted permutations. The package was originally conceived as an extension for the **vegan** package, essentially as internal functions for that package. Since then **permute** has undergone a number of revisions and is now a separate package in its own right, allowing **permute**'s functions to be used within other R packages.

The restricted permutations in **permute** are modelled on the permutations schemes of Cajo ter Braak available in the Canoco software since version 3.1.

The main functions in **permute** are `shuffle()` and `shuffleSet()` which return a single permutation or a set of *n* permutations, and `how()`, which is used to set up the permutation design.

The package comes with a large number of extractor functions to access aspects of the permutation design. It is recommended that these be used rather than subsetting the object return by `how()` as the internal representation of the permutation design may change.

### Features

 * Large range of permutation schemes
     * Unrestricted (i.e. randomisation)
     * Line transects or time series
     * Spatial grids
     * Split-plot designs; whole-plot and split plots can be any of the above permutation types or held fixed
     * Blocking factors (samples never permuted between blocks, only within)
 * Allows complete enumeration of all possible permutations (within machine and memory restrictions)
 * Checking of permutation designs (balance within plots where required, etc)
 * Calculation of maximum number of permutations for current design

## Bugs, feature requests
Bug reports and feature requests should be filed on the [Github](https://github.com/gavinsimpson/permute/issues) repository.

## Licence
permute is released under the [GNU General Public Licence, version 2](http://www.gnu.org/licenses/gpl-2.0.html).

## Links

 * [CRAN page](http://cran.r-project.org/package=permute)
 * [Development site](https://github.com/gavinsimpson/permute) on Github
