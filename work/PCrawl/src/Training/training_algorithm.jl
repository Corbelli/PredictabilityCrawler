using DataFrames
using ..PCrawl.Utils: value1d
using ..PCrawl.Learning: Pipeline, crossvalidation!
using ..PCrawl.Evolutionary: Gene
using ..PCrawl.Pso: RandomIntervals, Particle, activate

struct Algorithm
    previsibilityloss::Function
    minsamples::Int64
    benchmark::Bool
    k::Int64
    Algorithm(previsibilityloss; minsamples, benchmark=false, k=1) = new(previsibilityloss, minsamples, benchmark, k)
end
 
is_interval(x) = typeof(x) == BitArray{1} || typeof(x) == UnitRange{Int64} ? true : false
is_onlyone(x) = is_interval(x)||typeof(x)==Gene||typeof(x)==RandomIntervals||typeof(x)==Particle

function trainingfunction(inputs::Array{Float64, 2}, outputs::Array{Float64, 2}, state::Algorithm, pipe::Pipeline)
    function score(individual)
        predsignal = is_interval(individual) ? individual : activate(individual);
        x = inputs[predsignal, :]
        y = outputs[predsignal, :]
        if size(x, 1) >= state.minsamples
            trainloss, testloss = crossvalidation!(pipe, x, y; k=state.k)
            state.benchmark && return testloss, predsignal
            return state.previsibilityloss(testloss, y, size(inputs, 1))
        end
        return -Inf
    end
end
    
trainingfunction(inputs::DataFrame, outputs::Array{Float64, 2}, state::Algorithm, pipe::Pipeline) = 
    trainingfunction(convert(Matrix, inputs), outputs, state, pipe)
 

function training(inputs, outputs, state::Algorithm, pipe::Pipeline)
    score = trainingfunction(inputs, outputs, state, pipe)
    function funcion_vec_score(pop)
        is_onlyone(pop) && return score(pop)
        score.(pop)
    end
end

function ptraining(inputs, outputs, state::Algorithm, pipe::Pipeline)
    score = trainingfunction(inputs, outputs, state, pipe)
    function function_vec_score(pop)
        is_onlyone(pop) && return score(pop)
        n = length(pop)
        results = Array{Float64}(undef, n)
        Threads.@threads for i = 1:n
            results[i] = score(pop[i])
        end
        results
    end
end



