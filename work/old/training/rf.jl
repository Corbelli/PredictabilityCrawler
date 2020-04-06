include("loss/loss.jl") # class, loss_functions ...
include("training.jl") # Algorithm
include("../utils/folding.jl") # kfolding, jnfolding

using DecisionTree

#Pre Process
rf_pre_process(x, y) = x, y/std(y)

#Train and Predict

function rf_train_and_predict(x_train, y_train, x_test)
    settings = Forest(;n_trees=20, sample_portion=.4, n_features=15, max_depth=4)
    y = reshape(y_train, length(y_train))
    model = random_forest(x_train, y, settings);
    pred = apply_forest(model, x_test);
end
    
# Definitions
    
rf_train(;kwargs...) = Algorithm(pre_process=rf_pre_process,
                                 train_and_predict=rf_train_and_predict,
                                 ;kwargs...)
    
