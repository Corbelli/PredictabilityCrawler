using Distributions
include("../utils/manipulation.jl");
include("pso_particle.jl");


mutable struct RandomIntervals
    group_size::Int64
    offset::Int64
    n::Int64
    alphas
end

mutable struct IntervalSettings
    group_size::Int64
    offset::Int64
    n::Int64 
end

function init_intervals(nr_intervals::Int64, group_size::Int64, x, offset::Int64=0)
    sample_size = size(x, 1)
    nr_alphas = Int(ceil((sample_size - offset)/group_size)) + Int(offset != 0)
    [RandomIntervals(group_size, offset, sample_size, one_interval(x, nr_alphas))
        for x in 1:nr_intervals]
end
    
function init_intervals(group_size::Int64, x, offset::Int64=0)
    sample_size = size(x, 1)
    nr_alphas = Int(ceil((sample_size - offset)/group_size)) + Int(offset != 0)
    RandomIntervals(group_size, offset, sample_size, rand(Uniform(0, .9), nr_alphas)) 
end

one_interval(index, size) = [i == mod(index, size) ? 1.0 : 0.0 for i in 1:size]



function activate(nothing, intervals::RandomIntervals)
    n = intervals.n
    dists = [Bernoulli(alpha) for alpha in intervals.alphas]
    offset = rand(dists[1], intervals.offset)
    has_off = intervals.offset != 0
    activate = flat([rand(dist, intervals.group_size) for dist in dists[1+has_off:end]])
    Bool.([offset; activate])[1:n]
end

function particle(intervals::RandomIntervals, score_function)
    nr_groups = Int(ceil((intervals.n - intervals.offset)/intervals.group_size)) + 
                Int(intervals.offset != 0)
    velocities = rand(Uniform(-1, 1), nr_groups)
    ranges = [[0, 1] for i in 1:nr_groups]
    settings = IntervalSettings(intervals.group_size, intervals.offset, intervals.n)
    particle = Particle(intervals.alphas, velocities, nothing, 
                        intervals.alphas, nothing, Set([]), ranges, settings) 
    particle.value = score_function(particle)
    particle.best_know_func = particle.value
    return particle
end

function interval(particle::Particle)
    RandomIntervals(particle.settings.group_size, particle.settings.offset,
                    particle.settings.n, particle.position)
end

activate(nothing, particle::Particle) = activate(nothing, interval(particle))

function classify(intervals::RandomIntervals)
    offset = repeat([intervals.alphas[1] > .5], intervals.offset)
    has_off = intervals.offset != 0
    signal = [repeat([alpha > .5], intervals.group_size) for alpha in intervals.alphas[1+has_off:end]]
    return [offset; flat(signal)][1:intervals.n]
end

classify(particle::Particle) = classify(interval(particle))

function change_groupsize(intervals::RandomIntervals, new_group_size)
    offset = intervals.offset
    activation = activate(nothing, intervals)[1 + offset:end]
    q, r = divrem(intervals.n - intervals.offset, new_group_size)
    new_alphas = []
    offset != 0 ? push!(new_alphas, intervals.alphas[0]) : nothing
    for i=1:q
        slice = activation[new_group_size*(i-1) + 1:new_group_size*i]
        push!(new_alphas, count(slice)/new_group_size)
    end
    if r != 0
        slice = activation[new_group_size*q + 1:end]
        push!(new_alphas, count(slice)/new_group_size)
    end
    RandomIntervals(new_group_size, offset, intervals.n, new_alphas)
end

function change_offset(intervals::RandomIntervals, new_offset)
    activation = activate(nothing, intervals)
    group_size = intervals.group_size
    q, r = divrem(intervals.n - new_offset, intervals.group_size)
    new_alphas = []
    if new_offset != 0
        push!(new_alphas, count(activation[1:new_offset])/new_offset)
    end
    for i=1:q
        slice = activation[group_size*(i-1) + 1:group_size*i]
        push!(new_alphas, count(slice)/group_size)
    end
    if r != 0
        slice = activation[group_size*q + 1:end]
        push!(new_alphas, count(slice)/group_size)
    end
    RandomIntervals(group_size, new_offset, intervals.n, new_alphas)
end

change_offset(p::Particle, score_func, new_offset) = 
        particle(change_offset(interval(p), new_offset), score_func)
