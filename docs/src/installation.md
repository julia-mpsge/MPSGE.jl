# Installation Guide

This guide explains how to install Julia and MPSGE.If you have installation
troubles, read the [Common installation issues](@ref) section below.


## Install Julia

JuMP is a package for [Julia](https://julialang.org). To use JuMP, first
[download and install](https://julialang.org/downloads/) Julia.

!!! tip
    If you are new to Julia, read our LINK
    tutorial.



## Install MPSGE

From Julia, MPSGE is installed using the built-in package manager:
```julia
import Pkg
Pkg.add("MPSGE")
```

!!! tip
    We recommend you create a Pkg _environment_ for each project you use MPSGE
    for, instead of adding lots of packages to the global environment. The
    [Pkg manager documentation](https://julialang.github.io/Pkg.jl/v1/environments/)
    has more information on this topic.

When we release a new version of MPSGE, you can update with:
```julia
import Pkg
Pkg.update("MPSGE")
```



## Common installation issues

!!! tip
    When in doubt, run `import Pkg; Pkg.update()` to see if updating your
    packages fixes the issue. Remember you will need to exit Julia and start a
    new session for the changes to take effect.


### Check the version of your packages

Each package is versioned with a [three-part number](https://semver.org) of the
form `vX.Y.Z`. You can check which versions you have installed with
`import Pkg; Pkg.status()`.

This should almost always be the most-recent release. You can check the releases
of a package by going to the relevant GitHub page, and navigating to the
"releases" page. For example, the list of MPSGE releases is available at:
LINK HERE.


### Unsatisfiable requirements detected

Did you get an error like `Unsatisfiable requirements detected for package MPSGE`?
The Pkg documentation has a [section on how to understand and manage these conflicts](https://julialang.github.io/Pkg.jl/v1/managing-packages/#conflicts).