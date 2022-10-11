using CSV, Clustering, DataFrames, DelimitedFiles, Plots, Tables, Statistics

data = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_Only_Needed.csv", DataFrame);
data1 = Matrix(data);
df1 = DataFrame(data1, :auto);
CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_New_Only_Needed.csv", df1);
seed = initseeds(:kmpp, data1, 12)

@time for j in 0:29
    cluster = kmeans(data1, 12, maxiter=500, display=:final);
    @assert nclusters(cluster) == 12;
    a = assignments(cluster);
    cl1 = [];
    cl2 = [];
    cl3 = [];
    cl4 = [];
    cl5 = [];
    cl6 = [];``
    cl7 = [];
    cl8 = [];
    cl9 = [];
    cl10 = [];
    cl11 = [];
    cl12 = [];
    for i in 1:length(a)
        if (a[i] == 1)
            push!(cl1, i)
        elseif (a[i] == 2)
            push!(cl2, i)
        elseif (a[i] == 3)
            push!(cl3, i)
        elseif (a[i] == 4)
            push!(cl4, i)
        elseif (a[i] == 5)
            push!(cl5, i)
        elseif (a[i] == 6)
            push!(cl6, i)
        elseif (a[i] == 7)
            push!(cl7, i)
        elseif (a[i] == 8)
            push!(cl8, i)
        elseif (a[i] == 9)
            push!(cl9, i)
        elseif (a[i] == 10)
            push!(cl10, i)
        elseif (a[i] == 11)
            push!(cl11, i)
        elseif (a[i] == 12)
            push!(cl12, i)
        end
    end

    means = [mean(cl1), mean(cl2), mean(cl3), mean(cl4), mean(cl5), mean(cl6), mean(cl7), mean(cl8), mean(cl9), mean(cl10), mean(cl11), mean(cl12)];
    stddevs = [std(cl1), std(cl2), std(cl3), std(cl4), std(cl5), std(cl6), std(cl7), std(cl8), std(cl9), std(cl10), std(cl11), std(cl12)];
    medians = [median(cl1), median(cl2), median(cl3), median(cl4), median(cl5), median(cl6), median(cl7), median(cl8), median(cl9), median(cl10), median(cl11), median(cl12)];
    # ranges = [range(cl1), range(cl2), range(cl3), range(cl4), range(cl5), range(cl6), range(cl7), range(cl8), range(cl9), range(cl10), range(cl11), range(cl12)];
    # println("Means: ", means);
    # println("Standard Deviations: ", stddevs);
    # println("Medians: ", medians);
    c = counts(cluster);
    M = cluster.centers;
    k = [1:12]
    # println("Counts: ", c)
    # print(M)
    stats_df = DataFrame()
    stats_df.MeanDates = means;
    stats_df.DateStdDevs = stddevs;
    stats_df.Counts = c;

    centers_df = DataFrame(M, :auto);
    mkpath("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j));
    CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j) * "\\centers" * string(j) * ".csv", centers_df);
    CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster" * string(j) * "\\stats" * string(j) * ".csv", stats_df);
end

average_risks1 = [];
average_risks2 = [];
average_risks3 = [];
average_risks4 = [];
average_risks5 = [];
average_risks6 = [];
average_risks7 = [];
average_risks8 = [];
average_risks9 = [];
average_risks10 = [];
average_risks11 = [];
average_risks12 = [];
for i in 1:length(a)
    col = data1[:, i]
    av = mean(col)
    if (a[i] == 1)
        push!(average_risks1, av)
    elseif (a[i] == 2)
        push!(average_risks2, av)
    elseif (a[i] == 3)
        push!(average_risks3, av)
    elseif (a[i] == 4)
        push!(average_risks4, av)
    elseif (a[i] == 5)
        push!(average_risks5, av)
    elseif (a[i] == 6)
        push!(average_risks6, av)
    elseif (a[i] == 7)
        push!(average_risks7, av)
    elseif (a[i] == 8)
        push!(average_risks8, av)
    elseif (a[i] == 9)
        push!(average_risks9, av)
    elseif (a[i] == 10)
        push!(average_risks10, av)
    elseif (a[i] == 11)
        push!(average_risks11, av)
    elseif (a[i] == 12)
        push!(average_risks12, av)
    end
end


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