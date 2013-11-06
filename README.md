The Backbone Style Guide
====================

## Table of contents
* [Naming](#naming)
* [Namespacing](#namespacing)


## Naming

* Use `camelCase` for variables and functions

```javascript
// Bad
var my_var = [2, 1]

// Good
var myVar = [2, 1]
```

```javascript
// Bad
function my_function(args){
  ...
}

// Good
function myFunction(args){
  ...
}
```

* Use `CapitalizedWords` for classes and namespaces

```javascript
// Bad
app.views.search_property = Backbone.View.extend({})

// Good
App.Views.SearchProperty = Backbone.View.extend({})
```

* Do not use {model|view|collection} when naming `models`, `views` or `collections`

```javascript
// Bad
App.Views.SearchPropertyView = Backbone.View.extend({})

// Good
App.Views.SearchProperty = Backbone.View.extend({})
```

### Namespacing

* Always use a root element to not pollute the window namespace

```javascript
// Bad
SearchProperty = ...

// Still not perfect though
App.SearchProperty = ...
```

* Always use namespaces under the root element to reference backbone components as `Models`, `Views` or `Collections`.

```javascript
// Bad
App.SearchProperty = Backbone.View.extend({})

// Good
App.Views.SearchProperty = Backbone.View.extend({})
```
