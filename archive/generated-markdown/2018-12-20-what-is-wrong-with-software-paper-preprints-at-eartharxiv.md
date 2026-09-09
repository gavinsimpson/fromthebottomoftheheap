--- 
title: "What's wrong with software paper preprints on EarthArXiv?"
status: publish
layout: post
published: true
type: post
tags: 
- Preprints
- Software
- Open Science
- Open Source
- Science
- Rants
active: blog
category: science
---

Via [Twitter](https://twitter.com/geschichtenpost/status/1075747221625339904) I recently found out that [EarthArXiv](https://eartharxiv.github.io/index.html), a new preprint server for the geosciences doesn't accept software paper submissions. Actually, EarthArXiv [doesn't accept quite a few types of publication](https://eartharxiv.github.io/moderation.html) --- some justifiably, like *ad hominem* attack pieces, others unjustifiably like correspondence or opinion pieces. I find this general stance very odd indeed; commentary, editorial or opinion pieces and software papers are accepted in a large number of the general and specialized journals that serve the geoscience field, so why wouldn't EarthArxiv want to host these prior to publication of the version of record in one of those journals?

The commentary issues bothers me a lot; there is far too little commentary in the geoscience literature and, unless our field is unlike any other, there is a lot to critique. Yet typically this correspondence never sees the light of day or is subject to such draconian restrictions on length that the discussants rarely have the opportunity to fully articulate their concerns or defend their positions. And that's assuming the commentary is submitted within the time window allowed by the journal or that the editor decides to allow the commentary in the first place. Accepting commentary on published, peer reviewed articles would be a good first step in promoting collegial academic discussion in the literature. Deity knows we need it! 

Anyway, back to what really annoyed me this morning; not accepting software papers.

I was pleased to see that ["EarthArXiv supports scientific software development and citation"](https://eartharxiv.github.io/moderation.html#software). That's good to know, because the impression that I'm left with is that software papers aren't the right sort of thing for EarthArXiv. No reasons for this stance are given beyond the nebulous "Yet, software papers often follow citation standards that differ from research and data papers." Citation standards also differ for data, but data papers are acceptable (which is a good thing!) at EarthArXiv. So what's the problem with software papers?

I'd like to know because I'm biased; I write a lot of software that is freely available to the community under permissive open source licences. I'm far from being the only one. If researchers who use my or others' software to analyze their data or prepare their figures can submit preprints to EarthArXiv, why are we barred from submitting preprints about that software? It makes no sense to me.

EarthArXiv does give some [useful tips](https://eartharxiv.github.io/moderation.html#software) on what you as a software author can do instead;

* Use GitHub --- this really should be "Use version control"!!
* Mint a DOI for the repo on Zenodo
* Publish a paper in [<acronym title="Journal of Open Research Software">JORS</acronym>](https://openresearchsoftware.metajnl.com/) or [<acronym title="Journal of Open Source Software">JOSS</acronym>](https://joss.theoj.org/) --- have you ever seen a paper from either of these? I have and what they do is great, but JOSS, and to a lesser extent JORS, don't publish the kinds of detail one typically finds in a software paper at say Methods in Ecology and Evolution, where the reasons behind method choice or implementation details are regularly presented.
    They then say "You will now have a citable 'paper'", why the scare-quotes? Do the moderators at EarthArXiv not think such papers are real papers?

The final bit of advice is:

> If you really want a software paper on EarthArXiv such that Earth scientists can find it, then we recommend doing all the above plus writing up a short PDF with some Earth science examples showing off the utility. That EarthArXiv PDF would cite the Journal of Open Source Software report

Isn't that the very definition of a software paper?

This leaves me with the impression that the EarthArXiv moderators have a very particular type of software paper in mind and haven't considered --- or are not aware of --- the broader forms of software papers. One of my software papers is @Simpson2007-ya, which describes how to use my **analogue** R package. Another example is @Goring2015-vf in which we describe and illustrate how to use the **neotoma** R package to access the eponymous database [Neotoma DB](https://www.neotomadb.org/). Those are more typical of the software papers that I am familiar with. Significant effort goes into preparing these papers, easily as much as any other type of research paper. Papers like this serve very different needs than those published by JOSS. Neither of those papers was freely available to colleagues (IIRC) during the review process. A preprint on EarthArXiv would have served the community well.

It is frustrating in the extreme that papers like the two personal examples above would not be welcome on EarthArXiv.

I do hope that the people at EarthArXiv reconsider their stance on software papers and other types of scholarly work, especially commentary pieces.

## References
