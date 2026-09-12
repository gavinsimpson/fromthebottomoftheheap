--- 
title: "My aversion to pipes"
status: publish
layout: post
published: true
type: post
tags:
- R
- pipes
- packages
- debugging
active: blog
category: R
---



At the risk of coming across as even more of a curmudgeonly old fart than people already think I am, I really do dislike the current vogue in R that is the pipe family of binary operators; e.g. `%>%`. Introduced by Hadley Wickham and popularised and advanced via the [**magrittr** package](http://cran.r-project.org/web/packages/magrittr/index.html) by Stefan Milton Bache, the basic idea brings the forward pipe of the F# language to R. At first, I was intrigued by the prospect and initial examples suggested this might be something I would find useful. But as time has progressed and I've seen the use of these pipes spread, I've grown to dislike the idea altogether. here I outline why.

The forward pipe operator is designed, in R at least (I'm not familiar with F#), to avoid the sort of nested/inline R code of the type shown below


{% highlight r %}
the_data <- head(transform(subset(read.csv('/path/to/data/file.csv'),
                                  variable_a > x),
                           variable_c = variable_a/variable_b),
                 100)
{% endhighlight %}

replacing that awful mess with


{% highlight r %}
the_data <-
  read.csv('/path/to/data/file.csv') %>%
  subset(variable_a > x) %>%
  transform(variable_c = variable_a/variable_b) %>%
  head(100)
{% endhighlight %}

And when compared against one another like that, who wouldn't rejoice at the prospect of a pipe to banish such awful R code to distant memory? The problem with this comparison though is, *who writes code like that in the first code block*? I don't think I've *ever* written code like that, even when I was a very green useR around the turn of the century.

When you compare the pipe version with how I'd lay out the R code


{% highlight r %}
the_data <- read.csv('/path/to/data/file.csv')
the_data <- subset(the_data, variable_a > x)
the_data <- transform(the_data, variable_c = variable_a/variable_b)
the_data <- head(the_data, 100) # I'm perplexed as to why this would be a good thing to do?
{% endhighlight %}

the benefits of the pipe remain but they aren't, at least in my opinion, as compelling. My version is verbose; I repeatedly overwrite `the_data` object with subsequent operations. Rather the writing `the_data` once in the pipe version, I'd write it 7 times! But that said, I could pass my version to a relative novice useR and they'd have a reasonable grasp of what the code did. I don't think the same could be said for the pipe version.

But all that really doesn't matter does it. It's personal preference as to how you choose to write your data analysis and manipulation R script code. If you find it easier to write code and then read it back using the pipe operator all power to you.

Where I think it does make a difference is where you are

 1. writing code to go into an R package for general consumption on say CRAN, or
 2. writing example material for your package in a vignette or similar document.

I don't claim that these are the only problem areas nor that these are universally accepted. I wager I'm in the majority position at the moment, but that is probably down to the relatively recent arrival of the pipe on the R scene.

Why is the pipe a problem if you are writing code to go into a general purpose R package that you expect users to abuse with their own data in their own code? Two reasons. The pipe operator involves the [standard non-standard evaluation](http://adv-r.had.co.nz/Computing-on-the-language.html) (NSE) paradigm. The pipe captures expressions on each side of the `%>%` operator and then arranges for the thing on the left of `%>%` to be injected into the expression on the right of `%>%`, usually as the first argument but not always. This all involves capturing the expressions and evaluating them within the `%>%()` function.

OK, isn't that what all functions using a formula do, or what `transform()`, `subset()`, *et al* do? Well yes, and this is where my spider sense starts tingling. Who among us hasn't had those things fail on us when we dropped them into an `lapply()` inside an anonymous function? Or wrapped those function as part of a package function only for some user to execute your function in a way you didn't envisage? Now Hadley assures us that there is a correct way to do NSE and he even has a package for that, [**lazyeval**](http://cran.r-project.org/web/packages/lazyeval/). But still I have my reservations, despite Stefan's attempts to allay my fears

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/ucfagls">@ucfagls</a> <a href="https://twitter.com/kevin_ushey">@kevin_ushey</a> <a href="https://twitter.com/JennyBryan">@JennyBryan</a> <a href="https://twitter.com/noamross">@noamross</a> <a href="https://twitter.com/Voovarb">@Voovarb</a> so far none have. You&#39;re welcome to reopen the github issue if you have examples.</p>&mdash; Stefan Milton Bache (@stefanbache) <a href="https://twitter.com/stefanbache/status/603924900135510016">May 28, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

OK, let's assume Stefan and Hadley know what they are doing (and I invariably do) and the NSE used here really is safe. That still leaves the major problem I have with writing R code like this in package functions; how do you read it, parse it, and understand what it does? How do you track down a bug in the code and where it occurs if several steps are conflated into a single pipe chain? I'm not a pipe smoker so I'll have to guess; you undo the chain and see where things break. Wouldn't it have been easier to just write out the steps in the first place? That way the debugger can just step through the statements line by line as you've written them. I'm not alone in having concerns in this general area

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/daattali">@daattali</a> <a href="https://twitter.com/emhrt_">@emhrt_</a> <a href="https://twitter.com/ucfagls">@ucfagls</a> <a href="https://twitter.com/noamross">@noamross</a> <a href="https://twitter.com/recology_">@recology_</a> <a href="https://twitter.com/JennyBryan">@JennyBryan</a> <a href="https://twitter.com/Voovarb">@Voovarb</a> my main worry is that it makes errors harder to understand</p>&mdash; Hadley Wickham (@hadleywickham) <a href="https://twitter.com/hadleywickham/status/603883121197514752">May 28, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

I suppose a lot of this will come down to how well you grok pipes and how well you understand your actual code.

OK, enough of that; on to problem area number 2. I was recently helping a [StackOverflow user massage some output](http://stackoverflow.com/q/30489799/429846) from a **vegan** function into a format suitable for plotting with **ggplot2**. There, the aim was to go from this:

    Group.1                S.obs     se.obs    S.chao1   se.chao1
    Cliona celata complex  499.7143  59.32867  850.6860  65.16366
    Cliona viridis         285.5000  51.68736  462.5465  45.57289
    Dysidea fragilis       358.6667  61.03096  701.7499  73.82693
    Phorbas fictitius      525.9167  24.66763  853.3261  57.73494

to this:

                    Group.1   var        S       se
    1 Cliona celata complex chao1 850.6860 65.16366
    2 Cliona celata complex   obs 499.7143 59.32867
    3        Cliona viridis chao1 462.5465 45.57289
    4        Cliona viridis   obs 285.5000 51.68736
    5      Dysidea fragilis chao1 701.7499 73.82693
    6      Dysidea fragilis   obs 358.6667 61.03096
    7     Phorbas fictitius chao1 853.3261 57.73494
    8     Phorbas fictitius   obs 525.9167 24.66763

(or at least something pretty close it) so that the required *dynamite plot* (yes, yes, I know!) could be produced.

A little fiddling with **reshape2** suggested this wasn't something that it would handle gracefully (I may well be wrong here; I'm not familiar that particular package) and having recalled some details of Hadley's **tidyr** package I felt that it would be more suited to the problem at hand. Not having used **tidyr** I proceeded to CRAN to grab the manual and look at any vignettes that might help me with understanding how to solve this particular problem. Thankfully, Hadley is a conscientious R package maintainer and there was a rather nice [HTML-rendered version of the vignette](http://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html) right there on CRAN for me to peruse. The only downside to this was all the example code used pipes.

The very first usage example is (or was, depending on when you are reading this)


{% highlight r %}
library(tidyr)
library(dplyr)
preg2 <- preg %>% 
  gather(treatment, n, treatmenta:treatmentb) %>%
  mutate(treatment = gsub("treatment", "", treatment)) %>%
  arrange(name, treatment)
preg2
{% endhighlight %}

Innocuous enough I guess, until you realise that I"m also reading the manual which has usage that doesn't involve pipes and that Hadley isn't naming the arguments in the calls here. Now I am having to grok what is being passed, and where, by the pipes, whilst trying to match the usage shown in the example snippet with the arguments in the manual. I might be old-school but yes, I do read the manual.

The point I'm trying to make here with my little anecdote is this; what point did the use of the pipe serve here? How am I as a user new to the package helped by Hadley also using the pipe? In my case I wasn't; in fact it made it somewhat trickier to understand what went where, what the actual **tidyr** calls were etc. Now I fully understand that Hadley finds the pipe operator to be very expressive for data analysis, and who am I to argue with that? Where I would raise an issue is that if you are writing introductory example code, don't force your users to have to grapple with two new concepts at once, at least not in the first few examples.

I don't want to beat on Hadley over this; it's just that this was a prime example of where the use of the pipe was obfuscatory not revelatory, for me at least.

So yes, I am a curmudgeonly old fart, but this old dog can learn new tricks. Convince me I'm wrong here cause I really do want to like the pipe; my Granddad smoked one and I have fond memories of the smell and, well, all the cool kids are using the pipe so it must be good, right?
