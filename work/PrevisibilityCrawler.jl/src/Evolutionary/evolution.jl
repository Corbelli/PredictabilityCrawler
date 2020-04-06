include("visualization.jl")
using ..PrevisibilityCrawler.Utils: random_chance, sample, flat
import DataFrames: select
using Statistics: mean
using ProgressMeter

struct EvolSettings
    pressure::Int64
    mutation_p::Int64
    crossover_p::Int64
    elitism::Int64
end
        
function EvolSettings(;pressure=5, mutation_p=10, elitism=3, crossover_p=90)
    EvolSettings(pressure, mutation_p, crossover_p, elitism)
end

function tournament_selection(scores::Vector{Float64}, tournament_size::Int64=2)
    indexed_results = [(result, index) for (result, index) in zip(scores, 1:length(scores))];
    participants = indexed_results[sample(1:length(scores), tournament_size)]
    sorted = sort(participants, by=x -> x[1], rev=true)
    winner = sorted[1][2]
end

#::Vector{Gene}
function select(population::Vector{Gene}, nr_offsprings::Int64, scores::Vector{Float64}, settings::EvolSettings)
    mates = Vector{Vector{Gene}}(undef, 0)
    offsprint_count = 0
    while offsprint_count < nr_offsprings
        parent1 = tournament_selection(scores, settings.pressure)
        parent2 = tournament_selection(scores, settings.pressure)
        push!(mates, deepcopy(population[[parent1, parent2]]))
        offsprint_count += 2  
    end
    return mates
end
        
function get_offsprings(mates::Vector{Vector{Gene}}, settings::EvolSettings)
    n = length(mates)
    offsprings = Vector{Any}(undef, n)
    for i = 1:n
        if random_chance(settings.crossover_p)
            offsprings[i] = crossover(mates[i][1], mates[i][2])
        else
            offsprings[i] = mates[i]
        end
    end
    return convert(Vector{Gene}, flat(offsprings))
end
    
function mutate(offspring::Vector{Gene}, settings::EvolSettings)
    for (i, individual) in enumerate(offspring)
        random_chance(settings.mutation_p) && (offspring[i] = mutate(individual))
    end
    return offspring
end
 
function evolve(population::Vector{Gene}, scores::Vector{Float64}, settings::EvolSettings)
    nr_offsprings = length(population) - settings.elitism
    elite = population[sortperm(scores, rev=true)[1:settings.elitism]]
    mates = select(population, nr_offsprings, scores, settings)
    offspring = get_offsprings(mates, settings)
    offspring = mutate(offspring, settings)
    new_generation = [elite; offspring][1:length(population)]
end 

function knnscores(population::Vector{Gene}, score_function::Function, k::Int64=10)
    scores = score_function(population)
    evolve_scores = Vector{Float64}(undef, length(scores))
    for (index, gene) in enumerate(population) 
        distances = zip([distance(gene, gene2) for gene2 in population], 1:length(population))
        knn = sort(collect(distances), by=x->x[1])[1:k]
        valid = [x[2] for x in knn if !isinf(scores[x[2]])]
        evolve_scores[index] = isnan(mean(scores[valid])) ? -Inf : mean(scores[valid])
    end
    return scores, evolve_scores
end

function evolution(population::Vector{Gene}, score_function::Function, generations::Int64,                                            settings::EvolSettings, plot_choice::Union{String, Nothing}; kwargs...)
    scores, kscores = knnscores(population, score_function, get(kwargs, :knn, 5))
    e_scores = haskey(kwargs, :knn) ? kscores : scores
    best_scores = fill(NaN, generations)
    mean_scores = fill(NaN, generations)
    p = Progress(generations, .5)   # minimum update interval: 1 second
    state = State()
    for i in 1:generations
        best_scores[i] = max(scores...)
        mean_scores[i] = mean(scores[.!isinf.(scores)])      
        setstate!(state; population=population, scores=scores, score_function=score_function, 
                  best_scores=best_scores, mean_scores=mean_scores, i=i, generations=generations)
        plot_evolution(plot_choice, state; kwargs...)
        if haskey(kwargs, :restart) && any([i % R == 0 for R in kwargs[:restart]])
            key = findall([i%R==0 for R in kwargs[:restart]])[1]
            if key == 1
                particles = resetpop(population, e_scores)
            elseif key == 2
                score_function = kwargs[:scorefunction2]
                population = evolve(population, e_scores, settings);
            end
            population = resetpop(population, e_scores)
        else
            population = evolve(population, e_scores, settings);
        end
        scores, kscores = knnscores(population, score_function, get(kwargs, :knn, 5))
        e_scores = haskey(kwargs, :knn) ? kscores : scores
        plot_choice == "progress" && next!(p)
    end 
    graphs = Dict(:bests=>best_scores,:means=>mean_scores, :meta=>state.meta)
    return population, graphs
end
    
    
