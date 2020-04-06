include("../training/loss/random_bench.jl");
include("../genetic/visualization.jl");

using Plots
plt = Plots
using PlotlyJS
pty = PlotlyJS
using Parameters


mutable struct PSOState
    particles
    best_scores
    score_function
    i::Int64
end

function plot_evolution(plot_choice, state::PSOState; kwargs...)
    if plot_choice == "plot_scores"
        plot_function = plot_scores
    elseif plot_choice == "plot_particles"
        plot_function = plot_particles
    elseif plot_choice == nothing
        return
    end 
    IJulia.clear_output(true)
    display(plot_function(state; kwargs...))
end
            
function plot_scores(state::PSOState; kwargs...)
    @unpack best_scores, i = state
    plot_scores(best_scores, i)
end
                
function plot_scores(best_scores, i)
    latest = best_scores[i]
    plt.plot(best_scores, xlim=(0, length(best_scores)), title="$latest")
end
            
function plot_particles(state::PSOState; kwargs...)
    @unpack particles, score_function = state
    plot_genes(particles, score_function, kwargs[:reference])
end