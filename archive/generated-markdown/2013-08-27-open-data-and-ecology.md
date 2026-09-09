--- 
title: "Open data and Ecology"
status: publish
layout: post
published: true
type: post
tags: 
- "Open data"
- "Open science"
- "Ecology"
category: science
active: blog
---
Open science was present in good order at the recent <acronym title="Ecological Society of America">ESA</acronym> meeting in Minneapolis. Much of what was being discussed under that broadest of headings, *open science*, was the reproducibility of the science we do and one critical aspect of this is free, open access to data. Openly sharing data that underlie research publications is a rapidly-developing area of the scientific landscape faced today by scientists, not just ecologists; many journals now require data that support research papers be deposited under a permissive licence in approved repositories, such as [Dryad](http://datadryad.org/) or [figshare](http://figshare.com/), and a number of journals have been founded specifically to cater for the publication of *data papers*, including [Ubiquity Press](http://www.ubiquitypress.com/)' the [Journal of Open Archeological Data](http://openarchaeologydata.metajnl.com/), Nature Publishing Group's forthcoming [Scientific Data](http://www.nature.com/scientificdata/), and Wiley's [Geoscience Data Journal](http://onlinelibrary.wiley.com/journal/10.1002/(ISSN)2049-6060). Unfortunately, ecologists are more likely to be known for the iron-like grip with which the cling to their hard-won data. Into this landscape, Stephanie Hampton and colleagues [@hampton_big_data_2013] published (it's been online for a few months) a paper in [Frontiers in Ecology and Environment](http://www.frontiersinecology.org/); *[Big data and the future of ecology](http://doi.org/10.1890/120103)*

Their paper has recently generated some discussion on the blog-o-sphere (eg Joern Fischer on [Ideas for Sustainability](http://wp.me/p1B7cl-AL) and Ethan White's [Jabberwocky Ecology](http://wp.me/plPyw-kK)). Thankfully that discussion has been a friendly, courteous, and hence productive dialogue. It could easily have gone the other way; @hampton_big_data_2013 state (emphasis mine)

> Simply put, the era of data-intensive science is here. Those who step up to address major environmental challenges will leverage their expertise by leveraging their data. *Those who do not run the risk of becoming scientifically irrelevant*.

This isn't helpful at all. It's patently not true of course and I can't imagine the authors' believe it to be so.  The reason all the data exists in the first place is that ecologists have been out there collecting information to help them address all sorts of problems, both the big and the small!

And did they have to use "Big data"!? A meaningless concept if ever there was one, most ecological *big data* studies aren't really "Big data" in the sense it was originally coined; datasets with observations numbering in the 10s -- 100s of millions are "Big data", like the [Netflix Prize](http://en.wikipedia.org/wiki/Netflix_Prize) data set. Perhaps my exposure to the number crunching crowd through my activities in the R community has clouded my opinion of the term; very often, for me at least, its use smacks of the bandwagon, of a desire to be relevant or now. That's not the say that there aren't Big data ecological projects (Neon springs to mind as one obvious generator of Big data), its just that a lot of what we do or could do as ecologists will always sit at odds with the real Big data folks.

Those blots aside, the rest of the paper is a good rallying call for ecologists to open up access to their data. (There's even a bit of friendly rivalry thrown in through the comparison of the reticent ecologists and the generous geneticists.) Their position is summed up in four key points [@hampton_big_data_2013]:

 1. Data need to be organised, documented, and preserved for future generations. Data management plans should be something we take seriously and not let valuable data, however inconsequential it may at first seem, to languish in dusty filing cabinets or in proprietary formats from long-forgotten software and computer hard drives.
 2. Share data, and *importantly* do this through open, accessible, inter-linked data repositories, either through host institutions or community specific repositories.
 3. Collaborate; work with colleagues to collate and synthesise data (not surprising given the lead author's affiliation; [NCEAS](http://www.nceas.ucsb.edu/)) to address large-scale questions
 4. Educate; instill in your students the *data sharing* ethos through education, training, local lab data management and sharing protocols. Do likewise with your colleagues and peers.

Each of these points is well made and I encourage you to read the paper for yourself for examples of good practice and justifications for improving the openness of ecologists in general. (If you don't have access to *Frontiers*, Carly has a [self-archived copy](http://escholarship.org/uc/item/94f35801).)

No doubt many ecologists will disagree with the position taken by Hampton and colleagues. One oft-mentioned objection to openly sharing data is that of misuse, either unintentional or malicious. A certain number of people will always do bad science and whether they do so using open data or not is largely irrelevant. I would imagine it to be relatively easy to take apart an argument grounded on inappropriate use of a particular data, especially if it is your data and you know your stuff. Should this be a barrier to openly sharing data? For me, no; the benefits of sharing outweigh the negatives many fold.

Others are willing to share but not through a repository, citing the misuse issue. The problems with this approach are manifold;

 * it doesn't scale at all well when lots of people want to use your data or scale well to a large number of researchers all wanting to use separate data sets.
 * it doesn't meet the *discoverability* test at all; how do people find out that your data exist and might be available? In a world dominated by computers, should we really be compiling data sets for anaylsis by individually contacting researchers to request data, receive it in whatever format they deemed appropriate at the time? Imagine what web search would be like if Google et al had to ask permission to use each web masters' data (their HTML code) before it was included in search results!?
 * what happens to your data when you leave an institution, or have "shufflel'd off this mortall coile", or just upgraded to a fancy new Mac? Or heaven forbib you might have a hard drive fail on you. Or you forget what you did with the data (yes, really!) We need, nay *must*, do better than this with our data, even if one isn't a big fan of openly sharing them by depositing in a repository. Too much valuable data is lost this way. 
 
    There are repositories that allow private silos for data, but which encourage the use of proper metadata and documentation, and follow good archival practice. It is then but a small, simple step at a later date to make these data truly open.

I don't buy the argument, often made, that others don't have the skills or knowledge or expertise to use data properly, to understand the issues of a given data set. The opposite is true generally; people who want to use a data set properly will more than likely devote time and effort to understand the particular nuances and foibles and assess the degree to which they impact their particular analysis. Heck, they could even engage your expertise and draw you into the study --- a win all round.

Then there is the issue of being "scooped". I can sympathise with this issue, especially for early career researchers (ECRs), although everything "open" is a worry for ECRs. I'm not sure I could point to an example of someone taking data and scooping the originators of those data, especially within ecology. Others may have different experiences. Regardless, there are community norms that are in place or could be fostered; would you be willing to take someone's data and publish it without attribution, or without inviting the originator to collaborate? Where there are still concerns, the ecological community needs to add to the community norms to foster an environment that encourages, protects, and, yes, rewards those researchers that share data. The advent of citable data via data DOIs or through data papers is one aspect for addressing the latter. Expecting our fellow scientists to cite data products is part and parcel of the existing community norms.

Other issues often come up; chief among these is the argument that it would be irresponsible to share data, say on endagered species (which for example might identify extant populations which may become the target of "collectors", etc). These are important considerations and should not be taken lightly, but the data can be "anonymised" to the degree that these issues are assuaged whilst preserving some utility in the data, for example by only releasing location data at crude spatial resolution.

If the moral imperative wasn't enough, there are some pretty big sticks about to be wielded that may end up forcing all scientists, not just ecologists, to face up to their responsibilities when it comes to open data sharing and proper archival. As already mentioned, many desirable journals now require data to be deposited; rather than have to deal with this among the plethora of publishing minutae required to get your work into print, deal with it up front and make proper data recording and description part of your lab protocols.

The sticks get bigger still; major funding agencies are now requiring the data resulting from their granting schemes be made publicly, freely, and promptly available in suitable repositories. In particular, major funders, such as the US NSF, which disperses public funds, now mandate sharing of data;

> Investigators are expected to share with other researchers, at no more than incremental cost and within a reasonable time, the primary data, samples, physical collections and other supporting materials created or gathered in the course of work under NSF grants. Grantees are expected to encourage and facilitate such sharing. [*Source*](http://www.nsf.gov/bfa/dias/policy/dmp.jsp)

It was telling that the Data Management Plan session was one of the best-attended ancillary sessions at the recent ESA meeting; the data management plan is now part of the grant submission that anyone submitting to an NSF programme must supply.

Given the change in the funding landscape, you might as well embrace the open data movement and get ahead of the game.

Open science, not just open data, cuts to the heart of what, for me, it means to be a "scientist" or to *do science*. Science is, or should be, an open endeavour with anyone able to benefit from the advances that are made. Somewhat less idealistically, science is supposed to be reproducible. Unfortunately, too much of what we do, isn't. I am in little doubt that a reasonable amount of the published ecological literature is, shall we say, dubious. (That's not to say that scientists are pulling a fast one, it may simply be that a result is due to inappropriate data handling, or analysis, or some other quirk.)

Access to the data is but one aspect of reproducible research, of course, but it is a critical one. Given a reasonably detailed methodology one could probably reproduce the average study if one wanted to, but without the data it would be impossible or at least prohibitive to do so. The scientific community, and society at large, deserves to be able to test our results, to prod and poke them, to see that they hold up to further scrutiny.

This *is* what science *is*, and I wish more of us were out there *doing science* this way than worrying about being scooped or that their data will be misused.

## References
