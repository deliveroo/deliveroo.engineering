SASS/CSS is _not_ code, but you can apply a lot the same principles to it. Knowing how it's different though, and different again on a large site, is key to producing reusable, fast and understandable styling.

On a large site the most important thing to understand is to strive for re-use as much as possible.

With that end the overall strategy of our SASS/CSS is to take some well understood (and battle-tested) functionality from bootstrap and add our components on top.

> With great power, comes great responsibility.
> --Uncle Ben (the Spiderman one, not the rice one)

SASS is 'processed' into CSS which means you have to think about the text being spat out at the end of the compile process. Behaviours that make sense in Ruby might not make sense in SASS if speed and maintainability are you goals.

_PS They should be your goals._

*Pragmatism* above all things.

An intro to our technologies:

## SASS ([sass-lang.org](http://sass-lang.com/))

Our pre-processor of choice.

Generally we prefer the indented, HAML-style SASS syntax over the CSS-style SCSS syntax.

## KSS ([kneath/kss](https://github.com/kneath/kss))

A commenting style for our stylesheets. Can be used (in theory) to generate a component library, or styleguide.

Original launch [blog post](http://warpspire.com/posts/kss/).

## The Styleguide (housetrip.com/en/styleguide)

As part of the web app we have a component library, where designers and developers can examine existing components and are encouraged to examine and reuse components where they can.

Our approach is broadly Rails partial based for HTML reuse. If a component is used elsewhere in the app it should be a partial and most likely added to these documents.

There's also a section for more global formatting (forms, typography, grid) and some useful utility styles.


# History

We have currently 4 main areas of SASS/CSS in our app.

* **legacy** - used for old fixed width designs. DO NOT ADD CODE HERE.
* **admin** - used for admin areas, bootstrap with customisation
* **v4** _(name to change)_ - the responsive pages: home, search results & property pages
* **landing_pages** - fast minimal styles for the landing pages launched summer 2014

The final two are in the process of being combined into a _one true way_ set of styles.

Longer term we need to move older pages off the legacy styles and get admin onto only one version of bootstrap, with less customisation.


# Rules

## Basics

We prefer the indented SASS syntax

Use soft-tabs with a two space indentation

No CSS in the view layer on HTML elements.

## Comments

Use `//` for comment blocks

```sass
// a comment
.hero
  ...
```

## Use double quotes

```sass
.foo
  content: ""
```

Also quote attribute values in selectors, for consistency and code highlighting.

```sass
input[type="checkbox"]
  color: red
```

## Avoid specifying units for zero-values

```sass
.foo
  margin: 0
```

## Spaces after commas

Include a space after each comma in comma-separated property or function values

```sass
.bordered-thing
  border: 1px solid red, 2px dotted blue
```

## Use zeros for small values

Put `0` in front of values or lengths between -1 and 1.

```sass
.button
  margin-right: 0.25em
```

## Do not style ids

CSS `#something` values have very high [specificity](http://www.w3.org/TR/selectors/#specificity). Style with classes. In fact, use `#id`s as sparingly as possible.

## Do not style JavaScript classes

We have a convention of using `.js-hook-for-behaviour` classes to target JS. Don't style these, even if if means creating 'parallel' classes for styling.

## Do not use images for gradients

There's no need when we have CSS gradients at our disposal that work across all major browsers, including IE.

## Do not transform text server side

Think of the user who wants to copy and paste that text, or the next developer who needs to change the style. Implement all-caps with `text-transform:uppercase`, not (in Ruby) `String#upcase`.

## Never use `!important`

It's like leaving a loaded gun lying around. Think you have a counter-example? You're wrong. Don't say we didn't tell you.


## Specific Coding Style

Properties should be grouped together:

- Put at least one space after `:` in property declarations
- then layout-related properties (`position`, `float`, `display`
- then size related `width`, `height`, `margin`, `padding`
- then aspect-related properties (`color`, `border`)
- finally calls to responsive mixins, like `+respond-min($screen-sm-min)`

Good:

```sass
.hero
  display: table
  position: relative

  width: 100%

  color: $color-white
  background-color: $color-gray

  +respond-min($screen-sm-min)
    height: 576px
```

Bad:

```sass
.container
  +when-bigger-than-mobile
    color: white
    background-color: black
  font-size: 24px
```

## Prefixed properties

Do not use browser-specific, prefixed properties directly.

We will implement [autoprefixer](https://github.com/ai/autoprefixer) into our asset pipeline.


## Pixels vs. Ems

We use `px` for `font-size`, because it offers absolute control over text, `em` is a battle for another day.

Additionally, unit-less `line-height` is preferred because it does not inherit a percentage value of its parent element, but instead is based on a multiplier of the `font-size`.


## IE6/7 Support

**Don't.** IE8 is next on the hit list.

We have officially dropped support for these old browsers and are prompting people to update. We really do not want to spend our time fixing and testing for this small sebset of our userbase.


# Guidelines

## Naming

There are many variants of how to name your classes, we have settled on a simple style derived from [BEM](http://bem.info) that looks like `.thing-to-be-styled_modifer`.

So for example in the `components/_hero.sass` file...

```sass
.hero
  ...
.hero-background
  ...
.hero-content
  ...
.hero-title
  ...
.hero-title_left
  ...
```

Modifier or variant classes are designed to be used with their un-modified version. So if you were creating a left aligned hero title you'd use...

```haml
.hero-title.hero-title_left
  Content Goes Here
```

or

```html
<div class="hero-title hero-title_left">Content Goes Here</div>
```

In general, use semantic naming.

You may notice a few places where variants of a class use a color-based naming. For example `block.block_blue` in the `components/_block.sass`. This is because that's exactly what the variant is: "a block with a blue background".

If you have a choice, be semantic, but if the style is purely visual, name it that way.


## Semantics and Fear of Classes

A lot has been written on the value of semantics to HTML and CSS a lot of this thinking is derived (rightly) from getting us out of the "tables for layout" era. We're out, we made it.

Recent experience across the industry, in writing CSS for large scale websites, has forced some re-examination of the lust for minimal classes.

So remember, do not fear multiple classes on elements.

Our choice of layout grid system (bootstrap) and some of our utility classes are inherently 'unsemantic' but it's designed for reuse of CSS and agility in putting pages together.


## Do not nest classes in CSS/SASS

Once you start nesting it is very easy to get into specificty nightmares. Rules surprisingly overwriting each other, leading to more specificity in the code you're writing or even the dreaded `!important` declaration.

It's often used to give context to your components...

```sass
.landing-page
  ...
  .search-box
    ...
    > h2
      ...
```

All this does is lock that component to that page and prevent reuse. Try this instead.

```sass
.landing-page
  ...
.search-box
  ...
.search-box-title
  ...
```

Try and think *in generalities* when naming. Avoid `.button-for-search-filters`, use `.button-tiny`, there might even be one already you can use.

If there isn't, don't slavishly create another kind of something, work with your designer to try and reuse existing styles.


## Do not style html elements other than globally

Use descriptive classes.

```sass
.hero
  ...
.hero-title
  ...
```

over

```sass
.hero
  ...
  h2
    ...
```

Encourages reuse and lack of surprises. And allows our 'base' styling to remain consistant.


## Do not style typography in your component CSS

Most often you'll want to change the typography of something within your element. We have the somewhat ugly-but-effective `.text-l` to `.text-xxl` styles which you can apply to change those around and keep to our typographic hierarchy.

i.e. `<p class="text-xxl">` has the typographic styling of an `<h1>`

Yes it's a bit ugly, but it contains the proliferation of margins, paddings, font-sizes & line-heights across the CSS. It also helps us stick to our typographic grid.


## Use descriptive naming if you have to build a new component

When naming, think 'what is this' not 'where is this' or 'how is it used', the last two can change.

If you can't come up with a readable name for new class, ask someone for advice!

Think `.search-form` not `.landing-page-hero-search-form`.
Think `.btn.btn_large.btn_primary` not `.btn-on-map-overlay`.


* Variables use `$dashes-in-their-names`.
* Mixins use dashes too.
* Acronyms and domain lingo are forbidden.


## Nested imports

... are confusing. Don't do it.

The top-level stylesheets should include all required `@import` directives and be well commented.

The only dependancies for a component should be the 'global' styles: typography, colours etc. These will be included by any top-level stylesheet.


# SASS extend, just don't

You shouldn't use `extend` it's cognitively tricky and can produce huge style sheets. Particularly avoid any use of `@extend` that references a class from other file because it couples their compilation.

SASS is _generated_ into CSS, `extend` often ends up with CSS rules repeated for the selector. Just use the classes in the HTML. _Keep it simple._

e.g.

```sass
.font-size-xxl
  font-size: 600px

.hero-title
  @extend .font-size-xxl
  text-shadow: 10px solid #000
```

becomes

```css
.font-size-xxl, .hero-title {
  font-size: 600px;
}
.hero-title {
  text-shadow: 10px solid #000
}
```

The extend is an indirection and rapidly becomes complex when extend is used in multiple places. It's simpler for 'future you' to get the same result by doing this in your HTML. This is what the _cascade_ in Cascading Style Sheets is for.

```sass
.font-size-stupid
  font-size: 600px

.hero-title
  text-shadow: 10px solid #000
```

```html
<h2 class="font-size-stupid hero-title">Mega Title</h2>
```


# HouseTrip Style

We use a tweaked bootstrap (v3) grid to layout our pages.

The [bootstrap documentation](http://getbootstrap.com/css/#grid) is the best place to read up on how that works. We can use all of the existing types of bootstrap grid classes: e.g. `col-sm-offset-X`, `.col-sm-push-3`.

It uses (currently) only the `.col-sm-X` classes for the desktop version, we are not ready for full responsivity in our designs, but by following these guidelines _we can get there_.

There are also `.col-xs-X` that apply for all screen widths, including mobile, but use these sparingly.


### Special case div-itis avoidance

When you are simply after the full width of a container, there is no need to do this...

```haml
.row
  .col-sm-12
    %h1
```

You can simply omit the `row` and `col-sm-12`

```haml
%h1
```

Voila.

## Do not reinvent the wheel

Look at the component library. Look at other pages. Are there elements you could re-use?

Talk with your designers. Can we use this element that already exists rather than introduce a new variant?

Only use variables when they are truly global. Then put them in `global/_variables`.


## Components should flex within the grid element they are inside

A component should be styled independantly of the containing `col-sm-X` `div`. Overall width of a component is provided by the grid, elements within your component can be positioned within _that_ context.

Use floats and absolute positioning where required. You shouldn't need to do anything crazy like using negative margins, if you do find yourself doing it, there's probably another way.

You can also use nested `.row` and `.col-sm-X` classes within your components for additional grid-based layout.

It's also a possible smell if you find yourself setting widths rather than relying on the grid.


## SVG

For all non-photographic images we should try and use SVG. It is XML-based and therefore textand this compresses extremely well.

We can also inline SVG to reduce HTTP requests as we move away from any support other than IE8.

### A note on icon-fonts

Icon fonts are great. Including *all the icons* is not great. Generating classes for all the icons you need is a recipie for exventual CSS bloat.

We currently have the glyphicons fonts included in v4, but we use only a handful for their stated purpose (tiny icons next to text) and spend a lot of time in CSS tweaking their position.

Whilst icon fonts are not _off the table_ for simplicity let's stick with SVG for now.


## Colors

We have all the housetrip brand colours in `global/_colors.sass`, use these variables. Use from the top of that file and don't add any more, we are trying to reduce the number of colors and color variables.

For black and white use `#000` and `#fff`.

Prefer to use use functions (`transparentize`, `lighten`) over RGBA. You'd probably get the math wrong, and it'd be less readable, so why bother?


# File Organization

```
<app/assets/stylesheets>
├── application.sass               # app spreadsheet
├── legacy_application.sass        # don't add stuff in here
│
├── components                     # reusable elemenets
│   ├── _badges.css.sass
│   ├── _block.sass
│   ├── _footer.sass
│   ├── _hero.sass
│   ├── _highlight.sass
│   ├── ...
│   └── _navigation.sass
│
├── global
│   ├── _colors.sass               # colors
│   ├── _fonts.sass                # font-face
│   ├── _responsive_mixins.sass    # mixins
│   ├── _typography.sass           # typography
│   └── _variables.sass            # fonts
│
├── vendor                         # vendored (as scss files)
│   ├── _normalize.scss            # normalize cross-browser
│   ├── _jquery.plugin.scss        # js plugin css
│   └── bootstrap                  # bootstrap scss files
│       ├── _forms_variables.scss  # our tweaks to the vars
│       ├── _forms.scss
│       ├── _grid_variables.scss   # our tweaks to the vars
│       ├── _grid.scss
│       ├── _attachments.scss
│       └── ...
│       └── _utilities.scss
│
├── legacy						   # HERE BE DRAGONS
│   ├── ...
│   └── _lots.sass
│
├── v4   						   # working on moving into
│   ├── ...                        # the new coding standards
│   └── ...
│
└── pages                          # view specific partials
      └── controller_name            # try not to do this
          ├── _index.scss
          └── _show.scss
```

## Adding Third Party CSS

Goes in `vendor` directory, unedited. If there are multiple files, use a directory.

Most included files will be css files so change the extension to `.scss`. If you _do_ have to make changes, keep them small (this is most likely changes to image paths) and do it in a seperate commit.

I prefer to include non-minified source, so that future changes to plugins can be easily seen in a `git diff`.

For example the mixins from [bootstrap-sass](https://github.com/twbs/bootstrap-sass/) go into `vendor/bootstrap/_mixins.scss`.


## Work in Progress

If you are unsure put the CSS where you think it needs to go and reach out to the wider team pre-pull request. You'll also get feedback during the PR process.

We don't _do_ potential timebombs like `wip.sass` with later cleanup. Treat CSS as production-ready.


## Page specific styles

There is *never* a good reason to write page-specific styles, so `pages` should be empty. If it isn't, each file name should be the snake-cased, full path to the corresponding view partial.


# Going Off Topic

## Emails

_We are moving to responsive emails... please speak to your lead developer if you have email related stories._

The rules above apply, mostly. We have CSS inliners (`premailer` in Rails 2) that mostly do the heavy lifting for you.

The notable exception being, of course, that most of your layout will be done with tables.

Avoid using floats, padding, and margins in emails.

## Javascript

JQuery will typically use CSS-style selectors to designate objects, but this doesn't mean you're allowed to tightly couple the two.

- Use DOM IDs (`#foo`) to select individual nodes from Javascript code.
- Use HTML5 data attributes (`[data-myclass]`) to select groups of nodes.
- Do not ever mention classes that appear in CSS selectors from Javascript code.
- If you have to, only use classes with the `js-` prefix as above.

Good:

    # Haml
    .js-alertable.message#message_123{ data: { confirm: 'hey!' } }

    # Sass
    .message
      border: 1px dotted red

    # Coffee
    $('.js-alertable').on 'click', () ->
	  alert $(this).data('confirm')

Bad (Sass-Coffee coupling):

    # Haml
    .message#message_123{ data: { confirm: 'hey!' } }

    # Sass
    .message
      border: 1px dotted red

    # Coffee
    $('.message').on 'click', () ->
	  alert $(this).data('confirm')


-------------------------------------------------------

Thanks for reading!

If you disagree with something, or think the guide lacks something, feel free to issue a pull request against the guide!
Be prepared to defend, as we usually merge only when a consensus is reached.
