biol803-2015
============

Slide deck for two open science seminars given as part of Biol803, the 
graduate skills course of the Department of Biology at the University 
of Regina, Canada.

## Building the slide deck

The slides are generated from the `open-science.Rmd` source file using 
the **rmarkdown** package for R (yes, even though there is no R code 
anywhere in sight!). To rebuild the slide deck locally or to render 
modifications to the sources you will need the `rmarkdown` package 
installed and *all* of it's dependencies and system requirements.

See the **rmarkdown** [website](http://rmarkdown.rstudio.com/) and 
[github repo](https://github.com/rstudio/rmarkdown) for installation 
instructions and system requirements requirements.

A `Makefile` is present to simplify rebuilding the slides. Assuming a 
working R installation and that the `Rscript` programme is in your 
path, the slide deck can be rebuilt from a command prompt using `make`

```
make slides
```

Alternatively, assuming R's current working directory is the directory 
containing `open-science.Rmd`, the following R snippet will render the 
slide deck

```r
rmarkdown::render('open-science.Rmd')
```

## Reuse

The slide deck is, unless noted in the slides or in 
[LICENCE](./LICENCE) copyright &copy; 2013--2015 Gavin L. Simpson and 
it and the source files are released under a Creative Commons 
Attribution Licence:

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons Licence" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.

See [LICENCE](./LICENCE) for exceptions and details of other copyright 
holders of the HTML framework used for the slides and the images used.
