---
layout: post
title: Simple Group Structures via Templates in C++ – Part III
date: 2015-05-12 13:37
---

This is the third part of a series of posts on implementing a simple group structure in C++11 using template meta programming. If you have missed [the first part](/2015/05/08/groups-templates-pt1.html) or [the second part](/2015/05/08/groups-templates-pt1.html), make sure to check them out.

Last time we went from `Op<Op<A, B>::result, A>` to `Op<Op<A, B>, A>`. Now, we want to go to `Op<A, B, A>`. This requires _variadic templates_.

## Variadic templates
are awesome. They allow us to write functions and even types that take arbitrary numbers of (type) parameters. As an example think about this function:

```cpp
int sum(int x, int y) {
  return x + y;
}
```
we can improve it with templates to take an arbitrary input type that supports addition:

```cpp
template <typename T>
T sum(T lhs, T rhs) {
  return lhs + rhs;
}
```
but for summation of more than two values we would have to write another function or repeatedly apply `sum`. Writing a function for every possible case (three parameters, four parameters, …) is not only tiresome and unmaintainable it is also impossible as the number of parameters goes to infinity. Repeatedly applying the function works better but who really wants to write `sum(sum(sum(sum(sum(…)…)…)…)…)`?

With just four lines of code, we are able to solve that problem:

```cpp
template <typename T, typename... Ts>
T sum(T head, Ts... tail) {
  return head + sum(tail...);
}
```
The three dots (`...` not `…`) indicate the use of what is called a _parameter pack_. Parameter packs are at the core of variadic templates. You can find an excellent and comprehensive description on [cppreference.com](http://en.cppreference.com/w/cpp/language/parameter_pack). 

If you call `sum(1, 2, 3, 4)` somewhere in your code, your compiler should in theory generate `sum` functions taking four, three, and two parameters. However, modern compilers are smart enough to not actually do this and optimise most of it away. In fact, the generated assembly file (clang option `-S`) for this program is only a few lines long and contains no function calls whatsoever.

```cpp
#include "variadic.h"

int main() {
  return sum(1, 2, 3, 4);
}
```

## Back to our Group
In order to apply what we've learned about variadic templates and parameter packs to our original problem we just need to consider one difference between functions and types: There is no type overloading in C++. In the `sum` example it was okay to first define the base case (two parameters) and then specify the more common case but when working with types we must define the most common case first:

```cpp
template <typename...>
struct Op {};
```

Our initial definition then becomes a _specialisation_ of this template:

```cpp
template <typename LHS, typename... RHS>
struct Op<LHS, RHS...> {
  using result =
      typename Op<typename LHS::result,
                  typename Op<RHS...>::result>::result;
};
```

Notice how we use the same recursive structure as in the above example. Functional programmers will recognise this pattern as a _fold_.

And indeed, this assertion holds, showing that our code works the way we want it to

```cpp
static_assert(
  std::is_same<Op<A, A, A, B, A, B, B, A>::result, B>::value,
  "AAABABBA = B"
);
```


## Code
The code for this series of posts can be found on [GitHub](https://github.com/kdungs/cpp-group-study).


## Conclusion
Using a somewhat constructed example of an O(1) group, we have learned how to implement compile-time calculations on arbitrary structures. We also had a look at _parameter packs_ and _variadic templates_ that allow us to write very generic and highly re-usable code.

 * [Part 1](/2015/05/08/groups-templates-pt1.html)
 * [Part 2](/2015/05/10/groups-templates-pt2.html)


## Quesions, Remarks, …
Do you have any questions? Is anything unclear? Did I get something wrong? Is something horribly imprecise? Please let me know! Send an email to kevin at this domain or write an issue on [the GitHub repo](https://github.com/kdungs/cpp-group-study).

Cheers!
