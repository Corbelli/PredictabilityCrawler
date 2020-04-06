using Statistics

# Auxiliary Functions
p(x) = exp.(x) ./ (1 .+ exp.(x))
class(x, threshold) = convert(Matrix{Float64},[(x .< threshold) (x .>= threshold)])
get_coverage(interval::BitArray{1}) = count(interval)/length(interval)
acc(a, b) = a/(a + b)

# Loss functions for Classification
accuracy(pred, target, pred_signal) = acc(success_and_failures(pred, target)...)
function corby_loss(pred, target, pred_signal, p=0.11)
    score = min(accuracy(pred, target, pred_signal), .8)
    coverage = get_coverage(pred_signal)
    p*coverage + (1 - p)*score
end

# Loss functions for Regression
mae(x, y) = mean(abs.(x .- y))
rmae(predicted, y) = mae(predicted, y)/mean(abs.(y))
rmse(x, y) = sqrt(mean((x .- y).^2))
mse(x, y, pred_signal) = mean((x .- y).^2)
mse(x, y) = mean((x .- y).^2)
neg_mae(x, y) = -mae(x, y)
hoeffding(n, p_value) = sqrt(log(2/p_value)/(2*n))
var_frac(x, y) = 1 - std(x .- y)
hoot_loss(x, y, pred_signal) = 1 - (mean((x .- y).^2) + hoeffding(count(pred_signal), 0.05))

corby_mae(x, y, pred_signal, a=0.1832) = a*get_coverage(pred_signal) + (1 - a)*neg_mae(x, y)
corby_rmse(x, y, pred_signal, a= 0.157) = a*get_coverage(pred_signal) + (1 - a)*var_frac(x, y)


