module PCrawl

using PlotlyJS, Plots
plt = Plots; pty = PlotlyJS
export plt, pty

include("Utils/Utils.jl")
using .Utils
export wn, wn2, ar1, nlinear, make_x_y_ref
export sample, sample_pop!
export plot_predcitability, printtable, benchnames, benchtable, totable
export mse, rmse, mae, rmae, value

include("Learning/Learning.jl")
using .Learning
export fit!, apply, reverse, fit_apply!, idtransform, normtransform
export Pipeline, train!, predict, crossvalidation!, getmodel, loss
export XgBoostModel, earlystopcv, BicLassoModel, RandomForestModel, gridoptmodel, rfgridmodel
export lambda, coefs, r2lasso, nulldev, lassobic

include("Evolutionary/Evolutionary.jl")
using .Evolutionary
export evolution, EvolSettings, GA, score_points, random_points, init_population, init_genes
export benchmark, benchgraph, getmetrics, compare_states, getstats, bloxplot, aggr, benchaggr_, plotstates

include("Pso/Pso.jl")
using .Pso
export PSO, pso, Particle, init_intervals, classify, interval, RandomIntervals, activate
export random_init, benchmark


include("Training/Training.jl")
using .Training
export Algorithm, training, ptraining

include("Crawler/Crawler.jl")
using .Crawler
#crawlers
export pcrawlerpso, pcrawlerevol
# loading.jl
export loadsignalpaperdata, loadpaper, loadpaperdata, loadsignal, crawlpaper, crawlpapers, papers, savesig, loadfullpaperdata
# models.jl
export rfcrawler, boostcrawler, boostgrid, rfgrid, halfsample, classifynew, crossmase
# benchmarking
export wholebench, signalquality, crawlertests, getcoverage, selectsig

include("strategies.jl")
export corbystrategy, holdportfolio

end
