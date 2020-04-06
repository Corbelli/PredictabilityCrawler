# using .Market: Time, DateTime, Date, Minute, read, DataFrame, dropmissing!
using Dates: Time, DateTime, Date, Minute
using CSV: read
using TableReader
using DataFrames: DataFrame, dropmissing!

function loadzipfile(file::String; ticks::Union{Vector{String}, Nothing}=nothing)
    @time run(Cmd(["unzip", file]))
    filename = split(file, "/")[end]
    uncompressedname = split(filename, ".")[1] * ".TXT"
    println("lendo"); #sleep(1.5)
    @time data = DataFrame(readcsv(uncompressedname, colnames=header, comment="R", delim=';'))
    println("removendo"); #sleep(2)
    @time run(Cmd(["rm", uncompressedname]));
    println("tratando"); #sleep(2)
    @time data =treatdata(data, ticks)
    return data
end

function loadgzfile(file::String; ticks::Union{Vector{String}, Nothing}=nothing)
    run(Cmd(["gunzip", file]))
    uncompressedname = join(split(file, ".")[1:end-1])
    println("lendo"); sleep(1.5)
    data = DataFrame(readcsv(uncompressedname, colnames=header, comment="R", delim=';'))
    println("removendo"); sleep(.5)
    run(Cmd(["rm", uncompressedname])); sleep(.5)
    @time data =treatdata(data, ticks)
    return data
end

function loadcsvfile(file::String; ticks::Union{Vector{String}, Nothing}=nothing)
    println("lendo"); sleep(1.5)
    @time data = DataFrame(readcsv(file, colnames=header, comment="R", delim=';'))
    return data
    @time treatdata(data, ticks)
end

@views function treatdata(data::DataFrame, ticks::Union{Vector{String}, Nothing}=nothing)
    dropmissing!(data)
    data = data[:, [:InstrumentSymbol, :TradeIndicator, :AggressorBuyOrderIndicator, :SessionDate, :Tradetime,
                    :TradePrice, :TradedQuantity, :CrossTradeIndicator, :BuyMember, :SellMember]]
    ticks == nothing || (data = data[findall(in(ticks), data.InstrumentSymbol), :])
    data = data[data.TradeIndicator .== 1, :]
    data.TradeSign =  (data.AggressorBuyOrderIndicator .== 1) .- (data.AggressorBuyOrderIndicator .== 2)
    data.InstrumentSymbol = strip.(data.InstrumentSymbol, [' '])
    data.SessionDate = Date.(data.SessionDate)
    data.TradeDateTime =  DateTime.(data.SessionDate, Time.(data.Tradetime))
    data.TradedQuantity = parse.(Int64, data.TradedQuantity)
    data.TradePrice = parse.(Float64, data.TradePrice)
    return data[[:SessionDate, :InstrumentSymbol, :TradePrice, :TradedQuantity, :Tradetime, 
                 :TradeSign, :CrossTradeIndicator, :TradeDateTime, :BuyMember, :SellMember]]
end

export loadfile

header=["SessionDate", "InstrumentSymbol", "TradeNumber", "TradePrice", "TradedQuantity",
        "Tradetime", "TradeIndicator",  "BuyOrderDate", "SequentialBuyOrderNumber",
        "SecondaryOrderID-BuyOrder", "AggressorBuyOrderIndicator", "SellOrderDate", 
        "SequentialSellOrderNumber", "SecondaryOrderID-SellOrder", "AggressorSellOrderIndicator", 
        "CrossTradeIndicator", "BuyMember", "SellMember"]; 


function aggregateTrades(tradesDf::DataFrame, ticks::Vector{String}, intervalInMinutes::Union{String, Int64})
    dates = unique(tradesDf.SessionDate)
    ticks = unique(ticks)
    lastKnownPrice = NaN
    dfs = Vector{DataFrame}(undef, 0)
    for j in 1:length(ticks)
        for i in 1:length(dates)
            lastKnownPrice = (i > 1) ? dfs[end].lastPrice[end] : NaN  
            push!(dfs, aggregateDateTrades(tradesDf, ticks[j], dates[i], intervalInMinutes, lastKnownPrice))
        end
    end
    return vcat(dfs...)
