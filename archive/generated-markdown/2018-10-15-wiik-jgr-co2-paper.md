--- 
title: "Controls on subannual variation in pCO<sub>2</sub> in productive hardwater lakes"
status: publish
layout: post
published: true
type: post
tags:
- papers
- pCO2
- CO2
- GAM
- lakes
- climate
- hardwater
- timeseries
- DIC
- pH
active: blog
category: science
date: 2018-10-15 17:00:00
twitterimg: wiik-et-al-2018-figure-4.png
---

This year is looking like a bumper year for papers from the lab and collaborations, past and ongoing. Over the [summer hiatus]({{ site.baseurl }}{% post_url 2018-10-15-summer-hiatus %}) three papers came out online in their version-of-record form. The first of these was a paper on work that Emma Wiik, a former postdoc in my lab and Peter Leavitt's lab, conducted to further our research on the controls on CO~2~ exchange between lakes and the atmosphere.

Lakes play an important role in processing terrestrial carbon and influence carbon fluxes at the global scale. Unpacking the detail of the respective controls on CO~2~ exchange with the atmosphere is an active and productive area of limnological research. In 2015, we published [@Finlay2015-bw] an analysis of time series data of CO~2~ flux from hardwater prairie lakes, which showed that as these lakes warmed due to climate change, the efflux of CO~2~ from the lakes actually decreased. This result was contrary to those observed in northern Boreal lakes, and reflects the need to study a range of lake types when generalizing from individual research projects to global scale assessments of the role of lakes in the carbon cycle.

Emma's paper [@Wiik2018-ve], which was published in [Journal of Geophysical Research: Biogeosciences](https://doi.org/10.1029/2018JG004506) in May, took a closer look than the 2015 paper at the controls on CO~2~ exchange. Across the six Qu'Appelle lakes in the the 2015 study, we'd focused on trends in pH and CO~2~ flux and the control of annual CO~2~ flux by ice-cover duration, yielding results that spoke to the multi-annual to decadal scale relationships between CO~2~ exchange and the important drivers. In the new paper, we used generalized additive models (GAMs) to model the full 18-year time series of limnological data.

Two GAMs were fitted and described in the paper. The first modelled CO~2~ flux as a smooth function of lake pH over all six lakes, allowing for lake-specific effects of pH on CO~2~ as well as accounting for change over time. Our CO~2~ data were not directly measured, instead being calculated from geochemical equations, including pH. Hence this first model was simply to quantify how much of the variation in CO~2~ we could explain using pH. As the latter was used to calculate the former, the explained variation was high, but never equal to 1.

Having established that pH was the primary control on CO~2~ exchange in the six study lakes we wanted to try to model the lake water pH observations using a series of selected climatic and metabolic variables, chosen to reflect the major factors thought to control CO~2~ exchange. A second GAM was fitted with pH as the response variable and lake specific smooth functions of the metabolic and climatic variables.

Through the second GAM, we were able to show that in the six Qu'Appelle study lakes that metabolic drivers of CO~2~ flux we more important at the daily--monthly scale than climatic drivers, while the latter were more important at the interannual scale.

![Figure 4 from the paper. (a–c) GAM partial effect splines for significant metabolic variables. Dotted lines: means of $y$ and $x$; Shaded area: middle 90% of all observations. Rug: data points. (a) GAM splines for chlorophyll a, with lakes with significantly different splines to the global spline indicated by color/hue and linetype. (b) GAM spline of oxygen, with standard errors indicated by shading. (c) GAM spline of dissolved organic carbon, with standard errors indicated by shading.]({{ site.url }}/assets/img/posts/wiik-et-al-2018-figure-4.png "Figure 4 from Wiik et al 2018.")

The paper is available from the [journal website](https://doi.org/10.1029/2018JG004506) or via a [preprint]({{ site.baseurl }}/assets/reprints/wiik-2018-jgr-b-co2-preprint.pdf) if you do not have access to Journal of Geophysical Research: Biogeosciences.

### References
