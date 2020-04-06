random_chance(percentage::Int64=50) = rand(1:100) <= percentage

function sample(array, size::Int64=1, replacement::Bool=false)
    if replacement
        return size == 1 ? array[rand(1:length(array), size)][1] : array[rand(1:length(array), size)]
    else
        return size == 1 ? array[uniq_rand(1:length(array), size)][1] : array[uniq_rand(1:length(array), size)]
    end
    
end
    
function sample_pop!(array, size::Int64=1)
    indices = uniq_rand(1:length(array), size)
    elements = array[indices]
    deleteat!(array, sort(indices))
    return elements
end
    
function uniq_rand(_range, nr::Int64)
    gambled = distinct(rand(_range, nr))
    if length(collect(_range)) < nr
        throw(BoundsError("Trying to sample a number of distintic indexes greater than vector length"))
    end
    while length(gambled) != nr
        gambled =  distinct(push!(gambled,rand(_range)))
    end
    return gambled
end
    
distinct(list) = collect(keys(Dict(el=>nothing for el in list)))
