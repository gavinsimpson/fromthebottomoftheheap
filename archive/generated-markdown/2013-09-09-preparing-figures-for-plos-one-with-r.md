--- 
title: "Using Arial in R figures destined for PLOS ONE"
status: publish
layout: post
published: true
type: post
tags: 
- "Plotting"
- "R"
- "Graphics"
- "Publications"
- "Journals"
category: R
active: blog
---

Despite the refreshing change that the journal [PLOS ONE](http://www.plosone.org/) represents in terms of open access and an refreshing change to the stupidity that is quality/novelty selection by the two or three people that review a paper, it's submission requirements are far less progressive. Yes they make you [jump through a lot of hoops](http://www.plosone.org/static/figureGuidelines) getting your figures and tables just so, and I can appreciate why they want some control over this in terms of the look and feel of the journal. A couple of things grate though:

 * The insistence on only <acronym title="Encapsulated Postscript">EPS</acronym> files as the single acceptable vector-format
 * The insistence that Arial be used as the font face in the figures

The choice of EPS is a pain, but can be worked round relatively easily and R can output to an EPS file via the `postscript()` device, as long as you follow a few basic guidelines, which I'll cover below. But the use of Arial! *facepalm*...

Firstly, you may not legally be able to install these fonts on your computer (even though they are available in several forms on the internet) unless you have a licence for a Microsoft product that ships them --- though given the dominance of Windows in the consumer PC market, most people will have a valid Windows licence somewhere. Secondly, you need to work very hard to use these fonts in some applications, including R as we'll see, simply because those applications were built to use different or open font definitions.

What is doubly frustrating about this is that there are entirely free and open fonts that could be mandated by PLOS ONE. The [Liberation Fonts suite](https://fedorahosted.org/liberation-fonts/) for example is one such set of fonts, the creation of which was sponsored by Red Hat. The aim was to provide a font that is metric compatible (i.e. the glyphs occupy the same physical space) with Microsoft's Arial, Times New Roman, and Courier New fonts that are prevalent in the Windows world. The Liberation Fonts aren't *copies* of the Microsoft ones, but for a given string, they should occupy the same amount of real estate in the document or on screen. Or PLOS ONE could have stuck with the standard set of Postscript fonts, for which there are free equivalents.

Bob O'Hara [raised this issue over a year ago](http://occamstypewriter.org/boboh/2012/04/25/why_does_plos_hate_openness/), and Michael Eisen took the time to  [comment](http://occamstypewriter.org/boboh/2012/04/25/why_does_plos_hate_openness/#comment-2528) that this was an acknowledged issue and indicated that the problems stemmed from the publishing tools used by PLOS.

Despite the draconian restrictions, PLOS ONE does have a pretty good [set of instructions or tips](http://www.plosone.org/static/figureGuidelines) to go alongside them, to help authors prepare figures for the journal. These instructions even include some tips on creating your figures in R with the Arial font family. These instructions basically involve converting the `.ttf` (TrueType font files) into `.afm` (Adobe Font Metric) files via the `tt2afm` utility and subsequently registering the `.afm` files with R's `postscript()` plotting device.

Firstly, the instructions refer to an older way of specifying font families (as a vector paths to four or five `.afm` files --- the fifth file would be for the Symbol font, and if missing R will use the default); there is no reason to presume that R will continue to maintain this backwards-compatible behaviour. Second, they require the user to get and install the `tt2afm` utility (or some other utility that achieves the same job). Thirdly, the instructions are incomplete if you wish to have the figure reproduce on any system; the fonts need to be embedded for those users that don't have Arial installed. Admittedly, PLOS ONE's production system *will* have these fonts, so that this is missing is irrelevant, but it is something one may need to consider when working with colleagues using a range of OSes.

The new way of referring to font families is a little more convoluted now in modern versions of R. Thankfully, a very simple solution is present that handles the registration of fonts with R's graphics devices, *and* as an added bonus will convert `.tty` font files into the Type1 font equivalents. This solution is Winston Chang's **[extrafont](https://github.com/wch/extrafont)** package. In the code chunks below, I'll walk you through installing and using the package to produce a figure suitable for submission to PLOS ONE or any other journal that demands the use of the proprietary Arial font.

First up, install the **extrafont** package from your local CRAN mirror. For the code below to work, you'll need version 0.15 or later, which was released to CRAN a few days ago (as of writing). **extrafont** relies on two additional packages

 * **extrafontdb** contains the font database that **extrafont** will use. Initially this is an empty package skeleton, but as you'll see in a minute, it will be populated with the information regarding fonts found on your system that you can use within R graphics devices. The reason this is a separate package is that it won't get overwritten each time a new version of the main **extrafont** package is installed. Hence you only need to go through the potentially lengthy process of searching for and converting suitable fonts on system once.
 * **Rttf2pt1** contains an R wrapper for the `ttf2pt1` programme that can convert TrueType fonts into Postscript Type1 fonts, one of the font types that R can use. This is again in a separate package, but this time for licensing reasons. (`ttf2pt1` is licensed under a 3-clause BSD licence while **extrafont** is GPL-2 licensed, if this matters to you.)

As all of this is available on CRAN, thanks to Winston and the CRAN maintainers, you can get up and running simply by installing **extrafont** via

{% highlight r %}
install.packages("extrafont")
{% endhighlight %}

Assuming that the package installs for you then each time you wish to use it, you need to load the package into your R session (as with most other R packages)

{% highlight r %}
library("extrafont")
{% endhighlight %}

The first time you use the package, you will need to register fonts with the **extrafont** database. This process will search your computer for fonts, register them with the database and convert the font metric information in the `.ttf` files into `.afm` equivalents, plus a number of other steps like linking to the `.ttf` files for the actual glyphs (the `.afm` files only contain the metrics or size and other metadata for the font, not the individual characters or *glyphs*, which only live in the `.ttf` files) to allow font embedding. To initiate this process, run

{% highlight r %}
font_import()
{% endhighlight %}

This can take some time, depending on how many fonts you have installed on your system. However, you only need to do this once (assuming you don't install fonts regularly) or at the most after you've added fonts to your system. You'll need to confirm the process when asked (just hit `y` followed by return), and as it is doing its thing, you should see a series of statements printed to the console as each font is found and converted, eg

{% highlight rout %}
> font_import()
Importing fonts may take a few minutes, depending on the number of fonts and the speed of the system.
Continue? [y/n] y
Scanning ttf files in /usr/share/fonts/ ...
Extracting .afm files from .ttf files...
/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSans-Bold
/usr/share/fonts/dejavu/DejaVuSans-BoldOblique.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSans-BoldOblique
/usr/share/fonts/dejavu/DejaVuSans-ExtraLight.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSans-ExtraLight
/usr/share/fonts/dejavu/DejaVuSans-Oblique.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSans-Oblique
/usr/share/fonts/dejavu/DejaVuSans.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSans
/usr/share/fonts/dejavu/DejaVuSansCondensed-Bold.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSansCondensed-Bold
/usr/share/fonts/dejavu/DejaVuSansCondensed-BoldOblique.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSansCondensed-BoldOblique
/usr/share/fonts/dejavu/DejaVuSansCondensed-Oblique.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSansCondensed-Oblique
/usr/share/fonts/dejavu/DejaVuSansCondensed.ttf => /home/gavin/R/build/3.0-patched/library/extrafontdb/metrics/DejaVuSansCondensed
....
{% endhighlight %}

Once this is finished, you can get a list of fonts it found and registered via the `fonts()` function

{% highlight r %}
## When it is finished, look at the fonts it has found
fonts()
{% endhighlight %}

On my system, this returned

{% highlight rout %}
> fonts()
 [1] "Abyssinica SIL"         "Andale Mono"            "Arial Black"           
 [4] "Arial"                  "Comic Sans MS"          "Courier New"           
 [7] "DejaVu Sans"            "DejaVu Sans Light"      "DejaVu Sans Condensed" 
[10] "DejaVu Sans Mono"       "DejaVu Serif"           "DejaVu Serif Condensed"
[13] "Droid Arabic Naskh"     "Droid Sans"             "Droid Sans Arabic"     
[16] "Droid Sans Armenian"    "Droid Sans Devanagari"  "Droid Sans Ethiopic"   
[19] "Droid Sans Fallback"    "Droid Sans Georgian"    "Droid Sans Hebrew"     
[22] "Droid Sans Mono"        "Droid Sans Tamil"       "Droid Sans Thai"       
[25] "Droid Serif"            "FreeMono"               "FreeSans"              
[28] "FreeSerif"              "Georgia"                "Impact"                
[31] "Jomolhari"              "Khmer OS"               "Khmer OS Content"      
[34] "Khmer OS System"        "Liberation Mono"        "Liberation Sans"       
[37] "Liberation Sans Narrow" "Liberation Serif"       "LKLUG"                 
[40] "Lohit Assamese"         "Lohit Bengali"          "Lohit Devanagari"      
[43] "Lohit Gujarati"         "Lohit Kannada"          "Lohit Oriya"           
[46] "Lohit Punjabi"          "Lohit Tamil"            "Lohit Telugu"          
[49] "Meera"                  "Mingzat"                "NanumGothic"           
[52] "NanumGothicExtraBold"   "Eeyek Unicode"          "Nuosu SIL"             
[55] "OpenSymbol"             "Padauk"                 "PT Sans"               
[58] "PT Sans Narrow"         "Tahoma"                 "Times New Roman"       
[61] "Trebuchet MS"           "Verdana"                "VL Gothic"             
[64] "Waree"                  "Webdings"
{% endhighlight %}

Having loaded (or discovered and registered fonts with the system), you need to register the fonts with a particular graphics device. In particular, you need to do this for the `pdf()` or `postscript()` devices. For PLOS ONE, you'll be wanting the `postscript()` device as that journal requires EPS format files. Here I'll show both as PDF is generally more useful than EPS when passing figures between colleagues.

The `loadfonts()` function is used to register fonts and by default it will register them with the `pdf()` device. The `postscript()` device can be specified via the `device = "postscript"` argument
{% highlight r %}
loadfonts() ## for pdf()
## or
loadfonts(device = "postscript") ## for postscript()
{% endhighlight %}

R will print messages about which fonts have been registered; you can silence this by adding `quiet = TRUE` to the call to `loadfonts()`.

Now we are in a position to produce a plot and export it from R in PDF or EPS formats. By way of illustration, I'll use a kernel density estimate (KDE) of the probability density function of the Old Faithful duration between eruption data, available in object `faithful` (note this is now available without an explicit `data()` call)

{% highlight r %}
dens <- with(faithful, density(waiting))
plot(dens)
{% endhighlight %}

## Exporting EPS files via `postscript()`
To export an EPS file, we use the `postscript()` device, though to get true EPS output, some additional arguments need to be specified. These are

 * `paper = "special"`
 * `onefile = FALSE`
 * `horizontal = FALSE`

In addition, we need to tell the plot use a particular font family, in this case we use `family = "Arial"`. The character value you pass `family` is one of the entries returned by `fonts()` (see above). Here is a call that will generate an EPS file of the KDE of the Old Faithful data

{% highlight r %}
postscript("myfig.eps", height = 6, width = 6.83,
           family = "Arial", paper = "special", onefile = FALSE,
           horizontal = FALSE)
op <- par(mar = c(5, 4, 0.05, 0.05) + 0.1)
plot(dens, main = "", xlab = "Duration between eruptions (minutes)")
par(op)
dev.off()
{% endhighlight %}

Notice that here I use the `width = 6.83` (in inches) which corresponds to a 3-column figure in the PLOS One world. Other dimensions for figures can be found on the PLOS ONE [Guidelines for Figure and Table Preparation](http://www.plosone.org/static/figureGuidelines#dimensions).

## Exporting PDF files via `pdf()`
A similar invocation is required for the `pdf()` device, but there is no `horizontal` argument:

{% highlight r %}
pdf("myfig.pdf", height = 6, width = 6.83,
           family = "Arial", paper = "special", onefile = FALSE)
op <- par(mar = c(5, 4, 0.05, 0.05) + 0.1)
plot(dens, main = "", xlab = "Duration between eruptions (minutes)")
par(op)
dev.off()
{% endhighlight %}

## Setting up for use on other devices
If a device has a `family` argument, then you can use the following to open a new device using a given font family (here `"Arial"`)

{% highlight r %}
dev.new(family = "Arial")
{% endhighlight %}

This is useful if you want to visualise how the figure will look as you create it. However, it works using the system font provision (on Linux and MacOS X that means Pango), not via **extrafont**, so do read `?X11`, `?windows`, or `?quartz` for details on how fonts are resolved there.

## Embedding fonts
In order for the figure to display properly on any computer with a suitable viewer, the person viewing the file we just generated will need to have Arial installed on their system. Embedding the font (or a subset of glyphs actually used) avoids this situation, at the expense of increased file size. However, embedding fonts with R requires the use of [Ghostscript](http://pages.cs.wisc.edu/~ghost/), which needs to be installed. As I mentioned earlier, technically you don't need this for submission to PLOS ONE, but I include instructions for embedding fonts for completeness.

The **extrafont** package has a wrapper to the standard `embedFonts()` function in base R; `embed_fonts()`. This takes the path to the input EPS file, the path/filename for the outputted file with embedded fonts (this can be missing, in which case the input file is **overwritten**!), plus a `format` argument that you can usually ignore (see `?embedFonts` for details), and and optional argument `options`. This `options` argument is very useful to pass along arguments to the `ghostscript` programme. On my system, the default `ghostscript` output device was set to either US Letter or A4 paper, so the EPS figure had a large amount of white space above and to the right of the figure. This needed addressing, obviously and for that I used the `EPSCrop` argument, which has to be given as you would include it if working with `ghostscript` directly, hence in the code below I pass `-dEPSCrop` to the `option` argument.
{% highlight r %}
## EPS file
embed_fonts("./myfig.eps", outfile = "./myfig-embed.eps",
            options = "-dEPSCrop")
## PDF file
embed_fonts("./myfig.pdf", outfile = "./myfig-embed.pdf")
{% endhighlight %}

Note the PDF file doesn't need any additional `ghostscript` arguments so I omit the `option` argument in that case.

And that is it. Once you've set up **extrafont** and allowed it to search and convert any TrueType fonts on your system, using those fonts is as simple as registering your fonts with a particular device via `loadfonts(device = "foo")` (where `"foo"` is one of the supported devices; see `?loadfonts`), and then specifying the family name of the font when creating the plotting device.

If you have any suggestions for improving these instructions let me know in the Comments; I should pass them along to PLOS ONE at some point so that can add them to their [Guidelines for Figure and Table Preparation](http://www.plosone.org/static/figureGuidelines).
