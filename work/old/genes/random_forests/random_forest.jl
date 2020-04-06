include("../gene.jl")

using DecisionTree
using Random

function random_out(input, diversity=0.4)
    n = size(input, 1)
    min_diversity = Int(round(n*diversity))
    n_signal = rand(min_diversity:(n - min_diversity))
    n_noise = n - n_signal
    shuffle!([repeat(["noise"], n_noise); repeat(["signal"], n_signal)])
end

struct Forest
    n_trees::Int64
    sample_portion::Float64
    n_features::Int64
    max_depth::Int64
end


Forest(;n_trees, n_features, sample_portion=.5, max_depth=3) = Forest(n_trees, sample_portion, n_features, max_depth)
random_forest(input, output, settings::Forest) = build_forest(output, input, settings.n_features, settings.n_trees, settings.sample_portion, settings.max_depth)
grow_forest(input, settings::Forest) = random_forest(input, random_out(input), settings)



Gene(input::Array{Float64,2}, settings::Forest) = Gene(grow_forest(input, settings), settings, input)

activation(values::Array{Float64,2}, random_forest, settings::Forest) =  apply_forest(random_forest, values) .== "signal"