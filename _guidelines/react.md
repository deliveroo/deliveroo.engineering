---
layout:     guidelines
title:      "React/JSX Style Guide"
subtitle:   "A mostly reasonable approach to React and JSX"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}


## Class vs `React.createClass` vs stateless
If you have internal state and/or refs, prefer `class extends React.Component`
over `React.createClass` unless you have a very good reason to use mixins
[^prefer-es6-class], [^prefer-stateless-function].

```
// bad
const Listing = React.createClass({
  // ...
  render() {
    return <div>{this.state.hello}</div>;
  }
});

// good
class Listing extends React.Component {
  // ...
  render() {
    return <div>{this.state.hello}</div>;
  }
}
```

[^prefer-es6-class]: [ESLint: prefer-es6-class](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/prefer-es6-class.md)
[^prefer-stateless-function]: [ESLint: prefer-stateless-function](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/prefer-stateless-function.md)


If you don't have state or refs, prefer normal functions (not arrow functions)
over classes. When debugging in the good example below the stack trace will
include the function name whereas in the bad example it will say it’s from an
anonymous function:

```
// bad
class Listing extends React.Component {
  render() {
    return <div>{this.props.hello}</div>;
  }
}

// bad (relying on function name inference is discouraged)
const Listing = ({ hello }) => (
  <div>{hello}</div>
);

// good
function Listing({ hello }) {
  return <div>{hello}</div>;
}
```

## Quotes

Always use double quotes (`"`) for JSX attributes, and single quotes for all
other JS [^jsx-quotes]. JSX attributes [can’t contain escaped quotes](http://eslint.org/docs/rules/jsx-quotes), so double quotes make
contractions like `"don't"` easier to type. Regular HTML attributes also
typically use double quotes instead of single, so JSX attributes mirror this
convention:

```
// bad
<Foo bar='bar' />

// good
<Foo bar="bar" />

// bad
<Foo style={{ left: "20px" }} />

// good
<Foo style={{ left: '20px' }} />
```

[^jsx-quotes]: [ESLint: jsx-quotes](http://eslint.org/docs/rules/jsx-quotes)

## Props

Always use camelCase for prop names.

```
// bad
<Foo
  UserName="hello"
  phone_number={12345678}
/>

// good
<Foo
  userName="hello"
  phoneNumber={12345678}
/>
```

Omit the value of the prop when it is explicitly `true`. [^jsx-boolean-value]

```
// bad
<Foo
  hidden={true}
/>

// good
<Foo
  hidden
/>
```

[^jsx-boolean-value]: [ESLint: react/jsx-boolean-value](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/jsx-boolean-value.md)

Avoid using an array index as `key` prop, prefer a unique ID; using the index
as a key is an [anti-pattern](https://medium.com/@robinpokorny/index-as-a-key-is-an-anti-pattern-e0349aece318).

```
// bad
{todos.map((todo, index) =>
  <Todo
    {...todo}
    key={index}
  />
)}

// good
{todos.map(todo => (
  <Todo
    {...todo}
    key={todo.id}
  />
))}
```

## Refs

Always use ref callbacks [^no-string-refs].

```
// bad
<Foo
  ref="myRef"
/>

// good
<Foo
  ref={ref => { this.myRef = ref; }}
/>
```

[^no-string-refs]: [ESLint: no-string-refs](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/no-string-refs.md)

## Parentheses

Wrap JSX tags in parentheses when they span more than one line [^wrap-multilines].

```
// bad
render() {
  return <MyComponent className="long body" foo="bar">
           <MyChild />
         </MyComponent>;
}

// good
render() {
  return (
    <MyComponent className="long body" foo="bar">
      <MyChild />
    </MyComponent>
  );
}

// good, when single line
render() {
  const body = <div>hello</div>;
  return <MyComponent>{body}</MyComponent>;
}
```

[^wrap-multilines]: [ESLint: wrap-multilines](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/wrap-multilines.md)

## Tags

Always self-close tags that have no children [^self-closing-comp].

```
// bad
<Foo className="stuff"></Foo>

// good
<Foo className="stuff" />
```

[^self-closing-comp]: [ESLint: self-closing-comp](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/self-closing-comp.md)

If your component has multi-line properties, close its tag on a new line [^jsx-closing-bracket-location].

> Why? It produces nicer diffs.

```
// bad
<Foo
  bar="bar"
  baz="baz" />

// good
<Foo
  bar="bar"
  baz="baz"
/>
```

[^jsx-closing-bracket-location]: [ESLint: jsx-closing-bracket-location](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/jsx-closing-bracket-location.md)
