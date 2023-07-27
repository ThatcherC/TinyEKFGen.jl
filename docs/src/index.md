# TinyEKFGen.jl

A Julia C code generator for use with [TinyEKF](https://github.com/simondlevy/TinyEKF).

## Index

```@index
```

```@docs
TinyEKFGen.diffvwrtv(e::Array{SymEngine.Basic,1}, v::Array{SymEngine.Basic,1})

TinyEKFGen.outputHeader(
    filename,
    state::Vector{SymEngine.Basic},
    px::Vector{SymEngine.Basic},
    hx::Vector{SymEngine.Basic},
    constants=Dict(),
    post=Dict()
)
```


