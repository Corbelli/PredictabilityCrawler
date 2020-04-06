using .Learning: AbstractModel
using ..PrevisibilityCrawler.Utils: mse
import GLMNet, Distributions # GLMNet, Binomial

struct BicLassoModel <: AbstractModel
    meta::Dict{Symbol, Any}
    
    BicLassoModel() = new(Dict{Symbol, Any}())
end

function lassobic(x, y)
    model = BicLassoModel()
    model = setlambda(model, convert(Matrix, x), vec(y))
end

function setlambda(model, x, y)
    path = GLMNet.glmnet(convert(Matrix, x), vec(y))
    preds = GLMNet.predict(path, x)
    path_size = size(path.betas, 2)
    k = [count(path.betas[:, i] .!= 0) for i in 1:path_size]
    error_var = [mse(preds[:, i], y) for i in 1:path_size]
    n = length(y)
    BIC = n*log.(error_var) .+ k*log(n)
    model.meta[:lambda] = path.lambda[argmin(BIC)]
    return model
end

getclosestindex(list, value) = argmin( abs.(list .- value))
bestindex(bicpipe) = getclosestindex(bicpipe.model.meta[:path].lambda, bicpipe.model.meta[:lambda])

lambda(bicpipe) = bicpipe.model.meta[:path].lambda[bestindex(bicpipe)]
coefs(bicpipe) = bicpipe.model.meta[:path].betas[:, bestindex(bicpipe)]
r2lasso(bicpipe) = bicpipe.model.meta[:path].dev_ratio[bestindex(bicpipe)]
nulldev(bicpipe) = bicpipe.model.meta[:path].null_dev[bestindex(bicpipe)]


function trainmodel!(model::BicLassoModel, x, y)
    path = GLMNet.glmnet(convert(Matrix, x), vec(y))
    model.meta[:path] = path
#     if !haskey(model.meta, :lambda)
#         print("trained")
        model = setlambda(model, x, y)
#     end
end

function modelpredict(model::BicLassoModel, x)
    modellambda = model.meta[:lambda]
    closestlambdaindex = getclosestindex(model.meta[:path].lambda, modellambda)
    GLMNet.predict(model.meta[:path], x, closestlambdaindex)

end