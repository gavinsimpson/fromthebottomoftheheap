---
title: canadaHCD
subtitle: Canadian historical climate data
status: publish
layout: page
published: true
type: page
tags: []
active: code
---

## What is canadaHCD?
The Government of Canada's Historical Climate Data [website](http://climate.weather.gc.ca/index_e.html) provides access to hourly, daily, and monthly weather records for stations throughout Canada. These data are exposed through a simple web-based API that facilitates retrieval of data for one or more of the three period in CSV or XML format. *canadaHCD* provides an R-based interface to that API, taking care of forming the correct URL for a data set and of reading the different file formats.

## Bugs, feature requests
**canadaHCD** is still pre-beta code. Please file bug reports or feature requests as [Issues](https://github.com/gavinsimpson/canadaHCD/issues) on the [project's github page](https://github.com/gavinsimpson/canadaHCD)

### Features

 * download monthly, daily, or hourly data from Government of Canada's Historical Climate Data website,
 * search for weather station meta data from the Canadian Historical Climate Data records

## Licence
**canadaHCD** is released under the [GNU General Public Licence Version 2](http://www.gnu.org/licenses/gpl-2.0.html).
