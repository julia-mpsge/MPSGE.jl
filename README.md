# MPSGE

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://julia-mpsge.github.io/MPSGE.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://julia-mpsge.github.io/MPSGE.jl/dev/)
[![Build Status](https://github.com/julia-mpsge/MPSGE.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/julia-mpsge/MPSGE.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/julia-mpsge/MPSGE.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/julia-mpsge/MPSGE.jl)


We are working on the 1.0.0 release, with more organised documentation. In the meantime, the current main branch is working, there is hopefully enough documentation to be functional, and we invite and encourage users, testing, and questions etc. 
The latest tagged version should be good and working.
```julia
  import Pkg
  Pkg.add("MPSGE")
```
Or, in the package manager
```juila
pkg> add MPSGE
```


## License

The underlying solver, [PATH](https://pages.cs.wisc.edu/~ferris/path.html), is closed source and requires a license. 

Without a license, the PATH Solver can solve problems with up to 300 variables and 2000 nonzeros. For larger problems, [this web page](https://pages.cs.wisc.edu/~ferris/path/julia/LICENSE) provides a temporary license that is valid until the end of 2035. 

You can either store the license in the `PATH_LICENSE_STRING` environment variable, or you can use the `PATHSolver.c_api_License_SetString` function immediately after including the `MPSGE` package:

```julia
using MPSGE
MPSGE.PATHSolver.c_api_License_SetString("your license string here")
```

where `your license string here` is replaced with the actual license string.

