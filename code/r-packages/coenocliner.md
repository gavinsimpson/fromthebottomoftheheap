---
title: coenocliner
subtitle: a species abundance simulation package for R
status: publish
layout: page
published: true
type: page
tags: []
active: code
---

## What is coenocliner?

**coenocliner** is an R package to simulate species abundance (count) 
data along environmental gradients.

One of the key ways quantitative ecologists attempt to understand 
the properties and behaviour of the methods they use or dream up is 
through the use of simulated data.

Rather than have to reinvent the wheel each time I wanted to simulate 
some new data for a paper or to work on a new approach, I decided to 
start my own R package to contain a range of simulators encapsulating 
different response models, numbers of gradients, etc.

## Features

At the moment, coenocliner is limited in what it can do practically. 

The main response model is the Gaussian response, which is a 
symmetric model of the parameters; the optimum, tolerance and height 
of the response curve. Count data can be generated from this model 
from either a Poisson or negative binomial distribution, using the 
parameterised Gaussian response as the expectation or mean of the 
distribution.

Additional response models include:

 * The generalised beta response function.

A further feature of **coenocliner** that I hope to develop is to 
include simulation  wrapper functions that replicate the simulation 
methods used in research papers. A working example is `simJamil`, 
which produces simlations from a Gaussian logit response following 
the scheme described in @Jamil2013.
 
## Development

I would like to see coenocliner be as inclusive as possible; if you 
have code to simulate ecological species or community data that is 
just sitting around, consider adding it to coenocliner. In the 
meantime, I'm happy just having something tangible for my own use 
without having to remember the expressions for some of the response 
models.

Currently coenocliner is licensed under the GPL v2, but I'm happy to 
reconsider this if you want to contribute code under a more permissive 
licence.

## Installation

No binary packages are currently available for coenocliner. If you have 
the correct development tools you can compile the package yourself 
after downloading the source code from github. Once I work out how to 
link git with svn I'll start a project on 
[R-forge](http://r-forge.r-project.org) which will host binary packages 
of coenocliner.

If you use Hadley Wickham's **devtools** package then you 
can install coenocliner directly from github using functions that 
devtools provides. To do this, install **devtools** from CRAN via

    install.packages("devtools")

then run

    require("devtools")
    install_github("coenocliner", "gavinsimpson")

## Bugs, feature requests
Bug reports and feature requests should be filed as [issues](https://github.com/gavinsimpson/coenocliner/issues) on [github](https://github.com).

## Licence
**coenocliner** is released under the [GNU General Public Licence Version 2](http://www.gnu.org/licenses/gpl-2.0.html).

## Links

 * [Development site](https://github.com/gavinsimpson/coenocliner/) on [github](https://github.com)

### References
