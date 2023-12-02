# TinyEKFGen.jl

Generate C EKF programs from Julia expressions!

Check out the (early) [documentation here](https://thatcherc.github.io/TinyEKFGen.jl/).

### JuliaCon 2023 Presentation

[![Generating Extended Kalman Filters with Julia | Thatcher Chamberlin | JuliaCon 2023](https://img.youtube.com/vi/d1yMEsVpotQ/0.jpg)](https://www.youtube.com/watch?v=d1yMEsVpotQ)

### TODO:
- [x] Docs!
- [x] Formatting!
- [ ] Expression output tests
- [ ] Integration tests (Julia -> C -> `.obj` -> `@ccall` -> Julia)
- [ ] Export TinyEKFGen.Term = SymEngine.Basic
- [ ] Rewrite tests to get rid of SymEngine.Basic
- [ ] Switch to symbolics and export TinyEKFGen.Term = Symbolics.Num
