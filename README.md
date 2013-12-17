# Sass style guide

[File Organization](#file-organization) | [Naming conventions](#naming-conventions) | [Selectors](#selectors) | [Rulesets, Properties, Data types](#rulesets-properties-and-data-types) | [Integration with HTML and Javascript code](#integration-with-html-and-javascript-code)

----

Welcome to the [HouseTrip](http:://www.housetrip.com) CSS Styleguide, derived from Github's and others. We think it's cool and hope you will too. Before reading this, you should have a general understanding for **[specificity](http://www.w3.org/TR/CSS2/cascade.html#specificity)**, the **[Sass](http://sass-lang.com/)** syntax, and **[KSS](https://github.com/kneath/kss)** documentation.

Parts of this also assume you're using the excellent **[Compass](http://compass-style.org)** library.

While we port our styles over to object-orientated Sass with KSS documentation, please make sure to upgrade an entire element's Sass/CSS at once. Do not mix small amounts of OO-Sass in with "classic" Sass. *Do your future self a favor!*

If you're visiting from the internet, feel free to learn from our style. This is a guide we use for our own apps internally at HouseTrip. We encourage you to set up one that works for your own team.

### An introduction

> "Part of being a good steward to a successful project is realizing that writing code for yourself is a Bad Idea. If thousands of people are using your code, then write your code for maximum clarity, not your personal preference of how to get clever within the spec." - Idan Gazit

A very important thing to remember is that **Styles are code**. Sass code deserves the same love you give to code in other languages: clean, well organised, object-orientated, structured, well named, commented exactly like you'd write your Ruby (or any other language) code.

- Don't try to prematurely optimize your code; keep it readable and understandable.
- All code in any code-base should look like a single person typed it, even when many people are contributing to it.
- Strictly enforce the agreed-upon style.
- If in doubt when deciding upon a style use existing, common patterns.


### Basic coding Style

- Use soft-tabs with a two space indentation.
- Use `//` for comment blocks.
- Document styles with [KSS](https://github.com/kneath/kss).

Here is good example syntax:

    // This is a good example!
    $textColor:       #000
    $backgroundColor: white

    // Base settings
	.styleguide-format
	  border:     1px solid $textColor
	  color:      $textColor
	  background: $backgroundColor


## File Organization

In general, the CSS file organization should follow something like this

	<root>
	├── application.css.sass           # toplevel (mostly empty!)
	├── application
	│   ├── _mixins.sass               # all reusable mixins
	│   ├── _variables.sass            # colors, dimensions
	│   ├── components                 # reusable visual elemenet, and layouts
	│   │   ├── _badges.css.sass       #    not tied to specific models
	│   │   └── _responsive_table.css.sass
	│   ├── fonts.css.sass             # all fonts
    │   └── models                     # representation of app models
	│       ├── _attachments.css.sass  #   one file or more per model
	│       ├── _comment.css.sass
    │       ├── _idea.css.sass
	│       └── _user.css.sass
    ├── bootstrap_ext                  # patches to 3rd party libs
	│   ├── _buttons.css.sass          #   reflect the names
	│   ├── _code.css.sass             #   of library files
	│   ├── _floats.css.sass
	│   └── _type.css.sass
	└── pages                          # view specific partials
	    └── welcome.css.sass           #   mostly forbidden


### Where to put stuff?

Any `$variable` or `=mixin` that is used in more than one file should be put in `_variables` or `_mixins`. Others should be put at the top of the file where they're used.

As a rule of thumb, don't nest further than 3 levels deep. If you find yourself going further, think about reorganizing your rules (either the specificity needed, or the layout of the nesting).

There is *never* a good reason to write page-specific styles, so `pages` should be empty. If it isn't, each file name should be the snake-cased, full path to the corresponding view partial.

### @import

If using Rails 3.1+, use [Sprockets](https://github.com/sstephenson/sprockets) to **require** files. However, you should explicitly **import** any Sass that does not generate styles in the particular Sass file you'll be needing it's helpers in. Here's a good example:

	@import "application/variables"

	.rule
      color: $myVar

In other words:

- each file must import exactly what it needs (as load order may change)
- do not import full third part libraries (e.g. Compass), import just what you need.


Good:

	@import compass/css3/images

Bad:

	@import compass


## Naming conventions

Variables are `$camelCased`.
Classes and IDs use dashes, not snake case.
Mixins use dashes too.

Acronyms and domain lingo are forbidden.

Good:

    $myColor: black
    #some-stuff .what-ever-ranking
    	color: $myColor

Bad:

    $MYCOLOR: black
    #someStuff .what_ever_SQS
    	color: $MYCOLOR

### Semantic, view agnostic naming


Class names should reflect intent or function, not layout or aspect.
Name classes semantically.
If you can't come up with a readable name for new class, ask someone for advice!

Good:

    .button.button-alert
    	color: red

Bad:

    .button.button-red
    	color: red

Never make styles specific to a page, and generally avoid making classes dependent on _where_ they're going to be used.

Good (and fast):

    .carousel
    	@extend widget
    .carousel-hero
    	font-size: x-large

    // bad
    #home-page .carousel
    	@extend widget
    	font-size: x-large


### Object orientation

Follow object orientation guidelines. If this is jargon to you, [this article](http://coding.smashingmagazine.com/2011/12/12/an-introduction-to-object-oriented-css-oocss/) is a good starting point. In particular:

- Factor out common styles as superclasses (technically more like mixins).

	Good:

		.button
			@extend widget
			font-family: sans-serif
		.button-alert
			color: red

		<a class="button button-alert">

	Bad:

		.button
			@extend widget
			font-family: sans-serif
		.button-alert
			@extend widget
			font-family: sans-serif
			color: red

		<a class="button-alert">


- Class hierarchies should be listed rather than using `@extend` (a la Bootstrap).

	Good:

		.button
			@extend widget
			font-family: sans-serif
		.button-alert
			color: red

		<a class="button button-alert">

	Bad:

		.button
			@extend widget
			font-family: sans-serif
		.button-alert
			@extend button
			color: red

		<a class="button-alert">

- Namespace class names.

	Good:

		.button.button-instant-booking
		.property.property-instant-booking

	Bad:

	    .button.instant-booking
	    .property.instant-booking


- Separate containers/positioning from content/aspect classes:

	Good:

		.avatar
			+rounded-corners(100px)
			background-image: url("/avatar.png")

		.pull-left
			float: left

	Bad:

	    .avatar
			+rounded-corners(100px)
			background-image: url("/avatar.png")
			float: left




### Classes used in Javascript

Never reference `js-` prefixed class names from CSS files. `js-` are used exclusively from JS files.

Use the `js-` prefix for class names that are shared between HTML and JS.

## Selectors

### Classes vs. IDs

Elements that occur **exactly once** inside a page should use IDs, otherwise, use classes. When in doubt, use a class name.

- **Good** candidates for ids: header, footer, modal popups.
- **Bad** candidates for ids: navigation, item listings, item view pages (ex: issue view).

When styling a component, start with an element + class namespace (prefer class names over ids), prefer direct descendant selectors by default, and use as little specificity as possible. Here is a good example:

	/ Haml
	%ul.category-list
	  %li Category 1
	  %li Category 2
	  %li Category 3

    // Sass
	%ul.category-list // element + class namespace
	  & > li          // direct descendant selector > for list items
	    list-style-type: disc

	  a              // minimal specificity for all links
	    color: $alert_red

### CSS Specificity guidelines

Above all: always used the least specific selectors possible.
In Sass, this means that you should **never nest more than 2 levels deep**.

If you feel the need to, your classes are probably not semantic (enough).

Good:

	.hero-list
    	font-size: x-large

	a.call-to-action
    	color: red

Bad:

	.hero-list .item a.call-to-action
    	font-size: x-large
    	color: red

Extra rules:

- **Avoid the descendent selector** (e.g. `.sidebar h3`). It's a sign of non-OO styling.
- Avoid attaching classes to elements in your stylesheet (e.g. `div.header`, `h1.title`).
- **Do not use IDs** in CSS selectors. IDs are for Javascript use.
- If you must use an ID selector (`#selector`) make sure that you have no more than one in your rule declaration. A rule like `#header .search #quicksearch { ... }` is considered harmful.
- When modifying an existing element for a specific use, try to use specific class names. Instead of `.listings-layout.bigger` use rules like `.listings-layout.listings-bigger`. Think about ack/greping your code in the future.
- The class names `disabled`, `mousedown`, `danger`, `hover`, `selected`, and `active` should always be namespaced by a class (`button.selected` is a good example).


## Rulesets: Properties and Data types

The basics:

- Put at least one space after `:` in property declarations
- Align consecutive property values.
- Never use color codes (`#000`) or names (`black`) outside of variable declarations.


### Ordering properties

Properties should be grouped together:

- first calls to `@extend`,
- then calls to one line mixins (`@include`),
- then layout-related properties (`position`, `float`, `display`, `width`, `heigth`),
- then aspect-related properties (`font`, `border`, `color`),
- finally calls to `@content` mixins, like `when-bigger-than-mobile` in the following example:

Good:

```sass
.container
  font-size: 24px
  +when-bigger-than-mobile
    color: white
    background-color: black
```
Bad:

```sass
.container
  +when-bigger-than-mobile
    color: white
    background-color: black
  font-size: 24px
```

### Extending and mixing in

Always prefer `@extend` over mixins. Mixins duplicate rulesets whereas extensions reuse them (hence extension is much faster when your styles get rendered).
Prefer having multiple classes over both.

Good:

	.widget
    	+rounded-corners(3px)
    .button
    	@extend widget
    .
nn
Bad:

Call mixins with `+my-mixin(...)` instead of with `@include`.

Good:

Bad:

### Prefixed properties

Do not use browser-specific, prefixed properties directly. Compass does that for you.

If it's not enough, issue a fix to Compass, don't work around it.

Good:

    @import compass/css3/images

    .squid
      +linear-gradient(pink, cyan)

Bad:

    @import compass/css3/images

    .squid
      -o-linear-gradient: top, pink, cyan
      -webkit-gradient:   linear, top, bottom, pink, cyan

### Colours


Prefer to use use functions (`transparentize`, `lighten`) over RGBA. You'd probably get the math wrong, and it'd be less readable, so why bother?


### Pixels vs. Ems

Use `px` for `font-size`, because it offers absolute control over text. Additionally, unit-less `line-height` is preferred because it does not inherit a percentage value of its parent element, but instead is based on a multiplier of the `font-size`.


### Icon Fonts

Should we move towards the much more favourable Icon Fonts rather than PNG sprites. Something like [Font Awesome](http://fortawesome.github.io/Font-Awesome/) would be a great place to start.

    <i class="icon-search icon-large icon-blue">

is all that would be needed in order to display a large, blue magnifying glass icon

Given the likelyhood that the font doesn't contain all the icons needed fo the whole site, we might consider using [Font Custom](http://fontcustom.com/) and have the design team contribute to expanding the icon set.

Sprites/images may need to be used in the meantime.


### Let CSS do the styling

**Do not** use images for gradients. There's no need when we have CSS gradients at our disposal.

Good:

	.hero-unit
	    +gradient($light_gray,white)

Bad:

	.hero-unit
    	background-image: url("/gradient.png")


**Do not** transform text server side. Think of the user who wants to copy and paste that text, or the next developer who needs to change the style.

Implement all-caps with `text-transform:uppercase`, not (in Ruby) `String#upcase`.


### Shoehorning

Never use `!important`. It's like leaving a loaded gun lying around.
It means
Think you have a counter-example? You're wrong. Don't say we didn't tell you.


### Odds and ends

- Use lowercase and shorthand hex values

		.foo
		  color: #2ca

- Use single or double quotes consistently. Preference is for double quotes.

		.foo
		  content: ""

- Quote attribute values in selectors

    	input[type="checkbox"]
          color: red

- Where allowed, avoid specifying units for zero-values

		.foo
    	  margin: 0

- Comma separated selectors on multiple lines

        td,
        th
          color: $blue

- Include a space after each comma in comma-separated property or function values

		.button
          border: 1px solid red, 2px dotted blue

- Use shorthand properties where possible

    Good:

		.button
          margin: 1em 0

    Bad:

    	.button
          margin: 0
          margin-left:  1em
          margin-right: 1em

- Put 0s in front of values or lengths between -1 and 1.

		.button
          margin-right: 0.25em


### keep it DRY - use sass iterator

- Use `@each` iterator and string interpolation to keep it DRY

    Good:

        @each $code in en, fr, de
		  .small_flag_#{$code}
		    @include small-flags-sprite("#{$code}")

    Bad:

        .small_flag_en
          @include small-flags-sprite("en")
        .small_flag_fr
          @include small-flags-sprite("fr")
        .small_flag_de
          @include small-flags-sprite("de")

### IE6/7 Support

Don't.

From Christian Heilmann ([@codepo8](http://github.com/codepo8))

> **Stop building for the past** – using a library should not be an excuse for a company to use outdated browsers. This hurts the web and is a security issue above everything else. No, IE6 doesn’t get any smooth animations – you can not promise that unless you spend most of your time testing in it.

We have officially dropped support for these old browsers and are prompting people to update. We really do not want to spend our time fixing and testing for this small sebset of our userbase.



## Integration with HTML and Javascript code

### HTML

All new style should be oject-orientated; therefore:

- Do not use the `<style>` tag to add custom CSS to pages.
- Do not use the `style=` HTML attribute to style specific DOM elements.


### Emails

The rules above apply. You should use normal style files and object orientation, and let your CSS inliner (`premailer` in Rails 2, `roadie` in Rails 3) do the heavy lifting for you.

The notable exception being, of course, that most of your layout will be done with tables.

Avoid using floats, padding, and margins in emails.

### Javascript

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

Of you disagree with something, or think the guide lacks something, feel free to issue a pull request against the guide!
Be prepared to defend, as we usually merge only when a consensus is reached.
