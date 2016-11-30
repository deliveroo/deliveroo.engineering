---
layout:     guidelines
title:      "JavaScript Style Guide"
subtitle:   "A mostly reasonable approach to JavaScript"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Destructuring

Destructuring saves you from creating temporary references for those properties.

### Objects
{: #destructuring-objects}
Use object destructuring when accessing and using multiple properties of an object[^requireObjectDestructuring].

```javascript
// bad
function getFullName(user) {
  const firstName = user.firstName;
  const lastName = user.lastName;

  return `${firstName} ${lastName}`;
}

// good
function getFullName(user) {
  const { firstName, lastName } = user;
  return `${firstName} ${lastName}`;
}

// best
function getFullName({ firstName, lastName }) {
  return `${firstName} ${lastName}`;
}
```

[^requireObjectDestructuring]: [JSCS: requireObjectDestructuring](http://jscs.info/rule/requireObjectDestructuring)

### Arrays
{: #destructuring-arrays}
Use array destructuring [^requireArrayDestructuring].

```javascript
const arr = [1, 2, 3, 4];

// bad
const first = arr[0];
const second = arr[1];

// good
const [first, second] = arr;
```

[^requireArrayDestructuring]: [JSCS: requireArrayDestructuring](http://jscs.info/rule/requireArrayDestructuring)

### Objects over arrays
{: #destructuring-objects-over-arrays}

Use object destructuring for multiple return values, not array destructuring. This allows you to add new properties over time or change the order of things without breaking call sites [^disallowArrayDestructuringReturn].

```javascript
// bad
function processInput(input) {
  // then a miracle occurs
  return [left, right, top, bottom];
}

// the caller needs to think about the order of return data
const [left, __, top] = processInput(input);

// good
function processInput(input) {
  // then a miracle occurs
  return { left, right, top, bottom };
}

// the caller selects only the data they need
const { left, top } = processInput(input);
```

[^disallowArrayDestructuringReturn]: [JSCS: disallowArrayDestructuringReturn](http://jscs.info/rule/disallowArrayDestructuringReturn)

## Types

### Primitives
{: #types-primitives}

When you access a primitive type you work directly on its value.

+ `string`
+ `number`
+ `boolean`
+ `null`
+ `undefined`

```javascript
const foo = 1;
let bar = foo;

bar = 9;

console.log(foo, bar); // => 1, 9
```

### Complex Types
{: #types-complex}

When you access a complex type you work on a reference to its value; changes to the value (as long as it's not overwritten with a new value) will mutate the pointer value.

+ `object`
+ `array`
+ `function`

```javascript
const foo = [1, 2];
const bar = foo;

bar[0] = 9;

console.log(foo[0], bar[0]); // => 9, 9
```

## Commas

### Leading Commas
{: #commas-leading}

Don’t use leading commas [^comma-style], [^requireCommaBeforeLineBreak].

```javascript
// bad
const story = [
    once
  , upon
  , aTime
];

// good
const story = [
  once,
  upon,
  aTime,
];

// bad
const hero = {
    firstName: 'Ada'
  , lastName: 'Lovelace'
  , birthYear: 1815
  , superPower: 'computers'
};

// good
const hero = {
  firstName: 'Ada',
  lastName: 'Lovelace',
  birthYear: 1815,
  superPower: 'computers',
};
```

[^comma-style]: [ESLint: comma-style](http://eslint.org/docs/rules/comma-style.html)
[^requireCommaBeforeLineBreak]: [JSCS: requireCommaBeforeLineBreak](http://jscs.info/rule/requireCommaBeforeLineBreak)

### Trailing Commas
{: #commas-trailing}

*Do* use trailing commas. This leads to cleaner git diffs. Transpilers like Babel will remove the additional trailing comma in the transpiled code, which means you don't have to worry about the [trailing comma problem](https://satishchilukuri.com/blog/entry/ie-8-and-trailing-commas-in-javascript) in legacy browsers [^comma-dangle], [^requireTrailingComma].

```diff
// bad - git diff without trailing comma
const hero = {
     firstName: 'Florence',
-    lastName: 'Nightingale'
+    lastName: 'Nightingale',
+    inventorOf: ['coxcomb chart', 'modern nursing']
};

// good - git diff with trailing comma
const hero = {
     firstName: 'Florence',
     lastName: 'Nightingale',
+    inventorOf: ['coxcomb chart', 'modern nursing'],
};
```
```javascript
// bad
const hero = {
  firstName: 'Dana',
  lastName: 'Scully'
};

const heroes = [
  'Batman',
  'Superman'
];

// good
const hero = {
  firstName: 'Dana',
  lastName: 'Scully',
};

const heroes = [
  'Batman',
  'Superman',
];
```

[^comma-dangle]: [ESLint: comma-dangle](http://eslint.org/docs/rules/comma-dangle.html)
[^requireTrailingComma]: [JSCS: requireTrailingComma](http://jscs.info/rule/requireTrailingComma)

## Naming Conventions

### Descriptive Naming
{: #naming-conventions-descriptive}

Be descriptive with your naming. Avoid single letter names [^id-length].

```javascript
// bad
function q() {
  // ...stuff...
}

// good
function query() {
  // ..stuff..
}
```

[^id-length]: [ESLint: id-length](http://eslint.org/docs/rules/id-length)

### camelCase
{: #naming-conventions-camelcase}

Use `camelCase` when naming objects, functions, and instances [^camelcase], [^requireCamelCaseOrUpperCaseIdentifiers].

```javascript
// bad
const OBJEcttsssss = {};
const this_is_my_object = {};
function c() {}

// good
const thisIsMyObject = {};
function thisIsMyFunction() {}
```

[^camelcase]: [ESLint: camelcase](http://eslint.org/docs/rules/camelcase.html)
[^requireCamelCaseOrUpperCaseIdentifiers]: [JSCS: requireCamelCaseOrUpperCaseIdentifiers](http://jscs.info/rule/requireCamelCaseOrUpperCaseIdentifiers)

### PascalCase
{: #naming-conventions-pascalcase}

Use PascalCase only when naming constructors or classes [^new-cap], [^requireCapitalizedConstructors].

```javascript
// bad
function user(options) {
  this.name = options.name;
}

const bad = new user({
  name: 'nope',
});

// good
class User {
  constructor(options) {
    this.name = options.name;
  }
}

const good = new User({
  name: 'yup',
});
```

[^new-cap]: [ESLint: new-cap](http://eslint.org/docs/rules/new-cap.html)
[^requireCapitalizedConstructors]: [JSCS: requireCapitalizedConstructors](http://jscs.info/rule/requireCapitalizedConstructors)

### Leading Underscores
{: #naming-conventions-leading-underscores}

Do not use trailing or leading underscores [^no-underscore-dangle], [^disallowDanglingUnderscores]. JavaScript does not have the concept of privacy in terms of properties or methods. Although a leading underscore is a common convention to mean “private”, these properties are in fact fully public, and as such, are part of your public API contract. This convention might lead developers to wrongly think that a change won't count as breaking, or that tests aren't needed. If you want something to be “private”, it must not be observably present; i.e. a closure.

```javascript
// bad
this.__firstName__ = 'Panda';
this.firstName_ = 'Panda';
this._firstName = 'Panda';

// good
this.firstName = 'Panda';

function closure() {
  const privateFunction = () => {
    //...
  }
}
```

[^no-underscore-dangle]: [ESLint: no-underscore-dangle](http://eslint.org/docs/rules/no-underscore-dangle.html)
[^disallowDanglingUnderscores]: [JSCS: disallowDanglingUnderscores](http://jscs.info/rule/disallowDanglingUnderscores)

### Referencing `this`
{: #naming-conventions-this}

Don't save references to `this`. Use arrow functions or [`Function#bind`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind) instead [^disallowNodeTypes].

```javascript
// bad
function foo() {
  const self = this;
  return function () {
    console.log(self);
  };
}

// bad
function foo() {
  const that = this;
  return function () {
    console.log(that);
  };
}

// good
function foo() {
  return () => {
    console.log(this);
  };
}
```

[^disallowNodeTypes]: [JSCS: disallowNodeTypes](http://jscs.info/rule/disallowNodeTypes)

### Exports and filenames
{: #naming-conventions-exports-filenames}

A base filename should exactly match the name of its default export.

```javascript
// file 1 contents
class CheckBox {
  // ...
}
export default CheckBox;

// file 2 contents
export default function fortyTwo() { return 42; }

// file 3 contents
export default function insideDirectory() {}

// in some other file
// bad
import CheckBox from './checkBox'; // PascalCase import/export, camelCase filename
import FortyTwo from './FortyTwo'; // PascalCase import/filename, camelCase export
import InsideDirectory from './InsideDirectory'; // PascalCase import/filename, camelCase export

// bad
import CheckBox from './check_box'; // PascalCase import/export, snake_case filename
import forty_two from './forty_two'; // snake_case import/filename, camelCase export
import inside_directory from './inside_directory'; // snake_case import, camelCase export
import index from './inside_directory/index'; // requiring the index file explicitly
import insideDirectory from './insideDirectory/index'; // requiring the index file explicitly

// good
import CheckBox from './CheckBox'; // PascalCase export/import/filename
import fortyTwo from './fortyTwo'; // camelCase export/import/filename
import insideDirectory from './insideDirectory'; // camelCase export/import/directory name/implicit "index"
// ^ supports both insideDirectory.js and insideDirectory/index.js
```

### Default exports
{: #naming-conventions-default-exports}

Use `camelCase` when you export-default a function. Your filename should be identical to your function's name.

```javascript
function makeStyleGuide() {
}

export default makeStyleGuide;
```

### Singletons
{: #naming-conventions-singletons}

Use `PascalCase` when you export a constructor, class, singleton, function library or bare object.

```javascript
const DeliverooStyleGuide = {
  es6: {
  }
};

export default DeliverooStyleGuide;
```

## Modules

### Imports over require
{: #modules-imports}

Always use modules (`import`/`export`) over a non-standard module system. You can always transpile to your preferred module system. Modules are the future: let's start using the future now.

```javascript
// bad
const DeliverooStyleGuide = require('./DeliverooStyleGuide');
module.exports = DeliverooStyleGuide.es6;

// ok
import DeliverooStyleGuide from './DeliverooStyleGuide';
export default DeliverooStyleGuide.es6;

// best
import { es6 } from './DeliverooStyleGuide';
export default es6;
```

### Wildcard imports
{: #modules-wildcard-imports}

Do not use wildcard imports. This makes sure you have a single default export.

```javascript
// bad
import * as DeliverooStyleGuide from './DeliverooStyleGuide';

// good
import DeliverooStyleGuide from './DeliverooStyleGuide';
```

### No export from import
{: #modules-export-from-import}

Do not export directly from an import. Although the one-liner is concise, having one clear way to import and one clear way to export makes things consistent.

```javascript
// bad
// filename es6.js
export { es6 as default } from './DeliverooStyleGuide';

// good
// filename es6.js
import { es6 } from './DeliverooStyleGuide';
export default es6;
```

### Duplicate imports
{: #modules-duplicate-imports}

Only import from a path in one place. Having multiple lines that import from the same path can make code harder to maintain [^no-duplicate-imports].

```javascript
// bad
import foo from 'foo';
// … some other imports … //
import { named1, named2 } from 'foo';

// good
import foo, { named1, named2 } from 'foo';

// good
import foo, {
  named1,
  named2,
} from 'foo';
```

[^no-duplicate-imports]: [ESLint: no-duplicate-imports](http://eslint.org/docs/rules/no-duplicate-imports)

### Immutable exports
{: #modules-immutable-exports}

Do not export mutable bindings. Mutation should be avoided in general, but in particular when exporting mutable bindings. While this technique may be needed for some special cases, in general, only constant references should be exported [^no-mutable-exports].

```javascript
// bad
let foo = 3;
export { foo }

// good
const foo = 3;
export { foo }
```

[^no-mutable-exports]: [ESLint: no-mutable-exports](https://github.com/benmosher/eslint-plugin-import/blob/master/docs/rules/no-mutable-exports.md)

### Default exports
{: #modules-default-exports}

In modules with a single export, prefer default export over named export [^prefer-default-export].

```javascript
// bad
export function foo() {}

// good
export default function foo() {}
```

[^prefer-default-export]: [ESLint: prefer-default-export](https://github.com/benmosher/eslint-plugin-import/blob/master/docs/rules/prefer-default-export.md)

### Imports first

Put all `import` statements above non-import statements. Since `import` statements are hoisted, keeping them all at the top prevents surprising behavior [^imports-first].

```javascript
// bad
import foo from 'foo';
foo.init();

import bar from 'bar';

// good
import foo from 'foo';
import bar from 'bar';

foo.init();
```

[^imports-first]: [JSCS: imports-first](https://github.com/benmosher/eslint-plugin-import/blob/master/docs/rules/imports-first.md)

## Iterators and Generators

### Don’t use iterators
{: #dont-use-iterators}

Prefer JavaScript's higher-order functions instead of loops like `for-in` or `for-of`[^no-iterator] [^no-restricted-syntax].
You should always strive to write many small pure functions. For loops are less contained and more difficult to reason about.

[^no-iterator]: [ESLint: no-iterator](http://eslint.org/docs/rules/no-iterator.html)
[^no-restricted-syntax]: [ESLint: no-restricted-syntax](http://eslint.org/docs/rules/no-restricted-syntax)

Use `map()` / `every()` / `filter()` / `find()` / `findIndex()` / `reduce()` / `some()` / ... to iterate over arrays, and `Object.keys()` / `Object.values()` / `Object.entries()` to produce arrays so you can iterate over objects.

```javascript
const numbers = [1, 2, 3, 4, 5];

// bad
let sum = 0;
for (let num of numbers) {
  sum += num;
}
sum === 15;

// good
const sum = numbers.reduce((total, num) => total + num, 0);
sum === 15;
```


### Don’t use generators for now
{: #dont-use-generators}

They don't transpile well to ES5.

### Generators and Spacing
{: #generators-and-spacing}

If you must use generators, or if you disregard [our advice](#dont-use-iterators), make sure their function signature is spaced properly[^generator-star-spacing]. `function` and `*` are part of the same conceptual keyword - `*` is not a modifier for `function`, `function*` is a unique construct, different from `function`.

[^generator-star-spacing]: [ESLint: generator-star-spacing](http://eslint.org/docs/rules/generator-star-spacing)

```js
// bad
function * foo() {
}

const bar = function * () {
}

const baz = function *() {
}

const quux = function*() {
}

function*foo() {
}

function *foo() {
}

// very bad
function
*
foo() {
}

const wat = function
*
() {
}

// good
function* foo() {
}

const foo = function* () {
}
```


## References

This guide is taken in part from the following sources:

* [https://github.com/airbnb/javascript](https://github.com/airbnb/javascript)

## Footnotes
