# MPSGE.jl vs MPSGE/GAMS

This repository contains two examples, one small and one large, written in both MPSGE.jl and MPSGE/GAMS. The purpose is to compare the syntax differences between the two implementations and to demonstrate how to use MPSGE.jl for experienced users of MPSGE/GAMS.

## Running the Examples

The two Julia files to run are `small_model.jl` and `large_model.jl`. Running either of these files will activate the Julia environment and install the necessary dependencies. 

## File Structure

The two models are located in the directories `small` and `large`. Each Julia model is wrapped in a `Module` this is done for organization and to avoid name clashes between the two models. Within each module are the functions that define the model. We recommend using the help mode in the REPL to see the documentation for each function, which includes the syntax and a description of what the function does.

To use the help menu, simply type `?` followed by the function name in the REPL. For example, to see the documentation for the `small_model` function, you would type `?small_model`. Note this will only work if you have run the `small_model.jl` file and activated the module.


## Small Model

Two goods, two factors, one consumer compares a tax and a (iceberg) transactions cost; showing the substantial difference between the two

| Markets | X   | Y   | W    | CONS |
| ---     | --- | --- | ---  | ---  |
| PX      | 100 |     | -100 |      |
| PY      |     | 100 | -100 |      |
| PL      | -25 | -75 |      | 100  |
| PK      | -75 | -25 |      | 100  |
| PW      |     |     | 200  | -200 |


There is only a single function, `small_model()`, which defines the model. 

## Large Model
This is a high-dimensional competitive model with 99 countries, 11 goods, and 2 factors. This model exploits complementarity: e.g., the subset of goods that each country produces and what trade links are active/inactive and direction of trade.

There are two Julia versions of this model, one a direct translation, `CompetitiveDirect` of the GAMS code and one that uses Julia structs to organize the input data, `Competitive`. 

The `CompetitiveDirect` version contains both MPSGE and the algebraic equations written in MCP format. The variable names and indexing are the same as in teh GAMS code. This version is meant to be a direct translation of the GAMS code and is useful for users who are familiar with GAMS and want to see how the same model can be implemented in Julia.

The `Competitive` version only contains the MPSGE code. This version updates the variable names to be descriptive and uses Julia structs to organize the input data. This version is meant to show some additional features of the Julia language.

This version of the model turned out to be fairly interesting. The solutions to each version of the model were different. This is not unexpected given that we are, essentially, solving a large system of non-linear equations. To verify the two models represent the same system of equations, we plug the solution from `Competitive` into the equations in `CompetitiveDirect` and verify that they are satisfied. This is done in the section "Test solution from Competitive in CompetitiveDirect".

The final section of this model is "Extracting Equations from `Competitive`". In this section, we use features from MPSGE.jl to extract the cost functions, constraints, and other equations from the model. 
