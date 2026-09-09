--- 
title: New version of analogue (0.8-0)
status: publish
layout: post
published: true
type: post
tags: 
- analogue
- R
active: blog
category: R
excerpt: "Yesterday I pushed an update of my [analogue](http://analogue.r-forge.r-project.org/ 'analogue website') package to [CRAN](http://cran.at.r-project.org/web/packages/analogue/index.html 'analogue page on CRAN'). The new version is 0.8-0 and contains some new functions, several bug fixes and a major change arising from additions to R 2.14.x requiring all packages to have a namespace. analogue now has its own namespace rather than relying on the one R would automagically generate if it weren&apos;t provided. 0.8-0 is a moderate update to analogue containing some new functionality, some of which is there for testing/experimentation (like the fancy principal components regression)."
---

{{ page.excerpt | markdownify  }}

The main user visible changes are:

-   `crossval()` new function to perform leave-one-out, k-fold, n k-fold, and bootstrap cross-validation on transfer function models. A method for wa() models is provided.
-   `pcr()` performs principal components regression. Designed to allow
    transformations in the spirit of [Legendre & Gallagher (2001,
    Oecologia)](http://dx.doi.org/10.1007/s004420100716) that allow
    [PCA](http://en.wikipedia.org/wiki/Principal_component_analysis "Principal component analysis")
    to be usefully applied to species data.
-   `varExpl()` and `gradientDist()` are two new functions that extract
    the amount or variance explained by ordinations axes and the
    distances or locations along
    [ordination](http://en.wikipedia.org/wiki/Ordination "Ordination")
    axes. Methods currently available for `cca()` and `prcurve()`
    objects.
-   `weightedCor()` implements one of the tests from [Telford & Birks
    (2011, QSR)](http://dx.doi.org/10.1016/j.quascirev.2011.03.002)
    based on the weighted correlation of WA optima and constrained
    ordination species scores.
-   `Stratiplot()` now handles absolute data better following a few bug
    fixes and general improvements in the underlying code.
    `panel.Stratiplot()` gains new arguments `gridh` and `gridv` to
    allow user control of the grid lines on panel if plotted.
-   `mat()` gains a new argument \`kmax\` which can be used to limit the
    number of analogues considered as models when fitting MAT transfer
    functions. By default, `mat()` considers models with 1 through to
    n-1 analogues (n = number of sites). `kmax` can control this upper
    limit which will speed up fitting models, especially for large
    training sets. Invariably one wouldn't want to average over entire
    training sets to produce predictions, or even over large numbers of
    analogues.

There were also many bug fixes and minor enhancements. Full details can be found in the ChangeLog, the relevant portion of which is appended below. Several development releases were made on [R-forge](https://r-forge.r-project.org/projects/analogue/ "Analogue project on R-forge") after the 0.7-0 release to CRAN. These development versions were not publicly released, but the changes they implemented are all present in 0.8-0 of analogue.

~~~~
Version 0.8-0

    * Updated Example test checks and packaged for release to CRAN
    Jan 11, 2012.

Version 0.7-7

    * mat: new argument `kmax` can be used to limit the number of
    analogues considered as models when fitting MAT transfer
    functions. By default, `mat()` considers models with 1 through
    to n-1 analogues (n = number of sites). `kmax` can control this
    upper limit which will speed up fitting models, especially for
    large training sets. Invariably one wouldn't want to average
    over entire training sets to produce predictions, or even over
    large numbers of analogues. As such I may set an upper limit for
    the default value of `kmax` before this is released to CRAN.

    * cumWmean, cummean: as a result of the above addition of `kmax`,
    these two functions now take a `kmax` argument also. The default
    behaviour is unchanged however.

    * chooseTaxa: `type = "OR"` was not working due to a typo. It
    returned the same as `type = "AND"`.

Version 0.7-6

    * Stratiplot: Handling of absolute data types was broken. Fix
    applied that should allow this to work if there are only
    absolute scale variables or a mix or relative and absolute
    data. All reletaive data should be unaffected.

    * panel.Stratiplot: gains arguments `gridh` and gridv` which
    control the number of horizontal and vertical grid lines used
    on each panel. These correspond to the `h` and `v` arguments of
    `panel.grid` in the Lattice package. The default is `-1` for
    both, which attempts to align the grid lines with the tick marks.

Version 0.7-5

    * weightedCor: implements one of the tests from Telford & Birks
    (2011, QSR) based on the weighted correlation of WA optima and
    constrained ordination species scores. Has a plot method.

    * rdaFit: Non-user (currently) function that implements RDA
    without all of the overhead of vegan::rda. As such it doesn't
    compute PCA axes and does not return all the components described
    by ?cca.object in package vegan. This function is used principally
    in weightedCor(). Has a scores() method. rdaFit() is not
    documented as the exact details of the function and its
    capabilities remain to be determined.

Version 0.7-4

    * gradientDist: new function to extract locations along an
    ordination axis. Methods for prcurve() and cca().

    * varExpl: new function to extract the amount of variance
    explained by ordination axes. Currently methods for prcurve() and
    cca() are available.

    * Namespace: analogue now has an explicit name space in
    preparation for R 2.14.0-to-be. Hence analogue now depends on
    Vegan >= 1.17-12.

Version 0.7-3

    * pcr: coef(), fitted(), residuals(), eigenvals(), performance(),
    and screeplot() methods added.

Version 0.7-2

    * pcr: new function pcr() performs principal components
    regression. Designed to allow transformations in the spirit of
    Legendre & Gallagher (2001) that allow PCA to be usefully
    applied to species data.

Version 0.7-1

    * crossval: new function to perform leave-one-out, k-fold,
    n k-fold, and bootstrap cross-validation on transfer function
    models. A method for wa() models is provided.
    * tests: package now has a test that the examples continue to
    return correct output.
~~~~
