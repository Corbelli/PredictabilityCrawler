# Utilities
include("utils/manipulation.jl")

# Genes
include("genes/fuzzy_trees/fuzzy_tree.jl");
include("genes/random_forests/random_forest.jl");

# Training Setups
include("training/glmnet.jl")
include("training/sklearn.jl")


