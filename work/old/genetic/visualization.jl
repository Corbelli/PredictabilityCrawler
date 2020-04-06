include("../training/loss/random_bench.jl");
using Plots
plt = Plots
using PlotlyJS
pty = PlotlyJS
using Parameters

mutable struct State
    population
    scores
    score_function
    best_scores
    i::Int64
end

function plot_evolution(plot_choice, state::State;kwargs...)
    if plot_choice == "plot_scores"
        plot_function = plot_scores
    elseif plot_choice == "plot_pop"
        plot_function = plot_pop
    elseif plot_choice == "plot_conf"
        plot_function = plot_conf
    elseif plot_choice == "plot_genes"
        plot_function = plot_genes
    end 
    IJulia.clear_output(true)
    display(plot_function(state; kwargs...))
end

function plot_scores(state::State; kwargs...)
    @unpack best_scores, i = state
    plot_scores(best_scores, i)
end
                
function plot_scores(best_scores, i)
    latest = best_scores[i]
    plt.plot(best_scores, xlim=(0, length(best_scores)), ylim=(5, 9), title="$latest")
end
     
function plot_pop(state::State; kwargs...)
    @unpack population, score_function = state
    plot_pop(population, score_function, kwargs[:nr])
end
            
function plot_pop(population, score_function, nr)
    scores = score_func(population)
    activations =  activate.(nothing, population[sortperm(scores, rev=true)[1:nr]])
    plt.plot(activations, layout=(1, nr), ylim=(0,1), size=(700, 200))      
end
    
confidence(activations) =  sum(hcat([Int.(activation) for activation in activations]...), dims=2)
voting(results) =  hcat([Int.(result[2]) for result in results]...)


function plot_conf(state::State; kwargs...)
    @unpack population = state
    plot_conf(population)
end            

function plot_conf(population)
    activations = activate.(nothing, population)
    confidence_signal = confidence(activations)
    plt.plot(confidence_signal)   
end

function plot_genes(state::State; kwargs...)
    @unpack population, score_function, i = state
    plot_genes(population, score_function, kwargs[:reference], i)
end
               
function plot_genes(population, score_function, reference, i="Population")
    xp, yp , zp = score_points(population, score_function, reference);
    plt.scatter3d(xp, yp, zp, markersize=1, markercolor="red", xlim=(0,1), ylim=(30, 3000), zlim=(0,13))
    plt.plot!([1], [100], [10], markercolor="yellow", title="$i", markersize=5, st=:scatter3d)
end