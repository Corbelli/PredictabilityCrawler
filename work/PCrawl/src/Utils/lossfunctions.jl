using Statistics

# Loss functions for Regression
mae(y_hat, y) = mean(abs.(y_hat .- y))
rmae(y_hat, y) = mae(y_hat, y)/mean(abs.(y))
rmse(y_hat, y) = sqrt(mean((y_hat .- y).^2))
mse(y_hat, y) = mean((y_hat .- y).^2)


