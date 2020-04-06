using ..PrevisibilityCrawler: plt
using ..PrevisibilityCrawler.Utils: rmae
using .Learning: Pipeline, crossvalidation!, AbstractModel
import XGBoost

struct XgBoostModel <: AbstractModel
    meta::Dict{Symbol, Any}
end

function trainmodel!(model::XgBoostModel, x, y)
    trained = XGBoost.xgboost(x, model.meta[:nr_round], label=vec(y), param=model.meta[:params], silent=1);
    model.meta[:model] = trained
end

modelpredict(model::XgBoostModel, x) = XGBoost.predict(model.meta[:model], x)

function earlystopcv(x, y,  nr_round, pipeline::Pipeline)
    train = Vector{Float64}(undef, nr_round)
    test = Vector{Float64}(undef, nr_round)
    for i in 1:nr_round
        pipeline.model.meta[:nr_round] = i
        train[i], test[i] = crossvalidation!(pipeline, x, y)
    end
    lasttest = test[end]
    plt.plot([test, train], title="Validation Loss: $lasttest", label=["test error","train error"])
end

function gridsearch(x, y, paramname, paramindex, paramvalues, control; nr_rounds=100, loss=rmae, k=5)
    validations = Array{Float64}(undef, length(paramvalues))
    for (i, value) in enumerate(paramvalues)
        control[paramindex] = paramname=>value
        model = XgBoostModel(Dict(:params=>control, :nr_round=>nr_rounds));
        pipe = Pipeline(model, loss);
        train_error, validations[i] = crossvalidation!(pipe, x, y , k=k)
    end
    bestvalue = paramvalues[argmin(validations)]
end

function gridoptmodel(x, y; depths=[2, 3, 4, 5, 6], etas=[.3, .4, .5, .6, .7, .8], subs=[.3, .4, .5, .6, .7, .8],
                      nr_rounds)
    param = ["max_depth"=>2, "eta"=>.5, "subsample"=>.3, "objective"=>"reg:linear"]
    param[1] = "max_depth"=>gridsearch(x, y, "max_depth", 1, depths, param, nr_rounds=nr_rounds)
    param[2] = "eta"=>gridsearch(x, y, "eta", 2, etas, param, nr_rounds=nr_rounds)
    param[3] = "subsample"=>gridsearch(x, y, "subsample", 3, subs, param, nr_rounds=nr_rounds)
    return param
end

function topfx(xmat, y, nrfeatures=20)
    param = ["max_depth"=>7, "eta"=>.6, "subsample"=>1, "objective"=>"reg:linear"]
    model = XgBoostModel(Dict(:params=>param, :nr_round=>100));
    pipe = Pipeline(model, rmae);
    train!(pipe, xmat, y)
    xgb = getmodel(pipe)
    feature_importance = importance(xgb, String.(names(xmat)))
    nrfeatures = max(nrfeatures, size(feature_importance, 1))
    topfeatures = Symbol.([feature.fname for feature in feature_importance])[1:nrfeatures]
    xtop = convert(Matrix{Float64}, xmat[:, topfeatures])
end


