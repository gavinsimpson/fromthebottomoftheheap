--- 
title: "Decluttering ordination plots part 4: orditkplot()"
status: publish
layout: post
published: true
type: post
tags: 
- Graphics
- Ordination
- PCA
- R
- vegan
- Interactive
- Plots
category: R
active: blog
---
Earlier in this series I [looked at](http://www.fromthebottomoftheheap.net/2013/01/12/decluttering-ordination-plots-in-vegan-part-1-ordilabel/) the `ordilabel()` and [then the](http://www.fromthebottomoftheheap.net/2013/01/13/decluttering-ordination-plots-in-vegan-part-2-orditorp/) `orditorp()` functions, and [most recently](http://www.fromthebottomoftheheap.net/2013/06/27/decluttering-ordination-plots-in-vegan-part-3-ordipointlabel/) the `ordipointlabel()` function in the **[vegan](http://cran.r-project.org/package=vegan)** package as means to improve labelling in ordination plots. In this, the fourth and final post in the series I take a look at `orditkplot()`. If you've created ordination diagrams before or been following the previous posts in the irregular series, you'll have an appreciation for the problems of drawing plots that look, well, good! Without hand editing the diagrams, there is little that even `ordipointlable()` can do for you if you want a plot created automagically. `orditkplot()` sits between the automated methods for decluttering ordination plots I've looked at previously and hand-editing in dedicated drawing software like [Inkscape](http://www.inkscape.org) or Illustrator, and allows some level of tweaking the locations of labelled points within R.

To use `orditkplot()`, you'll need an R installation that can use the [Tcl/Tk](http://www.tcl.tk) ecosystem. On Windows this is probably taken care of for you as part of the Windows binaries. Installing Tcl and Tk on a Linux box is pretty straight-forward. The only difficulties I have come across are with MacOS X and that is probably because I don't own any Apple kit and haven't used it much. To check if your R can use Tcl/Tk, run `capabilities()` and look for the `tcltk` element. on my Linux laptop I have

{% highlight rout %}
> capabilities()
   jpeg      png     tiff    tcltk      X11     aqua http/ftp  sockets 
   TRUE     TRUE     TRUE     TRUE     TRUE    FALSE     TRUE     TRUE 
 libxml     fifo   cledit    iconv      NLS  profmem    cairo 
   TRUE     TRUE     TRUE     TRUE     TRUE    FALSE     TRUE
{% endhighlight %}

Assuming your R can use Tcl/Tk, we'll begin.

As with the previous posts, I'll illustrate `orditkplot()` through a PCA of the Dutch Dune Meadow data set distributed with **vegan**. Load the package and the data and fit the PCA; we will use `scaling = 3` throughout
{% highlight r %}
## load vegan and the data
require("vegan")
data(dune)

ord <- rda(dune) ## PCA of Dune data

scl <- 3 ## scaling = 3
{% endhighlight %}

`orditkplot()` will work with any of the ordination objects in **vegan**, but it is best to pass it something that is reasonably close to a good-looking layout. For that, I'll use the configuration of points and labels that `ordipointlabel()` achieves. Create the base plot and store the returned object

{% highlight r %}
## base plot
bplot <- ordipointlabel(ord)
{% endhighlight %}

This we pass to `orditkplot()`

{% highlight r %}
## improve this via orditkplot
orditkplot(bplot)
{% endhighlight %}

Note that when calling `orditkplot()`, you can specify a number of extra arguments that control how the configuration will be drawn on the Tk canvas, as well as pass in some graphical parameters from `?par`; read `?orditkplot` for details of which parameters are currently supported. Not all will affect the look of the rendered plot on the canvas but they do allow another level of control.

Hopefully you will now have a new window on screen that looks like

![PCA biplot of the Dutch dune meadow data produced using `orditkplot()`]({{ site.url }}/assets/img/posts/orditkplot-screen-grab.png)

You can now move labels around on the plot and edit labels. These features are illustrated in the video below, in which I spend a few minutes editing the base plot so that there is no overlap in the labels.

<iframe src="http://player.vimeo.com/video/82920329?color=f43d00" width="500" height="544" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="margin-left: auto; margin-right: auto; display: block; margin-top: 10px; margin-bottom: 10px;"></iframe>

  * To move a label around, lift-click on the label and drag it to a new location. You'll notice that the label is highlighted with a yellow background, and
    that as you move the label around, it is tethered to its score point by a thin line. This last feature allows you to move labels temporarily well out of the way whilst editing and not have to remember which labels belong to which points!
  * A double left-click will bring up a small dialogue box containing the current label text, which can be edited. Hit <kbd>Enter</kbd> once you are happy 
    with a label to close the dialogue and have the change reflected in the plot.
  * You can use the right mouse button (or <kbd>Shift</kbd> + left mouse button) to drag an area to zoom to. This opens another Tk canvas which is itself a separate plot showing only the region of interest; this is an experimental feature and not all arguments are passed to the new canvas. Note that as this is a separate canvas, this feature cannot be used to temporarily zoom in to a region of the current plot to facilitate editing.

The row of buttons along the bottom of the canvas window allow you to export the current plot to one of several graphics formats, dump the plot as a new R object in your session or close the canvas window. The buttons, in order, do

  * The **Copy to EPS** button uses Tcl/Tk functions to render the plot on the canvas to an <abbr class="initialism", title="Encapsulated Postscript">EPS</abbr> file. How well this works out will depend on the capabilities of your OS and the Tcl/Tk version in use. A save dialogue box will open allowing to specify a filename for the plot and where the file will be created.
  * **Export  plot** takes the R representation of the current Tcl/Tk plot and plots it to one of the following devices using `plot.orditkplot()`; <abbr class="initialism", title="Encapsulated Postscript">EPS</abbr>, <abbr class="initialism", title="Portable Document Format">PDF</abbr>, <abbr class="initialism", title="Portable Network Graphics">PNG</abbr>, <abbr class="initialism", title="Joint Photographic Expert Group">JPEG</abbr>, <abbr class="initialism", title="Bitmap file">BMP</abbr>, <abbr class="initialism", title="Tagged Image File Format">TIFF</abbr>.
    
    In addition, the plot can be exported in [Xfig](http://www.xfig.org) format via the same dialogue box. Choose the filetype wanted from the drop-down box, specify a filename and location for the saved file.
  * **Dump to R** creates an object of class `orditkplot` which is a representation of the layout and labels on the current canvas. This is a list with components
  
      + `labels` and `points`; numeric matrices of coordinates for the centres of the labels and points respectively. If you included site and species scores 
        in the base plot, as I did above, then these matrices contain a mixture of both scores. There is no way to directly index the species or the site scores from each matrix.
      + `par` contains relevant graphical parameters. See `?par` for their meaning.
      + `args` contains vectors of other graphical parameters which control how the scores in `labels` and `points` are drawn. `tcol` and `tcex` control the 
        colour and size of the labels for example, whilst `pcol` and `pcex` do the same for the points. This is how the distinction between species and site score points is preserved; they have different parameters controlling how they look. There are a number of other components in this list, including the axis limits.
      + `dim` contains the dimensions of the plot region, the box containing the points and labels.
    
    All of these are sufficient to give a reasonably faithful representation of the plot as it looked on the Tcl/Tk canvas but on a R plot device. This object can be plotted via the `plot()` method `plot.orditkplot()`, and added to as if it were any other R plot.
  * **Dismiss** closes the canvas window.

At the end of the video I used the **Dump to R** feature to create object `bplot2`, which can be plotted on a graphics device

{% highlight r %}
plot(bplot2)
{% endhighlight %}

**vegan** also provides methods for the `points()` and `text()` generics, allowing you to build up a plot in *layers*

{% highlight r %}
## build up plot
plot(ord, type = "n")
points(bplot2, pch = bplot2$args$pch)
text(bplot2, cex = 0.8, col = "navy")
{% endhighlight %}

The plot produced is shown below

![Plot produced by using `points()` and `text()` methods for class `orditkplot`.]({{ site.url }}/assets/img/posts/orditkplot-build-up.png)

In the example above, note that to distinguish between the species and the sites/sample points I needed to refer to the `$args$pch` component of the `bplot2` object. This is because

 1. Once the points are on the Tcl/Tk canvas the correspondence between which are sites/samples and which are species is lost, and
 2. The `points()` method is inconsistent with the `plot()` method and uses the same plotting character for all points[^1].

There is also a `scores()` method if you need to extract the locations of the labels or the points in the coordinate space of the plot.

And with that, we've come to end of the brief tour of the tools that **vegan** provides to help produce ordination plots. If these don't meet your needs, then you can export the plot as an EPS, PDF, or another vector format that can be edited in a vector drawing package like Inkscape. **vegan** provides lots of other functions to enhance ordination plots, and I'll take a look at some of those next year. Use the comments to let me know if of any particular functions you'd like me to cover first.

[^1]: Note to self: I should probably fix that...
