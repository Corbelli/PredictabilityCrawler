# using .LoadMarket: loadzipfile, loadgzfile, loadcsvfile
include("loadframe.jl")
using Dates
using DataFrames: DataFrame

function updatetriple(triple::Vector{DataFrame}, filestoread::Int64; dir="data/ftp_files/")
    ticks = unique(triple[3].tick)
    newtriple = loadfilestoframes(triple[end], filestoread, ticks; dir=dir)
    newtriple == nothing && (println("no files to go"); return triple)
    join = [triple[1];newtriple[1]], [triple[2];newtriple[2]], [triple[3];newtriple[3]]
end

function loadfilestoframes(savedDfs::DataFrame, filesToRead::Int64, ticks::Vector{String};                                                                                         dir="data/ftp_files/")
    filesInDf = dateToFileName.(unique(Date.(savedDfs.datetime)))
    filesNames = readdir(dir)
    NegFiles = [split(file, ".")[1] for file in filesNames if occursin("NEG",file)]
    filesToGo = NegFiles[[!(file in filesInDf) for file in NegFiles]]
    length(filesToGo) == 0 && (return nothing)
    loadedDfs = Vector{DataFrame}(undef, filesToRead)
    for i in 1:filesToRead
        readfile!(loadedDfs, filesToGo, filesNames, i; dir=dir)
    end
    println("agregando")
    @time agregggated = aggregateFiles(loadedDfs, ticks)
    return agregggated
end

function aggregateFiles(loadedDfs::Vector{DataFrame}, ticks::Vector{String})
    loaded5min = [aggregateTrades(df, ticks, 5) for df in loadedDfs]
    loaded60min = [aggregateTrades(df, ticks, 60) for df in loadedDfs]
    loadeddaily = [aggregateTrades(df, ticks, "daily") for df in loadedDfs]
    return vcat(loaded5min...), vcat(loaded60min...), vcat(loadeddaily...)
end

function readfile!(loadedDfs::Vector{DataFrame}, filesToGo, filesNames::Vector{String}, i::Int64; dir::String)
    file = filter(x -> occursin(filesToGo[i], x), filesNames)[1]
    extension =  split(file, ".")[end]
    length(extension) > 3 && (extension = "TXT")
    extension == "zip" && (loadedDfs[i] = loadzipfile(dir*file))
    extension == "TXT" && (loadedDfs[i] = loadcsvfile(dir*file))
    extension == "gz"  && (loadedDfs[i] = loadgzfile(dir*file))
    return loadedDfs
end
    
dateToFileName(date) = "NEG_"*Dates.format(date, "yyyymmdd")