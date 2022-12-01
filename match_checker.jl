using CSV, Clustering, DataFrames, DelimitedFiles, Plots, Tables, Statistics

unclustered_selected = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster365\\Upgrades365.csv", DataFrame);

checker_arr = []
k_values = []
for i in 1:365
    push!(k_values, i)
    current_selections = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster"*string(i)*"\\Upgrades"*string(i)*".csv", DataFrame);
    number_of_matches = 0
    for j in 1:length(current_selections[!, 1])
        try
            if (current_selections[j, 1] in unclustered_selected[!, 1])
                number_of_matches+=1
            end
        catch
            continue
        end
    end
    push!(checker_arr, number_of_matches)
end
print(checker_arr)

match_numbers = DataFrame()
match_numbers.Matches = checker_arr;
mkpath("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats");
CSV.write("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\match_numbers.csv", match_numbers);
    

scatter(k_values, checker_arr)

# data_with_extra_columns = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\20210101_20211231.csv", DataFrame);
# check_365 = CSV.read("C:\\Users\\lucas\\Documents\\ArcGIS\\Projects\\LFranke_WISPO_Proj\\Risk_DataTables\\Clustering Stats\\Cluster365\\centers365.csv", DataFrame);

# for h in 1:370
#     col = check_365[!, h]
#     orig_col = data_with_extra_columns[!, h]
#     if col != orig_col
#         print("Inconsistency at column " * string(h))
#     else
#         println("No Inconsistency " * string(h));
#     end
# end