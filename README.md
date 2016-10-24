# deliveroo.engineering

The [deliveroo.engineering](http://deliveroo.engineering) blog is the Deliveroo
Engineering team’s presence on the web. It is hosted using 
[Github Pages][github-pages], which runs on [Jekyll][jekyll]. The main bits of 
the blog are built using [Liquid][liquid] and [SCSS][sass]. Content written for
the site is formatted with [Markdown][markdown].

## Running deliveroo.engineering locally

If you’re doing any work on any part of the `deliveroo.engineering` blog, the 
best way to test it is to run it locally:

1. `git clone git@github.com:deliveroo/deliveroo.engineering.git`
2. `cd /path/to/deliveroo.engineering`
3. (optional) if you don’t already have it, install the correct version of Ruby
   as [specified][ruby-version] in the `.ruby-version`
4. `bundle install`
5. 
  1. if you use `pow`: `echo 4000 > ~/.pow/deliveroo.engineering` 
  2. if you use `puma-dev`: `echo 4000 > ~/.puma-dev/deliveroo.engineering`
6. `bundle exec jekyll serve --incremental` to run the Jekyll server
7. Open `deliveroo.engineering.dev` in your browser

Jekyll will then generate the site files automatically for you, which usually 
takes no more than a couple of seconds each time you make a change.

## Submitting a blog post

We love it when our engineers are able to share the lessons of their experiences
with the world (and each other!). If you have anything you’d like to write about
which has relevance to the world of engineering, create a pull request!

1. Name your branch `blog-posts/name-of-your-post`.
2. Read the meta-guidelines on 
   [how to format your post with Markdown][markdown-formatting].
3. Look at the [example blog post][example-post] to get an idea on how to 
   structure your post.
4. If you’ve not written a blog post before, create an author bio page using the 
   [example bio][example-bio] as a template, and add a square photo of yourself
   to [the portraits folder][portraits-folder]. Ideally this should be a JPEG of
   at least 600px _square_.
5. Test your blog post locally to ensure it looks okay.
6. Create a pull request and tag it with `ready for editor review`.
7. Invite feedback from the Engineering team!

## Submitting an engineering guideline

As well as a place to share our experiences and insights, the engineering blog
is also a repository of our accumulated best practices for development across
all the different technologies we work with. There are numerous 
[guidelines][guidelines] documents corresponding to these technologies; you
can contribute to these with your own insights, linting or formatting rules, 
or create an entirely new guideline for anything we don’t yet document or have
standards for.

1. Name your branch `guidelines/whatever-it-relates-to`.
2. Read the meta-guidelines on 
   [how to format your guidelines with Markdown][markdown-formatting].
3. Look at the [example guidelines][example-guidelines] to get an idea on how to 
   structure your guidelines document.
4. Test your guidelines documentation locally to ensure it looks okay.
5. Create a pull request and tag it with `guideline for review`.
6. Invite feedback from the Engineering team!

## Submitting improvements to the blog website

If you’re submitting a general improvement or bugfix to the blog website itself,
follow standard process by opening a pull request, and tagging the issue 
appropriately with `bugfix`, `design`, `refactor` etc.

[github-pages]: https://pages.github.com
[jekyll]: https://jekyllrb.com
[liquid]: https://shopify.github.io/liquid/
[sass]: http://sass-lang.com
[markdown]: http://daringfireball.net/projects/markdown/syntax/
[ruby-version]: https://github.com/deliveroo/deliveroo.engineering/blob/gh-pages/.ruby-version
[markdown-formatting]: http://deliveroo.engineering/guidelines/meta/#formatting-guidelines
[example-post]: https://github.com/deliveroo/deliveroo.engineering/blob/gh-pages/_posts/YYYY-MM-DD-your-blog-post-name.md
[example-bio]: https://github.com/deliveroo/deliveroo.engineering/blob/gh-pages/_authors/_example-bio.md
[portraits-folder]: https://github.com/deliveroo/deliveroo.engineering/tree/gh-pages/images/portraits
[guidelines]: https://github.com/deliveroo/deliveroo.engineering/tree/gh-pages/_guidelines
[example-guidelines]: https://github.com/deliveroo/deliveroo.engineering/tree/gh-pages/_guidelines/_example-guidelines.md
