#### Optimal Upgrade Selection Model ####

# This file provides an optimal upgrade selection model
# using the Julia Mathematical Programming package (JuMP) and
# the PowerModels package for data parsing.

# In this problem setup, we minimize the the total risk of wildfire ignition 
# for a given budget.

# Developed by Sofia Taylor and Line Roald.

###############################################################################
# 0. Initialization 
###############################################################################

# Load Julia Packages
#--------------------
using PowerModels, Gurobi, JuMP
using CSV, DataFrames, Plots
using LinearAlgebra, Statistics, StatsBase

print_upgraded_lines = true

for j in 1:365
    upgrades_df = DataFrame();
    ##############################################################################################################
    # Load and Configure Data
    # -----------------------
    # Read in Wildland Fire Potential Index risk values for the grid branches
    # TODO: Change this to clustered data
    branch_risk = CSV.read("C:/Users/lucas/Documents/ArcGIS/Projects/LFranke_WISPO_Proj/Risk_DataTables/Clustering Stats/Cluster"*string(j)*"/centers"*string(j)*".csv", DataFrame)

    # Get number of scenarios from data
    n_scenarios = 0 
    risk_start = 0
    for i = 1:length(names(branch_risk))
        if occursin("wfpi", names(branch_risk)[i])
            n_scenarios += 1
            if risk_start == 0
                risk_start = i
            end
        end
    end


    ###############################################################################
    # 1. Building the Optimization Model
    ###############################################################################

    # Parameters
    # ----------

    # Store risk values for all scenarios in the matrix 'risk'
    risk = Array{Float64}(undef, length(branch_risk.Length),n_scenarios)
    for l = 1:1:size(branch_risk,1)
        for s = 1:1:n_scenarios
            value =  branch_risk[!, risk_start - 1 + s][l]
            risk[l,s] = value
        end
    end

    # Set risk values of transformers equal to 0
    for l = 1:size(risk,1)
        if branch_risk.Length[l] == 0
            risk[l,:] .= 0
        end
    end


    # Normalize risk values
    # risk = risk/maximum(risk)

    # Upgrade cost = ($2 million)*length
    cost = [2000000*branch_risk.Length[l] for l in 1:length(branch_risk.Length)]


    # Variables
    # ---------                     


    # Initialize a JuMP Optimization Model
    #-------------------------------------
    model = Model(Gurobi.Optimizer)

    # Set output level
    set_optimizer_attribute(model, "OutputFlag", 0)
    # note: print_level changes the amount of solver information printed to the terminal

    # Variables
    # -----------

    # Total wildfire ignition risk
    @variable(model, R)

    # Total upgrade cost
    @variable(model, 0 <= C)

    # Binary decision for potential upgrade branch l
    # 1 if the upgrade is made, 0 if not
    @variable(model, z_upgrade[l in 1:length(branch_risk.Length)], Bin)

    # Constraints
    # -----------

    # Wildfire ignition risk definition
    # Wildfire risk for each line is the max across all scenarios        
    for l = 1:size(risk)[1]
        @constraint(model, R .>= risk[l,:]*(1 - z_upgrade[l]))
    end


    # Upgrade cost definition
    @constraint(model, C == sum(cost[l]*(z_upgrade[l]) for l in 1:size(risk)[1])) # sum across all lines

    # Objective Function: Budget
    # --------------------------

    # Constraint on upgrade budget
    budget = 600000000
    @constraint(model, C <= budget)

    # Minimize the sum of total risk of wildfire ignition
    @objective(model, Min, R)

    ###############################################################################
    # 3. Solve the Model and Review the Results
    ###############################################################################

    # Solve the optimization problem
    optimize!(model)

    # Check that the solver terminated without an error
    # println("The solver termination status is $(termination_status(model))")

    # Print useful information
    println("Total cost of upgrades:  \$$(value(C)).")

    pre_upgrade_risk = sum(risk)
    post_upgrade_risk = (sum(risk.*(1 .- JuMP.value.(z_upgrade))))
    println("Wildfire ignition risk:  $post_upgrade_risk, reduced from $pre_upgrade_risk.")
    println("Percent reduction: ", 100*(1 - post_upgrade_risk/pre_upgrade_risk))

    println("Total lines upgraded: ", round(sum(JuMP.value.(z_upgrade))), " out of ", size(risk)[1])
    println("Total line length upgraded: ", sum(JuMP.value.(z_upgrade).*branch_risk.Length), " mi out of ", sum(branch_risk.Length))


    # Get IDs of lines selected for upgrade
    upgrades = findall(round.(Int,JuMP.value.(z_upgrade)).==1)
    if print_upgraded_lines == true
        for i=1:length(upgrades)
            println(upgrades[i])
        end
    end
    upgrades_df[!,:"Upgrades"] = upgrades;
    # mkpath("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j));
    CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j) * "\\Upgrades"*string(j)*".csv", upgrades_df);
end

##############################################################################################################