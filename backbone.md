The Backbone Style Guide
====================

## Table of contents
* [Naming](#naming)
* [Namespacing](#namespacing)
* [File Organization](#file-organization)


## Naming

Use `camelCase` for variables and functions

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

Use `CapitalizedWords` for classes and namespaces

```javascript
// Bad
app.views.search_property = Backbone.View.extend({})

// Good
App.Views.SearchProperty = Backbone.View.extend({})
```

Do not use {model|view|collection} when naming `models`, `views` or `collections`

```javascript
// Bad
App.Views.SearchPropertyView = Backbone.View.extend({})

// Good
App.Views.SearchProperty = Backbone.View.extend({})
```

Use singular for `model` classes and plural for `collection` classes

```javascript
App.Models.Property = Backbone.Model.extend({})
App.Collections.Properties = Backbone.Collection.extend({})
```

Use singular or plural for `views` depending if you passing a model or collection

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

Always use a root element to not pollute the window namespace

```javascript
// Bad
SearchProperty = ...

// Still not perfect though
App.SearchProperty = ...
```

Always use namespaces under the root element to reference backbone components as `Models`, `Views` or `Collections`.

```javascript
// Bad
App.SearchProperty = Backbone.View.extend({})

// Good
App.Views.SearchProperty = Backbone.View.extend({})
```

Have exactly 1 file that contains all namespace initialization and bind the root namespace to `window`

```javascript
window.App = {}

App.Models = {}
App.Collections = {}
App.Views = {}
```

## File Organization

Assuming `root` is where you have your javascript assets, the file organization should follow these rules:

```
<root>
  ├── collections
    ├── collections1.js
    └── collections2.js
  ├── helpers
    ├── helper1.min.js
    ├── helper2.min.js
    └── helper3.min.js
  ├── lib
    ├── lib1.min.js
    ├── lib2.min.js
    └── lib3.min.js  
  ├── models
    ├── model1.js
    └── model2.js
  ├── vendor
    ├── vendor1.min.js
    ├── vendor2.min.js
    └── vendor3.min.js
  ├── views
    ├── context1
      ├── view1.js
      └── view2.js
    ├── context2
      ├── view1.js
      └── view2.js
  ├── app.js # initialize namespaces here
```

### Purpose of folders:

* `helpers` - Helper classes or helper methods that have dependencies on the application specifics. Example: date functions that convert Date to String objects with a specific format, compute a full name based on a backbone model first name and last name, handling a push state of a specific page, etc..

* `lib` - All library code created by our team that supports the app itself but could be applied on other contexts  - extended jquery plugins, specific galleries, etc..

* `vendor` - All 3rd party code (jquery, backbone, underscore, plugins, etc..). These files **should not be modified** and they should contain as a comment on top of file which version they at or the file name should reflect the version **jquery-2.6.6.6**. In case they need to be modified - always consider issuing a PR for the owner - they should be moved to `lib` folder.

* `views` - Whenever possible introduce context folders to facilitate understanding of the logic and place of the several components. Name it like: `search`, `search_bar`, `filters`, `gallery`. This helps not only cracking the code but enforces components to be named after their context folder: `SearchSort`, `SearchBarCalendar`, `SearchBarGuests`, `FiltersPanel`, etc..


If using Rails:

* the `vendor` folder should be in `/vendor/assets/javascripts` 

* the application code should be in `/app/assets/javascripts`


Requiring the files should follow this order

```
  vendor/*
  lib/*  
  app.js
  helpers/*
  models/*  
  collections/*  
  views/*  
```
