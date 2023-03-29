# deliveroo.engineering

The [deliveroo.engineering](https://deliveroo.engineering) blog is the Deliveroo
Engineering team’s presence on the web. It is hosted using
[Github Pages][github-pages], which runs on [Jekyll][jekyll]. The main bits of
the blog are built using [Liquid][liquid] and [SCSS][sass]. Content written for
the site is formatted with [Markdown][markdown].

## Running deliveroo.engineering locally

If you’re doing any work on any part of the `deliveroo.engineering` blog, the
best way to test it is to run it locally:

1. [Install docker](https://docs.docker.com/install/)
2. `$ git clone git@github.com:deliveroo/deliveroo.engineering.git`
3. `$ cd deliveroo.engineering`
4. `$ make build`
5. `$ make run`
6. Open `http://localhost:4000` in your browser

Jekyll will then generate the site files automatically for you, which usually
takes no more than a couple of seconds each time you make a change.


## Submitting a blog post

We love it when our engineers are able to share the lessons of their experiences
with the world (and each other!). If you have anything you’d like to write about
which has relevance to the world of engineering, it'd be great to hear it!

First, check out the [internal documentation on writing blog posts](https://go.roo.tools/eng-blog/contribute).

Then, once the post is ready to go:

1. Name your branch `blog-posts/name-of-your-post`.
3. Look at the [blog post template][template] to get an idea on how to
   structure your post.
4. If you’ve not written a blog post before, create an author bio page using the
   [bio template][template] as a template, and add a square photo of yourself
   to [the portraits folder][portraits-folder]. Ideally this should be a JPEG of
   at least 600px _square_.
5. Test your blog post locally to ensure it looks okay.
6. Create a pull request and tag it with `ready for editor review`.
7. Invite feedback from the Engineering team!
8. Request review from the [Engineering Editorial team](https://github.com/orgs/deliveroo/teams/working-group-engineering-blog)!

## Submitting improvements to the blog website

If you’re submitting a general improvement or bugfix to the blog website itself,
follow standard process by opening a pull request, and tagging the issue
appropriately with `bugfix`, `design`, `refactor` etc.

[github-pages]: https://pages.github.com
[jekyll]: https://jekyllrb.com
[liquid]: https://shopify.github.io/liquid/
[sass]: https://sass-lang.com
[markdown]: https://daringfireball.net/projects/markdown/syntax/
[ruby-version]: https://github.com/deliveroo/deliveroo.engineering/blob/gh-pages/.ruby-version
[post-example]: https://github.com/deliveroo/deliveroo.engineering/blob/gh-pages/_posts/YYYY-MM-DD-your-blog-post-name.md
[bio-example]: https://github.com/deliveroo/deliveroo.engineering/blob/gh-pages/_authors/_example-bio.md
[portraits-folder]: https://github.com/deliveroo/deliveroo.engineering/tree/gh-pages/images/portraits
[guidelines]: https://github.com/deliveroo/deliveroo.engineering/tree/gh-pages/_guidelines
