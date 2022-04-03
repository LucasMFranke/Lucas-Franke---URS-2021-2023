using CSV, Clustering, DataFrames, DelimitedFiles, Plots, Tables, Statistics

data = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_Only_Needed.csv", DataFrame);
data1=Matrix(data);
df1 = DataFrame(data1, :auto);
CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_New_Only_Needed.csv", df1);
#writedlm(stdout, data1);
#alg = KmppAlg;
seed = initseeds(:kmpp, data1, 12)
cluster = kmeans(data1, 12, maxiter=500, display=:final);\
@assert nclusters(cluster) == 12;
a = assignments(cluster);
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

averages = [mean(cl1), mean(cl2), mean(cl3), mean(cl4), mean(cl5), mean(cl6), mean(cl7), mean(cl8), mean(cl9), mean(cl10), mean(cl11), mean(cl12)];
stddevs = [std(cl1), std(cl2), std(cl3), std(cl4), std(cl5), std(cl6), std(cl7), std(cl8), std(cl9), std(cl10), std(cl11), std(cl12)];
println("Averages: ", averages);
println("Standard Deviations: ", stddevs);
c = counts(cluster);
M = cluster.centers;
k=[1,2,3,4,5,6,7,8,9,10,11,12]
println(c)
size(M)
bar(k, 
c,
label = "Counts/Cluster",
title = "Clusters",
xticks =:all,
xrotation = 45,
size = [600, 400],
legend =:topleft)