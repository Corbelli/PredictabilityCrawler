using CSV, DataFrames
using DataFrames, ProgressMeter, XGBoost, Statistics, Distributions

papers = ["BRFS3", "PETR4", "BBAS3", "BBDC4", "ITSA4", "VALE3", "ITUB4",
          "ABEV3", "RENT3", "KROT3", "B3SA3", "CCRO3", "JBSS3", "GGBR4",
          "ESTC3", "EMBR3", "ELET3", "CMIG4", "ELET6", "CSNA3"]


function wholebench(modelcallback::Function; thresh::Float64=.5)
    df = benchcrawler(papers[1], modelcallback=modelcallback)
    @showprogress 1 "Computing..."  for paper in papers[2:end]
        df = benchcrawler(paper, df, modelcallback=modelcallback, thresh=thresh)
    end
    return df
end

cdc(x, y) = count((x .* y) .>= 0)/length(x)


function benchcrawler(paper::String, df::Union{DataFrame, Nothing}=nothing; 
                      modelcallback::Function, thresh::Float64=.5)
    x, y, control, signal, xt, yt, controlt = loadsimulpaper(paper);
    df == nothing  && (df = benchmarkframe())
    xp = x[signal, :];
    yp = y[signal, :];
    # Train Classiflier to out of sample predictability
    param = ["max_depth" => 3, "eta" => .8, "subsample" => 1, "objective" => "binary:logistic"]
    previsible = xgboost(convert(Matrix, x), 500, label=signal, param=param, silent=1);
    predicted = XGBoost.predict(previsible, convert(Matrix,xt))
    signalt = predicted .>= thresh;
    xtp = xt[signalt, :];
    ytp = yt[signalt, :];
    coverage = count(signalt)/length(signalt)
    model, wholeloss, wholecdc, wholedir, wholenaive, wholemase = modelmetrics(x,y,xt,yt,modelcallback)
    model, predloss, predcdc, preddir, prednaive, predmase = modelmetrics(xp,yp,xtp,ytp,modelcallback)
    push!(df, (paper, coverage, wholeloss, predloss, wholecdc, predcdc, 
               wholedir, preddir, wholenaive, prednaive, wholemase, predmase))
    return df
end

benchmarkframe() = DataFrame(Stock=String[], SignalCoverage=Float64[], WholeMAE=Float64[], 
                             SelectedMAE=Float64[], WholeCDC=Float64[],                                                              SelectedCDC=Float64[],WholeDataDirection=Float64[],
                             SelectedDirection=Float64[], WholeNaiveMae=Float64[],
                             SelectedNaiveMae=Float64[], WholeMASE=Float64[], SelectedMASE=Float64[])

function modelmetrics(xtrain, ytrain, xtest, ytest, modelcallback)
    if typeof(modelcallback) <: PrevisibilityCrawler.Learning.AbstractModel
        model = modelcallback
    else
        model = modelcallback(xtrain, ytrain)
    end
    pipe = Pipeline(model, mae)
    train!(pipe, xtrain, ytrain)
    modelloss = loss(pipe, xtest, ytest)
    modelcdc = cdc(ytest, PrevisibilityCrawler.Learning.predict(pipe, xtest))
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

function loadsimulpaper(paper::String)
    x, y, control = loadpaper(paper)
    signal = loadsignal(paper)
    t1 = 1:2000
    n1 = 2001:size(x, 1)
    x1 = x[t1, :]
    y1 = value(y[t1, :])
    control1 = control[t1, :]
    xn1 = x[n1, :]
    yn1 = value(y[n1, :])
    controln1 = control[n1, :];
    signal = signal[t1];
    return x1, y1, control1, signal, xn1, yn1, controln1
end


function crawlpaper(paper::String)
    x, y, control = loadpaper(paper);
    train = 1:2000
    xtrain = x[train, :];
    ytrain = convert(Matrix{Float64}, y[train, :]);
    param = ["max_depth"=>2, "eta"=>.6, "subsample"=>1, "objective"=>"reg:linear"]
    model = XgBoostModel(Dict(:param => param, :nr_round => 10));
    signal = pcrawlerpso(xtrain, ytrain, model);
    signalfile = "data/csv_files/" * lowercase(paper) * "_signal2.csv"
    CSV.write(signalfile, DataFrame(signal=signal))
end

