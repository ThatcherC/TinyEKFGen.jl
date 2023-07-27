# TinyEKFGen.jl

Generate C EKF programs from Julia expressions!

Check out the (early) [documentation here](https://thatcherc.github.io/TinyEKFGen.jl/).

### TODO:
- [x] Docs!
- [x] Formatting!
- [ ] Expression output tests
- [ ] Integration tests (Julia -> C -> `.obj` -> `@ccall` -> Julia)
- [ ] Export TinyEKFGen.Term = SymEngine.Basic
- [ ] Rewrite tests to get rid of SymEngine.Basic
- [ ] Switch to symbolics and export TinyEKFGen.Term = Symbolics.Num
