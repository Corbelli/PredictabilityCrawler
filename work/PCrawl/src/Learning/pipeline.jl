using .Learning: Transform, fit_apply!, idtransform
using ..PCrawl.Utils: kfold
using Statistics

abstract type AbstractModel end

trainmodel!(::AbstractModel, x, y) = error("Type of Model is not an specif inheritance of AbstractModel")
modelpredict(::AbstractModel, x) = error("Type of Model is not an specif inheritance of AbstractModel")


struct Pipeline
    model::AbstractModel
    loss::Function
    xtransform::Transform{<:AbstractTransform}
    ytransform::Transform{<:AbstractTransform}
    originalspace::Bool

    function Pipeline(model::AbstractModel, loss::Function; 
                      xtransform::Transform{<:AbstractTransform}=idtransform(), 
                      ytransform::Transform{<:AbstractTransform}=idtransform(),
                      originalspace=true)
        new(model, loss, xtransform, ytransform, originalspace)
    end
end


function train!(pipe::Pipeline, x, y)
    xt = fit_apply!(pipe.xtransform, convert(Matrix, x))
    yt = fit_apply!(pipe.ytransform, y)
    trainmodel!(pipe.model, xt, yt)
    return nothing
end

function predict(pipe::Pipeline, x)
    xt = apply(pipe.xtransform, convert(Matrix, x))
    ytpredicted = modelpredict(pipe.model, xt)
    pipe.originalspace && return reverse(pipe.ytransform, ytpredicted)
    return ytpredicted
end

function loss(pipe::Pipeline, x, y)
    predicted = predict(pipe, x)
    pipe.originalspace ? _y = y : _y = apply(pipe.ytransform, y)
    pipe.loss(predicted, _y)
end

getmodel(pipe::Pipeline) = pipe.model.meta[:model]


function crossvalidation!(pipe::Pipeline, x, y; k=5)
    train_error = Vector{Float64}(undef, k)
    test_error = Vector{Float64}(undef, k)
    if k == 1
        train!(pipe, x, y)
        return nothing, loss(pipe, x, y)
    end
    for (i, (indextrain, indextest)) in enumerate(kfold(x, k))
        xtrain, ytrain = x[indextrain, :], y[indextrain, :]
        xtest , ytest = x[indextest, :], y[indextest, :]
        train!(pipe, xtrain, ytrain)
        train_error[i] = loss(pipe, xtrain, ytrain)
        test_error[i] = loss(pipe, xtest, ytest)
    end
    return mean(train_error), mean(test_error)
end



