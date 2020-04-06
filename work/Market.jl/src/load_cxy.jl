# using .Market: aggregateTrades
# using .Market.Features: fiveFeatures, dailyFeatures, sixtyFeatures, features
# using CSV: read
include("features.jl")

# function load_cxy(path::String)
#     data = read(path);
#     return make_cxy(data)
# end

# function make_cxy(data::DataFrame)
#     it5 = aggregateTrades(data, "ITSA4", 5);
#     it60 = aggregateTrades(data, "ITSA4", 60);
#     itd = aggregateTrades(data, "ITSA4", "daily");
#     it5 = fiveFeatures(it5);
#     itd = dailyFeatures(itd);
#     it60 = sixtyFeatures(it60);
#     data = nothing
#     x, y  = features(it5, it60, itd);
#     control = x[:, 2:3]
#     x = x[:, 4:end];
#     return control, x, y
# end

function make_cxy(df5::DataFrame, df60::DataFrame, dfd::DataFrame, forecasthorizon::Int64=6)
    df5 = fiveFeatures(df5);
    df60 = sixtyFeatures(df60);
    dfd = dailyFeatures(dfd);
    data = nothing
    x, y  = features(df5, df60, dfd, forecasthorizon);
    control = x[:, 2:3]
    x = x[:, 4:end];
    return control, x, y
end


