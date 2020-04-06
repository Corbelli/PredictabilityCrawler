include("../utils/sample.jl")

function is_negated(graph)
    if typeof(graph) == Gene
        return false
    end
    children = collect(values(graph))[1]
    typeof(children) != Gene && length(children) == 1
end

function child_path(graph)
    if typeof(graph) == Gene
        throw("Cannot get child : Graph passed is already in last level")
    end
    key = sample(collect(keys(graph)))
    key, sample(1:length(graph[key]))
end

function depth(graph)
    if typeof(graph) == Gene
        return 0
    else
        increment = is_negated(graph) ? 0 : 1
        return max([depth(child) for child in collect(values(graph))[1]]...) + increment
    end
end

function subgraph_path(graph, go_two_levels=false)
    if depth(graph) == 0
        throw("Individual Graph must be at least depth 1 for subgraphing")
    elseif depth(graph) == 1 && go_two_levels
        throw("Cannot go two levels on Individual of depth 1")
    end
    kvs = []
    push!(kvs, child_path(graph)...)
    subgraph = graph[kvs[1]][kvs[2]]
    if go_two_levels
        negated = 0 
        if is_negated(subgraph)
            push!(kvs, child_path(subgraph)...)
            subgraph = subgraph[kvs[3]][kvs[4]]
            negated = 1
        end
        if typeof(subgraph) == Gene
            return kvs
        end
        push!(kvs, child_path(subgraph)...)
        subgraph = subgraph[kvs[3 + 2*negated]][kvs[4 + 2*negated]]    
    end
    if is_negated(subgraph) && random_chance()
        return push!(kvs, child_path(subgraph)...)
    end
    return kvs
end

function subgraph_ref_and_index(graph, go_two_levels=false)
    path = subgraph_path(graph, go_two_levels)
    i = 1
    temp = graph
    while i < length(path)
        temp = temp[path[i]]
        i = i + 1
    end
    return temp, path[end]
end
        
function cardinality(graph)
    if typeof(graph) == Gene
        return 1
    else
        return sum([cardinality(child) for child in collect(values(graph))[1]])        
    end
end