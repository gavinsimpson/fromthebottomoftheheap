--- 
title: "radian: a modern console for R"
status: publish
layout: post
published: true
type: post
tags: 
- R
- Software
- Editor
- Code
- Shell
- radian
active: blog
category: R
---

Whenever I'm developing R code or writing data wrangling or analysis scripts for research projects that I work on I use *Emacs* and its add-on package [*Emacs Speaks Statistics*](https://ess.r-project.org/) (*ESS*). I've done so for nigh on a couple of decades now, ever since I switched full time to running Linux as my daily OS. For years this has served me well, though I wouldn't call myself an *Emacs* expert; not even close! With a bit of help from some R Core coding standards document I got indentation working how I like it, I learned to contort my fingers in weird and wonderful ways to execute a small set of useful shortcuts, and I even committed some of those shortcuts to memory. More recently, however, my go-to methods for configuring *Emacs+ESS* were failing; indentation was all over the shop, the smart `_` stopped working or didn't work as it had for over a decade, syntax highlighting of R-related files, like `.Rmd` was hit and miss, and *polymode* was just a mystery to me. Configuring *Emacs+ESS* was becoming much more of a chore, and rather unhelpfully, my problems coincided with my having less and less time to devote to tinkering with my computer setups. Also, fiddling with this stuff just wasn't fun any more. So, in a fit of pique following one to many reconfiguration sessions of *Emacs+ESS*, I went in search of some greener grass. During that search I came across [radian](https://github.com/randy3k/radian), a neat, attractive, simple console for working with R.

Written by [Randy Lai](https://github.com/randy3k), *radian* is a cross-platform console for R that provides code completion, syntax highlighting, etc in a neat little package that runs in a shell or terminal, such as Bash. I'm someone who fires up multiple terminals every day to run some bit of R code, to show a student how to do something, to quickly check on argument names or such like, or prepare an answer to a question on [stackoverflow](https://stackoverflow.com) or [crossvalidated](https://stats.stackexchange.com). Running R in a terminal after using an IDE/environment like *Emacs+ESS* or *RStudio* is an exercise in time travel; all those little helpful editing tools the IDE provides are missing and you're coding like it was the 1980s all over again. *radian* changes all that.

*radian* is a Python application so to run it you'll need a python stack installed. You'll also need a relatively recent version of R (&ge; 3.4.0). Using `pip`, the python package installer, installing *radian* is straightforward. Python v3 is recommended and on Fedora this mean I had to install using

```
pip-3 install --user radian
```

The `--user` flag does an user install, which sets the installation location to be inside your home directory. Once installed, you can start *radian* by simply typing the application name and hitting enter

```
radian
```

A nice configuration tip included in the *radian* `README.md` is to alias the `radian` command to `r`, so that running `R` runs the standard *R* console, while running `r` starts *radian*. On Fedora, you configure this alias in your `~/.bashrc` file

```
alias r="radian"
```

Having started *radian* you'll see something like this

![*radian* at start-up running in a *bash* shell on Fedora]({{ site.url }}/assets/img/posts/radian-startup.png)

*radian* starts up with a simple statement of the R version running in *radian* and the platform (OS) it's running on; so is it just a less-verbose version of the standard R console? The *radian* prompt hints at the greater capabilities however.

Code completion is a nice addition; yes, you have some form of code completion in the standard R console but in *radian* we have a more *RStudio* or *Emacs+ESS*-like experience with a drop-down menu for object, function, argument, and filename completion. To activate this you start typing, hit <kbd>Tab</kbd> and the relevant completions pops up. Hit <kbd>Tab</kbd> again or press the down cursor and you can scroll through the potential completions.

![Code completion in *radian*]({{ site.url }}/assets/img/posts/radian-completion.png)

We also get nice syntax highlighting of R code using the colour schemes from [*pygments*](https://help.farbox.com/pygments.html):

![Syntax highlighting in *radian* using the *monokai* theme]({{ site.url }}/assets/img/posts/radian-syntax-highlighting.png)

And, if you're copying & pasting code into the terminal or piping code in from a editor with an embedded terminal (that's running *radian*) then you also get rather handy multiline editing. Pressing the up cursor <kbd>&uarr;</kbd> will retrieve the previous set of commands pasted or piped into *radian*, and repeatedly pressin <kbd>&uarr;</kbd> will scroll back through the history. If you want to edit a set of R calls, instead of pressing <kbd>&uarr;</kbd> again, press <kbd>&larr;</kbd> to enter the chunk of code and then you can move around among the lines using the cursor keys, editing as you see fit. Hitting enter will run the entire chunk of code for you, edits and all:

![Multiline editing a *ggplot* call in *radian*]({{ site.url }}/assets/img/posts/radian-multiline-editing.gif)

You can configure aspects of the behaviour of *radian* via `options()` in your `.Rprofile`. The options I'm currently using on the computer used for the screenshots in this post are:

```
options(radian.auto_indentation = FALSE)
options(radian.color_scheme = "monokai")
```

but on my laptop I'm currently using

```
# auto match brackets and quotes
options(radian.auto_match = TRUE)

# auto indentation for new line and curly braces
options(radian.auto_indentation = TRUE)
options(radian.tab_size = 4)

# timeout in seconds to cancel completion if it takes too long
# set it to 0 to disable it
options(radian.completion_timeout = 0.05)

# insert new line between prompts
options(radian.insert_new_line = FALSE)
```

The last option is something I'm not sure about yet; as you can see in the screenshots, there's a new line between the prompts, which makes it super easy to read the R code you've entered, but with the font I'm currently using ([Iosevka](https://github.com/be5invis/Iosevka)) things look a bit too spread out. Setting `radian.insert_new_line = FALSE`, as I have it on the laptop results in more standard behaviour but it can feel a little cramped. I'll probably play with both options and see which I like best after a few more weeks of use.

You can also define shortcuts. This is useful for entering the assignment operator `<-`, which I have bound to <kbd>Alt</kbd> + <kbd>-</kbd> using

```
options(radian.escape_key_map = list(
          list(key = "-", value = " <- ")
        ))
```

where I've added spaces around the operator to mimic how the smart underscore works in *Emacs+ESS*.

I'm really liking using *radian* for my throw-away R sessions that I typically do in a terminal. The only issue I've noticed is that it is a little slow to print tibbles, and clearly it's not going to replace my current IDE &mdash; that's not what it is designed for. That said, *radian* can be run inside any app that can run a terminal and I've had this running inside [VS Code](https://code.visualstudio.com/) for example, which was nice.

If you have any comments on *radian* or other R consoles, let me know what you think below; if you've used *radian* I'm especially interested in your experience with it.
