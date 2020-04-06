include("../genes/gene.jl")
include("graph.jl")


### Operations to be used in the Individual Graph ###
struct IndividualOperations
    combinations::Array{Function,1}
    union::Function
    intersect::Function
    xor::Function
    negation::Function
end

or(a::Bool, b::Bool) = a || b
and(a::Bool, b::Bool) = a && b
negate(a::Bool) = !a

combinations = [and, or, xor]
operations = IndividualOperations(combinations, or, and, xor, negate)


### Definition of the Individual Struct and Initialization###
struct Individual
    graph
    gene_param
    gene_settings
    operations
end

function Individual(gene_param, gene_settings, operations::IndividualOperations=operations)
    Individual(graph(0, operations, gene_param, gene_settings), gene_param, gene_settings, operations)
end

Individual(ind::Individual) = Individual(graph(0, ind.operations, ind.gene_param, ind.gene_settings), 
                                         ind.gene_param, ind.gene_settings, ind.operations)

Individual(ind::Individual, graph) = Individual(graph, ind.gene_param, ind.gene_settings, ind.operations)


function graph(depth::Int64, operations::IndividualOperations, gene_param, gene_settings)
    if depth == 0
        Gene(gene_param, gene_settings)
    else
        Dict(operations.combinations[rand(1:3)] => 
            Any[graph(depth-1, operations, gene_param, gene_settings),
             graph(depth-1, operations, gene_param, gene_settings)])
    end
end 
    
graph(depth::Int64, ind::Individual) = graph(depth, ind.operations, ind.gene_param, ind.gene_settings)
    
    
depth(ind::Individual) = depth(ind.graph)
cardinality(ind::Individual) = cardinality(ind.graph)

subgraph_ref_and_index(ind::Individual, go_two_levels::Bool=false) = subgraph_ref_and_index(ind.graph, go_two_levels)    

### Activation and Print Functions###    
activate(input::Array{Float64,2}, individual::Individual) = node_activation(input, individual.graph)
    
function node_activation(input::Array{Float64,2}, graph_node)
    if typeof(graph_node) == Gene
          activate(input, graph_node)
    else
        computation = collect(keys(graph_node))[1]
        arguments = collect(values(graph_node))[1]
        computation.([node_activation(input, child) for child in arguments]...)
    end
end
        

print(individual::Individual) = print_graph(individual.graph)      
function print_graph(node, pre_indent=0, indent=4)
    if typeof(node) == Gene
        println( " " ^ pre_indent * "Gene" )
        return
    end
    for (key, values) in node
        if typeof(values) == Gene
            println( " " ^ pre_indent * "Gene" )
            continue
        end
        println( " " ^ pre_indent  * string(key))
        [print_graph(value, pre_indent + indent) for value in values]         
    end
    nothing 
end