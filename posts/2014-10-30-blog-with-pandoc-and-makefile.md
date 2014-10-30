---
title: A Simple Blog based on Pandoc and a Makefile
date: 2014-10-30
description: A short introduction to setting up a blog with just Pandoc and a Makefile.
---

... which I accidentally deployed already because it was so easy.

Yes, I rolled out a new version of my website today. I though about what engine to use for a while. [Hakyll](http://jaspervdj.be/hakyll/) was my usual choice because it's clean and simple and also because it's based on [Pandoc](http://johnmacfarlane.net/pandoc/). However, I am fed up with Cabal, Haskell's package manager that just doesn't seem to work right.

The next candidate in line was [Pelican](http://docs.getpelican.com/en/3.4.0/), pointed out to me by [Tim](https://betatim.github.io/) who uses it for his nice blog. A cool thing about Pelican is that it seems to play very nicely with [IPython Notebooks](http://ipython.org/notebook.html). This time it was pip (which usually works quite well) that got in my way.

In order to prevent further frustration with existing solutions, I quickly rolled my own minimalistic static page generator which consists of a small python script for indexing and a makefile for automated compilation and deploy. Of course it uses Pandoc as a backend.

The code is on [<i class="fa fa-github"></i> GitHub](https://github.com/kdungs/dun.gs), feel free to adapt it for your project. Just bear in mind that this was written in a few minutes with the sole purpose of publishing my new blog.
