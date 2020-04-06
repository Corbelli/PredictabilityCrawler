using Indicators, Base.Sort, Dates, TimeSeries, Statistics, RollingFunctions, GLM, DataFrames
rf = RollingFunctions
# using ..Market: runmin, runmax, lm, coeftable, @formula, DataFrame, Time, DateTime, ema, macd, rsi, hurst

function features(fiveMin::DataFrame, sixtyMin::DataFrame, daily::DataFrame, forecasthorizon::Int64=6)
    featureDf = featureFrame()
    target = []
    for i in 1:size(fiveMin, 1)
        row = fiveMin[i, :]
        time = Time(row.datetime)
        if (time >= Time("10:55:00")) && (time <= Time("16:25:00"))
            sixtyrow = getCorrespondingRow(sixtyMin, row.datetime)
            dailyrow = getCorrespondingRow(daily, row.datetime)
            if sixtyrow != nothing && dailyrow != nothing
                featureRow = makeFeatureRow(fiveMin[i-10:i, :], sixtyrow, dailyrow)
                if featureRow != nothing
                    push!(featureDf, featureRow)
                    push!(target, log(fiveMin.lastPrice[i + forecasthorizon]/fiveMin.lastPrice[i]))
                end
            end
        end
    end
    return featureDf, reshape(convert(Vector{Float64}, target), length(target), 1)
end

function getCorrespondingRow(df::DataFrame, datetime)
    index = searchsortedlast(df.datetime, datetime)
    index == 0 && return nothing
    return df[index, :]
end

function makeFeatureRow(fiveDf, sixtyRow, dailyRow)
    identifiers = [fiveDf.tick[end], fiveDf.datetime[end], fiveDf.lastPrice[end]]
    returns = abs.(diff(log.(fiveDf.lastPrice))) 
    logReturns(x) = log.(x/ fiveDf.lastPrice[end])
    supports = logReturns(Vector(fiveDf[end, 12:14]))
    resistances = logReturns(Vector(fiveDf[end, 15:17]))
    pivots = logReturns(Vector(dailyRow[12:16]))
    bbUp = logReturns(fiveDf.upperBBand[end-2:end])
    bbLow = logReturns(fiveDf.lowerBBand[end-2:end])
    bbMid = logReturns(fiveDf.midBBand[end-2:end])
    volumes = fiveDf.volume[end-3:end-1]#/fiveDf.volume[end]
    momentum = [sixtyRow.trend, fiveDf.macd[end], fiveDf.rsi[end]]
    vwap = logReturns(fiveDf.weightedPrice[end-2:end])
    ema9 = logReturns(fiveDf.ema9[end-2:end])
    ema27 = logReturns(fiveDf.ema27[end-2:end])
    ema200 = logReturns(fiveDf.ema200[end-2:end])
    row = [identifiers; returns; supports; resistances; pivots;
           bbUp; bbLow; bbMid; volumes; momentum; vwap; ema9; ema27; ema200]
    any(isnan.(row)) && return nothing
    return tuple(row...)
end

Base.isnan(x::String) = false
Base.isnan(x::DateTime) = false


featureFrame() = DataFrame(tick=String[], datetime=DateTime[], lastPrice=Float64[], # Indentifiers (To be ommited)
     r1=Float64[], r2=Float64[], r3=Float64[], r4=Float64[], r5=Float64[],    # last log returns
     r6=Float64[], r7=Float64[], r8=Float64[], r9=Float64[], r10=Float64[],    # //
     suppdiff1=Float64[], suppdiff2=Float64[], suppdiff3=Float64[], # Distance from last Supports
     resdiff1=Float64[], resdiff2=Float64[], resdiff3=Float64[], # Distance from last Resistances
     ppdiff1=Float64[], ppdiff2=Float64[], ppdiff3=Float64[], ppdiff4=Float64[], ppdiff5=Float64[],# Pivot Points
     bbupdiff1=Float64[], bbupdiff2=Float64[], bbupdiff3=Float64[],  # Upper Boilinger Bands (Distance)
     bblowdiff1=Float64[], bblowdiff2 = Float64[], bblowdiff3=Float64[],  # Lower Boilinger Bands (Distance)
     bbmiddiff1=Float64[], bbmiddiff2=Float64[], bbmiddiff3=Float64[],  # Mid Boilinger Bands (Distance)
     vol1=Float64[], vol2=Float64[], vol3=Float64[], # Last Volumes
     trend=Float64[], macd=Float64[], rsi=Float64[], # Momentum indicators
     vwapdiff1=Float64[], vwapdiff2=Float64[], vwapdiff3=Float64[], # last distances from vwap
     ema9diff1=Float64[], ema9diff2=Float64[], ema9diff3=Float64[], # last distances from ema9
     ema27diff1=Float64[], ema27diff2=Float64[], ema27diff3=Float64[], # last distances from ema27
     ema200diff1=Float64[], ema200diff2=Float64[], ema200diff3=Float64[]) # last distances from ema20


