using CSV, Clustering, DataFrames, DelimitedFiles, Plots, Tables, Statistics

data = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_Only_Needed.csv", DataFrame);
data_with_extra_columns = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231.csv", DataFrame);
data1 = Matrix(data);
df1 = DataFrame(data1, :auto);
CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_New_Only_Needed.csv", df1);
seed = initseeds(:kmpp, data1, 12)

@time for j in 0:29
    b = 12;
    cluster = kmeans(data1, b, maxiter=500, display=:final);
    @assert nclusters(cluster) == 12;
    a = assignments(cluster);
    cl_arr_of_arrs = [];
    cl1 = [];
    cl2 = [];
    cl3 = [];
    cl4 = [];
    cl5 = [];
    cl6 = [];
    cl7 = [];
    cl8 = [];
    cl9 = [];
    cl10 = [];
    cl11 = [];
    cl12 = [];
    for z in 1:b
        temp_arr = [];
        push!(cl_arr_of_arrs, temp_arr)
    end

    for p in 1:length(a)
        for ind in 1:b
            if (a[p]==ind)
                push!(cl_arr_of_arrs[ind], p)
            end
        end
    end
    mean_dates_opt = [];
    date_stds_opt = []
    median_dates_opt = [];
    for u in 1:b
        temp_mean = mean(cl_arr_of_arrs[u])
        temp_std_dev = std(cl_arr_of_arrs[u])
        temp_med = median(cl_arr_of_arrs[u])
        push!(mean_dates_opt, temp_mean)
        push!(median_dates_opt, temp_med)
        push!(date_stds_opt, temp_std_dev)
    end

    c = counts(cluster);
    M = cluster.centers;
    k = [1:12]
    stats_df = DataFrame()
    stats_df.MeanDates = mean_dates_opt;
    stats_df.Date_stddevs = date_stds_opt;
    stats_df.MedianDates = median_dates_opt
    stats_df.Counts = c;

    centers_df = DataFrame(M, :auto);
    column_names = []
    
    for n in 1:12
        push!(column_names, "wfpi_cluster"*string(n))
    end

    mean_risks = []
    risk_stddevs = []
    for l in 1:b
        colm = centers_df[:, l]
        temp_mean = mean(colm)
        temp_stddev = std(colm)
        push!(mean_risks, temp_mean)
        push!(risk_stddevs, temp_stddev)
    end

    stats_df.MeanRisks = mean_risks;
    stats_df.Risk_stddevs = risk_stddevs;

    rename!(centers_df, Symbol.(column_names))
    for f in [:UID, :From_Bus, :To_Bus, :Tr_Ratio, :Length]
        col = data_with_extra_columns[!, f]
        centers_df[!, f] = col
    end

    arr = data_with_extra_columns[!, :OID_]
    insertcols!(centers_df, 1, :OID_ => arr)

    mkpath("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j));
    CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j) * "\\centers" * string(j) * ".csv", centers_df);
    CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j) * "\\stats" * string(j) * ".csv", stats_df);
    p1 = bar(mean_dates_opt, mean_risks, label = "Mean Risk", title = "Mean Risk vs Mean Date", xticks =:all, xrotation = 45, legend =:outertopleft);
    savefig("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j) * "\\dates_vs_risk"*string(j)*".png");

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