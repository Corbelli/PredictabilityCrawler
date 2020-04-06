using ..PrevisibilityCrawler.Evolutionary: score_points
using ..PrevisibilityCrawler: plt
using IJulia
include("intervals.jl");


mutable struct PSOState
    particles::Union{Nothing, Vector{Particle}}
    best_scores::Union{Nothing, Vector{Float64}}
    mean_scores::Union{Nothing, Vector{Float64}}
    score_function::Union{Nothing, Function}
    iters::Union{Int64, Nothing}
    i::Union{Int64, Nothing}
    meta::Dict{Symbol, Any}
    
    PSOState(;particles=nothing, best_scores=nothing, mean_scores=nothing,
    score_function=nothing, iters=nothing, i=nothing, meta=Dict{Symbol, Any}()) = 
    new(particles, best_scores, mean_scores, score_function, iters, i, meta)
end

function setstate!(state::PSOState; kwargs...)
    for symbol in keys(kwargs)
        symbol in fieldnames(PSOState) && setfield!(state, symbol, kwargs[symbol])
    end
end

function plot_evolution(plotchoice::String, state::PSOState; kwargs...)
    plotfunction = nothing
    if plotchoice == "score"
        plotfunction = plot_scores
    elseif plotchoice == "particles"
        plotfunction = plot_particles
    elseif plotchoice == "snr_size"
        plotfunction = plot_size_snr 
    end 
    plotfunction == nothing && return
    if !haskey(kwargs, :silent)
        IJulia.clear_output(true)
        display(plotfunction(state; kwargs...))
    else
        plotfunction(state; kwargs...)
    end
end
        
function plot_size_snr(state::PSOState; kwargs...)
   haskey(state.meta, :sizes) || (state.meta[:sizes] = fill(NaN, state.iters))
   haskey(state.meta, :snrs) || (state.meta[:snrs] = fill(NaN, state.iters))
   size, snr = get_size_snr(state.particles, kwargs[:reference], state.score_function)
   state.meta[:sizes][state.i] = size/count(kwargs[:reference])
   state.meta[:snrs][state.i] = snr
    if !haskey(kwargs, :silent)
        plt.plot([state.meta[:sizes], state.meta[:snrs]], labels=["size", "snr"])
    end
end
            
function plot_scores(state::PSOState; kwargs...)
    plot_scores(state.best_scores, state.mean_scores,  state.i)
end
                
function plot_scores(best_scores, mean_scores, i)
    latest = best_scores[i]
    plt.plot([best_scores, mean_scores], xlim=(0, length(best_scores)), title="$latest", labels=["Best","Mean"])
end
            
function plot_particles(state::PSOState; kwargs...)
    plot_genes(state.particles, state.score_function, kwargs[:reference])
end
        
    
function plot_genes(state::PSOState; kwargs...)
    plot_genes(state.population, state.score_function, kwargs[:reference], state.i)
end
               
function plot_genes(population, score_function, reference, i="Population")
    xp, yp , zp = score_points(population, score_function, reference);
    plt.scatter3d(xp, yp, zp, markersize=1, markercolor="red", xlim=(0,1), ylim=(30, 2000), zlim=(0,2))
    plt.plot!([1], [100], [10], markercolor="yellow", title="$i", markersize=5, st=:scatter3d)
end