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

## Quotes

Always use double quotes (`"`) for JSX attributes, but single quotes for all other JS. eslint: [`jsx-quotes`](http://eslint.org/docs/rules/jsx-quotes)

> Why? JSX attributes [can't contain escaped quotes](http://eslint.org/docs/rules/jsx-quotes), so double quotes make contractions like `"don't"` easier to type.
> Regular HTML attributes also typically use double quotes instead of single, so JSX attributes mirror this convention.

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
