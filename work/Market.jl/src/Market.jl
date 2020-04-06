module Market

# include("loadframe.jl")
# export  loadzipfile, loadgzfile, aggregateTrades

# include("compileframe.jl")
# export loadfilestoframes, updatetriple

# module Features
#     include("features.jl")
#     export features, fiveFeatures, sixtyFeatures, dailyFeatures
# end

include("load_cxy.jl")
export  make_cxy

# include("visualization.jl")
# export make_tickgif

end
