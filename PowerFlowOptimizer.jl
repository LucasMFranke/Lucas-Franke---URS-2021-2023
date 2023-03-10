# Load Julia Packages
# --------------------
# Uncomment and add packages if needed

# import Pkg
# Pkg.add("PowerModels")
# Pkg.add("PowerModelsWildfire")
# Pkg.add("Gurobi")
# Pkg.add("JuMP")
# Pkg.add("CSV")
# Pkg.add("DataFrames")

# Load Julia Packages
#--------------------
using Pkg; Pkg.activate(".")
using PowerModels, PowerModelsWildfire
using Gurobi, JuMP
using CSV, DataFrames



# Load and Configure Risk Data
# ----------------------------

# Read in branch risk values
branch_risk = CSV.read("C:/Users/lucas/Documents/ArcGIS/Projects/LFranke_WISPO_Proj/Risk_DataTables/Clustering Stats/Cluster"*string(23)*"/centers"*string(23)*".csv", DataFrame)

# Get number of scenarios and first risk column from data
K = 0
for i = 1:length(names(branch_risk))
    if occursin("wfpi", names(branch_risk)[i])
        global K += 1
        if K == 1
            global riskColStart = i
        end
    end
end

# Uncomment and modify this line to manually change the total number of scenarios K that are run
# If commented, code will run for all 360 scenarios in csv
K = 10 

# Make transformer risk zero
for i = 1:size(branch_risk)[1]
    if branch_risk.Length[i] == 0 
        for k = 0:(K-1)
            branch_risk[i,riskColStart + k] = 0
        end
    end
end

# Create risk dictionary
R = Dict(branch_risk.OID_[i] =>collect(branch_risk[i,riskColStart:(riskColStart+K-1)]) for i in 1:size(branch_risk)[1])

# # Create cost dictionary
cost = Dict(branch_risk.OID_[i] => branch_risk.Length[i,:][1]*2000000 for i in 1:size(branch_risk)[1])

println("Risk and cost data is configured.")



# Load Power System Data
# ----------------------

# Load Matpower file of grid data
powermodels_path = joinpath(dirname(pathof(PowerModelsWildfire)), "..")
file_name = "$(powermodels_path)/test/networks/RTS_GMLC_risk.m"

# Store the power system data in the PowerModel dictionary format
data = PowerModels.parse_file(file_name)

# Add zeros to turn linear objective functions into quadratic ones
# so that additional parameter checks are not required
PowerModels.standardize_cost_terms!(data, order=2)

# Adds reasonable rate_a values to branches without them
PowerModels.calc_thermal_limits!(data)

# Note: ref contains all the relevant system parameters needed to build the OPS model
# When we introduce constraints and variable bounds below, we use the parameters in ref.
ref = PowerModels.build_ref(data) # use build_ref to filter out inactive components
ref_add_on_off_va_bounds!(ref, data)
ref = ref[:it][:pm][:nw][0]

println("Power system data is configured.")



# Initialize a JuMP Optimization Model
#-------------------------------------
model = Model(Gurobi.Optimizer)

# Add Variables
# -------------

# Add binary variables for the on/off status of all components in scenario k
@variable(model, z_on[(l,i,j) in ref[:arcs_from], k in 1:K], Bin)

# Add binary variables for the upgrade status of all branches
@variable(model, z_upgrade[(l,i,j) in ref[:arcs_from]], Bin)

# Add continous variables to indicate load served in scenario k
@variable(model, 0.0 <= x_load[l in keys(ref[:load]), k in 1:K] <= 1.0)

# Add variable for the total risk in scenario k
@variable(model, rho[k in 1:K] >= 0)

# Add variable for the total load shed in scenario k
@variable(model, delta[k in 1:K])

# Add voltage angles va for each bus i in scenario k
@variable(model, va[i in keys(ref[:bus]), k in 1:K])

# Add active power generation variable pg for each generator in scenario k
@variable(model, pg[i in keys(ref[:gen]), k in 1:K])

