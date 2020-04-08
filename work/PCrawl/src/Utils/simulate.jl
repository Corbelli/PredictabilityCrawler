using Distributions

noise(x) = repeat([0], x)
signal(x) = repeat([1], x) 

wn(nr_samples::Int64, σ=2) = [rand(Normal(0, σ), nr_samples) noise(nr_samples)]
wn2(nr_samples::Int64, bound=4) = [rand(Uniform(-bound, bound), nr_samples) noise(nr_samples)]

function ar1(nr_samples::Int64, ϕ=.7,  σ=2)
    ar = Vector{Float64}(undef, nr_samples)
    inovs = wn(nr_samples, σ)
    ar[1] = inovs[1]
    for i in 2:nr_samples
        ar[i] = ar[i-1]*ϕ + inovs[i]
    end
    return [ar signal(nr_samples)]
end

    
function make_x_y_ref(simulatio_data::Matrix{Float64}, windowsize::Int64)
    observations = simulatio_data[:, 1]
    x = hcat([observations[i:i+windowsize-1] for i in 1:(length(observations) - windowsize)]...)
    y = observations[windowsize+1:end]
    y = reshape(y, length(y), 1)
    return convert(Matrix, x'), y, BitArray(simulatio_data[:, 2][1:length(y)])
end