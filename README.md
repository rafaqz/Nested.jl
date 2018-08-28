# Nested

[![Build Status](https://travis-ci.org/rafaqz/Nested.jl.svg?branch=master)](https://travis-ci.org/rafaqz/Nested.jl)
[![Coverage Status](https://coveralls.io/repos/rafaqz/Nested.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/rafaqz/Nested.jl?branch=master)
[![codecov.io](http://codecov.io/github/rafaqz/Nested.jl/coverage.svg?branch=master)](http://codecov.io/github/rafaqz/Nested.jl?branch=master)

Nested provides an abstraction for developing recursive `@generated` functions
that manipulate nested data. Its a tiny package but a surprisingly powerful formula.


See [Flatten.jl](https://github.com/rafaqz/Flatten.jl) or [PlotNested.jl](https://github.com/rafaqz/PlotNested.jl) for an implementation.

Process:
- Provide an expression that calls your generated function.
- Provide methods for particular types you need to handle. These are outside the @generated function and can be extended by users.
- Wrap all method results in a tuple. This allows empty results to be splatted
  away, and returns single fields in the same format as structs and tuples.
- Provide an @generated function that calls nested.

Functions produced should be type stable and _very_ fast. 
If you need more to happen to fields than being wrapped in a tuple, write your own handler, again there are examples in Flatten.jl

A simple example that flattens nested structures to tuples:

```julia
using Nested

flatten_expr(T, path, x) = :(flatten(getfield($path, $(QuoteNode(x))))
flatten_inner(T) = nested(T, :t, flatten_expr) # Separated for inspectng code generation
flatten(x::Number) = (x,)
@generated flatten(t) = flatten_inner(t)
```

Test it out:

```julia
struct Foo{T}
    a::T
    b::T
    c::T
end

struct NestedFoo{T1, T2}
    nf::Foo{T1}
    nb::T2
    nc::T2
end

julia> nestedfoo = NestedFoo(Foo(1,2,3),4,5)
NestedFoo{Int64,Int64}(Foo{Int64}(1, 2, 3), 4, 5)

julia> flatten(nestedfoo)
(1, 2, 3, 4, 5)
```

Check how it works:

```julia
julia> flatten_inner(typeof(nestedfoo))
:((flatten(getfield(t, :nf))..., flatten(getfield(t, :nb))..., flatten(getfield(t, :nc))...))
```

Performance:

```julia
julia> using BenchmarkTools
julia> @btime flatten($nestedfoo)
  1.074 ns (0 allocations: 0 bytes)
(1, 2, 3, 4, 5)

julia> @code_native flatten(nestedfoo)
        .text
Filename: REPL[7]
        pushq   %rbp
        movq    %rsp, %rbp
Source line: 1
        movups  (%rsi), %xmm0
        movups  16(%rsi), %xmm1
        movq    32(%rsi), %rax
        movups  %xmm0, (%rdi)
        movups  %xmm1, 16(%rdi)
        movq    %rax, 32(%rdi)
        movq    %rdi, %rax
        popq    %rbp
        retq
        nop
```
