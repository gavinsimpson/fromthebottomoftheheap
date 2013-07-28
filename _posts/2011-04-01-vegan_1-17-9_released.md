--- 
title: New version of vegan released to CRAN (1.17-9)
status: publish
layout: post
published: true
type: post
tags: 
- R
- vegan
category: R
active: blog
excerpt: "Yesterday Jari packaged up the latest release in the current stable branch of the [vegan](http://vegan.r-forge.r-project.org/) package. Version 1.17-9 of vegan is now on [CRAN](http://cran.r-project.org/web/packages/vegan/index.html) as a source tarball with binaries for MS Windows and MacOS X to follow soon."
---

{{ page.excerpt | markdownify }}

New releases in the current, stable branch of the package tend to be for bug fixes but we sometimes include new functionality considered low impact and important enough to warrant early release. This release sees a fix to a bug in the `anova()` method for `rda()`, `cca()` and `capscale()`, which would produce incorrect results when partial models were supplied and testing was performed by axes (e.g. `anova.cca(..., by = "axis")`).

From a user's perspective, there were three important additions to vegan with this release:

-   `ordisurf()` gained several new arguments to allow control of the
    methods used by `gam()` when fitting response surfaces to ordination
    configurations. The smoothness selection method can now be specified
    via a new argument `'method'` and an additional penalty can be
    applied to smooth terms so that they can be penalized out (i.e.
    removed from) the model if there really is no relationship between
    the response and the ordination configuration. If this happens,
    `ordisurf()` won't draw a response surface at all.
-   Automatic plotting of the fitted surface as a side-effect of
    `ordisurf()` can now be turned off, and a new `plot()` method allows
    later plotting of response surfaces without having to refit the
    entire model again.
-   `metaMDSrotate()` can now rotate an nMDS ordination with an
    arbitrary dimensional solution whereas before it would only rotate
    2-D solutions.
-   `diversity()` (and related functions: `rarefy()`, `rrarefy()`, and
    `specnumber()`) are now more intuitive and work with vector inputs.
    As a result many sites/samples can be analysed at once now.

Full details of the release can be seen in the [NEWS](http://cran.r-project.org/web/packages/vegan/NEWS) file, the relevant portion of which appears at the bottom of this post. We've got some exciting new features planned for the next version of vegan, which I'll blog about when they start appearing in the development version on [R-forge](https://r-forge.r-project.org/projects/vegan/).

                VEGAN RELEASE VERSIONS 
                ======================

                       CHANGES IN VEGAN 1.17-9

    - anova of cca/rda/capscale results gave wrong results in partial
      models. The bug was introduced in vegan 1.17-7. 

    - diversity and related functions rarefy, rrarefy and specnumber
      now accept vector input. Earlier a single site had to be
      analysed either as a single-row matrix or using the non-default
      setting MARGIN = 2.

    - drarefy: new function that returns a matrix of probabilities
      that a species occurs in a rarefied sample of a given size.

    - metaMDS: it is possible to supply a starting configuration with
      argument 'previous.best'. A previous metaMDS or isoMDS result can
      also be given as a starting configuration. If the starting
      configuration has a higher number of dimensions than requested,
      the extra ones are dropped, and if the starting configuration
      has fewer dimensions, random scores for extra dimensions will be
      added. This may help in running metaMDS over a range of
      dimensionalities. 

    - metaMDSrotate: can now rotate metaMDS solutions with any number
      of dimensions so that the first axis is parallel to a fitted
      environmental vector. Previously, only two dimensional solutions
      worked.

    - ordilabel: gained argument 'xpd' that allows labels outside the
      plot area. This allows labels above axes, for instance.

    - ordisurf: gained several new arguments to control the mgcv::gam
      fitting. Also gained an argument to suppress plotting, and a new
      plot method. The fitted model can be specified with a formula. 

    - prestonfit and friends: default is now 'tiesplit = TRUE' (which
      was a new feature introduced in vegan 1.17-8).

