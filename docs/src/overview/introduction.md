# Overview of MPSGE

This chapter provides an overview of the MPSGE package. This is going to be a peak behind the scenes of how MPSGE works, what are its main components, and how they interact with each other. It is not necessary to understand all the details in order to use MPSGE, but it may help you get a better understanding of the package and its capabilities.

At it's core, MPSGE sits on top of JuMP, a powerful modeling language for mathematical optimization in Julia. MPSGE creates the necessary variables and constraints to represent a CGE model in JuMP, and then uses JuMP's solvers to find the equilibrium solution.