include("../../utils/sample.jl")
include("../../utils/manipulation.jl")
include("fuzzy/fuzzyfy.jl")
using Statistics
using Match
using DataFrames, Query

# Creates a Tree selecting nr_variables randomly to be used
function fuzzy_tree(nr_variables::Int64, settings::FuzzyTopologyAndOperations)
    if nr_variables > length(settings.topology)
        throw(ArgumentError("The number of variables to use must be equal or less 
                than the number of inputs defined in the fuzzy settings")) end
    selected_variables = nr_variables == 1 ? [sample(settings.topology, nr_variables)] :
                                             sample(settings.topology, nr_variables)
    fuzzy_node(selected_variables, false, settings.operations)
end

# Recursive Function responsable for creating the Tree
function fuzzy_node(variables::Array{Array{Int64,1},1} , son_of_arity_one::Bool, operations::Operations)
    options = ["variable", "function_arity_one", "function_arity_two"]
    valid = [length(variables) == 1, !son_of_arity_one, length(variables) > 1]
    choosen = sample(options[valid])
    @match choosen begin
       "variable" => Dict("index" => [[variables[1][1], rand(1:variables[1][2])]])
       "function_arity_one" =>  Dict(sample(operations.arity_one) => [fuzzy_node(variables, true, operations)])
       "function_arity_two" =>  Dict(sample(operations.arity_two) => 
            [fuzzy_node([variables[1]], false, operations), fuzzy_node(variables[2:end], false, operations)])
    end
end

# Recursive Function responsable for computing the value for a fuzzy node given a fuzzy vector
function fuzzy_score(fuzzy_x::Array{Array{Float64,1},1}, fuzzy_node)
    for (operator, args) in fuzzy_node
        if operator == "index"
            return fuzzy_indexes_to_values(fuzzy_x, args)[1]
        else 
            return operator([fuzzy_score(fuzzy_x, arg) for arg in args]...)
        end
    end
end    
    
# Prints a fuzzy tree
function fuzzy_print(dict, pre_indent=0, indent=4)
    for (key, values) in dict
        if key == "index"
            println( " " ^ pre_indent * "$(values[1])" )
            continue
        end
        println( " " ^ pre_indent  * string(key))
        [fuzzy_print(value, pre_indent + indent) for value in values]         
    end
    nothing 
end

