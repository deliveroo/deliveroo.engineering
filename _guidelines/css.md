---
layout:     guidelines
title:      "CSS and SCSS"
subtitle:   "Guidelines on writing CSS and SCSS"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}


## Nesting

### Parent references

Always define parent reference selectors before defining child selectors

```scss
// Bad
a {
  color: red;

  .span {
    color: blue;
  }

  &:hover {
    color: pink;
  }
}

// Good
a {
  color: red;

  &:hover {
    color: pink;
  }

  .span {
    color: blue;
  }
}
```

**Why:** by putting parent reference selectors first it keeps the styling for
that element together. By putting styling for other elements in the middle you
have to scroll around watching nesting levels to try and figure out what the
`&` references.

### Media queries

Put media queries inline nested in the selector they effect.

```scss
// Bad
a {
  color: red;

  .span {
    color: blue;
  }

  img {
    width: 100%;
  }
}
@include phone-only {
  a {
    .span {
      color: red;
    }
  }
}

// Good
a {
  color: red;

  .span {
    color: blue;

    @include phone-only {
      color: red;
    }
  }
  img {
    width: 100%;
  }
}
```

**Why:** nesting all the styles that effect a given selector within the
selector block reduces the chance of an engineer not realising more than one
block of Sass effects that selector tree.

When refactoring a block of styles it makes it much easier to grab all the
styles and extract them or move them around when they are self contained and
together. It also means if the selector tree changes it only needs to be
updated in one place rather than multiple places.


