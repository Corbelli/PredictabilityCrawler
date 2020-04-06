include("pso_algorithm.jl")


using ..PrevisibilityCrawler: plt, pty
import ..PrevisibilityCrawler.Evolutionary: benchmark
using Statistics, ProgressMeter, DataFrames

function benchmark(nrparticles::Int64, settings::PSO, initfunction::Function, scorefunction::Function,
                   groupsize::Int64, x, minsamples::Int64; kwargs...)
    graphs = Array{Dict}(undef, 30)
    @showprogress 1 "Computing..." for i in 1:30
        particles = Particle.(initfunction(nrparticles, groupsize, x, minsamples=minsamples), scorefunction);
        pop, graphs[i] = pso(particles, scorefunction, settings, "snr_size", silent=true; kwargs...);
    end
    return graphs
end


# function benchmark(nrparticles::Int64, settings::PSO, initfunction::Function, scorefunction::Function,
#                    groupsize::Int64, x, minsamples::Int64; kwargs...)
#     nrtrials = 30
#     populations = [Particle.(initfunction(nrparticles, groupsize, x, minsamples=minsamples), scorefunction)
#                    for i in 1:nrtrials]
#     @showprogress map(populations) do particles
#         pop, graph =  pso(particles, scorefunction, settings, "snr_size", silent=true; kwargs...);
#         return graph
#     end
#     return graphs
# end