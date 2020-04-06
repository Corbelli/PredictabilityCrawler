include("individual.jl")
include("../utils/sample.jl")

compose_and(graphs, operations::IndividualOperations) = Dict(operations.intersect => graphs)
compose_or(graphs, operations::IndividualOperations) = Dict(operations.union => graphs)
compose_xor(graphs, operations::IndividualOperations) = Dict(operations.xor => graphs)
compose_negate(graph, operations::IndividualOperations) = Dict(operations.negation => graph)


function complement_offsprings(ind1::Individual, ind2::Individual)
    operations = ind1.operations
    offsprings = [
        Individual(ind1, compose_and(Any[ind1.graph, ind2.graph], operations)),
        Individual(ind1, 
            compose_and(Any[compose_negate(Any[ind1.graph], operations), ind2.graph], operations)),
        Individual(ind1, compose_or(Any[ind1.graph, ind2.graph], operations)),
        Individual(ind1, compose_xor(Any[ind1.graph, ind2.graph], operations))
    ]
end


function exchange(big_ind::Individual, small_ind::Individual)
    if depth(big_ind) < 3
        throw("Biger Individual must be already depth 3 for exchange crossover")
    end
    if depth(small_ind) < 2
        ref1, index1 = subgraph_ref_and_index(big_ind, true);
        temp1 = ref1[index1]
        temp2 = small_ind.graph
        ref1[index1] = temp2
        return big_ind, Individual(big_ind, temp1)
    else
        go_two_levels = depth(small_ind) == 3 && random_chance()
        ref1, index1 = subgraph_ref_and_index(big_ind, go_two_levels);
        ref2, index2 = subgraph_ref_and_index(small_ind, go_two_levels);
        temp1 = ref1[index1]
        temp2 = ref2[index2]
        ref1[index1] = temp2
        ref2[index2] = temp1
        return big_ind, small_ind
    end
end
    
function exchange_crossover(ind1::Individual, ind2::Individual)
    temp1 = deepcopy(ind1)
    temp2 = deepcopy(ind2)
    if depth(ind1) >= depth(ind2)
        offsprings = exchange(temp1, temp2)
        return offsprings
    else
        offsprings = exchange(temp2, temp1)
        return offsprings
    end
    
end
            
            
function crossover(ind1::Individual, ind2::Individual)
    if depth(ind1) >= 3 || depth(ind2) >= 3
        exchange_crossover(ind1, ind2)
    else
        complement_offsprings(ind1, ind2)
    end
end

            
function mutate(ind::Individual)
    _depth = depth(ind)
    _ind = deepcopy(ind)
    if _depth == 0
        return Individual(ind)
    else
        go_two_levels = _depth > 1 ? random_chance() : false
        ref, i = subgraph_ref_and_index(_ind.graph, go_two_levels)
        ref[i] = graph(_depth - 1 - Int(go_two_levels), ind)
    end
    return _ind
end
 