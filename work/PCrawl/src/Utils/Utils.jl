module Utils

include("sample.jl")
export sample, sample_pop!
include("simulate.jl")
export wn, wn2, ar1, nlinear, make_x_y_ref
include("visualization.jl")
export plot_predcitability, printtable, benchnames, benchtable, totable
include("lossfunctions.jl")
export mse, rmse, mae, rmae
include("manipulation.jl")
export value
include("folding.jl")

end