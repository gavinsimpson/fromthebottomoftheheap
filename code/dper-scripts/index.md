---
title: R scripts for DPER volume 5
subtitle: data handling methods and numerical techniques
status: publish
layout: page
published: true
type: page
tags:
- R
- "DPER 5"
- Palaeolimnology
- Palaeoecology
category: R
active: code
---

I wrote or co-wrote 3 chapters in the recently-released 5th volume in the Developments in Palaeoenvironmental Research series *Tracking Environmental Change Using Lake Sediments: Data Handling Methods and Numerical Techniques*

 1. Statictical Learning in Palaeolimnology (Chapter 9; with John Birks),
 2. Analogue Methods in Palaeolimnology (Chapter 15), and
 3. Human Impacts: Applications of Numerical Methods to Evaluate Surface-Water Acidification and Eutrophication (Chapter 19; with Roland Hall)

The book itself didn't include any R code in support of the chapters but several chapters including each of mine did use R as the underlying tool for the examples presented. Springer have a website for electronic support materials for books they publish. Unfortunately this isn't the sort of place for code; we had to have all extra materials ready before the book went to press and then taht would be it, things would be frozen. The script (well collection of scripts) for the Statistical Learning chapter just weren't in a form ready to package so I didn't bother. Furthermore, the scripts for the Human Impacts chapter originally didn't even use R for everything; some methods, such as <acronym title="Weight Averaging Partial Least Squares">WA-PLS</acronym> weren't available in R when I wrote the chapter, which goes to show how long that book was in development for!

As a blog isn't the best place for these scripts, long term, I'll place copies in a github repository so I can update them from time to time. What I will include on the blog here are annotated versions of the scripts; *just be sure to check for the latest version of the code on github*

## Annotated R Scripts

 * [Statistical Learning in Palaeolimnology]({{ site.url }}/code/dper-scripts/chapter-9-statistical-learning.html)
 * [Analogue Methods in Palaeolimnology]({{ site.url }}/code/dper-scripts/chapter-15-analogue-methods.html)
 * [Human Impacts: Applications of Numerical Methods to Evaluate Surface-Water Acidification and Eutrophication]({{ site.url }}/code/dper-scripts/chapter-19-human-impacts.html)
