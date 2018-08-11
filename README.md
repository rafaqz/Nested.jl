# Nested

[![Build Status](https://travis-ci.org/rafaqz/Nested.jl.svg?branch=master)](https://travis-ci.org/rafaqz/Nested.jl)
[![Coverage Status](https://coveralls.io/repos/rafaqz/Nested.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/rafaqz/Nested.jl?branch=master)
[![codecov.io](http://codecov.io/github/rafaqz/Nested.jl/coverage.svg?branch=master)](http://codecov.io/github/rafaqz/Nested.jl?branch=master)

Nested provides an abstraction for developing `@generated` type-stable functions
that manipulate nested data. It is aimed at package developers and provides no
user facing functionality.


See [Flatten.jl](https://github.com/rafaqz/Flatten.jl) for an implementation.

Prosses:
- Provide the inner expression that at some point calls your generated function
  again.
- Provide some methods for particular types that return a value. These can be
  overriden at any time as they are not actually inside a generated function.
- Wrap all method results in a tuple. This allows empty results to be splatted away,
  and conveniently returns single fields in the same format as structs and
  tuples.
- Provide an @generated function that calls nested.
- Choose a handler: up constructs things, down flattens things. You can also
  provide your own handler function if the default up/down functions arenet enough.

Done. Functions produced should be type stable and _very_ fast

A simple example that flattens nested structures to tuples:

```julia
flatten_expr(T, path, i::Int) = :(flatten($path[$i]))
flatten_expr(T, path, fname::Symbol) = :(flatten($path.$fname))

flatten_inner(T) = nested(T, :t, flatten_expr, down)

flatten(x::Any) = (x,) 
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
