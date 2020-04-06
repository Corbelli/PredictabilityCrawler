using Plots
using Distributions
using Distributed


mutable struct IntervalSettings
    group_size::Int64
    offset::Int64
    n::Int64 
end

mutable struct Particle
    position::Vector{Float64}
    velocities::Vector{Float64}
    value::Union{Float64, Nothing}
    best_know_position::Vector{Float64}
    best_know_value::Union{Float64, Nothing}
    groupbelief::Union{Vector{Float64}, Nothing}
    informants::Set{Int64}
    ranges::Vector{Vector{Float64}}
    settings::IntervalSettings
end

best_particle(particles::Vector{Particle}) = particles[sortperm([p.value for p in particles])[end]]


function Particle(ranges::Vector{Vector{Float64}}, score_function::Function)
    position = init_position(ranges)
    vel_bounds = [abs(range[2] - range[1]) for range in ranges]
    velocities = [rand(Uniform(-vel_bound, vel_bound), 1)[1] for vel_bound in vel_bounds]
    particle = Particle(position, velocities, nothing, position, nothing, nothing, Set([]), ranges, nothing) 
    particle.value = score_function(particle)
    particle.best_know_value = particle.value
    return particle
end

function random_topology(particles::Vector{Particle}, K::Int64=3)
    _range = 1:length(particles)
    _ = [particle.informants = Set([]) for particle in particles]
    for i=_range
        for index in rand(_range, K)
            push!(particles[index].informants, i)
        end
        push!(particles[i].informants, i)
    end 
end

function best_informant(particle::Particle, particles::Vector{Particle})
    informants = collect(particle.informants)
    best = sort(particles[informants], by=x->x.value)[end]
end

function network_desire(particle::Particle, particles::Vector{Particle})
    best_informant_position = best_informant(particle, particles).position
    return best_informant_position - particle.position
end

function init_position(ranges::Vector{Vector{Float64}})
    nr_dims = length(ranges)
    [rand(Uniform(ranges[i]...), 1)[1] for i in 1:nr_dims]
end

personal_desire(particle::Particle) = particle.best_know_position - particle.position

function clip(particle::Particle)
    ranges = particle.ranges
    nr_dims = length(particle.position)
    for i = 1:nr_dims
        particle.position[i], cliped = clip(particle.position[i], ranges[i]) 
        if cliped
            particle.velocities[i] = 0
        end
    end
    return particle
end
            
function clip(value::Float64, range::Vector{Float64})
    if value < range[1]
        return range[1], true
    elseif value > range[2]
        return range[2], true
    else
        return value, false
    end
end

function update_personal_belief(particle::Particle)
    if particle.value > particle.best_know_value
        particle.best_know_position = particle.position
        particle.best_know_value = particle.value
    end
    return particle
end
        
        
function update_position(particle::Particle, signal)
    offset = particle.settings.offset
    group_size = particle.settings.group_size
    n = particle.settings.n
    q, r = divrem(n - offset, group_size)
    alphas = []
    offset != 0 && push!(alphas, count(signal[1:offset])/offset)
    for i=1:q
        slice = signal[group_size*(i-1) + 1:group_size*i]
        push!(alphas, count(slice)/group_size)
    end
    if r != 0
        slice = signal[group_size*q + 1:end]
        push!(alphas, count(slice)/group_size)
    end
    particle.position = alphas
    return particle
end
        
function update_personal_belief(particles::Vector{Particle})
    if particle.value > particle.best_know_value
        particle.best_know_position = particle.position
        particle.best_know_value = particle.value
    end
    return particle
end
