function exponential_smoothing(activation::BitArray{1}; α=0.9, threshold=0.1)
    signal = Int.(activation)
    filtered = zeros(length(signal))
    filtered[1] = signal[1]
    for i in 2:length(signal)
        filtered[i] = filtered[i-1]*α + signal[i]*(1 - α)
    end
    return filtered .> threshold
end

function exponential_smoothing(signal; α=0.9)
    filtered = zeros(length(signal))
    filtered[1] = signal[1]
    for i in 2:length(signal)
        filtered[i] = filtered[i-1]*α + signal[i]*(1 - α)
    end
    return filtered
end