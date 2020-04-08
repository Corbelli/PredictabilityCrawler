include("evolution.jl")
using ..PCrawl: plt, pty
using Statistics, ProgressMeter, DataFrames

function benchmark(nrgenes::Int64, evols::Int64, initfunction::Function, scorefunction::Function,
                   gasettings::GASetting, evolsettings::EvolSettings; kwargs...)
    graphs = Array{Dict}(undef, 30)
    @showprogress 1 "Computing..." for i in 1:30
        pop = initfunction(nrgenes, gasettings)
        pop, graphs[i] = evolution(pop, scorefunction, evols, evolsettings, "snr_size",                                                                silent=true; kwargs...)
    end
    return graphs
end

function aggr(nrgenes::Int64, evols::Int64, initfunction::Function, scorefunction::Function,
                   gasettings::GASetting, evolsettings::EvolSettings; kwargs...)
    nr_iter = 9
    intervals = Array{Any}(undef, nr_iter)
    @showprogress 1 "Computing..." for i in 1:nr_iter
        pop = initfunction(nrgenes, gasettings)
        pop, graphs = evolution(pop, scorefunction, evols, evolsettings, "snr_size", silent=true; kwargs...)
        scores = scorefunction(pop)
        best = pop[sortperm(scores, rev=true)[1]];
        intervals[i] = activate(best)
    end
    return vec(sum(permutedims(hcat(intervals...)), dims=1)) .>= 2
end

function benchaggr_(nrgenes::Int64, evols::Int64, initfunction::Function, scorefunction::Function,
                   gasettings::GASetting, evolsettings::EvolSettings; kwargs...)
    nr_iter = 30
    intervals = Array{Any}(undef, nr_iter)
    @showprogress 1 "Computing..." for i in 1:nr_iter
        intervals[i] = aggr(nrgenes, evols, initfunction, scorefunction, gasettings, evolsettings; kwargs...)
    end
    return permutedims(hcat(intervals...)) 
end

function getmetric(stategraphs, metric::String)
    metric == "means" && return [graphs[:means] for graphs in stategraphs]
    metric == "snrs" && return [graphs[:meta][:snrs] for graphs in stategraphs]
    metric == "sizes" && return [graphs[:meta][:sizes] for graphs in stategraphs]
    metric == "bests" && return [graphs[:bests] for graphs in stategraphs]
end


function getstats(stategraphs, metric::String, statistic::String="")
    metricvalues = getmetric(stategraphs, metric) 
    valuematrix = permutedims(hcat(metricvalues...))
    statistic == "mean" && return mean(valuematrix[:, end])
    statistic == "max" && return max(valuematrix[:, end]...)
    statistic == "min" && return min(valuematrix[:, end]...)
    return valuematrix[:, end]
end

function bloxplot(stategraphsvec, names::Vector{String}, metric::String, title::String="$metric Comparison")
    graphvalues = [getstats(stategraphs, metric) for stategraphs in stategraphsvec]
    boxes = [pty.box(;y=values, name=name) for (values, name) in zip(graphvalues, names)]
    pty.plot(boxes, pty.Layout(title=title, showlegend=false))
end

function benchgraph(stategraphs, metric::String;color::String="#62A8FA",name::String="")
    metricvalues = getmetric(stategraphs, metric)
    meanvalue = vec(mean(permutedims(hcat(metricvalues...)), dims=1))
    traces = [pty.scatter(y=series, showlegend=false, line=pty.attr(color=color), opacity=.3) 
              for series in metricvalues]
    meantrace = pty.scatter(y=meanvalue, name=name, line_color=color, showlegend=(name!=""))
    return [traces;meantrace]
end

function compare_states(graphs1, graphs2, name1::String, name2::String 
                        ;color1::String= "#ba0c0c", color2::String="#5794d8")
    best1 = benchgraph(graphs1, "bests", color=color1)
    best2 = benchgraph(graphs2, "bests", color=color2)
    bests = pty.plot([best1;best2], pty.Layout(title="Best Values"))
    mean1 = benchgraph(graphs1, "means", color=color1)
    mean2 = benchgraph(graphs2, "means", color=color2)
    means = pty.plot([mean1;mean2], pty.Layout(title="Mean Values"))
    snr1 = benchgraph(graphs1, "snrs", color=color1)
    snr2 = benchgraph(graphs2, "snrs", color=color2)
    snrs = pty.plot([snr1;snr2], pty.Layout(title="Snrs"))
    size1 = benchgraph(graphs1, "sizes", color=color1, name=name1)
    size2 = benchgraph(graphs2, "sizes", color=color2 , name=name2)
    sizes = pty.plot([size1;size2], pty.Layout(title="Relative Sizes"))
    [bests means;snrs sizes]
end

function plotstates(graphs, name::String;color1::String= "#ba0c0c", )
    best = benchgraph(graphs, "bests", color=color1)
    bests = pty.plot(best, pty.Layout(title="Best Values"))
    mean = benchgraph(graphs, "means", color=color1)
    means = pty.plot(mean, pty.Layout(title="Mean Values"))
    snr = benchgraph(graphs, "snrs", color=color1)
    snrs = pty.plot(snr, pty.Layout(title="Snrs"))
    size = benchgraph(graphs, "sizes", color=color1, name=name)
    sizes = pty.plot(size, pty.Layout(title="Relative Sizes"))
    [bests means;snrs sizes]
end

function getmetrics(stategraphs, name::String, df::Union{Nothing, DataFrame}=nothing)
    means = getmetric(stategraphs, "means")
    avg_mean = vec(mean(permutedims(hcat(means...)), dims=1))[end]
    bests = getmetric(stategraphs, "bests")
    avg_best = vec(mean(permutedims(hcat(bests...)), dims=1))[end]
    snrs = getmetric(stategraphs, "snrs")
    avg_snr = vec(mean(permutedims(hcat(snrs...)), dims=1))[end]
    sizes = getmetric(stategraphs, "sizes")
    avg_size = vec(mean(permutedims(hcat(sizes...)), dims=1))[end]
    row = (name, avg_mean, avg_best, avg_snr, avg_size)
    if df == nothing
        df = DataFrame(Configuration=String[], AverageMeanValue=Float64[], AverageBestValue=Float64[],
                       AverageSNR=Float64[], AverageRelativeSize=Float64[])
    end
    push!(df, row)
    return df
end

### Agregated GA

function getaggvalues_(intervals, reference, metric::Union{String, Nothing}=nothing)
    n = size(intervals, 1)
    sizes = Array{Float64}(undef, n)
    snrs = Array{Float64}(undef, n)
    for i in 1:n
        snrs[i], sizes[i] = snr_size(intervals[i, :], reference)
    end
    metric == "snrs" && return snrs
    metric == "sizes" && return sizes
    return snrs, sizes
end


function getaggmetrics(intervals, reference, name::String, df::Union{Nothing, DataFrame}=nothing)
    if df == nothing
        df = DataFrame(Name=String[], AverageSNR=Float64[], AverageRelativeSize=Float64[])
    end
    snrs, sizes = getaggvalues_(intervals)
    push!(df, (name, mean(snrs), mean(sizes)))
end

function aggrbloxplot(intervals, references,names::Vector{String}, metric::String, 
                      title::String="$metric Comparison")
    graphvalues = [getaggvalues_(interval, ref, metric) for (interval, ref) in zip(intervals, references)]
    boxes = [pty.box(;y=values, name=name) for (values, name) in zip(graphvalues, names)]
    pty.plot(boxes, pty.Layout(title=title, showlegend=false))
end