# Add power flow variables p to represent the active power flow for each branch in scenario k
@variable(model,  p[(l,i,j) in ref[:arcs_from], k in 1:K])

# Build JuMP expressions for the value of p[(l,i,j), k] and p[(l,j,i), k] on the branches
# note: this is used to make the definition of nodal power balance simpler
# A separate expression is needed for each scenario k
p_expr = Array{Dict{Tuple{Int64, Int64, Int64}, AffExpr}}(undef, 360)
for k = 1:K
    p_expr[k] = Dict([((l,i,j), 1.0*p[(l,i,j),k]) for (l,i,j) in ref[:arcs_from]])
    p_expr[k] = merge(p_expr[k], Dict([((l,j,i), -1.0*p[(l,i,j),k]) for (l,i,j) in ref[:arcs_from]]))
end

# Add variables for McCormick Envelope relaxation
# One variable is needed for each line and each scenario
@variable(model, w[(l,i,j) in ref[:arcs_from], k in 1:K] >= 0)

println("\nVariables added to model.")



# Add Objective Function
# ----------------------

# Set weighting factors
alpha = 1   # Cost weight
beta = 1    # Risk weight
gamma = 1  # Load weight

# Objective: minimize upgrade cost + risk + load shed
JuMP.@objective(model, Min,
     alpha*(sum(cost[l]*z_upgrade[(l,i,j)] for (l,i,j) in ref[:arcs_from])) # upgrade cost
     + beta*sum(rho)         # wildfire risk
     + gamma*sum(delta)       # load shed due to power shutoffs
)

println("Objective function added to model.")

# alpha*(sum(cost[l]*value.(z_upgrade[(l,i,j)]) for (l,i,j) in ref[:arcs_from]))

# value.(rho)

# Add Constraints
# ---------------

# Constraint to limit risk
for k in 1:K
    JuMP.@constraint(model, rho[k] >=
        beta*(sum(R[l][k]*z_on[(l,i,j), k] - R[l][k]*w[(l,i,j),k] for (l,i,j) in ref[:arcs_from])*sum(cost[l] for (l,i,j) in ref[:arcs_from])) 
    )
end

# Constraint to limit load shed
for k in 1:K
    JuMP.@constraint(model, delta[k] >=
        - gamma*(sum(x_load[i,k]*load["pd"] for (i,load) in ref[:load])*sum(cost[l] for (l,i,j) in ref[:arcs_from]))/100
    )
end

# Fix the voltage angle to zero at the reference bus
for k in 1:K
    for (i,bus) in ref[:ref_buses]
        @constraint(model, va[i,k] == 0)
    end
end

# Branch constraints
for k in 1:K
    for (i,branch) in ref[:branch]

        # Build the from variable id of the i-th branch, which is a tuple given by (branch id, from bus, to bus)
        f_idx = (i, branch["f_bus"], branch["t_bus"])
        p_fr = p[f_idx, k]                     # p_fr is a reference to the optimization variable p[f_idx]
        z_br = z_on[f_idx, k]
        va_fr = va[branch["f_bus"],k]         # va_fr is a reference to the optimization variable va on the from side of the branch
        va_to = va[branch["t_bus"],k]         # va_fr is a reference to the optimization variable va on the to side of the branch
        # Compute the branch parameters and transformer ratios from the data
        g, b = PowerModels.calc_branch_y(branch)

        # Voltage angle difference limit
        JuMP.@constraint(model, va_fr - va_to <= branch["angmax"]*z_br + ref[:off_angmax]*(1-z_br))
        JuMP.@constraint(model, va_fr - va_to >= branch["angmin"]*z_br + ref[:off_angmin]*(1-z_br))

        # DC Power Flow Constraint
        if b <= 0
            JuMP.@constraint(model, p_fr <= -b*(va_fr - va_to + ref[:off_angmax]*(1-z_br)) )
            JuMP.@constraint(model, p_fr >= -b*(va_fr - va_to + ref[:off_angmin]*(1-z_br)) )
        else # account for bound reversal when b is positive
            JuMP.@constraint(model, p_fr >= -b*(va_fr - va_to + ref[:off_angmax]*(1-z_br)) )
            JuMP.@constraint(model, p_fr <= -b*(va_fr - va_to + ref[:off_angmin]*(1-z_br)) )
        end

        # Thermal limit
        JuMP.@constraint(model, p_fr <=  branch["rate_a"]*z_br)
        JuMP.@constraint(model, p_fr >= -branch["rate_a"]*z_br)

    end
