var documenterSearchIndex = {"docs":
[{"location":"Tutorials/basic_examples/m1_vec/#Basic-Vectorized-Example","page":"Basic Vectorized Example","title":"Basic Vectorized Example","text":"","category":"section"},{"location":"Tutorials/intermediate_examples/M22/#Closed-2\\times2-Economy-with-Intermediate-Inputs-and-Nesting","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"","category":"section"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"This model is available in a notebook file here.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"Consider the following social accounting matrix. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"Markets X Y W CONS\nPX 120 -20 -100 \nPY -20 120 -100 \nPW   200 -200\nPL -40 -60  100\nPK -60 -40  100","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"We are going to use this matrix to construct a simple CES nesting structure that permits the modeler to specify different elasticities of substitution between different groups of inputs.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/#Model-Initialization","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Model Initialization","text":"","category":"section"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"First we import MPSGE and initialize the model.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"using MPSGE\n\nM = MPSGEModel()","category":"page"},{"location":"Tutorials/intermediate_examples/M22/#Defining-Variables","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Defining Variables","text":"","category":"section"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"This model has:","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"Three sectors X, Y, and W\nFive commodities PX, PY, PW, PL, and PK\nOne consumer CONS","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"Let's add these to the model.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"@sectors(M, begin\n    X\n    Y\n    W\nend)\n\n@commodities(M, begin\n    PX\n    PY\n    PW\n    PL\n    PK\nend)\n\n@consumer(M, CONS)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"We use the plural version of both sector and commodity because we have  multiple of each. Each of these variables has been added to the local  namespace, so we can type X and it will display X. This is useful as we continue to build the model. These can also be accessed directly from the model, M[:X]. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/#Parameters","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Parameters","text":"","category":"section"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"In this model we will want a two parameters, tax and σ. This will allow us to apply various shocks without recompiling the model.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"@parameters(M, begin\n    tax, 0\n    σ, .5\nend)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"The parameter block requires that you set initial values for each parameter. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/#Production","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Production","text":"","category":"section"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"In this model we will have three production blocks, one for each sector. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"We'll detail the X production block as it has the most interesting structure.  Here is the full production block,","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"@production(M, X, [s = σ, t = 0, va => s = 1], begin\n    @Output PX 120 t\n    @Input  PY 20  s\n    @Input  PL 40  va taxes = [Tax(CONS,tax)]\n    @Input  PK 60  va taxes = [Tax(CONS,tax)]\nend)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"there is a lot going on in this, let's break it down piece by piece. The first few pieces, @production(M, X, are self-explanatory, model and  sector. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"This brings us to [s = σ, t = 0, va => s = 1] which defines the nesting structure. There are two top level nests s and t with respective elasticities of σ and 0. Compare this to the other nest, va, which sits under s, this is denoted with va => s and the = 1 sets the elasticity to 1. One thing to notice is that σ is a previously defined parameter. In general, any quantity can be either a number or parameter.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"Finally, inputs and outputs. These must be wrapped in the begin .. end syntax. The syntax of building an output is the same as an input, so we'll describe an  output. The required information is a commodity, quantity, and nest. We have used Julia macro syntax to suppress parentheses and commas, but you could  equivalently defined these as ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"@Output(PX, 120, t)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"Outputs have two possible keywords, reference_price and taxes.  reference_price is a simple quantity whereas taxes is an array of Tax objects, as illustrated in the PK input. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"Link to the I/O macro documentation. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"The remaining production blocks are similar,","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"@production(M, Y, [t = 0, s = .75, va => s = 1], begin \n    @Output PY 120 t\n    @Input  PX 20 s\n    @Input  PL 60 va\n    @Input  PK 40 va\nend)\n\n@production(M, W, [t = 0, s = 1], begin\n    @Output PW 200 t\n    @Input  PX 100 s\n    @Input  PY 100 s\nend)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/#Demand","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Demand","text":"","category":"section"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"Each consumer will have a corresponding demand block. Here is the demand block for CONS","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"@demand(M, CONS, begin\n    @final_demand(PW, 200)    \n    @endowment(PL, 100)\n    @endowment(PK,100)\nend)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"The first two inputs are the model and the consumer. Then there are two  begin .. end blocks, the first is for final demand and the second is  endowments. This may get improved in the future to be a single block. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/#Solving-the-Model","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Solving the Model","text":"","category":"section"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"To solve the model, you call solve! on the model. You can also pass PATH options view keyword arguments. In this case we are testing the  benchmark calibration so we set the cumulative iteration limit to 0.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"solve!(M; cumulative_iteration_limit = 0)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"While the solver output can be useful, it's more useful to see the values and the marginal values. Any non-zero marginal value should be investigated.  LINK TO MODEL DEBUGGING INFORMATION HERE.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"df_benchmark = generate_report(M)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"This will return a Julia dataframe, which you can manipulate using any dataframe technique. If you plan to manipulate this dataframe, it will be useful to use the DataFrames package","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"using DataFrames.jl","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"You can also retrieve information using standard JuMP functions, for example","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"value(X)","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"will give you the value of X. ","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"We can solve a counterfactual by changing the value of a parameter. In this  case we'll also fix PW to 1 to pin a specific solution.","category":"page"},{"location":"Tutorials/intermediate_examples/M22/","page":"Closed 2times2 Economy with Intermediate Inputs and Nesting","title":"Closed 2times2 Economy with Intermediate Inputs and Nesting","text":"fix(PW,1)\nset_value!(tax,.5)\n\nsolve!(M)\ndf = generate_report(M)","category":"page"},{"location":"Tutorials/basic_examples/m1_mpsge/#Basic-Example","page":"Basic Example","title":"Basic Example","text":"","category":"section"},{"location":"Tutorials/getting_started/introduction/#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"Tutorials/getting_started/introduction/","page":"Introduction","title":"Introduction","text":"The purpose of these \"Getting Started\" tutorials is to teach new users the basics of Julia, JuMP, and MPSGE.","category":"page"},{"location":"Tutorials/getting_started/introduction/#How-these-tutorials-are-structured","page":"Introduction","title":"How these tutorials are structured","text":"","category":"section"},{"location":"Tutorials/getting_started/introduction/","page":"Introduction","title":"Introduction","text":"A high-level overview of the structure of this documentation will assist in finding relevant information.","category":"page"},{"location":"Tutorials/getting_started/introduction/","page":"Introduction","title":"Introduction","text":"The \"Getting Started With\" tutorials are designed as basic introductions to Julia, JuMP, and MPSGE. If you are new to Julia, JuMP, or MPSGE these are the places to start. For now, the non-MPSGE bullets point to JuMP documentation. \nGetting started with Julia\nGetting started with JuMP\nGetting Started with MPSGE\nGetting started with sets and indexing\nGetting started with data and plotting\nDebugging Models\nTips for large models","category":"page"},{"location":"Tutorials/getting_started/introduction/#Markusen's-Examples","page":"Introduction","title":"Markusen's Examples","text":"","category":"section"},{"location":"installation/#Installation-Guide","page":"Installation Guide","title":"Installation Guide","text":"","category":"section"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"This guide explains how to install Julia and MPSGE.If you have installation troubles, read the Common installation issues section below.","category":"page"},{"location":"installation/#Install-Julia","page":"Installation Guide","title":"Install Julia","text":"","category":"section"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"JuMP is a package for Julia. To use JuMP, first download and install Julia.","category":"page"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"tip: Tip\nIf you are new to Julia, read our LINK tutorial.","category":"page"},{"location":"installation/#Install-MPSGE","page":"Installation Guide","title":"Install MPSGE","text":"","category":"section"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"From Julia, MPSGE is installed using the built-in package manager:","category":"page"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"import Pkg\nPkg.add(\"MPSGE\")","category":"page"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"tip: Tip\nWe recommend you create a Pkg environment for each project you use MPSGE for, instead of adding lots of packages to the global environment. The Pkg manager documentation has more information on this topic.","category":"page"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"When we release a new version of MPSGE, you can update with:","category":"page"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"import Pkg\nPkg.update(\"MPSGE\")","category":"page"},{"location":"installation/#Common-installation-issues","page":"Installation Guide","title":"Common installation issues","text":"","category":"section"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"tip: Tip\nWhen in doubt, run import Pkg; Pkg.update() to see if updating your packages fixes the issue. Remember you will need to exit Julia and start a new session for the changes to take effect.","category":"page"},{"location":"installation/#Check-the-version-of-your-packages","page":"Installation Guide","title":"Check the version of your packages","text":"","category":"section"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"Each package is versioned with a three-part number of the form vX.Y.Z. You can check which versions you have installed with import Pkg; Pkg.status().","category":"page"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"This should almost always be the most-recent release. You can check the releases of a package by going to the relevant GitHub page, and navigating to the \"releases\" page. For example, the list of MPSGE releases is available at: LINK HERE.","category":"page"},{"location":"installation/#Unsatisfiable-requirements-detected","page":"Installation Guide","title":"Unsatisfiable requirements detected","text":"","category":"section"},{"location":"installation/","page":"Installation Guide","title":"Installation Guide","text":"Did you get an error like Unsatisfiable requirements detected for package MPSGE? The Pkg documentation has a section on how to understand and manage these conflicts.","category":"page"},{"location":"Tutorials/getting_started/getting_started_mpsge/#Getting-Started-with-MPSGE","page":"Getting Started with MPSGE","title":"Getting Started with MPSGE","text":"","category":"section"},{"location":"Tutorials/getting_started/getting_started_mpsge/","page":"Getting Started with MPSGE","title":"Getting Started with MPSGE","text":"This tutorial is intended to provide an introduction to writing a simple model in MPSGE.","category":"page"},{"location":"Tutorials/getting_started/getting_started_mpsge/#An-Example","page":"Getting Started with MPSGE","title":"An Example","text":"","category":"section"},{"location":"Tutorials/getting_started/getting_started_mpsge/","page":"Getting Started with MPSGE","title":"Getting Started with MPSGE","text":"We should use the transportation model as a basic example. Further, when writing JuMP section of these tutorials we should go through the same example","category":"page"},{"location":"Tutorials/getting_started/getting_started_mpsge/#Step-By-Step","page":"Getting Started with MPSGE","title":"Step By Step","text":"","category":"section"},{"location":"Tutorials/getting_started/getting_started_mpsge/#MPSGE-Model-Basics","page":"Getting Started with MPSGE","title":"MPSGE Model Basics","text":"","category":"section"},{"location":"Tutorials/getting_started/getting_started_mpsge/#Sectors,-Commodities,-and-Consumers","page":"Getting Started with MPSGE","title":"Sectors, Commodities, and Consumers","text":"","category":"section"},{"location":"Tutorials/getting_started/getting_started_mpsge/#Extract-Information","page":"Getting Started with MPSGE","title":"Extract Information","text":"","category":"section"},{"location":"Tutorials/getting_started/getting_started_mpsge/#Non-Indexed-Version","page":"Getting Started with MPSGE","title":"Non-Indexed Version","text":"","category":"section"},{"location":"","page":"MPSGE","title":"MPSGE","text":"CurrentModule = MPSGE","category":"page"},{"location":"#[MPSGE](https://github.com/julia-mpsge/MPSGE.jl)","page":"MPSGE","title":"MPSGE","text":"","category":"section"},{"location":"#What-is-MPSGE?","page":"MPSGE","title":"What is MPSGE?","text":"","category":"section"},{"location":"","page":"MPSGE","title":"MPSGE","text":"MPSGE is a high level language for creating computable general equilibrium (CGE) models. Original implemented in FORTRAN and made available as a subsystem in GAMS. The MPSGE documentation provided by GAMS is a useful reference, especially for background, theory, and some understanding of the included features.","category":"page"},{"location":"#Resources-for-getting-started","page":"MPSGE","title":"Resources for getting started","text":"","category":"section"},{"location":"","page":"MPSGE","title":"MPSGE","text":"JuMP","category":"page"},{"location":"#How-the-documentation-is-structured","page":"MPSGE","title":"How the documentation is structured","text":"","category":"section"},{"location":"#Citing-MPSGE","page":"MPSGE","title":"Citing MPSGE","text":"","category":"section"},{"location":"#License","page":"MPSGE","title":"License","text":"","category":"section"},{"location":"docs/","page":"-","title":"-","text":"","category":"page"},{"location":"docs/","page":"-","title":"-","text":"Modules = [MPSGE]","category":"page"},{"location":"docs/#MPSGE.extract_scalars-Tuple{MPSGE.MPSGEScalarVariable}","page":"-","title":"MPSGE.extract_scalars","text":"extract_scalars\n\nTakes a variable and extracts it the sub-variables. \n\n\n\n\n\n","category":"method"},{"location":"docs/#MPSGE.production_sectors-Tuple{MPSGEModel}","page":"-","title":"MPSGE.production_sectors","text":"production_sectors(m::MPSGEModel)\n\nReturn all sectors that have a corresponding production block.  These are coming from a dictionary, so order is not guaranteed.\n\nThis is primarily used when generating constraints.\n\n\n\n\n\n","category":"method"},{"location":"docs/#MPSGE.sectors-Tuple{Commodity}","page":"-","title":"MPSGE.sectors","text":"sectors(C::Commodity)\n\nReturn only the sectors that have the input commodity in their production block. \n\nThis is an optimization in building the model as the structure is very sparse  iterating over all sectors is expensive.\n\n\n\n\n\n","category":"method"},{"location":"docs/#MPSGE.sectors-Tuple{MPSGEModel}","page":"-","title":"MPSGE.sectors","text":"sectors(m::MPSGEModel)\n\nReturn all sectors in a model\n\n\n\n\n\n","category":"method"},{"location":"docs/#MPSGE.solve!-Tuple{MPSGE.AbstractMPSGEModel}","page":"-","title":"MPSGE.solve!","text":"solve!(m::abstract_mpsge_model; keywords)\nFunction to solve the model. Triggers the build if the model hasn't been built yet.\n\nExample\n\njulia> solve!(m, cumulative_iteration_limit=0)\n\n\n\n\n\n","category":"method"},{"location":"how_it_works/#How-MPSGE-Works","page":"How MPSGE Works","title":"How MPSGE Works","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Work in progress – This explanation is quick and dirty. A more fully featured explanation is in progress.","category":"page"},{"location":"how_it_works/#Constructing-Equations","page":"How MPSGE Works","title":"Constructing Equations","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Consider a production block on sector S. This block will have an input tree and output tree. The generated equations are different for inputs vs outputs.  However, they only differ up to a sign in certain locations. Let ","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"epsilon = leftbeginarraycl\n    -1  textTree is input \n     1  textTree is output\nendarrayright","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"represent this sign. ","category":"page"},{"location":"how_it_works/#Compensated-Demand","page":"How MPSGE Works","title":"Compensated Demand","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Consider a netput tree containing a single nest and k children, either commodities or  nests, as in the Figure below. ","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"(Image: \"one_level_tree\")","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Each child node has a quantity q_i. Each commodity node has a reference price p_i,  base quantity Q_i, reference quantity q_i=p_icdot Q_i, variable C_i,  and taxes t_ih, where the index h is a consumer. Then q = sum q_i  is the quantity of the root n. The root also has an elasticity sigma.","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"The cost function for a commodity node n_i will be given by pi(nC_i) where","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"pi(nC_i) = fracC_i(1-epsilonsum_h t_ih)p_i","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"This must be indexed by both the parent nest and commodity as commodities can appear in a netput tree multiple times, albeit not directly under the same nest. The cost function for any non-commodity child node is defined recursively in this manner. This is well defined as all leaves are commodities.","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"The cost function on the root n, C(n), depends on the elasticity of the root. If sigma=1, the cost function is given by Cobb-Douglass","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"  C(n) =  prod_i=1^k pi(nC_i)^fracq_iq","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"And if sigmane1 then we use a CES cost function","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"C(n) = \n        left(sum_i=1^k fracq_iq pi(nC_i)^1+epsilonsigmaright)^frac11+epsilonsigma","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"In general, these trees can be highly nested. Consider a path from the root, n_1 to a leaf n_k+1. Using this we can calculate the compensated demand, CD(SCn_k), for the sector S, commodity C and nest n_k","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"CD(SCn_k) = -epsilon Q_C left(fracC(n_k)pi(n_kC)right)^-epsilonsigma_k prod_i=1^k-1 left(fracC(n_i)C(n_i+1)right)^-epsilonsigma_i","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Finally, the compensated demand, CD(SC), is the summation over all nests that have C as a leaf.","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"CD(SC) = sum_substackntext nest textif (nC)text is an edge CD(SCn)","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"For convenience we take any compensated demand not defined above to be 0, this follows from the empty summation in CD(SC).","category":"page"},{"location":"how_it_works/#\\tau","page":"How MPSGE Works","title":"tau","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"For sector S and consumer H define ","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"tau(SH) = - sum_substackCintext Commoditiesnintext nests CD(SCn)cdot t_SCHncdot C","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"where t_SCHn is the tax on the commodity C by consumer H in sector S  under nest n.","category":"page"},{"location":"how_it_works/#Endowments/Demands","page":"How MPSGE Works","title":"Endowments/Demands","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"For commodity C and consumer H define E(HC) to be the endowment quantity. This is taken to be 0 if there is no endowment for H and C.","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Let sigma be the elasticity of demand, q_C be the quantity of demand for commodity C in H consumer demand, q = sum_C q_C be the total demand, and p_C be the reference price of the commodity. Define the demand function, D(HC), as","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"D(HC) = fracq_Cqcdot fracHCcdot leftbeginarrayccfracp_Hcdottextexpenditure(H)C^sigma-1  sigmane1  1  textotherwise endarrayright","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"where","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"textexpenditure(H) = left(sum_Cintext demands(H) fracq_Ccdot Cqcdot p_Cright)^1(1-sigma)","category":"page"},{"location":"how_it_works/#Constraints","page":"How MPSGE Works","title":"Constraints","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"With these definitions, we can define the complementarity constraints. ","category":"page"},{"location":"how_it_works/#Zero-Profit","page":"How MPSGE Works","title":"Zero Profit","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Let S be a sector with a production block, then the zero profit condition is  given by,","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"left(sum_Cintext CommoditiesCD(SC)cdot Cright) - sum_Hintext Consumers tau(SH) perp S","category":"page"},{"location":"how_it_works/#Market-Clearance","page":"How MPSGE Works","title":"Market Clearance","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Let C be a commodity, then the market clearance condition is given by,","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"left(sum_Sintext Sectors CD(SC)cdot S right) - sum_Hintext Consumers E(HC) - D(HC) perp C","category":"page"},{"location":"how_it_works/#Income-Balance","page":"How MPSGE Works","title":"Income Balance","text":"","category":"section"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"Let H be a consumer, then the income balance condition is given by,","category":"page"},{"location":"how_it_works/","page":"How MPSGE Works","title":"How MPSGE Works","text":"H - left(sum_Cintext Commodities E(HC)cdot C - sum_Sintext Sectorstau(SH)cdot Sright) perp H","category":"page"}]
}
