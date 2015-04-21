---
layout: post
title: C++ Template Meta Programming – Part 1
date: 2015-05-21
---

Ready for some crazy stuff? In this post I will explore some template meta programming techniques in C++11 that will blow your mind if you have never seen them before. We will have a look at how to implement multiplication of arbitrary types that gets evaluated at compile time.

For the sake of this exercise let us say we have two values `a` and `b` and want to define a multiplication `×` between the two as follows:

|   ×   | a | b |
|:-----:|:-:|:-:|
| **a** | a | b |
| **b** | b | a |

The gentle reader will recognise this structure as an example of O(1), one of the rather simple [groups](https://en.wikipedia.org/wiki/Group_theory). We could identify a = 1, b = -1.

Since our values are very arbitrary, we define two types for them.[^1]

```cpp
struct A {};
struct B {};
```

The tricky part is defining the multiplication. We might come up with something like this

```cpp
A mult(const A& lhs, const A& rhs) { return {}; }
B mult(const A& lhs, const B& rhs) { return {}; }
// and so on
```

which would get the job done but require objects of type `A` and `B` which only exist at runtime. Instead we will define a templated type that represents the multiplication of two types:

```cpp
template <typename LHS, typename RHS>
struct Mult {};
```
Now, we manually specify specialisations of this templated type and give them a type alias for the resulting type. This way we can encode the type information for our multiplication table.

```cpp
template<>
struct Mult<A, A> {
  using type = A;
};

template <>
struct Mult<A, B> {
  using type = B;
};

// and so forth
```

In order to verify that this works, we can use `static_assert` like so:

```cpp
#include <type_traits>  // for std::is_same
static_assert(std::is_same<Mult<A, A>::type, A>::value, "A × A = A");
static_assert(std::is_same<Mult<A, B>::type, B>::value, "A × B = B");
static_assert(std::is_same<Mult<B, A>::type, B>::value, "B × A = B");
static_assert(std::is_same<Mult<B, B>::type, A>::value, "B × B = A");

// this will fail _during compilation_:
static_assert(std::is_same<Mult<B, B>::type, B>::value, "B x B ≠ B");
```

And that is it already. Pretty neat, huh?


## Further Down the Rabbit Hole
Two questions come to mind now: How do we output the result of our calculations and how do we represent repeated multiplication?

### Printing Results
The easiest way is to use the `typeinfo` header and just write

```cpp
std::cout << typeid(Mult<B, A>::type).name() << '\n';
```

If you want to have a little bit more control over the output, you can specify a templated function that returns a `std::string` and manually specify the implementations for `A` and `B`.

```cpp
template <typename T>
std::string repr() {
  return "No representation.";
}

template <>
std::string repr<A>() {
  return "A";
}

template <>
std::string repr<B>() {
  return "B";  
}
```
These are so simple that your compiler will most likely inline them for you.


### Repeated Multiplication
Right now, if we want to express say a×b×a×b, we would have to write `Mult<Mult<Mult<A, B>::type, A>::type, B>::type` which is a lot of `::type`s. A small modification to our original definitions can make life easier for us:

```cpp
struct A { using type = A; };
struct B { using type = B; };

template <typename LHS, typename RHS>
struct Mult {
  using type = typename Mult<typename LHS::type,
                             typename RHS::type>::type;
};

// specialisations follow here
```

this allows us to write `Mult<Mult<Mult<A, B>, A>, B>::type` for a×b×a×b. Neat!


# Next Time
Wouldn't it be nice to be able to write `Mult<A, B, A, B>` instead of having to write `Mult<Mult<Mult...` all the time? It sure would. The next post in this series will cover _variadic templates_ that give us the means to implement that functionality.

[^1]: One could of course argue (from a group theoretical standpoint) that they should be two incarnations of the same type and use an `enum class` instead. We could do this, but then we would have to dispatch at runtime and could not benefit from template meta programming, so bear with me for a moment.
