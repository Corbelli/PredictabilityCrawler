using ..PCrawl: pty
using DataFrames
using DataFrames: names
attr = pty.attr

bestc = "#62AD7A"
headercolor = "#084493"
headercolor = "#BC2024"
bestc = "#5A95D6"
badc = "#FC4C47"
drawc = "D1D1D6"

benchnames = ["Stock" "Selected Fraction" "Whole MAE" "Selected MAE" "Whole CDC" "Selected CDC" "Whole Naive" "Selected Naive" "Whole MASE" "Selected MASE"]


function benchtable(df::DataFrame)
    tickets = value(df)[:, 1]
    proportion = round.(value(df)[:,2], digits=2)
    maes = round.(value(df)[:, 3:4], digits=5)
    cdc = round.(value(df)[:, 5:6], digits=2)
    naives = round.(value(df)[:, 9:10], digits=4)
    mase = round.(value(df)[:, 11:end], digits=2)
    final = [tickets proportion maes cdc naives mase]
    colors = fill("white", size([names; final]))
    for i in 1:size(colors, 1)-1
        if final[i, 3] > final[i, 4]
            colors[i, 3] = bestc
            colors[i, 4] = badc
        elseif final[i, 4] > final[i, 3]
            colors[i, 3] = badc
            colors[i, 4] = bestc
        else
            colors[i, 3] = drawc
            colors[i, 4] = drawc
        end
    end
    printtable(benchnames, final, colors, 1230)
end

function totable(df::DataFrame; digits::Union{Int64, Nothing}=nothing)
    dfnames = String.(names(df))
    if digits == nothing
        values = value(df)
    else
        values = round.(value(df), digits=digits)
    end
    colors = fill("white", size([names; values]))
    printtable(dfnames, values, colors, align=false)
end



function printtable(names, rows, colors, width::Int64=800, height::Int64=600; align=true)
    headeralign = align == true ? ["left", "center"] : "center"
    table = pty.table(header=attr(values=names,
                                  align=headeralign,
                                  fill_color=headercolor, line=attr(width=1, color="black"),
                                  font=attr(family="Arial", size=14, color="white")),
                      cells=attr(values=rows, align=headeralign,
                                 line=attr(color="black", width=1),
                                 font=attr(family="Arial", size=11, color="black"),
                                 fill_color=colors))
    pty.plot(table, pty.Layout(width=width,height=height, margin=attr(l=20, r=100, b=10)))
end


function plot_predcitability(signal, reference; title=nothing)
    reference = typeof(reference) == Array{Float64,1} ? Bool.(reference) : reference
    all = pty.scatter(;y=signal)
    beginings = findall(x -> x == 1, diff(reference))
    reference[1] == true && pushfirst!(beginings ,1)
    ends = findall(x -> x == -1, diff(reference))
    reference[end] == true && push!(ends, length(reference))
    coverage = count(reference)/length(reference)
    title = title == nothing ? "Coverage : $coverage" : title
    shapes = pty.rect(beginings,ends,0,1;xref="x",yref="paper",line_width=0,fillcolor="#d3d3d3", opacity=.3)
    pty.plot([all], pty.Layout(;shapes=shapes, title=title, margin=attr(l=20, r=100, b=40)))
end