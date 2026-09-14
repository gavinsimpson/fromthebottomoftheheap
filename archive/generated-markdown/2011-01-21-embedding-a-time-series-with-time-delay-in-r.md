--- 
title: Embedding a time series with time delay in R
status: publish
layout: post
published: true
type: post
tags:
- Embed
- Time series
active: blog
category: R
excerpt: "I've recently been looking at [Martin Trauth](http://www.geo.uni-potsdam.de/member-details/show/108.html 'Martin Trauth's web page at The University of Potsdam Institute of Earth and Environmental Science')&apos;s book [MATLAB® Recipes for Earth Sciences](http://www.springer.com/earth+sciences+and+geography/computer+&+mathematical+applications/book/978-3-642-12761-8 'Matlab book page at Springer') to try to understand what some of my palaeoceanography colleagues are doing with their data analyses (lots of frequency domain time series techniques and a preponderance of filters). Whilst browsing, the [recurrence plot](http://en.wikipedia.org/wiki/Recurrence_plot 'Recurrence plots entry in Wikipedia') section caught my eye as something to look into further, both for palaeo-based work but also for work on ecological thresholds and tipping points."
---

{{ page.excerpt | mardownify }}

In a recurrence plot, the recurrences of a phase space are plotted. As we tend not to have the phase space, just the time series of observations, we [embed](http://en.wikipedia.org/wiki/Embedding) the observed series to produce the *m* dimensional phase space. A key feature of the recurrence plot is the *time delay* included during embedding. There is an `embed()` function in R but it does not handle the time delay aspects that one needs for the recurrence plot, so I decided to write my own. The results are shown below in my function `Embed()`. It has been written to replicate the standard R `embed()` function where `d = 1` (i.e. no time delay), which is a useful check that it is doing the right thing.

{% highlight r %}
Embed <- function(x, m, d = 1, as.embed = TRUE) {
    n <- length(x) - (m-1)*d
    if(n <= 0)
        stop("Insufficient observations for the requested embedding")
    out <- matrix(rep(x[seq_len(n)], m), ncol = m)
    out[,-1] <- out[,-1, drop = FALSE] +
        rep(seq_len(m - 1) * d, each = nrow(out))
    if(as.embed)
        out <- out[, rev(seq_len(ncol(out)))]
    out
}
{% endhighlight %}

The arguments are:

-   `x`: the time series, observed at regular intervals.
-   `m`: the number of dimensions to embed `x` into.
-   `d`: the time delay.
-   `as.embed`: logical; should we return the embedded time series
    in the order that `embed()` would?

On a simple time series, this is what we get using `embed()` and `Embed()`:

{% highlight rout %}
> embed(1:10, 4)
     [,1] [,2] [,3] [,4]
[1,]    4    3    2    1
[2,]    5    4    3    2
[3,]    6    5    4    3
[4,]    7    6    5    4
[5,]    8    7    6    5
[6,]    9    8    7    6
[7,]   10    9    8    7
> Embed(1:10, 4)
     [,1] [,2] [,3] [,4]
[1,]    4    3    2    1
[2,]    5    4    3    2
[3,]    6    5    4    3
[4,]    7    6    5    4
[5,]    8    7    6    5
[6,]    9    8    7    6
[7,]   10    9    8    7
{% endhighlight %}

And here we have the results of
embedding the same simple time series into 4 dimensions with a time
delay of 2:

{% highlight rout %}
> Embed(1:10, 4, 2)
     [,1] [,2] [,3] [,4]
[1,]    7    5    3    1
[2,]    8    6    4    2
[3,]    9    7    5    3
[4,]   10    8    6    4
{% endhighlight %}

So what does embedding do? Without additional time delay, `embed()` and `Embed()` produce a matrix with `m` columns containing the original time series and lagged versions of it, each column a lag 1 version of the previous column. Incomplete rows, that arise due to the lagging of the series with itself, are discarded. You can see this in the identical calls to `embed()` and `Embed()` shown above. There were 10 observations in the series, and we asked for 4 lag 1 versions of this series. Hence each of the series in the embedded version contains just seven observations; we loose three observations because the 2nd, 3rd, and 4th columns are progressively shifted by 1 time unit relative to the original series.

Time delay embedding allows for additional delay between the lagged versions of the original series. If `d = 2`, then each of the `m - 1` new series is lagged by 2 time intervals. This is shown in the final example above, with `Embed(1:10, m = 4, d = 2)`, where the entries within the rows are offset by 2. However, the embedded series now contain just four observations.

How we use this to produce a recurrence plot will be covered in a separate post.
