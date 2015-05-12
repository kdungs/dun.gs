---
layout: post
title: Simple Group Structures via Templates in C++ – Part II
date: 2015-05-10 15:51
---

This is the second part of a series of posts on implementing a simple group structure in C++11 using template meta programming. If you have missed [the first part](/2015/05/08/groups-templates-pt1.html), make sure to check it out.

The last time we saw how we can implement a simple O(1) group structure using templates in C++11. We were already able to use the result of a calculation as input for another one but there was a lot of syntactic overhead. For a simple example like _ABA_, we could write `Op<Op<A, B>::result, A>::result`. For _n_ operands, we have to write `::result` _n-1_ times.

When we defined our base case in the previous example, we did not specify a result type so using anything but `A` or `B` would fail. If instead we write

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

A simple modification to our initial definition of our types `A` and `B` will allow for more flexibility without having to specify all possible cases (`Op<A, Op<…>>`, `Op<Op<…>, A>`, …) manually:

```cpp
struct A { using result = A; };
struct B { using result = B; };
```

Now we can even write

```cpp
using x = Op<Op<Op<Op<Op<A, B>, A>, A>, B>, A>::result;
static_assert(std::is_same<x, A>::value, "ABAABA = A");
```
which is a significant improvement over how we had to do it in the last post. Now we only have to write `::result` once independent of how many operations we perform. However, we still have to write `Op<…>` _n-1_ times for _n_ operations.


## Code
The code for this series of posts can be found on [GitHub](https://github.com/kdungs/cpp-group-study).


## What's next?
Next time we make the final improvements allowing us to write something like `Op<A, B, A, A, B, A>`. This will involve _variadic templates_ so don't miss it.


 * [Part 1](/2015/05/08/groups-templates-pt1.html)
 * [Part 2](/2015/05/12/groups-templates-pt3.html)
