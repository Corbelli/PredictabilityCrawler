using Interpolations
using PlotlyJS 
pty = PlotlyJS;
#jupyter labextension install @jupyterlab/plotly-extension


# Layout to be used in generic evaluations
generic_layout = pty.Layout(
                    autosize=false, 
                    width=700,
                    height=500, 
                    margin=attr(l=65, r=50, b=65, t=90))


# Receives a list containing x, y and z data, a starting point 
# to the y vector and a title, plot the surface error for that
# configuration
function pty_surface(data, y_beggining, colorscale="Viridis")
    return pty.surface(
        colorscale = colorscale,
        x = data[1],
        y = data[2][y_beggining:end],
        z = data[3][y_beggining:end],
        opacity = 1
    )
end


function error_surface(results, sizes, aggregate_func)
    x = collect(range(0, stop=1, length=length(results[end])))
    y = sizes
    surface_results = [aggregate(result, aggregate_func) for result in results]
    z = [interpolate_series(surface_result, x) for surface_result in surface_results]
    return [x, y, z]
end

function interpolate_series(series, x)
    itp = Interpolations.interpolate(series, BSpline(Linear()))
    temp_x = (x.* (length(series) - 1)) .+ 1
    return itp(temp_x)
end

# Receives a tuple (x, y), where y is the [(loss_vectors, intervals)]
# array of tuples and returns (x, aggregate.(y))
function aggregate(result, aggregate_func)
    return [tuple == nothing ? NaN : aggregate_func(tuple...) for tuple in result]
end
    
# Receives a training setup and optionally a size grid and return
# the loss vectors of all surface points, alongside with the size vectors
# THE SCORE FUNCTION MUST HAVE THE BENCHMARK PARAMETER SET TO TRUE
function loss_vectors_surface(score_function, sizes, n_noise, n_signal)
    results = error_size_grid(score_function, sizes, n_noise, n_signal)
    return results
end

# This functions receives a size grid and compute the
# error at different signal2noise ratios for each size
# in the grid, returning an array of (x, y) tuples
function error_size_grid(score_function, sizes, n_noise, n_signal)
    results = Array{Any}(UndefInitializer(), length(sizes))    
    #Threads.@threads for i = 1:length(sizes)
    for i = 1:length(sizes)
        results[i] = error_fixed_size(sizes[i], score_function, n_noise, n_signal)
    end    
    return results
end

# This functions assume an structure where the first interval is only
# noise and the second one is only signal, here we can change the size
# of an interval and study what happens to the score function as the
# signal2noise ratio changes
function error_fixed_size(n_size, score_function, n_noise=285, n_signal=285)
    error_score = Array{Any}(UndefInitializer(), n_size + 1)
    start = n_noise - n_size - 1
    valid_interval(i) = ((i + start) >= 1) && ((i + start + n_size) <= (n_noise + n_signal))
    for i in 1:(n_size + 1)
        if valid_interval(i)
            interval = (i + start):(i + start + n_size)
            error_score[i] = score_function(interval)
        else
            error_score[i] = nothing
        end
    end
    return error_score
end

