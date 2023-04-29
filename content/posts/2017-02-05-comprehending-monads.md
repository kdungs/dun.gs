+++
title = "Comprehending monads"
aliases = ["/posts/2017-02-05-comprehending-monads.html"]
+++

In this post, we explore the relationship between Monads and list comprehension and implement some ideas from Haskell in Python.

<!-- more -->

List comprehension is a very useful and commonly used feature in both Python and Haskell. Many people will be familiar with the following way to calculate the squares of a list of numbers in Python

```python
def squares(xs):
    return [x ** 2 for x in xs]
```

This is almost exactly the same in Haskell

```haskell
squares xs = [x ^ 2 | x <- xs]
```

But what is actually going on here? Although Python does not have static typing let's agree that the function `squares` takes a list of numbers as input and returns a list of numbers as well. In Haskell, we'd write this type signature as

```haskell
squares :: Num a => [a] -> [a]
```

But why are lists interesting? A list is a type that _wraps_ another type. We could say "list" is a context that we can put values in.[^python-lists] With this notion of "contexts", we can rephrase our understanding of list comprehension. When we write `x ** 2 for x in xs` what we are saying is: "`xs` is a context that contains `x`. Please take the value(s) out of their context and give us their square(s) in another list."

In Haskell, there is another way to express the above list comprehension using "do-notation".

```haskell
squares xs = do
    x <- xs
    return (x ^ 2)
```

This reads almost exactly like the above formulation of our intent. Do-notation is a very generic concept though. It is syntactic sugar for dealing with generic "contexts". In Haskell they are called "monads" and have a formal definition. Put simply, for a type to be a monad there must be a `return` function[^return-name] that puts a value in a context. For lists this is simply the list constructor.  In Python, we could write

```python
def list_return(x):
    return [x]
```

Additionally, there must be a function called `bind` (in Haskell this is written as the infix operator `>>=`) which takes a value in a context and a function from the type of that value to another type wrapped in the same context. Or formally

```haskell
bind :: Monad m => m a -> (a -> m b) -> m b
```

For lists in Python we could implement this as follows

```python
def list_bind(xs, f):
    ys = []
    for x in xs:
      ys += f(x)
    return ys
```

Note that this is subtly different from mapping `f` over `xs`. Now how does this relate to list comprehension and the do-notation? With those definitions of `list_return` and `list_bind`, we could rewrite our squares function like this

```python
def list_squares(xs):
    return lists_bind(xs, lambda x: list_return(x ** 2))
```

Or equivalently in Haskell

```haskell
squares' xs = xs >>= \x -> return (x ^ 2)
```

If we compare this to the version in do-notation, we can see how it's really just syntactic sugar.

```haskell
squares xs = do
  x <- xs
  return (x ^ 2)
```


## More monads

If all we ever dealt with was lists, this whole exercise would be pretty useless.[^useless] Luckily for us lists aren't the only monads in existence. Haskell has a type called `Maybe`. Instances of `Maybe` can be either `Just` a value or `Nothing`. The monad operations for `Maybe` are defined as follows

```haskell
return x = Just x

Nothing >>= f = Nothing
Just x >>= f = Just (f x)
```

Earlier, we discussed how do-notation was just syntactic sugar for using `return` and `bind` while for lists, list-comprehension was just syntactic sugar for do-notation. And in fact, in Haskell we can write the following (seemingly crazy) code once we activate the monad comprehensions language extension.

```haskell
{-# LANGUAGE MonadComprehensions #-}

squareMaybe mx = [x ^ 2 | x <- mx]
```

which if applied on `Just 5` gives `Just 25`. If it's applied on `Nothing`, the result is still `Nothing.`

As you might have noticed, our `squareMaybe` function is exactly the same as our initial `squares` function. With monad comprehensions activated, its type signature becomes

```haskell
squares :: (Num a, Monad m) => m a -> m a
```


### Python, maybe?

In Python, we could mimic this behaviour by treating `None` as nothing and a value as `Just` a value. 

```python
def maybe_return(x):
    return x

def maybe_bind(mx, f):
  if mx is None:
    return None
  return f(mx)
```

This is pretty useful if we have a bunch of computations that could potentially return `None` and we want to chain them together. While this implementation is certainly universal (it gives us the monad operations for `Maybe` without a corresponding type) it doesn't give us monad comprehension.

In order to get this behaviour in Python, we need to go a little bit crazy and (ab)use iterators. What we will do is create dedicated types for `Nothing` and `Just` and make them iterable so we can use them in generator expressions. Finally we will introduce a convenience method to get around the limitation of Python's `[]` being closely associated with lists and nothing else.

First, let's start with `Nothing`.

```python
class Nothing(object):
    def __repr__(self):
        return "Nothing"

    def __iter__(self):
        return self

    def next(self):
        raise StopIteration()
```

By defining the `__iter__` method, we make instances of `Nothing` iterable but every iteration will immediately stop because of `next` raising the `StopIteration` exception when it's called.

Similarly, we can define `Just` as follows.

```python
class Just(object):
    def __init__(self, x):
        self.x = x

    def __repr__(self):
        return "Just {}".format(x)

    def __iter__(self):
        def iter_impl():
            yield self.x
        return iter(iter_impl())
```

Using this, we can implement `return` and `bind`.[^nicer-bind]

```python
def maybe_return(x):
    return Just(x)

def maybe_bind(mx, f):
    if type(mx) is Nothing:
        return mx
    return f(mx.x)
```

And we're almost done. In order to get comprehension for our `Maybe`, we need one extra step. Right now, we could write something like

```python
[x ** 2 for x in Just(5)]
```

and it would work. However, the result would not be `Just 25` but rather `[25]` which is not what we want. We would have replaced our maybe by a list. We get around this by introducing a convenience function

```python
def maybe_comprehend(gen):
    try:
        return Just(next(gen))
    except StopIteration:
        return Nothing()
```

which allows us to write

```python
maybe_comprehend(x ** 2 for x in Just(5))
```

and get the expected result `Just 25`. Pretty neat, isn't it?


## Feedback, questions, comments?

If you want to point out errors in the above text, have inquiries, or simply want to tell me how reading it was a complete waste of your time, feel free to [go to the corresponding issue on GitHub, in order to discuss this article.](https://github.com/kdungs/dun.gs/issues/8)


[^python-lists]: In Python, the types of a list's elements can be heterogeneous which brings with it a bunch of problems that we simply choose to ignore at this point.

[^return-name]: Not to be confused with `return` in Python. Luckily, in the future, this will be renamed to `pure`. The technical details can be found on the [corresponding mailing list](https://mail.haskell.org/pipermail/libraries/2015-September/026121.html)

[^useless]: You might argue that it is useless anyway…

[^nicer-bind]: To make things a bit nicer (and not use `type`), we could of course define a `bind` member function in `Nothing` and `Just` and call that one from `maybe_bind`.
