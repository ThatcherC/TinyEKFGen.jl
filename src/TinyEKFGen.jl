module TinyEKFGen

import SymEngine
import Printf
import Espresso

# inspired by https://github.com/symengine/SymEngine.jl/issues/194
# adapted with https://github.com/dfdx/Espresso.jl
#          and https://github.com/JuliaLang/julia/pull/5713
function rewriteExponents(f::SymEngine.Basic)
    pat = :(_x^2)
    rpat = :(_x * _x)
    noexp = Espresso.rewrite_all(convert(Expr, f), pat, rpat)

    noTimesMinusOne = Espresso.rewrite_all(convert(Expr, noexp), :(-1 * _x), :(-_x))

    noTimesOne = Espresso.rewrite_all(convert(Expr, noTimesMinusOne), :(_x * 1), :(_x))

    noPowMinus1 = if isa(noTimesOne, Expr)
        Espresso.rewrite_all(convert(Expr, noTimesOne), :(_b^_n), :(pow(_b, _n)))
    else
        noTimesOne
    end

    # TODO symplify rationals like 1//2

    noPowMinus1
end

function symbolicStringNoExponents(f::SymEngine.Basic)
    string(rewriteExponents(f))
end

# ╔═╡ 1494ecfc-0d87-11eb-069e-f1a7b48fa83a
function cprintmat(out, M, name)
    rows, cols = size(M)

    for r in 1:rows
        for c in 1:cols
            equation = symbolicStringNoExponents(M[r, c])
            if equation != "0"
                println(out, "\t$name[$(r-1)][$(c-1)] = $equation;")
            end
        end
    end
end

"""
	function diffvwrtv(e::Array{Basic,1}, v::Array{Basic,1})

Compute Jacobian of a vector of expresses `e` with respect to another vector of expressions `v`.
"""
function diffvwrtv(e::Array{SymEngine.Basic,1}, v::Array{SymEngine.Basic,1})
    a = transpose(SymEngine.diff.(e, v[1]))
    for i in 2:length(v)
        a = vcat(a, transpose(SymEngine.diff.(e, v[i])))
    end
    transpose(a)
end

"""The terms we need to fill in for the EKF at each step are
- The predicted next state `px`
- The state transition model linearization `F`
- The predicted observations `hx`
- The observation model linearization `H`

We might also opt to include an update to the noise model, as I have done in
the LAD EKF

I also want a way to keep track of variables/symbols that are not part of the
state, as those will need to be passed into the EKF update function.
These would include modelled observations that code from an external model
(such as the local \$ \vec B \$ field direction based on current location) or
changes to the dynamics model, such commanded torques or changes in moment of
inertia or internal angular momentum"""

# ╔═╡ 4fcd6fcc-0d84-11eb-1a5b-a30b0493c44e
"""# C Code Generation
The steps needed to generate the `model` function are:
- ✅ Get required `#define`s for `Nsta` (number of variables in the state vector) and `Mobs` (number of observations)
- ✅ Do defines for constant values (like MOIs \$I_n\$)
- ✅ Generate the function signature for `model` - shoud look something like this:
  ```
  void model(double px[Nsta], double F[Nsta][Nsta], double hx[Mobs],
             double H[Mobs][Nsta], double modeledB[3], double dt){
  ```
  - `px`, `F`, `hx`, and `H` definitions will all stay the same (assuming we want doubles), but the external arguments like `modeledB...` and `dt` will need to be added in to the signature
  - However, we don't need to add in constants like `I_1` (or maybe even `dt`, perhaps)
- ✅ Match equation symbols (`q01`, `bbx`, etc.) to elements in the ekf struct's state variable `x` (`ekf.x[1]`). This will have a line for each symbol in the state \$ x \$ that looks like this:

  `double q0 = ekf.x[0];`


- ✅ Calculate predicted new state. This will have one line per state variable, like `px[0] = q0 + 0.5*dt*(q1*wx + q2*wy + q3*wz);`

    - ⬜ In some cases, some post-processing on the state might be required. In the case of my EKF, I need to normalize the 4 elements of the attitude quaternion. **TODO:** how to implement predicted state post-processing?
- ✅ Fill in the `F` matrix. This will have one line per non-zero element of\$ F\$, like `F[0][2] = 0.5*wy*dt;`
    - ⬜ Optional pre-processing step: set all matrix elements to zero. I don't think this is strictly necessary, but it protects against other parts of the code setting an element of `F` that we expect to be zero to some other value.
    - ⬜ Currently, I set all all non-zero element of `F` on each step. There are few constant elements though (always set to 1 in my case) that could be skipped after initialization **iff** the matrix isn't zeroed out at the start
- ✅ Fill in `hx` with predicted observations. One line per observation (ie `hx[3] = wx;`)
- ✅ Fill in the `H` matrix. This will have one line per non-zero element of\$ H\$
- ✅ Fill in any changes to `ekf.Q` if needed
- ✅ Rewrite any exponents of the form `x ^ 2` to `x * x`

- ⬜ Create `setupEKF` function:
  ```
  void setupEKF(ekf_t * ekf_p){
  ekf_init(ekf_p, Nsta, Mobs);
  ```
- ⬜ Setup initial state `ekf_p->x[]` and fill in `ekf_p->Q[][]` and `ekf_p->R[][]`

**Meta-Todos**
- Make the C type chooseable? Are doubles the way to go?
- Do I really want that `ekf.Q` re-write at the end of the generated block, or is that best left for use in higher-level, not-generated code?

"""

