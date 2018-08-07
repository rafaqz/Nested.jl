# Nested

[![Build Status](https://travis-ci.org/rafaqz/Nested.jl.svg?branch=master)](https://travis-ci.org/rafaqz/Nested.jl)
[![Coverage Status](https://coveralls.io/repos/rafaqz/Nested.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/rafaqz/Nested.jl?branch=master)
[![codecov.io](http://codecov.io/github/rafaqz/Nested.jl/coverage.svg?branch=master)](http://codecov.io/github/rafaqz/Nested.jl?branch=master)

Nested provides an abstraction for developing `@generated` type-stable functions
that manipulate nested data. It is aimed at package developers and provides no
user facing functionality.


See [Flatten.jl](https://github.com/rafaqz/Flatten.jl) for an implementation.

Concept:
- Functions produced should be type stable and very fast
- nested checks if a field is to be included _after_ the generated function runs,
  so you can override methods. But still at compile time, so it has no runtime cost. 
- `nested()` runs in `Down` or `Up` mode - flattening things or constructing things
- Tuples and Structs are splatted, or constructed
- Voids are removed, or reinserted 
- Units are stripped, or reapplied
- Numbers and Any are processes with the passed in `val` function
- Nested does not currently deconstruct arrays, as these are more difficult to
  handle at compile time.
- Other types are yet to be decided. 

You can't write your own methods, this is all hyperpure for `@generated`.
