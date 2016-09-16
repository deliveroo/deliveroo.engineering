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
If you have internal state and/or refs, prefer `class extends React.Component` over `React.createClass` unless you have a very good reason to use mixins. eslint: [`react/prefer-es6-class`](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/prefer-es6-class.md) [`react/prefer-stateless-function`](https://github.com/yannickcr/eslint-plugin-react/blob/master/docs/rules/prefer-stateless-function.md)

```jsx
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

And if you don't have state or refs, prefer normal functions (not arrow functions) over classes:

> Why? When debugging in the good example below the stack trace will include the function name whereas in the bad example it will say its from an anonymous function

```jsx
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

Avoid using an array index as `key` prop, prefer a unique ID: using the index as a key is an [anti-pattern](https://medium.com/@robinpokorny/index-as-a-key-is-an-anti-pattern-e0349aece318).

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
