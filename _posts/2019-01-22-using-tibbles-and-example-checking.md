--- 
title: "Tibbles, checking examples, & character encodings"
date: 2019-01-22 13:00:00
status: publish
layout: post
published: true
type: post
tags:
- tibble
- check
- testing
- package
- developer
active: blog
category: R
---



Recently I've been preparing my [**gratia** package](https://gavinsimpson.github.io/gratia/) for submission to CRAN. During my pre-flight testing I noticed an issue under Windows checking the examples in the package against the reference output I generated on linux. In the latest release of the [**tibble** package](https://tibble.tidyverse.org/), the way tibbles are printed has changed subtly and in a way that leads to cross-platform differences. As I write this, tibbles with more than a set number of rows are printed in a truncated form, showing only the first 10 rows of data. In such cases, a final line is printed with an ellipsis and a note as to how many more rows are in the tibble. It was this ellipsis that was causing the cross-platform issue where differences between the output generated on windows and the reference output were being identified during `R CMD check` on Windows. If this is causing you an issue, here's one way to solve the problem.

The problem is this:

{% highlight r %}
library('tibble')
as_tibble(iris)
{% endhighlight %}



{% highlight text %}
# A tibble: 150 x 5
   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
          <dbl>       <dbl>        <dbl>       <dbl> <fct>  
 1          5.1         3.5          1.4         0.2 setosa 
 2          4.9         3            1.4         0.2 setosa 
 3          4.7         3.2          1.3         0.2 setosa 
 4          4.6         3.1          1.5         0.2 setosa 
 5          5           3.6          1.4         0.2 setosa 
 6          5.4         3.9          1.7         0.4 setosa 
 7          4.6         3.4          1.4         0.3 setosa 
 8          5           3.4          1.5         0.2 setosa 
 9          4.4         2.9          1.4         0.2 setosa 
10          4.9         3.1          1.5         0.1 setosa 
# … with 140 more rows
{% endhighlight %}

Note that little ellipsis on the last line. Yes, those three little dots &mdash; that &hellip; was what was causing all the trouble. Don't get me wrong, I'm all on board when it comes to proper typography, but for something so small, that one &hellip; caused a good deal of hair-pulling as I prepared my package for a clean submission to CRAN!

On Windows you won't see that cute little &hellip;; instead you'll see this


{% highlight r %}
as_tibble(iris)
{% endhighlight %}



{% highlight text %}
# A tibble: 150 x 5
   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
          <dbl>       <dbl>        <dbl>       <dbl> <fct>  
 1          5.1         3.5          1.4         0.2 setosa 
 2          4.9         3            1.4         0.2 setosa 
 3          4.7         3.2          1.3         0.2 setosa 
 4          4.6         3.1          1.5         0.2 setosa 
 5          5           3.6          1.4         0.2 setosa 
 6          5.4         3.9          1.7         0.4 setosa 
 7          4.6         3.4          1.4         0.3 setosa 
 8          5           3.4          1.5         0.2 setosa 
 9          4.4         2.9          1.4         0.2 setosa 
10          4.9         3.1          1.5         0.1 setosa 
# ... with 140 more rows
{% endhighlight %}

Yes, a rather ugly, second-rate approximation of the &hellip;, I think you'll agree!

I have to thank Brodie Gaslam [(\@BrodieGaslam)](https://twitter.com/BrodieGaslam) on Twitter) for identifying the source of the difference between output on Linux and Windows and for suggesting the solution I show below. What Brodie identified was that the [**cli**](https://github.com/r-lib/cli) package, which **tibble** uses to show this ellipsis, contains code to determine what system it is running on and to adjust it's output accordingly. So, on Linux you see `…` and on Windows you see `...`, *because* (I assume many) Windows systems aren't set up to understand what `…` is. What I see on Linux is thanks to Unicode (specifically I have UTF-8 encoding in my Linux sessions) but this doesn't work (or, as easily) on Windows, which defaults to a different character set or encoding, and which has no idea what `…` is.

As it turns out, there doesn't appear to be a simple way to make Windows, certainly not the CRAN Windows build system. But what we can do, which is what Brodie mentioned to me on Twitter, is to set a global option that the **cli** package looks for to control its behaviour on **Linux**. That's right, we're going to reduce output generated under `R CMD check` to the lowest common denominator; the user will still get the benefit of the fancy typography that **cli** affords their R sessions, but we don't need that fanciness for checking the examples.

The option you need is `cli.unicode` and it needs to be set to `FALSE`. Here it is in action


{% highlight r %}
as_tibble(iris)
op <- options(cli.unicode = FALSE)
as_tibble(iris)
options(op)
{% endhighlight %}



{% highlight text %}
# A tibble: 150 x 5
   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
          <dbl>       <dbl>        <dbl>       <dbl> <fct>  
 1          5.1         3.5          1.4         0.2 setosa 
 2          4.9         3            1.4         0.2 setosa 
 3          4.7         3.2          1.3         0.2 setosa 
 4          4.6         3.1          1.5         0.2 setosa 
 5          5           3.6          1.4         0.2 setosa 
 6          5.4         3.9          1.7         0.4 setosa 
 7          4.6         3.4          1.4         0.3 setosa 
 8          5           3.4          1.5         0.2 setosa 
 9          4.4         2.9          1.4         0.2 setosa 
10          4.9         3.1          1.5         0.1 setosa 
# … with 140 more rows
# A tibble: 150 x 5
   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
          <dbl>       <dbl>        <dbl>       <dbl> <fct>  
 1          5.1         3.5          1.4         0.2 setosa 
 2          4.9         3            1.4         0.2 setosa 
 3          4.7         3.2          1.3         0.2 setosa 
 4          4.6         3.1          1.5         0.2 setosa 
 5          5           3.6          1.4         0.2 setosa 
 6          5.4         3.9          1.7         0.4 setosa 
 7          4.6         3.4          1.4         0.3 setosa 
 8          5           3.4          1.5         0.2 setosa 
 9          4.4         2.9          1.4         0.2 setosa 
10          4.9         3.1          1.5         0.1 setosa 
# ... with 140 more rows
{% endhighlight %}

To make this work in an example, you will want to include it in a `\dontshow` block, which will not show up in the help for the function, nor will it be executed if a user runs the example via `example()`. Setting the option this way will only happen during testing via `R CMD check`.

In the [**roxygen2**](https://github.com/klutometis/roxygen) sources for [my example](https://github.com/gavinsimpson/gratia/blob/master/R/derivatives.R#L57-L69) I now have


{% highlight r %}
@examples

\dontshow{
op <- options(cli.unicode = FALSE)
}
# do something here
\dontshow{options(op)}
{% endhighlight %}

This idiom is required to handle more issues than just this character encoding problem. Most of my examples use simulated data, so I need a `set.seed()` call inside `\dontshow{}`. If you are showing the results of any statistical model, you'll already be reducing the number of digits shown in the output via `options(digits = 5)` as CRAN gets annoyed if you are checking results to silly levels of precision. The user doesn't need to see any of this.

I should note that I'm not using this checking of example output as true unit test (there's loads of those in the `/tests` folder of the package thank you very much), but I do still think that checking the output of examples against reference output is useful. At the very least it doesn't (usually) hurt to check the output when it's being generated as part of the checks anyway. I also want useful examples so I tend to show snippets of outputs as part of the example. Having the comparison between expected and actual output is a handy check of what I'm presenting to the user.

Hopefully this is useful to people coming across the same or similar issues with their packages. And thanks again to Brodie for explaining what the problem was.
