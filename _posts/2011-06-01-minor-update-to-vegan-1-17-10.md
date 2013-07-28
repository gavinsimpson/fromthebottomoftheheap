--- 
title: Minor update to Vegan (1.17-10)
status: publish
layout: post
published: true
type: post
tags: 
- R
- vegan
active: blog
category: R
excerpt: "I overlooked blogging about this at the time, but Jari released a minor update to our Vegan package to fix a few issues following release of R 2.13-0. As far as the user is concerned, this mainly affects `capscale()`. `metaMDSrotate()`, a helper function for rotating nMDS solutions from function `metaMDS()` can now handle missing values via argument `na.rm = TRUE`. The relevant section of the `NEWS` file is reproduced below."
---

{{ page.excerpt | markdownify }}

~~~~
                   CHANGES IN VEGAN 1.17-10

    - This is minor revision that mainly fixes vegan with respect to
      changes in the currently released R 2.13.0. Most importantly,
      cmdscale() output changed in R 2.13.0 and because of this
      capscale() could fail in some rare situations with argument 'add
      = TRUE'. This vegan bug made BiodiversityR package fail its
      tests in R 2.13.0. 

    - metaMDSrotate: gained argument na.rm = TRUE.
~~~~
