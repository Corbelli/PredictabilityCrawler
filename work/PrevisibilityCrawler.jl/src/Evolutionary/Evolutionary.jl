module Evolutionary
include("benchmark.jl")
export evolution, EvolSettings, GA, score_points, random_points, init_population, init_genes
export benchmark,benchgraph, getmetrics, compare_states, getstats, bloxplot, aggr, benchaggr_, plotstates
end