include("../utils/folding.jl")
include("../utils/manipulation.jl")
include("../genetic/individual.jl")


#include("loss/gittins/gittins.jl")
include("loss/loss.jl")
using GLMNet, Distributions
using ScikitLearn

#Training Function To Use with a Scikit-learn Model

# Compute Cross-Validation in the test sample, computing the predictability signal given by each individual,
# trainig the model acording to this signal and assigning the score of each trained model in
# the generalization sample to each individual according to the performance obtained when the 
# samples are selected according to that individual guess

function sk_train_predict(model)
    function train_predict(x_train, y_train, x_test)
        ScikitLearn.fit!(model, x_train, y_train)
        ScikitLearn.predict(model, x_test)
    end
end


function get_sk_score_function(model, df, target, loss_func=hoot_loss, threshold=0.1, folding=jnfolding(.75, 15))
    function score(individual)
        loss = []
        pred_signal = activation(individual, df, threshold);
        x, y = value(normalize(df[pred_signal, :])), normalize(target[pred_signal, :])
        if size(x, 1) > 20
            for (train, test) in folding(x)
                x_train, x_test = x[train, :], x[test, :]
                y_train, y_test = value1d(y[train, :]), value1d(y[test, :])
                ScikitLearn.fit!(model, x_train, y_train)
                loss = push!(loss, mse(ScikitLearn.predict(model, x_test), y_test, pred_signal))
            end
            return 1 - (mean(loss) + std(loss)*((1/15) +  (.25/.75))) , pred_signal 
        end
        return -Inf, pred_signal
    end
    score_vec(population) = score.(population)
end


