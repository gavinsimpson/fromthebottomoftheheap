--- 
title: Why I love open source!
status: publish
layout: post
published: true
type: post
tags: 
- R
- vegan
category: R
active: blog
excerpt: "Today I had a great reminder of why I love open source software and why I spend a bit of my time contributing [R](http://www.r-project.org 'R Project Website') code to several packages."
---

{{ page.excerpt | markdownify  }}

In the [vegan](https://r-forge.r-project.org/projects/vegan/ "Vegan website") package, I had included some code to do an analysis of multivariate dispersions. Bone-headedness on my part meant that if you tried to plot the ordination results behind the model/test for any axes other than the first two, the code failed. A user (Sarah Goslee) spotted this and emailed me with a fix to the code, that I had integrated and added to the vegan source tree on R-Forge within about 30 mins of Sarah's email landing in my in-box.

This particular bug was fixed in the forthcoming 1.17.5 release of vegan.

Don't you just love open source!
