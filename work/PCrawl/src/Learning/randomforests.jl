using .Learning: AbstractModel
using DecisionTree: build_forest, apply_forest
 

struct RandomForestModel <: AbstractModel
    meta::Dict{Symbol, Any}
end


function trainmodel!(model::RandomForestModel, x, y)
    params = model.meta[:params]
    forest = build_forest(vec(y), x, params[:nfeatures], params[:ntrees], params[:sampleportion], params[:maxdepth])
    model.meta[:model] = forest
end

modelpredict(model::RandomForestModel, x) = apply_forest(model.meta[:model], x)

function rfgridmodel(x, y; depths=[2, 3, 4, 5], portions=[.3, .4, .5, .6, .7, .8, .9], 
                     nfeatures=[5, 10, 15, 20], ntrees=10)
    param = Dict(:maxdepth=>2, :nfeatures=>5, :sampleportion=>0.4, :ntrees=>ntrees)
    param[:maxdepth] = rfgridsearch(x, y, :maxdepth, depths, param)
    param[:nfeatures] = rfgridsearch(x, y, :nfeatures, nfeatures, param)
    param[:sampleportion] = rfgridsearch(x, y, :sampleportion, portions, param)
    return param
end

function rfgridsearch(x, y, paramsymbol, paramvalues, params; loss=rmae, k=5)
    validations = Array{Float64}(undef, length(paramvalues))
    for (i, value) in enumerate(paramvalues)
        params[paramsymbol] = value
        model = RandomForestModel(Dict(:params => params));
        pipe = Pipeline(model, loss);
        train_error, validations[i] = crossvalidation!(pipe, x, y , k=k)
    end
    bestvalue = paramvalues[argmin(validations)]
end