function sixtyFeatures(sixtyMin::DataFrame, range=120)
    price = sixtyMin.lastPrice
    fillgaps!(price)
    sixtyMin.trend = roll(price, getTrend, range)
    return sixtyMin
end

function dailyFeatures(daily::DataFrame)
    pivot = (daily.maxPrice .+ daily.minPrice + daily.lastPrice)
    daily.pivot = shift(pivot)
    daily.pivotResistance1 = shift(2*pivot .- daily.minPrice)
    daily.pivotResistance2 = shift(pivot .+ (daily.maxPrice - daily.minPrice))
    daily.pivotSupport1 = shift(2*pivot .- daily.maxPrice)
    daily.pivotSupport2 =  shift(pivot .- (daily.maxPrice - daily.minPrice))
    return daily
end

function fiveFeatures(fiveMin::DataFrame, range::Int64=200)
    price = fiveMin.lastPrice
    fillgaps!(price)
    support_(series) = getSR(series, "support")
    resistances_(series) = getSR(series, "resistance")
    supports = roll(price, support_, range, [NaN, NaN, NaN])
    resistances = roll(price, resistances_, range, [NaN, NaN, NaN])
    boilingerBands = bbands(price)
    fiveMin.lastSupport = [sup[3] for sup in supports]
    fiveMin.secondLastSupport = [sup[2] for sup in supports]
    fiveMin.thirdLastSupport = [sup[1] for sup in supports]
    fiveMin.lastResistance = [res[3] for res in resistances]
    fiveMin.secondLastResistance = [res[2] for res in resistances]
    fiveMin.thirdLastResistance = [res[1] for res in resistances]
    fiveMin.macd = macd(price)[:, 3]
    fiveMin.rsi = rsi(price)
    fiveMin.lowerBBand = boilingerBands[:, 1]
    fiveMin.midBBand = boilingerBands[:, 2]
    fiveMin.upperBBand = boilingerBands[:, 3]
    fiveMin.ema9 = ema(price, n=9)
    fiveMin.ema27 = ema(price, n=27)
    fiveMin.ema200 = ema(price, n=200)
    return fiveMin
end

function shift(x)
    y = circshift(x, 1)
    y[1] = NaN
    return y
end

roll(series, func, range, null=NaN) = [last >= range ? func(series[last-range+1:last]) : null
                                        for last in 1:length(series)]

rowToArray(row) = Vector(row)
dfToarray(df) = convert(Matrix, df)


function getSR(series, lineType, horizon=15)
    if lineType == "support"
        extrema = rf.runmin(series, 20)
    elseif lineType == "resistance"
        extrema = rf.runmax(series, 20)
    else
        throw("lineType must be either support or resistance")
    end
    levels = []
    for (i, value) in enumerate(extrema)
        if i  + horizon >= length(series)
            break
        elseif length(levels) == 0
            if extrema[i + horizon] == value
                push!(levels, value)
            else
                continue
            end
        elseif value != levels[end] && extrema[i + horizon] == value
            push!(levels, value)
        end
    end
    if length(levels) > 3
        levels = levels[end-2:end]
    elseif length(levels) < 3
        levels = [repeat([NaN], 3 - length(levels)); levels]
    end
    return levels
end

function getTrend(series)
    df = DataFrame(x=collect(1:length(series)), y=series)
    ols = lm(@formula(y ~ x), df)
    trend = coeftable(ols).cols[1][2]
end

function stableHurst(series)
    instableHurst = hurst(series)
    for i in 2:length(series)
        if isnan(instableHurst[i])
            instableHurst[i] = instableHurst[i-1]
        end
    end
    return ema(instableHurst, n=27)
end

function fillgaps!(series)
    for (i, value) in enumerate(series[1:end-1])
        (isnan(value)  && !isnan(series[i+1]) )&& (series[i] = series[i+1])
        isnan(series[i+1]) && (series[i+1] = series[i])
    end
end