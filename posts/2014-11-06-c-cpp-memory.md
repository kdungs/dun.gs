---
title: Memory management of C libraries in C++
date: 2014-11-06
description: Wrapping C-style new and free in C++ memory managing objects.
---

Today I had some time to play around with [libgit2](https://libgit2.github.com), an excellent C-library for [Git](http://git-scm.com/). But since I was thinking about using it together with the freshly released [Proxygen](https://github.com/facebook/proxygen), the fast HTTP-framework from Facebook, I wanted to use the library functions from C++ from the start.

This was a perfect opportunity to play around with C++ memory management objects in the context of a C-library.

## Academic Example
In C-libraries, one often finds the following pattern for construction and destruction of objects on the heap:

```C
    typedef struct { /*...*/ } object_t;
object_t *object_new();
void object_free(object_t *);
```

The important thing here is that `object_new()` returns an owning pointer and it is the user's responsibility to clean up after use. If the user forgets to call `object_free`, the memory is leaked.

With `std::unique_ptr` and `std::shared_ptr`, C++ offers smart containers for memory management which guarantee that the memory is freed after use. They also allow the user to specify a custom "deleter" which is particularly helpful when dealing with C-library functions.

```cpp
    using uniqueObjectPtr = std::unique_ptr<object_t,
                                        decltype(&object_free)>;
uniqueObjectPtr obj{object_new(), object_free};
```

A working example of this can be found in [<i class="fa fa-github"></i> kdungs/cpp-neat/ManageC](https://github.com/kdungs/cpp-neat/tree/master/ManageC).

## Real World Example: libgit2
Take for example the following snippet that makes use of libgit2 to load information about a local git repository

```C
    git_repository *repo = NULL;
git_repository_open(&repo, "./testrepo");
/* Do something with repo. */
git_repository_free(repo);
```

In a C++-context, we don't want to take care of manually freeing the memory. Instead, we put the resulting repo into a memory managing object, that knows which function to call in order to free the memory.

```cpp
    using uniqueRepositoryPtr = std::unique_ptr<
  git_repository, decltype(&git_repository_free)>;
git_repository *rawRepo = nullptr;
git_repository_open(&rawRepo, "./testrepo");
uniqueRepositoryPtr repo{std::move(rawRepo), git_repository_free};
```

I agree that it is a bit clumsy to first declare a raw pointer that is then moved into the memory managing object. The problem here is that libgit2 uses the return value of most of its functions for error codes and I don't see a way around that.


