include("../utils/manipulation.jl") # value1d
include("../utils/filters.jl") # exponential_smoothing

include("../genetic/individual.jl") # Individual, activation
include("../PSO/Intervals.jl") # Individual, activation



struct Algorithm
    folding
    smoothing
    loss
    pre_process
    train_and_predict
    aggregate_loss
    min_samples::Int64
    benchmark::Bool
end
 
function Algorithm(;folding, smoothing, loss, pre_process, train_and_predict, 
          aggregate_loss=mean, min_samples=40, benchmark=false)
    Algorithm(folding, smoothing, loss, pre_process, train_and_predict, 
          aggregate_loss, min_samples, benchmark)
end
    
is_interval(x) = typeof(x) == BitArray{1} || typeof(x) == UnitRange{Int64} ? true : false

function training_function(inputs::Array{Float64, 2}, outputs::Array{Float64, 2}, state::Algorithm)
    function score(individual)
        loss = []
        pred_signal = is_interval(individual) ? individual : activate(inputs, individual);
        x = inputs[pred_signal, :]
        y = outputs[pred_signal, :]
        if size(x, 1) > state.min_samples
#             for (train, test) in state.folding(x)
#                 x_train , y_train = state.pre_process(x[train, :], y[train, :])
#                 x_test , y_test = state.pre_process(x[test, :], y[test, :])
#                 prediction_test = state.train_and_predict(x_train, y_train, x_test)
#                 loss = push!(loss, state.loss(prediction_test, y_test))
#             end
            x, y = state.pre_process(x, y)
            prediction_test = state.train_and_predict(x, y, x)
            loss = state.loss(prediction_test, y)
            if state.benchmark
                return loss, pred_signal
            else
                return state.aggregate_loss(loss, pred_signal)
            end
        end
        return -Inf
    end
end


inov(gene, pop) = sum([sum(xor.(gene.dna, friend.dna)) for friend in pop])
function inov_score(population)
    inovs = [inov(gene, pop) for gene in population]
    inov_scores =  1 .+ .0(inovs  .- min(inovs...))./max(inovs...)
end
 

function training(df, target, state::Algorithm)
    score = training_function(df, target, state)
    function funcion_vec_score(pop)
        if typeof(pop) == Individual || is_interval(pop) || typeof(pop) == Gene || typeof(pop) == RandomIntervals || typeof(pop) == Particle
            score(pop)
        else
            score.(pop)
        end
    end
end

function p_training(df, target, state::Algorithm)
    score = training_function(df, target, state)
    function function_vec_score(pop)
        if typeof(pop) == Individual || is_interval(pop) || typeof(pop) == Gene || typeof(pop) == RandomIntervals
            score(pop)
        end
        n = length(pop)
        results = Array{Any}(UndefInitializer(), n)
        Threads.@threads for i = 1:n
            results[i] = score(pop[i])
        end
        results
    end
end