# ╔═╡ 2e8c54f6-0d8c-11eb-177b-d339433399ef
"""
	function outputHeader(filename, state, px, hx, constants=Dict(),post=Dict())
	function outputHeader(filename, state, px, F, hx, H,constants=Dict(),post=Dict())
```
filename: output C header file name
state: Kalman filter state
px:    Predicted new state f(state=x)
F:     df/dx, state update matrix
hx:    Predicted measurements from current state, h(state=x)
H:     dh/dx, observation derivative matrix
constants: Map from symbol name to value for symbols to be treated as constants
post:  map of matrix name to matrix to be printed at the end of the output code
```
"""
function outputHeader(
    filename,
    state::Vector{SymEngine.Basic},
    px::Vector{SymEngine.Basic},
    hx::Vector{SymEngine.Basic},
    constants=Dict(),
    post=Dict(),
)
    F = diffvwrtv(px, state)
    H = diffvwrtv(hx, state)
    outputHeader(filename, state, px, F, hx, H, constants, post)
end
function outputHeader(filename, state, px, F, hx, H, constants=Dict(), post=Dict())
    usedSymbols = union(SymEngine.free_symbols.([state, px, F, hx, H])...)
    externalTerms = setdiff(usedSymbols, state)  # get all the symbols that aren't part

    modelInputs = setdiff(externalTerms, keys(constants))

    out = open(filename, "w")
    println(out, "#define Nsta $(size(state)[1])")
    println(out, "#define Mobs $(size(hx)[1])\n")
    println(out, "#include \"tiny_ekf_struct.h\"")
    println(out, "#include \"tiny_ekf.h\"\n")

    #create function signature
    println(
        out,
        "void model(double x[Nsta], double px[Nsta], double F[Nsta][Nsta], double hx[Mobs], double H[Mobs][Nsta],",
    )
    print(out, "           ")

    sortedInputKeys = sort(modelInputs, by=k -> SymEngine.toString(k))
    inputArguments = join(map(s -> "double $s", sortedInputKeys), ", ")
    print(out, inputArguments)
    println(out, "){\n")

    #print out constant definition
    sortedConstantKeys = sort(collect(keys(constants)), by=k -> SymEngine.toString(k))
    for k in sortedConstantKeys
        println(out, "\tdouble $(SymEngine.toString(k)) = $(constants[k]);")
    end
    println(out)

    #unpack ekf.x array into named variables
    for n in 1:length(state)
        symbolname = SymEngine.toString(state[n])
        println(out, "\tdouble $symbolname = x[$(n-1)];")
    end
    println(out, "")

    # fill in predicted state px
    for n in 1:length(px)
        equation = symbolicStringNoExponents(px[n])
        println(out, "\tpx[$(n-1)] = $equation;")
    end
    println(out, "")

    # fill in predicted state px
    for r in 1:size(F)[1]
        for c in 1:size(F)[2]
            equation = symbolicStringNoExponents(F[r, c])
            if equation != "0"
                println(out, "\tF[$(r-1)][$(c-1)] = $equation;")
            end
        end
    end
    println(out, "")

    # fill in modeled observations hx
    for n in 1:length(hx)
        equation = symbolicStringNoExponents(hx[n])
        println(out, "\thx[$(n-1)] = $equation;")
    end
    println(out, "")

    # fill in predicted state px
    for r in 1:size(H)[1]
        for c in 1:size(H)[2]
            equation = symbolicStringNoExponents(H[r, c])
            if equation != "0"
                println(out, "\tH[$(r-1)][$(c-1)] = $equation;")
            end
        end
    end

    for name in keys(post)
        println(out, "")
        cprintmat(out, post[name], name)
    end

    println(out, "}")
    close(out)
end

export diffvwrtv

end # module
