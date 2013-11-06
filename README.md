The Backbone Style Guide
====================

## Table of contents
* [Naming](#naming)
* [Namespacing](#namespacing)
* [File Organization](#file-organization)


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

* Use singular for `models` and plural for `collections`

```javascript
App.Models.Property = Backbone.Model.extend({})
App.Collections.Properties = Backbone.Collection.extend({})
```

* Use singular or plural for `views` depending if you passing a model or collection

```javascript
App.Views.SearchProperty = Backbone.View.extend({})

new App.Views.SearchProperty({
  model: new App.Models.Property(...)
});

App.Views.SearchProperties = Backbone.View.extend({})

new App.Views.SearchProperties({
  collection: [new App.Models.Property(...)]
})
```

## Namespacing

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

* Always have a file that contains all namespace initialization

```javascript
window.App = {}

App.Models = {}
App.Collections = {}
App.Views = {}
```

## File Organization

* Assuming `root` is where you have your javascript assets, the file organization should follow these rules:

```
<root>
  ├── app.js # initialize namespaces here
  ├── lib
    ├── jquery.min.js
    ├── underscore.min.js
    └── myotherlib.min.js
  ├── models
    ├── model1.js
    └── model2.js
  ├── collections
    ├── collections1.js
    └── collections2.js
  ├── views
    ├── context1
      ├── view1.js
      └── view2.js
    ├── context2
      ├── view1.js
      └── view2.js
```

* Requiring the files should follow this order

```
  lib/*  
  app.js  
  models/*  
  collections/*  
  views/*  
```
