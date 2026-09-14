--- 
title: New version of analogue (0.7-0)
status: publish
layout: post
published: true
meta: 
  _edit_last: "15232487"
  jabber_published: "1306931176"
type: post
tags: 
- analogue
- R
active: blog
category: R
excerpt: "Last week I pushed an update of my [analogue](http://analogue.r-forge.r-project.org/ 'analogue website') package to [CRAN](http://cran.at.r-project.org/web/packages/analogue/index.html 'analogue page on CRAN'). The last release (0.6-23) was on CRAN sometime in Mar 2010 so an update was well overdue."
---

{{ page.excerpt | markdownify }}

This (0.7-0) is a major update to analogue containing lots of new functionality. The main changes are:

-   `chooseTaxa()` is a new utility function for choosing which taxa to
    select from a species training set. Usual practice is to select the
    most abundant species (or conversely, not select the rare species)
    from a data set for plotting or building a transfer function. Whilst
    this idea might be a bit questionable to an ecologist (surely the
    rare things are important for something? Or are they? That in itself
    is an interesting question!) it helps with transfer function model
    building because to the modelling functions the rare species are
    often noise. `chooseTaxa()` allows the user to select species that
    reach at least a stated abundance (say 2%) and/or are present in at
    least a stated number of samples (say 5 samples). The distinction
    allows us to a low abundance taxon that is ubiquitous in a training
    set.
-   `timetrack()` can overlay data from a sediment core on to an
    ordination of a training set. Usually the training set contains data
    on species-environment relationships, whilst the environment is
    typically not measured (or even available) for samples in a sediment
    core. We can, however, use the species scores from the ordination of
    the training data to position the sediment core data into the
    ordination: in Canoco-speak, these samples are known as
    *supplementary* (or *passive* for older Canoco-aware users). This
    type of overlay is known as a timetrack. The function has a `plot()`
    method with which to visualise the timetrack overlay.
