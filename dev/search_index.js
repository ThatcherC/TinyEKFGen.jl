var documenterSearchIndex = {"docs":
[{"location":"#TinyEKFGen.jl","page":"TinyEKFGen.jl","title":"TinyEKFGen.jl","text":"","category":"section"},{"location":"","page":"TinyEKFGen.jl","title":"TinyEKFGen.jl","text":"A Julia C code generator for use with TinyEKF.","category":"page"},{"location":"#Index","page":"TinyEKFGen.jl","title":"Index","text":"","category":"section"},{"location":"","page":"TinyEKFGen.jl","title":"TinyEKFGen.jl","text":"","category":"page"},{"location":"","page":"TinyEKFGen.jl","title":"TinyEKFGen.jl","text":"TinyEKFGen.diffvwrtv(e::Array{SymEngine.Basic,1}, v::Array{SymEngine.Basic,1})\n\nTinyEKFGen.outputHeader(\n    filename,\n    state::Vector{SymEngine.Basic},\n    px::Vector{SymEngine.Basic},\n    hx::Vector{SymEngine.Basic},\n    constants=Dict(),\n    post=Dict()\n)","category":"page"},{"location":"#TinyEKFGen.diffvwrtv-Tuple{Vector{Basic}, Vector{Basic}}","page":"TinyEKFGen.jl","title":"TinyEKFGen.diffvwrtv","text":"function diffvwrtv(e::Array{Basic,1}, v::Array{Basic,1})\n\nCompute Jacobian of a vector of expressions e with respect to another vector of expressions v.\n\n\n\n\n\n","category":"method"},{"location":"#TinyEKFGen.outputHeader","page":"TinyEKFGen.jl","title":"TinyEKFGen.outputHeader","text":"function outputHeader(filename, state, px, hx, constants=Dict(),post=Dict())\nfunction outputHeader(filename, state, px, F, hx, H,constants=Dict(),post=Dict())\n\nfilename: output C header file name\nstate: Kalman filter state\npx:    Predicted new state f(state=x)\nF:     df/dx, state update matrix\nhx:    Predicted measurements from current state, h(state=x)\nH:     dh/dx, observation derivative matrix\nconstants: Map from symbol name to value for symbols to be treated as constants\npost:  map of matrix name to matrix to be printed at the end of the output code\n\n\n\n\n\n","category":"function"}]
}