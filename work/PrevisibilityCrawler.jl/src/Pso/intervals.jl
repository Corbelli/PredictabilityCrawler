include("psoparticle.jl");
using Distributions
using ..PrevisibilityCrawler.Utils: flat, sample_pop!
import ..PrevisibilityCrawler.Evolutionary: activate

mutable struct RandomIntervals
    group_size::Int64
    offset::Int64
    n::Int64
    alphas::Vector{Float64}
end

function RandomIntervals(groupsize::Int64, x)
    samplesize = size(x, 1)
    nr_alphas, offset = divrem(samplesize, groupsize)
    offset != 0 && (nr_alphas += 1)
    RandomIntervals(groupsize, offset, samplesize, rand(Uniform(0, .4), nr_alphas)) 
end

function RandomIntervals(particle::Particle)
    RandomIntervals(particle.settings.group_size, particle.settings.offset,
                    particle.settings.n, particle.position)
end

function RandomIntervals(signal::Union{BitArray{1}, Vector{Bool}}, groupsize::Int64)
    samplesize = length(signal)
    nr_alphas, offset = divrem(samplesize, groupsize)
    offset != 0 && (nr_alphas += 1)
    println(offset)
    println(nr_alphas)
    alphas = Vector{Float64}(undef, nr_alphas)
    firstgroup = offset != 0 ? offset : groupsize
    alphas[1] = count(signal[1:firstgroup])/firstgroup
    _signal = signal[firstgroup+1:end]
    for i=1:(nr_alphas-1)
        slice = _signal[groupsize*(i-1) + 1:groupsize*i]
        alphas[i+1] = count(slice)/groupsize
    end
    return RandomIntervals(groupsize, offset, samplesize, alphas)
end

function random_init(nr_intervals::Int64, groupsize::Int64, x; kwargs...)
    return [RandomIntervals(groupsize, x) for i in 1:nr_intervals]
end



init_intervals(nr_intervals::Int64, groupsize::Int64, x; minsamples::Int64) = 
    init_intervals(nr_intervals, groupsize, size(x, 1); minsamples=minsamples)

function init_intervals(nr_intervals::Int64, groupsize::Int64, samplesize::Int64; minsamples::Int64)
    nr_alphas, offset = divrem(samplesize, groupsize)
    offset != 0 && (nr_alphas += 1)
    setsize =  Int64(ceil(minsamples/groupsize)) + 1
    indices = collect(1:nr_alphas)
    intervals = Vector{RandomIntervals}(undef, nr_intervals)
    for i=1:nr_intervals 
        if length(indices) < setsize
            remaining = setsize - length(indices)
            sampled = indices
            indices = collect(1:nr_alphas)
            sampled = [sampled;sample_pop!(indices, remaining)]
        else
            sampled = sample_pop!(indices, setsize)
        end
        alphas = repeat([0], nr_alphas)
        [alphas[j] = true for j in sampled]
        intervals[i] = RandomIntervals(groupsize, offset, samplesize, alphas)
    end
    return intervals
end

function activate(intervals::RandomIntervals)
    n = intervals.n
    dists = [Bernoulli(alpha) for alpha in intervals.alphas]
    offset = rand(dists[1], intervals.offset)
    has_off = intervals.offset != 0
    activate = flat([rand(dist, intervals.group_size) for dist in dists[1+has_off:end]])
    Bool.([offset; activate])[1:n]
end

activate(particle::Particle) = activate(RandomIntervals(particle))

function classify(intervals::RandomIntervals)
    offset = repeat([intervals.alphas[1] > .5], intervals.offset)
    has_off = intervals.offset != 0
    signal = [repeat([alpha > .5], intervals.group_size) for alpha in intervals.alphas[1+has_off:end]]
    return [offset; flat(signal)][1:intervals.n]
end

classify(particle::Particle) = classify(RandomIntervals(particle))

function change_groupsize(intervals::RandomIntervals, new_group_size::Int64)
    signal = activate(intervals)
    RandomIntervals(signal, new_group_size)
end

function Particle(intervals::RandomIntervals, scorefunction::Function)
    nr_groups = Int(ceil((intervals.n - intervals.offset)/intervals.group_size)) + Int(intervals.offset != 0)
    velocities = rand(Uniform(-1, 1), nr_groups)
    ranges = [[0., 1.] for i in 1:nr_groups]
    settings = IntervalSettings(intervals.group_size, intervals.offset, intervals.n)
    particle = Particle(intervals.alphas, velocities, nothing, intervals.alphas, nothing, nothing, Set([]),                             ranges, settings) 
    particle.value = scorefunction(particle)
    particle.best_know_value = particle.value
    return particle
end
    
function get_size_snr(population::Vector{Particle}, reference::BitArray{1}, scorefunction::Function)
   best = best_particle(population)
   solution = classify(best)
   size = count(solution)
   snr = count((.!xor.(reference, solution))[solution])/count(solution)
   return size, snr
end