end

function aggregateDateTrades(tradesDf, tick, date, intervalInMinutes, lastKnownPrice=NaN)
    if typeof(tradesDf.Tradetime[1]) == String
        tradesDf.Tradetime = Time.(tradesDf.Tradetime)
    end
    if intervalInMinutes == "daily"
        return daily(tradesDf, tick, date)
    end
    startTime = Time("10:00:00")
    endTime = Time("17:00:00")
    interval = Minute(intervalInMinutes)
    candles = collect(startTime:interval:endTime)
    df = aggregatedFrame()
    tickDf = tradesDf[(tradesDf.InstrumentSymbol .== tick) .& (tradesDf.SessionDate .== date), :] 
    for i in 2:length(candles)
        trades = insideFrame(tickDf, candles[i-1], candles[i]);
        if (size(trades, 1) == 0) && (i == 2)
            row = emptyFirstRow(tick, date, candles[i], lastKnownPrice)
        elseif size(trades, 1) == 0
            row = emptyRow(df[end, :], date, candles[i])
        else
            row = tradedRow(tick, date, candles[i], trades)
        end
        push!(df , row)
    end
    return df
end
        
function daily(tradesDf, tick, date)
    tickDf = tradesDf[(tradesDf.InstrumentSymbol .== tick) .& (tradesDf.SessionDate .== date), :] 
    maxPrice = max(tickDf.TradePrice...)
    minPrice = min(tickDf.TradePrice...)
    nrBuys = size(tickDf[tickDf.TradeSign .== 1, :], 1)
    nrSells = size(tickDf[tickDf.TradeSign .== -1, :], 1)
    volume = sum(tickDf.TradedQuantity .* tickDf.TradePrice)
    qtd = sum(tickDf.TradedQuantity)
    weightedPrice = volume/qtd
    df = aggregatedFrame()
            row = (tick, DateTime(date, tickDf.Tradetime[end]), tickDf[1, :TradePrice], 
                tickDf[end, :TradePrice], weightedPrice, minPrice, maxPrice, nrBuys, nrSells, volume, qtd)
    push!(df , row)
    return df
end
        
aggregatedFrame() = DataFrame(tick = String[], datetime = DateTime[], firstPrice= Float64[], 
                              lastPrice = Float64[], weightedPrice = Float64[], minPrice = Float64[],
                              maxPrice = Float64[], nrBuys = Int64[], nrSells= Int64[], 
                              volume = Float64[], qtd = Int64[])
        
insideFrame(df, startTime, endTime) = df[(df.Tradetime.>startTime) .& (df.Tradetime.<=endTime), :]

emptyFirstRow(tick, date, time, lastKnownPrice) = (tick, DateTime(date, time), lastKnownPrice, lastKnownPrice,
                                             lastKnownPrice, lastKnownPrice, lastKnownPrice, 0, 0, 0, 0)
emptyRow(lastRow, date, time) = (lastRow.tick, DateTime(date, time), lastRow.lastPrice, lastRow.lastPrice,
                                 lastRow.lastPrice, lastRow.lastPrice, lastRow.lastPrice, 0, 0, 0, 0)

function tradedRow(tick, date, time, trades)
    datetime = DateTime(date, time)
    firstPrice = trades.TradePrice[1]
    lastPrice = trades.TradePrice[end]
    minPrice = min(trades.TradePrice...)
    maxPrice = max(trades.TradePrice...)
    nrBuys = size(trades[trades.TradeSign .== 1, :], 1)
    nrSells = size(trades[trades.TradeSign .== -1, :], 1)
    volume = sum(trades.TradedQuantity .* trades.TradePrice)
    qtd = sum(trades.TradedQuantity)
    weightedPrice = volume/qtd
    return (tick, datetime, firstPrice, lastPrice, weightedPrice, minPrice, 
            maxPrice, nrBuys, nrSells, volume, qtd)
end