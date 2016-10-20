---
title: Simple higher order functions in C++
author: Kevin
---

Here is a question from a friend of mine that I will try to answer in this post: 

> I have the problem that I want to pass a function to a function. Until now, I have used `std::function` but I know there is also the possibility of function pointers and also you said something about templates and who knows what else. The question is of course: What's the difference and what is best?

In technical terms the question is: "How do **higher-order functions** work in C++ and which way to implement them is recommended?". I will examine the problem in two steps and then discuss the alternatives.

## Functions in C++
What exactly is a "function" in C++? For the purpose of this exercise let's limit ourselves to _mathematical_ functions that return a value from a number of parameters without side-effects (a.k.a. _pure_ functions).

Assuming a function `add` that takes two `int`s as input and returns an `int` representing their sum we want to be able to write

```cpp
int z = add(x, add(1, y));
```
and similar stuff. There are multiple ways to define `add` such that it fulfils our demand.


### Standard Function Definitions
The usual approach to defining a function C++ is of course the well-known

```cpp
int add(int x, int y) {
  return x + y;
}
```

which already existed in C, is simple, and gets the job done.


### Function Objects
Another way to define `add` such that it can be used in the above example would be by defining a class with a `()` operator. An instance of such a class will be _callable_. Some people refer to those classes (or objects instantiated from them) as "functors", but they are wrong ;).

```cpp
class Adder {
 public:  
  int operator()(int x, int y) const {
    return x + y;
  }
};
```

And then later in our code before we want to use `add` we would have to instantiate an object of this class e.g. via

```cpp
Adder add;
````

Object-oriented people will rejoice on seeing this because they immediately realise that one could define a base class `ArithmeticOperation` with a `virtual` `operator()` and let `Adder` inherit from it. The result would be polymorphism through virtual function calls. One could then define a higher-order function that takes two values and an `ArithmeticOperation` and produces its result like so

```cpp
int resultOfCalculation(const ArithmeticOperation& op,
                        int x, int y) {
  return op(x, y);
}
```

and voila there is already a solution for the initial problem. The fact that this approach smells a lot like Java might be a hint that it is probably not the optimal solution. If you need more convincing: Virtual function calls prevent inlining and will make your code less efficient. Also you'd limit the set of possible functions `resultOfCalculation` can be called on. It will only work on function objects (no normal functions, no lambdas) that inherit from `ArithmeticOperation`. A more extensible approach can be found further down.


### Lambdas
Introduced in C++11, lambdas are in many cases just syntactic sugar for function objects. Their clear advantage is that they can easily be defined _anonymously_ which makes them the perfect candidates to be used with STL algorithms.

```cpp
auto add = [](int x, int y) { return x + y; };
```
will define `add` the way we want it. Please note that without `auto` we would have practically no chance to tell the type of the function literal `[](int x, int y) { return x + y; }`. We could write 

```cpp
std::function<int(int, int)> add = [](int x, int y) {
  return x + y;
};
```
but that doesn't mean that the type of the expression is actually `std::function<int(int, int)>`. What happens is that an object of that type will be created from the object that is created from the expression. Savvy?



## Passing Functions
Back to the original problem of how to pass a function as a parameter to another (higher-order) function.

We want to be able to write

```cpp
int res = resultOfCalculation(add, x, y);
```

and expect the result to be the same as just calling `add(x, y)`. (Ideally we would also want the machine code to do exactly that but let's take one step at a time...)

Assuming we have a function `mult` that has the same type signature as `add` (i.e. `int(int, int)`) but returns the product of its two parameters, we want to be able to interchange `add` and `mult` when calling `resultOfCalculation`.

```cpp
int sum = resultOfCalculation(add, x, y);
int prod = resultOfCalculation(mult, x, y);
```

How should we define `resultOfCalculation`?


### Function Pointers
In the world of C without the ++, this would be the go-to solution.

```cpp
int resultOfCalculation(int (*op)(int, int),
                           int x, int y) {
  return (*op)(x, y);
}
```
It works fine for regularly defined functions. On my machine with `clang`, it works as well for lambdas but that doesn't mean you can expect it to work all the time. Especially if your lambdas are not pure. Neither does it work easily with callable objects.


### std::function
Defined in the `functional` header and available since C++11, `std::function<>` is basically a templated callable class that wraps around anything that can behave like a function.

```cpp
int resultOfCalculation(const std::function<int(int, int)>& op,
                        int x, int y) {
  return op(x, y);
}
```
Usually it will get the job done for you but might not be the most efficient way as hidden copies can occur and a `std::function` will be constructed.


### Template Type Deduction
TTD is a mechanism in C++ that – similarly to `auto` – allows for types to be deduced at compile time. This enables us to write

```cpp
template <typename FN>
int resultOfCalculation(const FN& op, int x, int y) {
  return op(x, y);
}
```
which also works across the board. The compiler will create one instance of this function for every function it is used with. However in this case all of them will be fully inlined resulting in the best performance since neither do we have to dereference pointers nor construct temporary objects.

This technique relies on duck typing; meaning that the way `op` is used limits the type it can have. E.g. when we try to pass something that is not callable, we will get a _compiler error_. A downside is that all possible values of `op` have to be known at compile time. _Concepts_ in C++17 will help strictly specifying requirements as well as giving more helpful error messages. In this example we could just as well pass in a function that returns something that can be casted into an `int` and nobody would ever notice.


#### Advanced TTD
Another way of implementing `resultOfCalculation` with template magic is the following (thanks to Manuel Schiller for reminding me)

```cpp
template <typename FN, typename T1, typename T2>
auto resultOfCalculation(
  const FN& op,
  const T1& x,
  const T2& y
) -> decltype(op(x, y)) {
  return op(x, y);  
}
```
which is more general than the above as it will work with any function `op` that can be called with two parameters of arbitrary types `T1` and `T2`. It also generalises the resulting return type as the return type of `op` when called with `x` and `y`. One could even make it more general to accept any number of arguments using _variadic templates_ but that would go beyond the scope of this post. In case you are not a fan of `decltype`, `std::result_of` is your friend here.


## Conclusion
If efficiency is your concern and you don't have new functions appear after compilation, go with function templates. This is also the way STL algorithms take function parameters. `std::function` can help make your code more readable and especially make the requirements more clear.



## Code
A working example of everything discussed in this post can be found in [this gist](https://gist.github.com/kdungs/30787bb2f6e65a1bf0ef).



## Questions and Comments
Did I get anything wrong? Do you find parts too superficial? Do you have a question? Just send an email to kevin at this domain.
