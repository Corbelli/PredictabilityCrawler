include("operations/basic.jl")
include("sets/triangular.jl")


# Contains the index representation of the fuzzy variables (index and nr of sets),
# the avaiable fuzzy operations and the inputs fuzzysets
struct FuzzyTopologyAndOperations
    topology::Array{Array{Int64,1},1}
    operations::Operations
    inputs_fuzzysets::Array{Array{Any,1},1}
end

FuzzyTopologyAndOperations(inputs_fuzzysets, operations) = FuzzyTopologyAndOperations(fuzzysets_to_topology(inputs_fuzzysets), operations, inputs_fuzzysets)


# Creates the index representation out of the corresponding fuzzysets for each input
fuzzysets_to_topology(inputs_fuzzysets) = [[i, length(inputs_fuzzysets[i])] for i in 1:length(inputs_fuzzysets)];

# Extracts the corresponding value from the fuzzy vector given the index representation of a specif fuzzy set
function fuzzy_indexes_to_values(fuzzy_x::Array{Array{Float64,1},1}, indices)
    [fuzzy_x[indice[1]][indice[2]] for indice in indices]
end

# Fuzzyfy a vector, returning a fuzzy array for each variable
function fuzzy(array::Array{Float64,1}, settings::FuzzyTopologyAndOperations)
    if length(array) != length(settings.inputs_fuzzysets) 
        throw(ArgumentError("There has to be a fuzzy-sets 
                representation for each element in the array")) end
    [μ.(value, fuzzysets) for (value, fuzzysets) in zip(array, settings.inputs_fuzzysets)]
end




