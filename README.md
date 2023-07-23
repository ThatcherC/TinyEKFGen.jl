# TinyEKFGen.jl

Generate C EKF programs from Julia expressions!

### TODO:
- Docs!
- Formatting!
- Expression output tests
- Integration tests (Julia -> C -> `.obj` -> `@ccall` -> Julia)
- Export TinyEKFGen.Term = SymEngine.Basic
- Rewrite tests to get rid of SymEngine.Basic
- Switch to symbolics and export TinyEKFGen.Term = Symbolics.Num
