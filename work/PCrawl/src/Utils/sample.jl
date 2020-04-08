random_chance_int(percentage::Int64=50) = rand(1:100) <= percentage

random_chance_float(percentage::Float64=.5) = rand(1:10000) <= Int64(round(percentage*10000))

function random_chance(percentage::Union{Int64, Float64})
    if typeof(percentage) == Float64
        return random_chance_float(percentage)
    elseif typeof(percentage) == Int64
        return random_chance_int(percentage)
    else
        error("Type of percentage not allowed")
    end
end

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