loadsignal(paper::String) = vec(value((CSV.read("data/csv_files/" * lowercase(paper) * "_signal2.csv"))))


function loadpaper(paper::String)
    filex = "data/csv_files/" * lowercase(paper) * "_x.csv"
    filey = "data/csv_files/" * lowercase(paper) * "_y.csv"
    filecontrol = "data/csv_files/" * lowercase(paper) * "_control.csv"
    x = CSV.read(filex);
    y = CSV.read(filey);
    control = CSV.read(filecontrol);
    return x, y, control
end


function pcrawlerpso(x, y, model; minsamples::Int64=400)
    acceptable = [2000, 4000, 6000]
    intervals = [1:2000, 2001:4000, 4001:6000]
    modelloss = rmae
    explainedmae(loss, prevy, datasetsize) =  (length(prevy)/datasetsize)*0.3 + (1- loss)
    prevloss = explainedmae
    pipe = Pipeline(model, modelloss);
    algo = Algorithm(prevloss, minsamples=minsamples, k=3);
    settings = PSO(phip=.5, phig=1, w=.5, K=5, max_iter=100)
    nrparticles = 100; groupsize = 40; minsamples =minsamples;
    totalsize = size(x, 1)
    !(totalsize in acceptable) && throw("Acceptable sizes: 2000, 4000 or 6000. Keep it simple, ok?")
    nrruns = div(totalsize, 2000)
    runintervals = intervals[1:nrruns]
    signal = []
    for interval in runintervals
        xtemp = x[interval, :]
        ytemp = y[interval, :]
        scorefunction = training(xtemp, ytemp, algo, pipe);
        particles = Particle.(random_init(nrparticles, groupsize, x, minsamples=minsamples), scorefunction);
        particles, graphs = pso(particles, scorefunction, settings, "progress")
        push!(signal, convert(Vector{Bool}, classify(particles)))
    end
    return vcat(signal...)
end


function pcrawlerevol(x, y, model; minsamples::Int64=500)
    acceptable = [2000, 4000, 6000]
    intervals = [1:2000, 2001:4000, 4001:6000]
    modelloss = rmae
    explainedmae(loss, prevy, datasetsize) =  (length(prevy)/datasetsize)*0.1 + (1- loss)
    prevloss = explainedmae
    pipe = Pipeline(model, modelloss);
    algo = Algorithm(prevloss, minsamples=minsamples, k=3);
    evolsettings = EvolSettings(;pressure=2, mutation_p=10, crossover_p=80, elitism=1);
    gasettings = GA(2000 ;minsamples=minsamples, groupsize=40);
    totalsize = size(x, 1)
    !(totalsize in acceptable) && throw("Acceptable sizes: 2000, 4000 or 6000. Keep it simple, ok?")
    nrruns = div(totalsize, 2000)
    runintervals = intervals[1:nrruns]
    signal = []
    for interval in runintervals
        xtemp = x[interval, :]
        ytemp = y[interval, :]
        scorefunction = training(xtemp, ytemp, algo, pipe);
        pop = init_genes(100, gasettings)
        pop, graphs = evolution(pop, scorefunction, 100, evolsettings, "progress", knn=5);
        scores = scorefunction(pop);
        best = pop[sortperm(scores, rev=true)[1]];
        push!(signal, convert(Vector{Bool}, activate(best)))
    end
    return vcat(signal...)
end


function halfsample(x, y, model, name::String="")
    idloss(loss, a, b) = loss
    sizes = [1000]
    prevloss = idloss;
    pipe = Pipeline(model, rmae);
    algo = Algorithm(prevloss, minsamples=500, k=3);
    scorefunction = training(x, y, algo, pipe);
    xreal, yreal = random_points(500, sizes, length(y), scorefunction);
    histreal = pty.histogram(x=yreal, opacity=.7, name=name, histnorm="probability density");
    pty.plot([histreal], 
             pty.Layout(title="Half-sample Histogram for $name Data", barmode="overlay"))
end

function classifynew(x, signal, outofsample_x; thresh::Float64=.5)
    param = ["max_depth" => 6, "eta" => .8, "subsample" => 1, "objective" => "binary:logistic"]
    previsible = xgboost(convert(Matrix, x), num_round, label=signal, param=param, silent=1);
    predicted = XGBoost.predict(previsible, convert(Matrix,outofsample_x))
    predicted .>= thresh
end