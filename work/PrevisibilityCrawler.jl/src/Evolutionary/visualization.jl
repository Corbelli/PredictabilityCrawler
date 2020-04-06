using ..PrevisibilityCrawler: plt, pty
using IJulia
include("randombenchmark.jl")


mutable struct State
    population::Union{Vector{Gene}, Nothing}
    scores::Union{Vector{Float64}, Nothing}
    score_function::Union{Function, Nothing}
    best_scores::Union{Vector{Float64}, Nothing}
    mean_scores::Union{Vector{Float64}, Nothing}
    i::Union{Int64, Nothing}
    generations::Union{Int64, Nothing}
    meta::Dict{Symbol, Any}
    State(;population=nothing, scores=nothing, score_function=nothing, best_scores=nothing,                     mean_scores=nothing, i=nothing, generations=nothing, 
          meta=Dict{Symbol, Any}()) = new(population, scores, score_function,
          best_scores, mean_scores, i, generations, meta)
end

function setstate!(state::State; kwargs...)
    for symbol in keys(kwargs)
        symbol in fieldnames(State) && setfield!(state, symbol, kwargs[symbol])
    end
end

function plot_evolution(plot_choice, state::State;kwargs...)
    plotfunction = nothing
    if plot_choice == "score"
        plotfunction = plot_scores
    elseif plot_choice == "best_individuals"
        plotfunction = plot_pop
    elseif plot_choice == "confidence_signal"
        plotfunction = plot_conf
    elseif plot_choice == "genes"
        plotfunction = plot_genes
    elseif plot_choice == "snr_size"
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

function plot_size_snr(state::State; kwargs...)
   haskey(state.meta, :sizes) || (state.meta[:sizes] = fill(NaN, state.generations))
   haskey(state.meta, :snrs) || (state.meta[:snrs] = fill(NaN, state.generations))
   size, snr = get_size_snr(state.population, kwargs[:reference], state.score_function)
   state.meta[:sizes][state.i] = size/count(kwargs[:reference])
   state.meta[:snrs][state.i] = snr
   if !haskey(kwargs, :silent)
        plt.plot([state.meta[:sizes], state.meta[:snrs]], labels=["size", "snr"])
    end
end

function plot_scores(state::State; kwargs...)
    plot_scores(state.best_scores, state.mean_scores, state.i)
end

                
function plot_scores(best_scores, mean_scores, i)
    latest = best_scores[i]
    plt.plot(mean_scores)
    plt.plot([best_scores, mean_scores], xlim=(0, length(best_scores)), title="$latest", labels=["Best","Mean"])
end

     
function plot_pop(state::State; kwargs...)
    plot_pop(state.population, state.score_function, kwargs[:nr])
end
            
function plot_pop(population, score_function, nr)
    scores = score_func(population)
    activations =  activate.(nothing, population[sortperm(scores, rev=true)[1:nr]])
    plt.plot(activations, layout=(1, nr), ylim=(0,1), size=(700, 200))      
end
    
confidence(activations) =  sum(hcat([Int.(activation) for activation in activations]...), dims=2)
voting(results) =  hcat([Int.(result[2]) for result in results]...)


function plot_conf(state::State; kwargs...)
    plot_conf(state.population)
end            

function plot_conf(population)
    activations = activate.(nothing, population)
    confidence_signal = confidence(activations)
    plt.plot(confidence_signal)   
end

function plot_genes(state::State; kwargs...)
    xp, yp, zp = plot_genes(state.population, state.score_function, kwargs[:reference], state.i)
    haskey(state.meta, :x) || (state.meta[:x] = [])
    haskey(state.meta, :y) || (state.meta[:y] = [])
    haskey(state.meta, :z) || (state.meta[:z] = [])
    push!(state.meta[:x], xp)
    push!(state.meta[:y], yp)
    push!(state.meta[:z], zp)
end
               
function plot_genes(population, score_function, reference, i="Population")
    xp, yp , zp = score_points(population, score_function, reference);
    plt.scatter3d(xp, yp, zp, markersize=1, markercolor="red", xlim=(0,1), ylim=(30, 400), zlim=(5, 14))
    plt.plot!([1], [100], [10], markercolor="yellow", title="$i", markersize=5, st=:scatter3d)
    return xp, yp, zp
end