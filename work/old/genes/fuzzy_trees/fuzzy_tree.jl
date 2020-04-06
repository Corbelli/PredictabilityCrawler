# This File holds the convinience functions to create and proccess individuals and populations
include("../gene.jl")

include("fuzzy_nodes.jl")
include("fuzzy/fuzzyfy.jl")

import DataFrames: eachrow
eachrow(x::Array{Float64,2}) = (x[i, :] for i in 1:size(x, 1))


Gene(max_var::Int64, settings::FuzzyTopologyAndOperations) = Gene(fuzzy_tree(rand(1:max_var), settings),
                                                                  settings, max_var) 

# Train each row of data frame according to an individual gene and a respective fuzzyfier
function gene_score(x::Array{Float64,2}, fuzzy_tree, settings::FuzzyTopologyAndOperations)
    [fuzzy_score(fuzzy(vector(row), settings), fuzzy_tree) 
     for row in eachrow(x)]
end

activation(x::Array{Float64,2}, fuzzy_tree, 
           settings::FuzzyTopologyAndOperations, threshold=.1) = gene_score(x, fuzzy_tree, settings) .>= threshold


print(fuzzy_tree, settings::FuzzyTopologyAndOperations) = fuzzy_print(fuzzy_tree)

