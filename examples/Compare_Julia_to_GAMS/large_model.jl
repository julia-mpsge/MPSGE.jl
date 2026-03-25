using Pkg
Pkg.activate(".")
Pkg.instantiate()

using MPSGE
using DataFrames

using MPSGE.PATHSolver
PATHSolver.c_api_License_SetString("1259252040&Courtesy&&&USR&GEN2035&5_1_2026&1000&PATH&GEN&31_12_2035&0_0_0&6000&0_0")

using MPSGE.JuMP

I = 1:9
J = 1:11
G = 1:11


# ============================================
# Translation of `bigmps.gms` into Julia style
# ============================================
include("large/Competitive.jl")
using .Competitive

#@doc Competitive

countries = [Country(i, j) for i in I, j in J]
factors = [Labor(), Capital()]
goods = [Good(g) for g in G]


M = Competitive.competitive_model(countries, factors, goods);
solve!(M)
df = generate_report(M)

# ============================================
# A direct translation of the GAMS code, no special Julia structures
# ============================================
include("large/CompetitiveDirect.jl")
using .CompetitiveDirect

M_direct = CompetitiveDirect.competitive_model(I, J, [:L, :K], G);
M_direct_mcp = CompetitiveDirect.mcp_competitive_model(I, J, [:L, :K], G);

solve!(M_direct)
df_direct = generate_report(M_direct)

optimize!(M_direct_mcp)

# ==================================================
# Test solution from Competitive in CompetitiveDirect
# ==================================================

# ==================================================
# Step 1: Verify the benchmark is not balanced
# ==================================================
solve!(M_direct, cumulative_iteration_limit=0)

# ==================================================
# Step 2: Update start values of M_direct with the solution from M
# ==================================================

# Sectors
set_start_value.(
    M_direct[:X], 
    [value(M[:Good_Production][Country(i,j), Good(g)]) for i in I, j in J, g in G]
    );

set_start_value.(
    M_direct[:EX], 
    [value(M[:Export][Country(i,j), Good(g)]) for i in I, j in J, g in G]
    );

set_start_value.(
    M_direct[:IX], 
    [value(M[:Import][Country(i,j), Good(g)]) for i in I, j in J, g in G]
    );

set_start_value.(
    M_direct[:XX], 
    [value(M[:Supply][Country(i,j), Good(g)]) for i in I, j in J, g in G]
    );

set_start_value.(
    M_direct[:W], 
    [value(M[:Welfare][Country(i,j)]) for i in I, j in J]
    );

# Commodities

set_start_value.(
    M_direct[:PW], 
    [value(M[:Utility_Price][Country(i,j)]) for i in I, j in J]
    );

set_start_value.(
    M_direct[:PX], 
    [value(M[:Producer_Price][Country(i,j), Good(g)]) for i in I, j in J, g in G]
    );

set_start_value.(
    M_direct[:PCX], 
    [value(M[:Consumer_Price][Country(i,j), Good(g)]) for i in I, j in J, g in G]
    );

set_start_value.(
    M_direct[:PF], 
    [value(M[:Factor_Price][Country(i,j), f]) for i in I, j in J, f in factors]
    );

set_start_value.(
    M_direct[:PFX], 
    [value(M[:World_Price][Good(g)]) for g in G]
    );

# Consumers

set_start_value.(
    M_direct[:CONS], 
    [value(M[:Consumer][Country(i,j)]) for i in I, j in J]
    );

# =========================================
# Step 3: Solve M_direct at the benchmark solution
# =========================================
solve!(M_direct, cumulative_iteration_limit=0)



# =========================================
# Extracting Equations from `Competitive`
# =========================================

cost_function(M[:Good_Production][Country(1,1), Good(1)])