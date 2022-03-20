using CSV, Clustering, DataFrames, DelimitedFiles, Plots

data = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_Only_Needed.csv", DataFrame)
data1=Matrix(data)
df1 = DataFrame(data1, :auto)
CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_New_Only_Needed.csv", df1)
writedlm(stdout, data1)
cluster = kmeans(data1, 12, display=:final);
@assert nclusters(cluster) == 12
a = assignments(cluster)
c = counts(cluster)
M = cluster.centers
k=[1,2,3,4,5,6,7,8,9,10,11,12]
println(c);
#println(a);
size(M)
bar(k, 
c,
label = "Counts/Cluster",
title = "Clusters",
xticks =:all,
xrotation = 45,
size = [600, 400],
legend =:topleft)