-   `prcurve()` is a user-friendly wrapper function to fit a principal
    curve to palaeoecological data. We often summarise change in species
    composition in a sediment core through time using ordination axes,
    say PCA axes 1 and 2 scores, but standard ordination techniques tend
    to require two or more axes to capture the dominant gradient in the
    data. Geometrically, we see this as an arch or horseshoe
    configuration in the ordination diagram. A principal curve is a
    generalisation of the first principal component, and is a smooth
    curve fitted in high dimensions using smoothers. Where there is a
    dominant gradient (i.e. temporal change) the principal curve will
    tend to explain more of the variance in the data using a single
    "component" than 2 or more PCA or CA axes. The underlying fitting is
    performed using the [princurve](http://cran.r-project.org/web/packages/princurve/index.html "CRAN page for princurve") package, which is now a dependency. The function is named after the standard R function `prcomp()`, which performs PCA.
-   `Stratiplot()` has gained the ability to draw zones over the
    stratigraphy, and it can now accommodate mixtures of proportional
    (e.g % composition) and absolute (e.g. biogeochemical data) data
    types. The latter functionality is experimental at the moment and
    the interface is a little clunky.
-   The package has a new data set; `abernethy`. These are the classic
    Abernethy Forest pollen data of Hilary Birks. These data have been
    used extensively as an example data set in the development of
    numerical techniques for the analysis of palaeoecological data. The
    package uses these data to illustrate the fitting of principal
    curves using new function `prcurve()`.

There were also many bug fixes and minor enhancements. Full details can be found in the ChangeLog, the relevant portion of which is appended below. Several development releases were made on [R-forge](https://r-forge.r-project.org/projects/analogue/ "Analogue project on R-forge") after the 0.6-23 release to CRAN. These development versions were not publicly released, but the changes they implemented are all present in
0.7-0 of analogue.

~~~~
Version 0.7-0

    * timetrack: new function to passively project sediment core
    samples within an ordination of training or reference set
    samples. Both unconstrained and constrained ordinations are
    supported using the Vegan package. 'fitted' and 'plot' methods
    are available.

    * prcurve: new function to fit principal curves to sediment
    core samples. A 'plot' method is also provided. The function uses
    functionality from the princurve package, which is now a
    dependency.

    Several support functions are also provided; 'smoothSpline' is
    a wrapper to 'smooth.spline' for fitting splines to individual
    species in order to fit the principal curve. 'initCurve'
    implements several methods for initialising the principal curve.

    * Stratiplot: if 'zones' are supplied, a legend on the right-hand
    side of the diagram can be drawn by setting argument 'drawLegend'
    to TRUE (the default). Currently, only simple blocks that
    demarcate the zone boundaries are drawn and labelled using
    argument 'zoneNames'.

    First attempt to allow both relative (percentages or proportions)
    and absolute variables, or mixtures thereof, in a single plot. The
    user is free to specify which variables should be treated as relative
    or absolute, and variables marked as absolute will be drawn with
    fixed-width panels, the size of which can be controlled via argument
    'absoluteSize' (default is 0.5 * largest panel width). Consider
    this functionality unstable at the moment.

    * residLen: was not 'join'-ing the training set and passive data
    correctly and would fail if species were found in one but not the
    other data set.

    * tran: improvements to the underlying code.

    * distance: resilience to NA in "gower", "alt.gower", "mixed".

    * cma: added methods for 'mat' and 'predict.mat' objects. These
    allow you to retrieve the k-closest analogues for training set
    and prediction data respectively.

    * dissimilarities: new method for 'mat' objects.

    * datasets: package datasets have been resaved with optimal
    compression determined via resaveRdaFiles(). This has reduced
    the package tarball size considerably. As a result, however,
    analogue now requires R version 2.10.0 or later.

    * predict.wa: bug in bootstrap and k-fold CV methods when
    tolerance down-weighting was used.

    * fixUpTol: erroneous error criterion would cause CV of WA models
    with tolerance down-weighting to stop with an error.

    * waFit: new function that encapsulates the main WA computations.
    This is currently used by wa() and with the intention of being
    used in all functions that computed WA transfer function models.

    * Examples: Streamlined some further examples to use Imbrie &
    Kipp data set, and to not re-run the same code again. Improves
    package check times by a second or two on my PC.

Version 0.6-26

    * abernethy: New data set containing the classic Abernethy Forest
    data of Birks and Mathewes (1978)

    * Stratiplot: Preserves the names component as far as is
    possible, even to the extent of processing the names after the
    manipulations arising from the formula interface.

    Bug in padding of the y-axis now fixed; default is to add 1% of
    the range y-axis to the y-axis limits specified.

    Bug in computing length of variable labels when 'strip = FALSE'
    now fixed.

    * panel.Stratiplot: Add capability to draw zones on stratigraphic
    plots via new argument 'zones' which takes the numeric levels of
    the zone boundaries on the scale of the plot y-axis. How the
    zone markers are drawn can be controlled via several graphical
    parameters. See ?panel.Stratiplot.

    * chooseTaxa: Explicitly preserves row and column names.

    * DESCRIPTION: prematurely added princurve as a dependency in
    previous version.

Version 0.6-25

    * chooseTaxa: new function to select species on basis of number
    of occurrences and maximum abundance. Function is an S3 generic
    with a default method.

Version 0.6-24

    * Dependencies: package now depends on package 'grid'.

    * Stratiplot: gains ability to draw variable labels above the
    plot panels so that the plots conform to common standards. If
    you prefer the 'strips' of Lattice plots, set 'strip = TRUE'
    to get the old behaviour.

    Stratiplot was fixinging the min(ylim) value at 0 and contained
    redundant calls to set the y-axis limits. The behaviour has been
    rationalised and a new 'ylim' argument added. The default
    behaviour uses the range of the y-data for 'ylim'.

    * panel.Stratiplot: fix warning messages (from Grid) due to
    inappropriate colour specification. Reference lines in
    Stratiplot now plot correctly again.

    * plot.roc: was resetting the plotting region at the end of
    plotting even when there was no need to do so.

    * residuals: Residuals were defined as \hat{x}_i - x_i to match
    fitted vs. observed scatterplots. Definition of residuals in wa()
    and related functions has been changed to the more common
    definition of x_i - \hat{x}. Reported by Andreas Plank and Steve
    Juggins.

    * plot.wa: Following changed definition of residuals, plot.wa()
    now plots observed values on the y-axis and fitted values on the
    x-axis for 'which = 1'.

    * summary.predict.mat: print method was incorrectly extracting
    the model estimates for training set samples.

    * predict.wa: fix minor bug with CV when tolerance DW was used.

    * Package: reduced package check time in examples, by using
    the Imbrie & Kipp data.
~~~~
