include("loss/loss.jl") # class, loss_functions ...
include("training.jl") # Algorithm
include("../utils/folding.jl") # kfolding, jnfolding

using GLMNet, Distributions # GLMNet, Binomial

#Pre Process

glmnet_class_pre_process(x, y) = x, class(y, 0)
reg_pre_process(x, y) = x, y/std(y)

#Train and Predict

function glmnet_class_train_and_predict(x_train, y_train, x_test, default_lambda=0.1)
    if sum(y_train[:, 1]) == sum(y_train) || sum(y_train[:, 2]) == sum(y_train)
        model = y_train[1, 1] == 0 ? -1 : 1
        return fill(model, size(x_test, 1))
    end
    if size(x_train, 1) > 50
        cv = glmnetcv(x_train, y_train, Binomial(), nfolds=5);
        return GLMNet.predict(cv.path, x_test, argmin(cv.meanloss));
    else
        path = glmnet(x_train, y_train, Binomial())
        return GLMNet.predict(path, x_test, get_closest_index(path.lambda, default_lambda));
    end
end

    
function glmnet_bic(input, output)
    output = flat(output)
    path = glmnet(input, output)
    preds = GLMNet.predict(path, input)
    path_size = size(path.betas, 2)
    k = [count(path.betas[:, i] .!= 0) for i in 1:path_size]
    error_var = [mse(preds[:, i], output) for i in 1:path_size]
    n = length(output)
    BIC = n*log.(error_var) .+ k*log(n)
    best_path_index = argmin(BIC)
    path, best_path_index
end  
    
function glmnet_reg_train_predict(x_train, y_train, x_test)
    model, bic_index = glmnet_bic(x_train, y_train)
    GLMNet.predict(model, x_test, bic_index)
end
    
# Definitions
    
glmnet_classification(;kwargs...) = Algorithm(pre_process=glmnet_class_pre_process,
                                              train_and_predict=glmnet_class_train_and_predict,
                                              ;kwargs...)
    
glmnet_regression(;kwargs...) = Algorithm(pre_process=reg_pre_process,
                                          train_and_predict=glmnet_reg_train_predict,
                                          ;kwargs...)
    
