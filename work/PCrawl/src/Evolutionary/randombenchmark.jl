using ..PCrawl.Utils: uniq_rand
using Distributed

include("ga.jl")

function random_activation(size::Int64, snr::Float64, reference)
    signals = findall(x->x==1, reference)
    noises = findall(x->x==0, reference)
    nr_signal = Int(round(snr*size))
    spots = []
    try
        spots = [uniq_rand(noises, size - nr_signal); uniq_rand(signals, nr_signal)]
    catch
        return nothing
    end
    choosen = repeat([false], length(reference))
    [choosen[i] = true for i in spots]
    return convert(BitArray{1}, choosen)
end
    
function random_activation(size::Int64, datasetsize::Int64)
    spots = uniq_rand(1:datasetsize, size)
    choosen = repeat([false], datasetsize)
    [choosen[i] = true for i in spots]
    return convert(BitArray{1}, choosen)
end

function error_surface_point(size, snr, reference, score_function)
    activation = random_activation(size, snr, reference)
    score = activation == nothing ? NaN : score_function(activation)[1]
    return snr, size, score
end
    
function error_surface_point(size::Int64, datasetsize::Int64, score_function::Function)
    activation = random_activation(size, datasetsize)
    score = activation == nothing ? NaN : score_function(activation)[1]
    return size, score
end

function random_points(nr_points::Int64, sizes, snrs, reference::BitArray{1}, score_func::Function)
    x = Vector{Float64}(undef, nr_points)
    y = Vector{Float64}(undef, nr_points)
    z = Vector{Float64}(undef, nr_points)
    for i=1:nr_points
        x[i], y[i], z[i] = error_surface_point(rand(sizes, 1)[1], rand(snrs, 1)[1], reference, score_func)
    end
    return x, y, z   
end
    
function random_points(nr_points::Int64, sizes, datasetsize::Int64, score_func::Function)
    x = Vector{Float64}(undef, nr_points)
    y = Vector{Float64}(undef, nr_points)
    for i=1:nr_points
        x[i], y[i]  = error_surface_point(rand(sizes, 1)[1], datasetsize, score_func)
    end
    return x, y
end

function score_points(population, score_func, reference)
    points = [point(gene, score_func, reference) for gene in population]
    x = [point[1] for point in points]
    y = [point[2] for point in points]
    z = [point[3] for point in points]
    return x, y, z
end
    
function point(gene, score, reference)
    activation = activate(gene)
    selected = reference[activation]
    y = count(activation)
    z = score(gene)
    x = sum(selected)/length(selected)
    return x, y, z
end