+++
title = "Refined simple group structures via templates in C++"
aliases = ["/posts/2016-02-08-groups-templates-refined.html"]
+++

This is a follow-up to a post from last year called [Simple group structures via templates in C++](@/posts/2015-05-12-groups-templates.md) in which we implemented a compile-time O(1) group structure.  Now we want to revisit the code and use a nice pattern that can be learned in “C++ Template Metaprogramming: Concepts, Tools, and Techniques from Boost and Beyond” by Abrahams and Gurtovoy.

<!-- more -->

All code for this post can be found on [GitHub](https://github.com/kdungs/cpp-group-study).

At the end of the last post, the following code worked:

```cpp
static_assert(
  std::is_same<Op<A, A, A, B, A, B, B, A>::result, B>::value,
  "AAABABBA = B");
```

which if you ask me is pretty awesome. The final result from the old post looked like this:

```cpp
struct A { using result = A; };
struct B { using result = B; };

template <typename...> struct Op {};
template <> struct Op<A, A> { using result = A; };
template <> struct Op<A, B> { using result = B; };
template <> struct Op<B, A> { using result = B; };
template <> struct Op<B, B> { using result = A; };

template <typename LHS, typename... RHS>
struct Op<LHS, RHS...> {
    using result = typename Op<typename LHS::result,
                               typename Op<RHS...>::result>::result;
};
```

As you can see, we have to write `using result = …` seven times in just ten lines of code. Using inheritance, we can get rid of this. Note that our base class will completely disappear due to the “empty base optimisation” leaving the same nice and clean machine code we had before but allowing us to write cleaner code.

We define a little wrapper type that accepts an arbitrary type `T` and exposes it through a type alias

```cpp
template <typename T>
struct result_t {
  using result = T;
};
```

no magic so far. Now, we define our types `A` and `B` to inherit from `result_t` while passing their respective type as the argument

```cpp
struct A : result_t<A> {};
struct B : result_t<B> {};
```

Now they will have a result member type set to their own type. Using this pattern, we can refactor our original code and arrive at this extremely concise solution

```cpp
template <typename T> struct result_t { using result = T; };
struct A : result_t<A> {};
struct B : result_t<B> {};

template <typename...> struct Op {};
template <> struct Op<A, A> : A {};
template <> struct Op<A, B> : B {};
template <> struct Op<B, A> : B {};
template <> struct Op<B, B> : A {};

template <typename LHS, typename... RHS>
struct Op<LHS, RHS...> : Op<typename LHS::result,
                            typename Op<RHS...>::result> {};
```


## Questions, remarks, …

Do you have any questions? Is anything unclear? Did I get something wrong? Is something horribly imprecise? Please let me know!  [Go to the corresponding issue on GitHub, in order to discuss this article.](https://github.com/kdungs/dun.gs/issues/7)
