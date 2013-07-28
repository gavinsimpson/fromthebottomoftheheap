--- 
title: "Embedding a time series with time delay in R &mdash; Part II"
status: publish
layout: post
published: true
type: post
tags: 
- Embed
- Time delay
- Time series
active: blog
category: R
excerpt: "Some months ago, I [posted]({{ site.url }}/2011/01/21/embedding-a-time-series-with-time-delay-in-r/ 'Embedding a time series with time delay in R') a function that extended the base [R](http://www.r-project.org 'R Website') function `embed()` to allow for time delay embedding. Today, David Gonzales [alerted]({{ site.url }}/2011/01/21/embedding-a-time-series-with-time-delay-in-r/#comment-870452698 'Link to David's comment') me to an inconsistency between `embed()` and `Embed()`."
---

{{ page.excerpt | markdownify  }}

The example David used was

{% highlight rout %}
R> (x <- seq(1,20,3))
[1]  1  4  7 10 13 16 19
R> embed(x, 4)
     [,1] [,2] [,3] [,4]
[1,]   10    7    4    1
[2,]   13   10    7    4
[3,]   16   13   10    7
[4,]   19   16   13   10
R> Embed(x, 4)
     [,1] [,2] [,3] [,4]
[1,]    4    3    2    1
[2,]    7    6    5    4
[3,]   10    9    8    7
[4,]   13   12   11   10
{% endhighlight %}

where `Embed()` clearly returns an incorrect result.

In this post, I present an explanation of the problem and address the shortcomings in the original code with an updated version of `Embed()`.

The reason the original version of `Embed()` doesn't work with David's example is that when I wrote it, I had in mind that it would work on the *indices* of the time series, not the values of the time series. I had overlooked that `embed()` returned the embedded time series, not the indices &mdash; the problem of testing with
vectors like `1:10`!

Updating `Embed()` to output the same result as `embed()` is a trivial matter; we just get the function to work with `seq_along(x)` and not `x` itself and then use the old `Embed()` behaviour to index `x` to return the embedded time series. As an added extra, as we are generating the indices anyway, we can optionally have the function return those instead of the embedded series.

Here is the updated version of `Embed()`

{% highlight r %}
Embed <- function(x, m, d = 1, indices = FALSE, as.embed = TRUE) {
    n <- length(x) - (m-1)*d
    X <- seq_along(x)
    if(n <= 0)
        stop("Insufficient observations for the requested embedding")
    out <- matrix(rep(X[seq_len(n)], m), ncol = m)
    out[,-1] <- out[,-1, drop = FALSE] +
        rep(seq_len(m - 1) * d, each = nrow(out))
    if(as.embed)
        out <- out[, rev(seq_len(ncol(out)))]
    if(!indices)
        out <- matrix(x[out], ncol = m)
    out
}
{% endhighlight %}

The main difference is that we create `X <- seq_along(x)` and create `out` using that rather than the time series (`x`). I've also added a new argument, `indices`, that defaults to `FALSE`. If we want `Embed()` to return the indices of the embedded time series, call the function with `indices = FALSE`.

The new version of `Embed()` gives the same results as before and is consistent with `embed()` when we pass it a time series that is identical to its indices

{% highlight rout %}
R> embed(1:5, 2)
     [,1] [,2]
[1,]    2    1
[2,]    3    2
[3,]    4    3
[4,]    5    4
R> Embed(1:5, 2)
     [,1] [,2]
[1,]    2    1
[2,]    3    2
[3,]    4    3
[4,]    5    4
{% endhighlight %}

but it also works for time series like those in David's example:

{% highlight rout %}
R> (x <- seq(1,20,3))
[1]  1  4  7 10 13 16 19
R> embed(x, 4)
     [,1] [,2] [,3] [,4]
[1,]   10    7    4    1
[2,]   13   10    7    4
[3,]   16   13   10    7
[4,]   19   16   13   10
R> Embed(x, 4)
     [,1] [,2] [,3] [,4]
[1,]   10    7    4    1
[2,]   13   10    7    4
[3,]   16   13   10    7
[4,]   19   16   13   10
{% endhighlight %}

and we have the added benefit of being able to return the indices of the embedded time series

{% highlight rout %}
R> Embed(x, 4, indices = TRUE)
     [,1] [,2] [,3] [,4]
[1,]    4    3    2    1
[2,]    5    4    3    2
[3,]    6    5    4    3
[4,]    7    6    5    4
{% endhighlight %}

Now I just need to do something on the recurrence plot that I originally wrote `Embed()` for!
