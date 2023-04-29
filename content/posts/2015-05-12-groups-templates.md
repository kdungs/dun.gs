---
title: Simple group structures via templates in C++
author: Kevin
---

If you enjoyed the previous post on Simple Higher Order Functions in C++ you
already got a taste of templates in C++. In this post we have a look at how we
can implement compile-time _groups_ in C++11. If you are unfamiliar with the
concept of groups, you can read about them on
[Wikipedia](https://en.wikipedia.org/wiki/Group_%28mathematics%29) or [Wolfram
MathWold](http://mathworld.wolfram.com/Group.html).

<!-- more -->

The code for this post can be found on
[GitHub](https://github.com/kdungs/cpp-group-study).

For this example we look at O(1), a rather simple group structure. A possible
incarnation of O(1) is ({1, -1}, ×). Here we call our elements _A_ and _B_ and
for simplicity we omit the group operation sign. We want _AA=A_, _BB=A_,
_AB=B_, and _BA=B_. _A_ is the identity of the group. This group is also cyclic
with order 1 and _B_ being the generator.

First we create two types representing _A_ and _B_:

```cpp
struct A {};
struct B {};
```

Next we need a type representing the binary group operation. That type should
have two template parameters representing the left- and the right-hand side of
the operator. We also need a type definition (here an alias) inside the type to
specify the result of the operation.

```cpp
template <typename LHS, typename RHS>
struct Op {};

template <>
struct Op<A, A> {
  using result = A;
};

template <>
struct Op<A, B> {
  using result = B;
};

// and so on…
```

We can verify that this does indeed work using static assertions. Assuming we
have put our definitions from above in a file called `group.h`, the following
program is sufficient to check that what we did is correct.

```cpp
#include "group.h"

#include <type_traits>

static_assert(std::is_same<Op<A, A>::result, A>::value, "A × A = A");
static_assert(std::is_same<Op<A, B>::result, B>::value, "A × B = B");
static_assert(std::is_same<Op<B, A>::result, B>::value, "B × A = B");
static_assert(std::is_same<Op<B, B>::result, A>::value, "B × B = A");
```

save it as `test_group.cc` and compile it with `c++ -O3 -std=c++11 -o
test_group.o test_group.cc`. The fact that is compiles implies correctness.
Pretty cool, huh?

At this point, we are already able to use the result of a calculation as input
for another one but there is a lot of syntactic overhead. For a simple example
like _ABA_, we could write `Op<Op<A, B>::result, A>::result`. For _n_ operands,
we have to write `::result` _n-1_ times.

When we defined our base case in the previous example, we did not specify a
result type so using anything but `A` or `B` would fail. If instead we write

```cpp
template <typename LHS, typename RHS>
struct Op {
  using result = typename Op<typename LHS::result,
                             typename RHS::result>::result;
};
```

it allows for expressions where both sides are the results of operations like

```cpp
static_assert(std::is_same<Op<Op<A, B>, Op<B, A>>::result, A>::value,
              "(AB)(BA) = A");
```

A simple modification to our initial definition of our types `A` and `B` will
allow for more flexibility without having to specify all possible cases (`Op<A,
Op<…>>`, `Op<Op<…>, A>`, …) manually:

```cpp
struct A { using result = A; };
struct B { using result = B; };
```

Now we can even write

```cpp
using x = Op<Op<Op<Op<Op<A, B>, A>, A>, B>, A>::result;
static_assert(std::is_same<x, A>::value, "ABAABA = A");
```

which is a significant improvement over how we had to do it before. Now we only
have to write `::result` once independent of how many operations we perform.
However, we still have to write `Op<…>` _n-1_ times for n operations.


## Variadic templates

are awesome. They allow us to write functions and even types that take
arbitrary numbers of (type) parameters. As an example think about this
function:

```cpp
int sum(int x, int y) {
  return x + y;
}
```

we can improve it with templates to take an arbitrary input type that supports
addition:

```cpp
template <typename T>
T sum(T lhs, T rhs) {
  return lhs + rhs;
}
```

but for summation of more than two values we would have to write another
function or repeatedly apply `sum`. Writing a function for every possible case
(three parameters, four parameters, …) is not only tiresome and unmaintainable
it is also impossible as the number of parameters goes to infinity. Repeatedly
applying the function works better but who really wants to write
`sum(sum(sum(sum(sum(…)…)…)…)…)`?

With just four lines of code, we are able to solve that problem:

```cpp
template <typename T, typename... Ts>
T sum(T head, Ts... tail) {
  return head + sum(tail...);
}
```

The three dots (`...` not `…`) indicate the use of what is called a _parameter
pack_. Parameter packs are at the core of variadic templates. You can find an
excellent and comprehensive description on
[cppreference.com](http://en.cppreference.com/w/cpp/language/parameter_pack).

If you call `sum(1, 2, 3, 4)` somewhere in your code, your compiler should
theoretically generate `sum` functions taking four, three, and two parameters.
However, modern compilers are smart enough to not actually do this and optimise
most of it away. In fact, the generated assembly file (clang option `-S`) for
this program is only a few lines long and contains no function calls
whatsoever.

```cpp
#include "variadic.h"

int main() {
  return sum(1, 2, 3, 4);
}
```


## Back to our group

In order to apply what we've learned about variadic templates and parameter
packs to our original problem we just need to consider one difference between
functions and types: There is no type overloading in C++. In the `sum` example
it was okay to first define the base case (two parameters) and then specify the
more common case but when working with types we must define the most common
case first:

```cpp
template <typename...>
struct Op {};
```

Our initial definition then becomes a _specialisation_ of this template:

``cpp
template <typename LHS, typename... RHS>
struct Op<LHS, RHS...> {
  using result =
      typename Op<typename LHS::result,
                  typename Op<RHS...>::result>::result;
};
```

Notice how we use the same recursive structure as in the above example.
Functional programmers will recognise this pattern as a _fold_.

And indeed, this assertion holds, showing that our code works the way we want
it to

```cpp
static_assert(
  std::is_same<Op<A, A, A, B, A, B, B, A>::result, B>::value,
  "AAABABBA = B"
);
```

## Conclusion

Using a somewhat contrived example of an O(1) group, we have learned how to
implement compile-time calculations on arbitrary structures. We also had a look
at _parameter packs_ and _variadic templates_ that allow us to write very
generic and highly re-usable code.


## Questions, remarks, …

Do you have any questions? Is anything unclear? Did I get something wrong? Is
something horribly imprecise? Please let me know! [Go to the corresponding
issue on GitHub, in order to discuss this
article.](https://github.com/kdungs/dun.gs/issues/5)
