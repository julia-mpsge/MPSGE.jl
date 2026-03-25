```@meta
CurrentModule = MPSGE
```


# [MPSGE](https://github.com/julia-mpsge/MPSGE.jl)

## What is MPSGE?
MPSGE is a high level language for creating computable general equilibrium (CGE) models. Originally implemented in FORTRAN and made available as a subsystem in [GAMS](https://www.gams.com/). The [MPSGE documentation](https://www.gams.com/latest/docs/UG_MPSGE_Intro.html) provided by GAMS is a useful reference, especially for background, theory, and some understanding of the included [features](https://www.gams.com/latest/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_KeywordsSyntax).



## Resources for getting started


[JuMP](https://jump.dev/JuMP.jl/stable/)

[PATH Solver](https://pages.cs.wisc.edu/~ferris/path.html) \
For models with more than 300 variables or 2000 nonzeros, a PATH license needs to be set up on the system/computer. Otherwise the solve will throw an error: 
- Solver Status: OTHER_ERROR
- Model Status: UNKNOWN_RESULT_STATUS.

The link above has instructions for installing a free license for academic use. 
## How the documentation is structured

!!! note
    This documentation is under active development. 

- **Tutorials**: Written for new users of MPSGE. Walks through the MPSGE modelling process step-by-step. 
- **Mathematical Background**: MPSGE hides most of it's computation, this page describes precisely how MPSGE works.
- **API Reference**: A complete list of the functions MPSGE makes available. This is the same information you get in the help entry for individual functions.

## Citing MPSGE
A paper is being prepared. In the meantime reach out to the authors of the package for information.


## License