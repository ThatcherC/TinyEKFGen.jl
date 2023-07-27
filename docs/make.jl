using Documenter
using SymEngine
using TinyEKFGen

makedocs(sitename="TinyEKFGen", format=Documenter.HTML(), modules=[TinyEKFGen])

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(repo="github.com/ThatcherC/TinyEKFGen.jl.git")
