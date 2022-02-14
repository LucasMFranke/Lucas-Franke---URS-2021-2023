using CSV, Clustering, DataFrames, DelimitedFiles

data = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231_Only_Needed.csv", DataFrame)
data1=Matrix(data)
#print(data1)
cluster = kmeans(data1, 12);
@assert nclusters(cluster) == 12
a = assignments(cluster)
c = counts(cluster)
M = cluster.centers
size(M)