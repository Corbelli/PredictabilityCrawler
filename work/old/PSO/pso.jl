include("pso_particle.jl");
include("intervals.jl");
include("visualization.jl");


struct PSO
    phip::Float64
    phig::Float64
    w::Float64
    K::Int64
    max_iter::Int64
end


function PSO(; phip=.3, phig=.1, w=.5, K=3, max_iter=100)
    PSO(phip, phig, w, K, max_iter)
end

function pso(particles, score_function, settings::PSO, plot_choice=nothing; kwargs...)
    random_topology(particles, settings.K)
    bests = repeat([NaN], settings.max_iter)
    best_particles = []
    best_global = best_particle(particles).value
    for i in 1:settings.max_iter
        bests[i] = best_global
        particles = [update_particle(particle, score_function, particles, settings) for particle in particles]
        best_global = update_best(particles, best_global, settings)
        state = PSOState(particles, bests, score_function, i)
        push!(best_particles, deepcopy(best_particle(particles)))
        plot_evolution(plot_choice, state; kwargs...)
    end
    return sort(best_particles, by=x->x.value, rev=true)[1:length(particles)]
end


function update_best(particles, best_global, settings)
    particle = best_particle(particles)
    if particle.value > best_global
        return particle.value
    else
        random_topology(particles, settings.K)
        return best_global
    end
end

function update_particle(particle, score_function, particles, settings::PSO)
    particle = update_vel_pos(particle, particles, settings)
    signal = activate(nothing, particle)
    particle.value = score_function(signal)
    particle = update_position(particle, signal)
    particle = update_personal_belief(particle)   
end

function update_vel_pos(particle::Particle, particles, pso::PSO)
    nr_dims = length(particle.position)
    rp = rand(Uniform(0, 1.193), nr_dims)
    rg = rand(Uniform(0, 1.193), nr_dims)
    personal_belief = pso.phip*rp.*personal_desire(particle)
    informants_belief = pso.phig*rg.*network_desire(particle, particles)
    particle.velocities = particle.velocities*pso.w +  personal_belief + informants_belief
    particle.position = particle.position + particle.velocities
    return clip(particle)
end


