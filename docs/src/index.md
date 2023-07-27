# TinyEKFGen.jl

A Julia C code generator for use with [TinyEKF](https://github.com/simondlevy/TinyEKF).

```@contents
```

## Key Management Functions

```@docs
Tiny.getAPIkey()
```

```@docs
ReplGPT.setAPIkey(key::String)

ReplGPT.clearAPIkey()
```

## Conversation Management

```@docs
ReplGPT.initialize_conversation()

ReplGPT.save_conversation(filepath)
```

## Output Formatting

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
TinyEKFGen.outputHeader(filename, state, px, F, hx, H, constants=Dict(), post=Dict())
```


## Index

```@index
```
