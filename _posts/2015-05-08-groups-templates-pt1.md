---
layout: post
title: Simple Group Structures via Templates in C++ – Part I
date: 2015-05-08 13:37
---

If you enjoyed my previous post on [Simple Higher Order Functions in C++](/2015/04/17/simple-higher-order-functions.html) you already got a taste of templates in C++. In this post we have a look at how we can implement compile-time _groups_ in C++11. If you are unfamiliar with the concept of groups, you can read about them on [Wikipedia](https://en.wikipedia.org/wiki/Group_%28mathematics%29) or [Wolfram MathWold](http://mathworld.wolfram.com/Group.html).

For this example we look at O(1), a rather simple group structure. A possible incarnation of O(1) is ({1, -1}, ×). Here we call our elements _A_ and _B_ and for simplicity we omit the group operation sign. We want _AA=A_, _BB=A_, _AB=B_, and _BA=B_. _A_ is the _identity_ of the group. This group is also _cyclic_ with order 1 and _B_ being the _generator_.

First we create two types representing _A_ and _B_:

```cpp
struct A {};
struct B {};
```

Next we need a type representing the binary group operation. That type should have two template parameters representing the left- and the right-hand side of the operator. We also need a type definition (here an alias) inside the type to specify the result of the operation.

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

We can verify that this does indeed work using static assertions. Assuming we have put our definitions from above in a file called `group.h`, the following program is sufficient to check that what we did is correct:

```cpp
#include "group.h"

#include <type_traits>

static_assert(std::is_same<Op<A, A>::result, A>::value, "A × A = A");
static_assert(std::is_same<Op<A, B>::result, B>::value, "A × B = B");
static_assert(std::is_same<Op<B, A>::result, B>::value, "B × A = B");
static_assert(std::is_same<Op<B, B>::result, A>::value, "B × B = A");
```
save it as `test_group.cc` and compile it with `c++ -O3 -std=c++11 -o test_group.o test_group.cc`. The fact that is compiles implies correctness. Pretty cool, huh?

## Code
The code for this series of posts can be found on [GitHub](https://github.com/kdungs/cpp-group-study).

## What's next?
The next part in this series will cover chaining operations which will let us easily express something like _x=ABAABA_. Right now, we would have to write

```cpp
using x = Op<A,
             Op<B,
                Op<A,
                   Op<A,
                      Op<B,A>::result
                   >::result
                >::result
              >::result
            >::result;
```
but maybe there is a way to make this a bit more expressive…

 * [Part 2](/2015/05/10/groups-templates-pt2.html)
 * [Part 3](/2015/05/12/groups-templates-pt3.html)
