---
layout: post
title:  "Title of your blog post goes here"
author: "Your Name"
exerpt: >
  A short synopsis or excerpt of your blog post should go here. This will appear
  on the home and articles pages as a summary of your post. You should change
  the name of your blog post to start with the date you want the post to say
  it was posted, in the YYYY-MM-DD format.

---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Adding a ‘Table of Contents’

If you have a lot of headings and subheadings, you can generate an automatic
table of contents at the top of your blog post with the following Markdown:

```markdown
## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}
```

The list item here will have its contents replaced with the table of contents.
The syntax you see in braces (e.g. `{:.no_toc}`) is how `Markdown` lets you
apply arbitrary classes or IDs to elements, although in this case `.no_toc` also
prevents the heading saying _Table of Contents_ from appearing _in_ the Table of
Contents, too.


## Subheadings

Start with a H2 (two hash symbols) as the highest level of heading you use, 
and go deeper as necessary. Only headings between H2 and H4 will appear in the
table of contents. Markdown will automatically generate an ID for each heading,
to allow you to link to a section within your blog post, so you might find it 
prudent to explicitly specify a name to use for this ID, like so:

```markdown
### Content
{:#something-about-content}
<!-- stops it from generating <h3 id="content">Content</h3> -->
```

## Images
{:#blog-post-images}

If you’re using images in your article, the best way to display them is inside a
`<figure>` element, like so:

```markdown
<figure>
![Alternative text](/images/posts/your-blog-post-name/image-name.jpg)
</figure>
```

## Footnotes

If your article cites a lot of external references, consider using footnotes to
display these. You do that by using a Markdown footnote reference:

```markdown
Some text and then a footnote[^reference]

[^reference]: [Note (typography)](https://en.wikipedia.org/wiki/Note_(typography))
```

If you do use footnotes, please remember to add a subheading for footnotes at
the very end of the document, i.e.

```markdown
## Footnotes
```

This prevents any other content immediately preceding the auto-generated 
footnotes running into them, which might make them look strange.

## Asides

If you wanted to go into a parenthetical aside at some point in the post, you 
can do this with an `<aside>` element, like so:
  
```markdown
<aside>
#### About that thing I was just talking about there…

There are some caveats to bear in mind, and I’ll talk about them now…
</aside>
```

Aside elements are floated, so you will probably want to test to make sure
the elements immediately after it look good. In some cases you might want to 
tweak the aside’s order in the document to ensure it reflows nicely.

## Code examples

We use the Rouge syntax highlighter, which supports numerous[^not-jsx] modern
languages, and will give you nice output. Using this is as simple as:

```markdown
  ```language
  # your code goes here
  ```
```

[^not-jsx]: Sadly, JSX is not yet supported; you should simply omit the language identifier in this case.

## External links

Markdown’s syntax for external links is pretty easy to use:

```markdown
Here is some text [with a link](https://en.wikipedia.org/wiki/Hyperlink).
```

If you’re trying to adhere to an [80-character column limit][80-characters] 
these links can often be problematic, so it is recommended that you use the
reference-style of links:

```markdown
Here is some text [with a link][wikipedia-hyperlink].

[wikipedia-hyperlink]: https://en.wikipedia.org/wiki/Hyperlink
```

[80-characters]: https://gcc.gnu.org/codingconventions.html#Line


## Footnotes
