using Dates, UUIDs
import Base.+
dt = Dates

b3_taxes = 0.00023756
source_ir = 0.01
darf_ir = 0.19
arbitrage_fee = 0
arbitrage_iss = 0.05
custody_fee = 20

function expecpremium(startprice::Float64, closeprice::Float64, quantity::Int64)
    startstockcost = startprice*quantity
    closestockcost = closeprice*quantity
    total_arbitrage = arbitrage_fee * (1 + arbitrage_iss)
    totaltaxes = (startstockcost + closestockcost)*b3_taxes + 2*total_arbitrage
    liquid = (abs(closestockcost - startstockcost) - totaltaxes)*(1 - source_ir - darf_ir)
    investiment = min(startstockcost, closestockcost)
    expectedpremium = (investiment + liquid)/investiment
end

mutable struct Operation
   id::UUID 
   stock::String
   quantity::Int64
   date::Union{Nothing, Date}
   sellshort::Bool
   startprice::Float64
   startcost::Float64
   closeprice::Union{Nothing, Float64}
   closecost::Union{Nothing, Float64}
   liquid::Union{Nothing, Float64}
end

function Operation(stock::String, startprice::Float64, quantity::Int64; sellshort::Bool=false)
    id = uuid1()
    stockcost = startprice*quantity
    total_arbitrage = arbitrage_fee * (1 + arbitrage_iss)
    starttax = stockcost*b3_taxes + total_arbitrage
    if sellshort 
        startcost = starttax - stockcost
    else
        startcost = starttax + stockcost
    end
    return Operation(id, stock, quantity, nothing, sellshort, startprice, startcost, 
                     nothing, nothing, nothing)
end

function close!(op::Operation, closeprice)
    op.closeprice = closeprice
    stockcost = op.closeprice*op.quantity
    total_arbitrage = arbitrage_fee * (1 + arbitrage_iss)
    closetax = stockcost*b3_taxes + total_arbitrage
    if op.sellshort
        op.closecost = closetax + stockcost 
    else
        op.closecost = closetax - stockcost
    end
    op.liquid = - (op.startcost + op.closecost)
    (op.liquid > 0) && (op.liquid *= (1 - source_ir))
end

struct Wallet
   operations::Vector{Operation}
   datetimes::Vector{DateTime}
   months::Vector{String}
   acumliquid::Vector{Float64}
   cash::Vector{Float64}
   invested::Vector{Float64}
   total::Vector{Float64}
end

Wallet(cash::Float64) = Wallet(Vector{Operation}(undef,0),  Vector{DateTime}(undef, 0), Vector{String}(undef, 0), [0], [cash], [0], [cash])
    
function update!(wallet::Wallet, datetime::DateTime, values::Dict{String, Float64})
    push!(wallet.datetimes, datetime)
    push!(wallet.cash, wallet.cash[end])
    dates = wallet.datetimes
    if (length(dates) > 2) && (dt.monthname(dates[end]) != dt.monthname(dates[end-1]))
        collectDARFandCustody!(wallet, dt.monthname(wallet.datetimes[end-1]))
    end
    invested = 0
    for operation in open_ops(wallet)
        opvalue = operation.quantity*values[operation.stock]
        (operation.sellshort) && (opvalue *= -1)
        invested += opvalue
    end
    push!(wallet.invested, invested)
    push!(wallet.total, wallet.invested[end] + wallet.cash[end])
end
        
open_ops(wallet::Wallet) = [op for op in wallet.operations if op.closeprice == nothing]
has_open(wallet::Wallet) =  length(open_ops(wallet)) != 0
        
function add!(wallet::Wallet, op::Operation)
    op.date = wallet.datetimes[end]
    wallet.cash[end] -= op.startcost
    if op.sellshort 
        wallet.invested[end] -= op.startprice*op.quantity
    else
        wallet.invested[end] += op.startprice*op.quantity
    end
    wallet.total[end] = wallet.invested[end] + wallet.cash[end]
    push!(wallet.operations, op)
end

function close_op!(wallet::Wallet, id::UUID, values::Dict{String, Float64})
    operation = filter(operation -> operation.id == id, wallet.operations)[1]
    closeprice = values[operation.stock]
    close!(operation, closeprice)
    wallet.cash[end] -= operation.closecost
    if operation.sellshort
        wallet.invested[end] += operation.closeprice*operation.quantity
    else
        wallet.invested[end] -= operation.closeprice*operation.quantity
    end
    wallet.total[end] = wallet.invested[end] + wallet.cash[end]
end

function collectDARFandCustody!(wallet::Wallet, month::String)
    operationsinmonth = [op for op in wallet.operations 
                         if (dt.monthname(op.date) == month) && op.liquid != nothing]
    if length(operationsinmonth) == 0 
        liquidinmonth = 0
    else
        liquidinmonth = sum(getfield.(operationsinmonth, :liquid))
    end
    (wallet.acumliquid[end] < 0) && (liquidinmonth += wallet.acumliquid[end])
    (liquidinmonth > 0) && (wallet.cash[end] -= liquidinmonth*darf_ir)
    wallet.cash[end] -= custody_fee
    push!(wallet.acumliquid, liquidinmonth)
    push!(wallet.months, month)
end
