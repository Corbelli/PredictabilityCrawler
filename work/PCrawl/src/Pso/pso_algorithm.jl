include("visualization.jl");
using ProgressMeter


mutable struct PSO
    phip::Float64
    phig::Float64
    w::Float64
    K::Int64
    max_iter::Int64
    
    PSO(; phip=.3, phig=.1, w=.5, K=3, max_iter=100) = new(phip, phig, w, K, max_iter)
end

function pso(particles::Vector{Particle}, scorefunction::Function, settings::PSO, 
                plot_choice::Union{String, Nothing}=nothing; kwargs...)
    updatenetwork(particles, settings)
    bests = repeat([NaN], settings.max_iter)
    means = repeat([NaN], settings.max_iter)
    best_global = best_particle(particles).value
    state = PSOState(iters=settings.max_iter, score_function=scorefunction) 
    p = Progress(settings.max_iter, .5)   # minimum update interval: 1 second

    updatefunction(particle) = update_particle(particle, scorefunction, settings)
    for i in 1:settings.max_iter
        bests[i] = best_global
        means[i] = mean([p.value for p in particles if !isinf(p.value)])
        if haskey(kwargs, :restart) && haskey(kwargs, :minsamples) && any([i % R == 0 for R in kwargs[:restart]])
            key = findall([i%R==0 for R in kwargs[:restart]])[1]
            if key == 1
                particles = resetpop(particles, kwargs[:minsamples], scorefunction, settings)
            elseif key == 2
                scorefunction = kwargs[:scorefunction2]
                settings.K = 7
                updatenetwork(particles, settings)
                particles = map(updatefunction, particles)
                updategroupbeliefs(particles)
            end
        else
            particles = map(updatefunction, particles)
            updategroupbeliefs(particles)
        end
        best_global = update_best(particles, best_global, settings)
        setstate!(state ;particles=particles, best_scores=bests, mean_scores=means, i=i)
        plot_choice == "progress" && next!(p)
        plot_evolution(plot_choice, state; kwargs...)
    end
    graphs = Dict(:bests=>bests,:means=>means, :meta=>state.meta)
    return best_particle(particles), graphs
end


function update_best(particles::Vector{Particle}, bestglobal::Float64, settings::PSO)
    particle = best_particle(particles)
    if particle.value > bestglobal
        return particle.value
    else
        updatenetwork(particles, settings)
        return bestglobal
    end
end

function updategroupbeliefs(particles::Vector{Particle})
    for particle in particles
        particle.groupbelief = network_desire(particle, particles)
    end
end

function updatenetwork(particles::Vector{Particle}, settings::PSO)
    random_topology(particles, settings.K)
    updategroupbeliefs(particles)
end

function update_particle(particle::Particle, scorefunction::Function, settings::PSO)
    particle = update_vel_pos(particle, settings)
    signal = activate(particle)
    particle.value = scorefunction(signal)
    particle = update_position(particle, signal)
    particle = update_personal_belief(particle)   
end

function update_vel_pos(particle::Particle, pso::PSO)
    nr_dims = length(particle.position)
    rp = rand(Uniform(0, 1.193), nr_dims)
    rg = rand(Uniform(0, 1.193), nr_dims)
    personal_belief = pso.phip*rp.*personal_desire(particle)
    informants_belief = pso.phig*rg.*particle.groupbelief
    particle.velocities = particle.velocities*pso.w +  personal_belief + informants_belief
    particle.position = particle.position + particle.velocities
    return clip(particle)
end


function resetpop(particles::Vector{Particle}, minsamples::Int64 ,scorefunction::Function, settings::PSO)
    popsize = length(particles)
    best = deepcopy(best_particle(particles))
    pop = Particle.(init_intervals(popsize-1, best.settings.group_size, best.settings.n, 
                                   minsamples=minsamples), scorefunction);
    new_pop = [pop; best]
    updatenetwork(new_pop, settings)
    return new_pop
end