--- 
title: "Quantitative palaeolimnology: my book chapters are finally out!"
status: publish
layout: post
published: true
type: post
tags: 
- analogue
- Numerical analysis
- Palaeoecology
- Palaeolimnology
- R
- Science
- Statistics
- vegan
active: blog
category: R
excerpt: "Today I received confirmation that the delayed [fifth volume](http://www.springerlink.com/content/978-94-007-2744-1/) in the [Developments in Palaeoenvironmental Research](http://www.springerlink.com/content/1571-5299/) series has been published. The book is titled *Data Handling and Numerical methods*, though it covers more of the latter and, IMHO, is far more interesting than the dry title would suggest (who gets excited by *Data Handling*? Well, one or two people perhaps ;-)"
---

{{ page.excerpt | markdownify }}

A [full table of contents](http://www.springerlink.com/content/978-94-007-2744-1/#section=1058967&page=12) can be found on the [SpringerLink](http://www.springer.com "Springer Science+Business Media") website, though in their infinite wisdom, this material is not available as [HTML](http://en.wikipedia.org/wiki/HTML "HTML") but as embedded previews of the pages, which you can download as PDFs (as you can each chapter but for the proper fee). I authored or co-authored three of the 21 chapters

-   Chapter 9 [Statistical Learning in Palaeolimnology](http://dx.doi.org/10.1007/978-94-007-2745-8_9) (with [John Birks](http://www.uib.no/persons/John.Birks))
-   Chapter 15 [Analogue Methods in Palaeolimnology](http://dx.doi.org/10.1007/978-94-007-2745-8_15)
-   Chapter 19 [Human Impacts: Applications of Numerical Methods to Evaluate Surface-Water Acidification and Eutrophication](http://dx.doi.org/10.1007/978-94-007-2745-8_19) (with [Roland Hall](http://biology.uwaterloo.ca/people/roland-hall))

![Classification tree fitted to the SCP chemical data in DPER Chapter 9]({{ site.url }}/assets/img/posts/classification_tree_scp_example.png)

All three chapters relied heavily upon R; the first two being conducted entirely in R. Chapter 19 was written such a long time ago now that it wasn't all done in R (WA-PLS, Maximum Likelihood transfer functions methods weren't then available in R, nor were some of the ordination based methods I used). However, I'm confident the entire thing (at least the acidification parts) could be done using R now.

I have scripts for all the analyses performed using R. Some need a little work before I post them (mainly for Chapter 9) but I aim to maintain up-to-date scripts on my blog. Details soon.

Although writing these chapters took on a life of their own and used up far more time than they should have done, I am genuinely pleased with the results. I certainly learned a huge amount more about the statistics that underlay the techniques that palaeolimnologists and palaeoecologists use day in day out.

To pre-empt requests for PDFs of the chapters; I don't have any so don't ask. I'm not sure what arrangements were made originally with the publisher in that regard. I haven't even seen the final book yet either; still waiting on my copy to pop through the letter box. If you want a copy and didn't get in a pre-order at the discount rate, I suspect the best bet would be to pick on up later this summer at the [International Paleolimnology Symposium in Glasgow](http://paleolim.org/ips2012/), where I'm sure there will be a conference discount. If I hear of any offers in the meantime I'll post something here.
