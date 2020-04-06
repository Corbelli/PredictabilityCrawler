include("individual.jl")
include("../utils/manipulation.jl")
include("../utils/filters.jl")
include("evolutionary_operations.jl")
include("visualization.jl")

struct EvolSettings
    pressure::Int64
    mutation_p::Int64
    elitism::Int64
    min_innovation::Int64
end
        
function EvolSettings(; pressure=5, mutation_p=10, elitism=3, min_innovation=20)
    EvolSettings(pressure, mutation_p, elitism, min_innovation)
end

function valid_individuals(size::Int64, operations::IndividualOperations, 
                           settings, score_function,  gene_param)
    population = [Individual(gene_param, settings, operations) for i in 1:size]
    results = score_function(population)
    survivors = [individual 
                 for (individual, result) in zip(population, results)
                 if result[1] > -Inf];
end

function init_population(gene_param, settings, size::Int64, score_function, 
                         individual_operations::IndividualOperations=operations)
    population = []
    while length(population) < size
        current_size = length(population)
        new = valid_individuals(size - current_size, individual_operations, 
                                settings, score_function, gene_param)
        if length(new) > 0
            push!(population, new...)
        end
    end
    return population
end

function tournament_selection(scores, winners=1, tournament_size=5)
    indexed_results = [(result, index) for (result, index) in zip(scores, 1:length(scores))];
    participants = indexed_results[sample(1:length(scores), tournament_size)]
    sorted = sort(participants, by=x -> x[1], rev=true)
    winners_index = sort([participant[2] for participant in sorted[1:winners]])
end
    

function get_mates(population, nr_offsprings, scores, settings::EvolSettings)
    mates = []
    offsprint_count = 0
    temp_pop = copy(population)
    temp_scores = copy(scores)
    while (offsprint_count < nr_offsprings) && (length(temp_pop) >= 2)
        pressure = length(temp_pop) > settings.pressure ? settings.pressure : length(temp_pop)
        remaining = nr_offsprings - offsprint_count
        nr_parents = remaining == 1 ? 1 : random_chance(settings.mutation_p) ? 1 : 2
        indexes = tournament_selection(temp_scores, nr_parents, pressure)
        push!(mates, temp_pop[indexes])
        deleteat!(temp_pop, indexes)
        deleteat!(temp_scores, indexes)
        offsprint_count = offsprint_count + nr_parents    
    end
    if length(temp_pop) == 1
        push!(mates, temp_pop[1])
    end
    return mates
end
        
function get_offsprings(mates)
    n = length(mates)
    offsprings = Array{Any}(UndefInitializer(), n)
    for i = 1:n
        if length(mates[i]) == 2
            offsprings[i] = crossover(mates[i][1], mates[i][2])
        else
            offsprings[i] = [mutate(mates[i][1])]
        end
    end
    return flat(offsprings)
end
 
function evolve(population, scores, score, settings::EvolSettings)
    nr_offsprings = length(population) - settings.elitism
    elite = population[sortperm(scores, rev=true)[1:settings.elitism]]
    mates = get_mates(population, nr_offsprings, scores, settings)
    offspring = get_offsprings(mates)
    candidates = [elite; offspring]
end  
    
function reset_pop(population, score_function, nr_to_keep=1)
    n = length(population)
    scores = score_function(population)
    best = deepcopy(population[sortperm(scores)[end-nr_to_keep+1:end]])
    pop = init_population(n-nr_to_keep, ga_settings, size(x)[1]);
    new_pop = [pop; best]
    return new_pop, score_function(new_pop)
end

function evolution(population, score_function, generations, settings::EvolSettings, plot_choice; kwargs...)
    scores = score_function(population)
    best_scores = repeat([NaN], generations)
    for i in 1:generations
        if i % 30 == 0
            population, scores = reset_pop(population, score_function)
        end
        population = evolve(population, scores, score_function, settings);
        scores = score_function(population)
        best_scores[i] = max(scores...)      
        state = State(population, scores, score_function, best_scores, i)
        plot_evolution(plot_choice, state; kwargs...)
    end 
    return population
end
    


    
