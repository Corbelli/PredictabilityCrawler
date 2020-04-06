using CSV: read, write
include("crawlers.jl")

papers = ["BRFS3", "PETR4", "BBAS3", "BBDC4", "ITSA4", "VALE3", "ITUB4",
          "ABEV3", "RENT3", "KROT3", "B3SA3", "CCRO3", "JBSS3", "GGBR4",
          "ESTC3", "EMBR3", "ELET3", "CMIG4", "ELET6", "CSNA3"]

function loadsignalpaperdata(paper::String, signalname::Union{String, Nothing}=nothing)
    signal = loadsignal(paper, signalname)
    xtrain, ytrain, controltrain, xtest, ytest, controltest = loadpaperdata(paper, trainsamples=length(signal))
    return xtrain, ytrain, controltrain, signal, xtest, ytest, controltest
end

function loadpaperdata(paper::String; trainsamples=2000)
    x, y, control = loadpaper(paper)
    train = 1:trainsamples
    test = (trainsamples+1):size(x, 1)
    xtrain = x[train, :]
    ytrain = value(y[train, :])
    controltrain = control[train, :]
    xtest = x[test, :]
    ytest = value(y[test, :])
    controltest = control[test, :];
    return xtrain, ytrain, controltrain, xtest, ytest, controltest
end

function loadpaper(paper::String)
    filex = "data/csv_files/" * lowercase(paper) * "_x.csv"
    filey = "data/csv_files/" * lowercase(paper) * "_y.csv"
    filecontrol = "data/csv_files/" * lowercase(paper) * "_control.csv"
    return read(filex), read(filey), read(filecontrol)
end

function loadsignal(paper::String, signalname::Union{String, Nothing}=nothing)
    name = signalname == nothing ? "2" : "_"*signalname
    vec(value((read("data/csv_files/" * lowercase(paper) * "_signal"*name*".csv"))))
end

function crawlpaper(paper::String, signalname::String, modelcallback, mode::String; trainsamples=2000)
    !(mode in ["pso", "evol"]) && throw("Mode should be pso or evol")
    crawler = mode == "pso" ? pcrawlerpso : pcrawlerevol
    xtrain, ytrain, controltrain, xtest, ytest, controltest = loadpaperdata(paper, trainsamples=trainsamples)
    model = modelcallback(xtrain, ytrain)
    signal = crawler(xtrain, ytrain, model);
end

function crawlpapers(signalname::String, modelcallback, mode::String, trainsamples=2000; papers=papers)
   for paper in papers
        signal = crawlpaper(paper, signalname, modelcallback, mode, trainsamples=trainsamples)
        savesig(paper, signal, signalname)
   end
end

function savesig(paper, signal, signalname::String)
    signalfile = "data/csv_files/" * lowercase(paper) * "_signal" * "_" *  signalname * ".csv"
    write(signalfile, DataFrame(signal=signal))
end

function savesigout(paper, signal, signalname::String)
    signalfile = "data/csv_files/" * lowercase(paper) * "_outsignal" * "_" *  signalname * ".csv"
    write(signalfile, DataFrame(signal=signal))
end

function loadsignalout(paper::String, signalname::Union{String, Nothing}=nothing)
    name = signalname == nothing ? "2" : "_"*signalname
    vec(value((read("data/csv_files/" * lowercase(paper) * "_outsignal"*name*".csv"))))
end

function loadfullpaperdata(paper::String, signalname::Union{String, Nothing}=nothing)
    signal = loadsignal(paper, signalname)
    signalout = loadsignalout(paper, signalname)
    xtrain, ytrain, controltrain, xtest, ytest, controltest = loadpaperdata(paper, trainsamples=length(signal))
    return xtrain, ytrain, controltrain, signal, xtest, ytest, controltest, signalout
end