end

# Nodal power balance constraints
for k in 1:K
    for (i,bus) in ref[:bus]

        # Build a list of the loads and shunt elements connected to the bus i
        bus_loads = [(l,ref[:load][l]) for l in ref[:bus_loads][i]]

        # Active power balance at node i
        @constraint(model,
            sum(pg[g,k] for g in ref[:bus_gens][i]) -                         # sum of active power generation at bus i -
            sum(p_expr[k][a] for a in ref[:bus_arcs][i]) -                    # sum of active power flow on lines from bus i -
            sum(x_load[l,k]*load["pd"] for (l,load) in bus_loads)            # sum of active load * load shed  at bus i = 0
            == 0
        )
    end
end

# Generator constraints
for k in 1:K
    for (i,gen) in ref[:gen]

        # Power limit
        JuMP.@constraint(model, pg[i,k] <= gen["pmax"])#*z_gen[i])
        JuMP.@constraint(model, pg[i,k] >= 0)#*z_gen[i])

    end
end

# McCormick Envelope upper and lower bound constraints
for k in 1:K
    for (i,branch) in ref[:branch]

        f_idx = (i, branch["f_bus"], branch["t_bus"])
        ω = w[f_idx,k]
        zup = z_upgrade[f_idx]
        zon = z_on[f_idx,k]

        @constraint(model, ω >= zup + zon - 1 )
        @constraint(model, ω <= zon)
        @constraint(model, ω <= zup)

    end
end

println("Constraints added to model.")

# Solve the optimization problem
# ------------------------------

optimize!(model)

# Check that the solver terminated without an error
println("The solver termination status is $(termination_status(model))")

# Print results
# -----------------------

# Check objective value, although the value does not have significance
println("The objective value is $(objective_value(model))")

# Compute load served in each scenario, based on load curtailment variables
for k in 1:K
    served_load = sum(value(x_load[i,k])*load["pd"] for (i,load) in ref[:load])
    total_load = sum(load["pd"] for (i,load) in ref[:load])
    println("The load served in scenario $k is $served_load, out of the total $total_load.")
end

# Get upgraded devices
global num_upgraded = 0
for l in sort(collect(keys(ref[:branch])))
    f_idx = (l, ref[:branch][l]["f_bus"], ref[:branch][l]["t_bus"])
    value(z_upgrade[f_idx])==1 ? println("Branch $l is upgraded.") : false
    value(z_upgrade[f_idx])==1 ? num_upgraded+=1 : false
end
println("Number upgraded: $num_upgraded")

# Compute total wildfire risk (prior to any upgrade or shutoff decisions)
global total_risk = 0
for k in 1:K
    total_risk += sum(R[l][k] for (l,i,j) in ref[:arcs_from])
end

# Compute risk in each scenario and print results
for k in 1:K
    new_risk = sum(value.(z_on[(l,i,j),k])*R[l][k] for (l,i,j) in ref[:arcs_from])
    println("The system risk is $new_risk, reduced from $total_risk.")
end

# Compute and print the cost of upgrading lines
upgrade_cost = sum(cost[l]*value(z_upgrade[(l,i,j)]) for (l,i,j) in ref[:arcs_from])
total_cost = sum(cost[l] for (l,i,j) in ref[:arcs_from])
println("The upgrade cost is $upgrade_cost, out of the total cost of upgrading all lines $total_cost")

