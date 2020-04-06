include("investing.jl")

function corbystrategy(priceseries::Dict{String, Vector{Float64}}, datetimes::Vector{DateTime}, 
                  predictions::Dict{String, Vector{Float64}}, initialcash::Float64)
    wallet = Wallet(initialcash)
    buy_percent = 1.0
    sellshort_percent = 0.8
    premiumrisk = 1.00
    countdown = -1
    for (i, datetime) in enumerate(datetimes)
        prices = Dict(stock=>priceseries[stock][i] for stock in keys(priceseries))
        update!(wallet, datetime, prices)
        (has_open(wallet)) && (countdown -= 1)
        (countdown > 0) && continue
        (countdown == 0) && close_op!(wallet, open_ops(wallet)[1].id, prices)
        countdown = -1
        forecasts = Dict(stock=>prices[stock]*exp(predictions[stock][i]) for stock in keys(predictions))
        quantities = Dict(stock=>Int64(div(wallet.cash[end], prices[stock])) for stock in keys(predictions))
        expecpremiums = Dict(stock=>expecpremium(prices[stock], forecasts[stock], quantities[stock]) 
                             for stock in keys(prices))
        stocks = collect(keys(expecpremiums))
        premiums = collect(values(expecpremiums))
        beststock = stocks[argmax(premiums)]
        bestpremium = expecpremiums[beststock]
        if bestpremium > premiumrisk
           sellshort = prices[beststock] > forecasts[beststock]
           cashpercent = sellshort ? sellshort_percent : buy_percent
            quantity = Int64(div(wallet.cash[end] * cashpercent, prices[beststock]))
           add!(wallet, Operation(beststock, prices[beststock], quantity, sellshort=sellshort))
           countdown = 6
        end

    end
    return wallet
end

function holdportfolio(priceseries::Dict{String, Vector{Float64}}, datetimes::Vector{DateTime}, 
                       initialcash::Float64)
    wallet = Wallet(initialcash)
    initvalues = Dict(stock=>priceseries[stock][1] for stock in keys(priceseries))
    moneyperstock = wallet.cash[1] / length(collect(keys(priceseries)))
    update!(wallet, datetimes[1], initvalues)
    for stock in keys(priceseries)
        quantity = Int64(div(moneyperstock , initvalues[stock])) 
        add!(wallet, Operation(stock, initvalues[stock], quantity, sellshort=false))
    end
    for (i, datetime) in enumerate(datetimes[2:end])
        values = Dict(stock=>priceseries[stock][i] for stock in keys(priceseries))
        update!(wallet, datetime, values)
    end
    return wallet
end