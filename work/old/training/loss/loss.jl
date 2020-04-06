# Auxiliary Functions
p(x) = exp.(x) ./ (1 .+ exp.(x))
class(x, threshold) = convert(Matrix{Float64},[(x .< threshold) (x .>= threshold)])
get_coverage(interval::BitArray{1}) = count(interval)/length(interval)
get_coverage(interval::UnitRange{Int64}) = length(interval)/485 ## TODO - TIRAR NUMERO ABSOLUTO DAQUI

acc(a, b) = a/(a + b)


function success_and_failures(prediction_logits, target)
    prediction_classes = class(p(prediction_logits), .5)
    intermediate_array = prediction_classes .* target
    successfull_classification = intermediate_array[:, 1] + intermediate_array[:, 2]
    α = sum(successfull_classification)
    β = length(successfull_classification) - α
    return α, β
end

# Loss functions for Classification
gittins_loss(pred, target, pred_signal) = gittins_index(success_and_failures(pred, target)...)

accuracy(pred, target, pred_signal) = acc(success_and_failures(pred, target)...)

vitu_loss(pred, target, pred_signal) = 2.5*accuracy(pred, target, pred_signal) - 2*gittins_loss(pred, target, pred_signal)

function corby_loss(pred, target, pred_signal, p=0.11)
    score = min(accuracy(pred, target, pred_signal), .8)
    coverage = get_coverage(pred_signal)
    p*coverage + (1 - p)*score
end

# Loss functions for Regression
mae(x, y) = mean(abs.(x - y))
rmse(x, y) = sqrt(mean((x .- y).^2))
mse(x, y, pred_signal=0) = mean((x .- y).^2)
neg_mae(x, y) = -mae(x, y)
hoeffding(n, p_value) = sqrt(log(2/p_value)/(2*n))
var_frac(x, y) = 1 - std(x .- y)
hoot_loss(x, y, pred_signal) = 1 - (mean((x .- y).^2) + hoeffding(count(pred_signal), 0.05))

corby_mae(x, y, pred_signal, a=0.1832) = a*get_coverage(pred_signal) + (1 - a)*neg_mae(x, y)
corby_rmse(x, y, pred_signal, a= 0.157) = a*get_coverage(pred_signal) + (1 - a)*var_frac(x, y)


