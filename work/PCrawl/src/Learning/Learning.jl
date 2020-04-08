module Learning

include("transform.jl")
export fit!, apply, reverse, fit_apply!, idtransform, normtransform

include("pipeline.jl")
export AbstractModel, Pipeline, train!, predict, crossvalidation!, getmodel, loss

include("xgboost.jl")
export XgBoostModel, earlystopcv, gridoptmodel

include("lasso.jl")
export BicLassoModel, lambda, coefs, r2lasso, nulldev, lassobic

include("randomforests.jl")
export RandomForestModel, rfgridmodel


end