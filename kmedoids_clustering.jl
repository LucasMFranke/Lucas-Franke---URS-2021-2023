using CSV, Clustering, DataFrames, DelimitedFiles, Plots, Tables, Statistics, Distances

data = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_Only_Needed.csv", DataFrame);
data_with_extra_columns = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231.csv", DataFrame);
data1 = Matrix(data);
df1 = DataFrame(data1, :auto);
CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_New_Only_Needed.csv", df1);

@time for j in 1:365
    b = j;
    squareMatrix = pairwise(Euclidean(), data1);
    cluster = kmedoids(squareMatrix, b, maxiter=500, display=:final);
    a = assignments(cluster);
    cl_arr_of_arrs = [];
    medoidsDF = DataFrame()

    c = counts(cluster);
    M = cluster.medoids;
    k = [1:b]
    # println(M)
    
    # println(data1[:, M[1]])

    for z in 1:b
        colName = string(z)
        medoidsDF[!, colName] = data1[:, M[z]]
        # println(z)
    end

    column_names = []

    for n in 1:b
        push!(column_names, "wfpi_day"*string(M[n]))
    end

    # Adds a few columns with data about the lines to the dataframe
    rename!(medoidsDF, Symbol.(column_names))
    for f in [:UID, :From_Bus, :To_Bus, :Tr_Ratio, :Length]
        col = data_with_extra_columns[!, f]
        medoidsDF[!, f] = col
    end

    arr = data_with_extra_columns[!, :OID_]
    insertcols!(medoidsDF, 1, :OID_ => arr)

    # println(medoidsDF)

    mkpath("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\K-Medoids Stats\\Cluster" * string(j));
    CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\K-Medoids Stats\\Cluster" * string(j) * "\\medoids" * string(j) * ".csv", medoidsDF);
    # CSV.write("C:\\Users\\lucas\\Documents\\Lucas-Franke---URS-2021-2022-main\\Risk_DataTables\\K-Medoids Stats\\Cluster" * string(j) * "\\stats" * string(j) * ".csv", stats_df);
    # p1 = scatter(mean_dates_opt, mean_risks, label = "Mean Risk", title = "Mean Risk vs Mean Date", xticks =:all, xrotation = 45, legend =:outertopleft);
    # savefig("C:\\Users\\lucas\\Documents\\Lucas-Franke---URS-2021-2022-main\\Risk_DataTables\\K-Medoids Stats\\Cluster" * string(j) * "\\dates_vs_risk"*string(j)*".png");
end


# average_risks1 = [];
# average_risks2 = [];
# average_risks3 = [];
# average_risks4 = [];
# average_risks5 = [];
# average_risks6 = [];
# average_risks7 = [];
# average_risks8 = [];
# average_risks9 = [];
# average_risks10 = [];
# average_risks11 = [];
# average_risks12 = [];
# for i in 1:length(a)
#     col = data1[:, i]
#     av = mean(col)
#     if (a[i] == 1)
#         push!(average_risks1, av)
#     elseif (a[i] == 2)
#         push!(average_risks2, av)
#     elseif (a[i] == 3)
#         push!(average_risks3, av)
#     elseif (a[i] == 4)
#         push!(average_risks4, av)
#     elseif (a[i] == 5)
#         push!(average_risks5, av)
#     elseif (a[i] == 6)
#         push!(average_risks6, av)
#     elseif (a[i] == 7)
#         push!(average_risks7, av)
#     elseif (a[i] == 8)
#         push!(average_risks8, av)
#     elseif (a[i] == 9)
#         push!(average_risks9, av)
#     elseif (a[i] == 10)
#         push!(average_risks10, av)
#     elseif (a[i] == 11)
#         push!(average_risks11, av)
#     elseif (a[i] == 12)
#         push!(average_risks12, av)
#     end
# end


#p1 = bar(k, c, label = "Counts/Cluster", title = "Clusters", xticks =:all, xrotation = 45, legend =:outertopleft);

# scatter(cl1, average_risks1,  ylabel = "Average Risk", xlabel  = "Data index", label = "Cluster 1", legend =:outertopleft, size = [1000, 600], color=:red)
# scatter!(cl2, average_risks2, label = "Cluster 2", color=:blue)
# scatter!(cl3, average_risks3, label = "Cluster 3", color=:yellow)
# scatter!(cl4, average_risks4, label = "Cluster 4", color=:green)
# scatter!(cl5, average_risks5, label = "Cluster 5", color=:orange)
# scatter!(cl6, average_risks6, label = "Cluster 6", color=:purple)
# scatter!(cl7, average_risks7, label = "Cluster 7", color=:pink)
# scatter!(cl8, average_risks8, label = "Cluster 8", color=:lightgreen)
# scatter!(cl9, average_risks9, label = "Cluster 9", color=:black)
# scatter!(cl10, average_risks10, label = "Cluster 10", color=:violet)
# scatter!(cl11, average_risks11, label = "Cluster 11", color=:gray)
# scatter!(cl12, average_risks12, label = "Cluster 12", color=:lightblue)