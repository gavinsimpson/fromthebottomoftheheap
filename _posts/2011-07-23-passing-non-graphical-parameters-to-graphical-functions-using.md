--- 
title: Passing non-graphical parameters to graphical functions using ...
status: publish
layout: post
published: true
type: post
tags: 
- R
- Programming
- Functions
active: blog
category: R
excerpt: "Argument passing via `...` is a great feature of the R language, allowing you to write wrappers around existing functions that do not need to list all the arguments of the wrapped function. `...` is used extensively in S3 methods and in passing graphical parameters on to graphical functions. When writing you own plot methods, using `...` allows the user of your function to pass arguments like `cex`, `col`, `lty`, etc. on to the plotting function inside your method. You do, however, need to be careful in where you use `...` and which functions you pass `...` on to."
---

{{ page.excerpt | markdownify  }}

Consider the following object `FOO` that is a data frame with our own class `"foo"`

{% highlight r %}
FOO <- data.frame(x = 1:10, y = 1:10)
rownames(FOO) <- LETTERS[1:10]
class(FOO) <- "foo"
{% endhighlight %}

A simplified `plot()` method to plot the `x` and `y` components of our object, displaying the data as points or text labels might be


{% highlight r %}
plot.foo <- function(X, type = c("points","text"), ...) {
    x <- X$x
    y <- X$y
    type <- match.arg(type)
    plot(x, type = "n", ...)
    if(type == "points") {
        points(x, y, ...)
    } else {
        text(x, y, labels = rownames(x), ...)
    }
    invisible(x)
}
{% endhighlight %}

Note that we are passing `...` on to each of `plot()`, `points()`, and `text()` so our method is very simple. However, if we try to suppress the drawing of axes using the `axes` argument of `plot.default()`, our method will generate errors

{% highlight rout %}
> plot(FOO, axes = FALSE)
Warning message:
In plot.xy(xy.coords(x, y), type = type, ...) :
  "axes" is not a graphical parameter
{% endhighlight %}

Turning warnings into errors, we see that the call to `points()` is where the warning originates (actually in `plot.xy()`, frame 5, but `points()` is the offending code in our method)

{% highlight rout %}
> options(warn = 2) ## turn warnings to errors
> 
> plot(FOO, axes = FALSE)
Error in plot.xy(xy.coords(x, y), type = type, ...) : 
  (converted from warning) "axes" is not a graphical parameter
> ## look at the call stack
> traceback()
9: doWithOneRestart(return(expr), restart)
8: withOneRestart(expr, restarts[[1L]])
7: withRestarts({
       .Internal(.signalCondition(simpleWarning(msg, call), msg, 
           call))
       .Internal(.dfltWarn(msg, call))
   }, muffleWarning = function() NULL)
6: .signalSimpleWarning("\"axes\" is not a graphical parameter", 
       quote(plot.xy(xy.coords(x, y), type = type, ...)))
5: plot.xy(xy.coords(x, y), type = type, ...)
4: points.default(x, y, ...)
3: points(x, y, ...)
2: plot.foo(FOO, axes = FALSE)
1: plot(FOO, axes = FALSE)
{% endhighlight %}

The warning results from our function passing `axes = FALSE` on to the lower-level plotting functions. An obvious solution is to process `...` and strip out any offending non-graphical parameters and then arrange for the calls to use the stripped out `...`. Doing this is possible, but is very complicated. There is an
alternative, simpler solution that is used in several base R functions and suggested to me by Brian Ripley (when I asked about doing this on R-Help for a function in the vegan package). The trick is to have a local, in-line wrapper around `points()` of the following form:

{% highlight r %}
lPoints <- function(..., log, axes, frame.plot, panel.first, panel.last) { 
    points(...)
}
{% endhighlight %}

Here we list all the arguments of `plot.default()` we *don't* want passed on to the low-level plotting calls, but importantly, they are listed *after* `...`. The only code in the body of the local function is a call to the low-level graphics function we want to use. Importantly, of the arguments taken by `lPoints()` only `...` is passed on to the graphics function it wraps. Because the arguments from `plot.default()` are named and come after `...` in the definition of `lPoints()`, any arguments passed to `lPoints()` that fully match the named arguments are automatically stripped from the `...` that is passed on to the wrapped function. Using this trick, we can now write our `plot.foo()` method like this:

{% highlight r %}
plot.foo <- function(X, type = c("points","text"), ...) {
    lPoints <- function(..., log, axes, frame.plot,
                        panel.first, panel.last) points(...)
    lText <- function(..., log, axes, frame.plot,
                      panel.first, panel.last) text(...)
    x <- X$x
    y <- X$y
    type <- match.arg(type)
    plot(x, type = "n", ...)
    if(type == "points") {
        lPoints(x, y, ...)
    } else {
        lText(x, y, labels = rownames(x), ...)
    }
    invisible(x)
}
{% endhighlight %}

Now we can pass arguments to both `plot.default()` and `points()` and `text()`, and the call that raised the warning earlier, now works without complaint:

{% highlight rout %}
> plot(FOO, axes = FALSE)
>
{% endhighlight %}

Remember to reset the warning level if you followed the code above

{% highlight r %}
options(warn = 0)
{% endhighlight %}
