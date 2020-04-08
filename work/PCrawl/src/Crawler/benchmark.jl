using Distributions, ProgressMeter, DataFrames
using CSV: write
include("models.jl")
include("loading.jl")

metricsframe() = DataFrame(Stock=String[], SignalCoverage=Float64[], WholeMAE=Float64[], 
                             SelectedMAE=Float64[], WholeCDC=Float64[],                                                              SelectedCDC=Float64[],WholeDataDirection=Float64[],
                             SelectedDirection=Float64[], WholeNaiveMae=Float64[],
                             SelectedNaiveMae=Float64[], WholeMASE=Float64[], SelectedMASE=Float64[])

function wholebench(modelcallback::Function; thresh::Float64=.5, papers=papers, signalname=nothing)
    dfs = []
    @showprogress 1 "Computing..."  for paper in papers
        x, y, control, signal, xt, yt, controlt = loadsignalpaperdata(paper, signalname);
        push!(dfs, signalquality(paper, x, y, signal, xt,  yt, 
              modelcallback, signalname, thresh=thresh))
    end
    return vcat(dfs...)
end
    
selectsig(x, y, signal) = x[signal, :], y[signal, :]
cdc(x, y) = count((x .* y) .>= 0)/length(x)
getcoverage(signal) = count(signal)/length(signal)


# Uses the signal to train the classifier, find predictable samples in the new observations
# and compare the results using the techinique applied at that signal vs whole dataset
function signalquality(paper, x, y, signal, xt,  yt, modelcallback, signalname; thresh::Float64=.5)
    signalout = classifynew(x, signal, xt, thresh=thresh);
    savesigout(paper, signalout, signalname)
    coverage = getcoverage(signalout)
    xp, yp = selectsig(x, y, signal)
    xtp, ytp = selectsig(xt, yt, signalout)
    model, wholeloss, wholecdc, wholedir, wholenaive, wholemase = modelmetrics(x,y,xt,yt,modelcallback)
    model, predloss, predcdc, preddir, prednaive, predmase = modelmetrics(xp,yp,xtp,ytp,modelcallback)
    df = metricsframe()
    push!(df, (paper, coverage, wholeloss, predloss, wholecdc, predcdc, 
               wholedir, preddir, wholenaive, prednaive, wholemase, predmase))
    return df
end

function modelmetrics(xtrain, ytrain, xtest, ytest, modelcallback)
    if typeof(modelcallback) <: PCrawl.Learning.AbstractModel
        model = modelcallback
    else
        model = modelcallback(xtrain, ytrain)
    end
    pipe = Pipeline(model, mae)
    train!(pipe, xtrain, ytrain)
    modelloss = loss(pipe, xtest, ytest)
    modelcdc = cdc(ytest, PCrawl.Learning.predict(pipe, xtest))
    dir = count(ytest .>=0)/length(ytest)
    naivemae = mean(abs.(ytest))
    mase = modelloss/naivemae
    return model, modelloss, modelcdc, dir, naivemae, mase
end
    
function crawlertests(df::DataFrame)
    testsdf = DataFrame(MAE=Float64[], CDC=Float64[], MASE=Float64[])
    maetest = pairedtest(df.WholeMAE, df.SelectedMAE)
    cdctest = pairedtest(df.SelectedCDC, df.WholeCDC)
    masetest = pairedtest(df.WholeMASE, df.SelectedMASE)
    push!(testsdf, [maetest, cdctest, masetest])
    return testsdf
end
         
function pairedtest(a, b)
    μ =  mean(a .- b);
    σ = std(a .- b)/sqrt(length(a));
    dist = TDist(length(a) - 1)
    pvalue = 1 - cdf(dist, μ/σ)
end