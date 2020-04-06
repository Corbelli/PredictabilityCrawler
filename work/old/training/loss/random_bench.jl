include("../../utils/sample.jl");


function random_activation(size::Int64, snr::Float64, reference)
    signals = findall(x->x==1, reference)
    noises = findall(x->x==0, reference)
    nr_signal = Int(round(snr*size))
    spots = []
    try
        spots = [uniq_rand(noises, size - nr_signal); uniq_rand(signals, nr_signal)]
    catch
        return nothing
    end
    choosen = repeat([false], length(reference))
    [choosen[i] = true for i in spots]
    return convert(BitArray{1}, choosen)
end

function error_surface_point(size, snr, reference, score_function)
    activation = random_activation(size, snr, reference)
    score = activation == nothing ? NaN : score_function(activation)[1]
    return snr, size, score
end

function random_points(nr_points, sizes, snrs, reference, score_func)
    x = []
    y = []
    z = []
    for i=1:nr_points
        temp = error_surface_point(rand(sizes, 1)[1], rand(snrs, 1)[1], reference, score_func)
        push!(x, temp[1])
        push!(y, temp[2])
        push!(z, temp[3])
    end
    return x, y, z   
end
    
    

function score_points(population, score_func, reference)
    points = [point(gene, score_func, reference) for gene in population]
    x = [point[1] for point in points]
    y = [point[2] for point in points]
    z = [point[3] for point in points]
    return x, y, z
end
    
function point(gene, score, reference)
    activation = activate(nothing, gene)
    selected = reference[activation]
    y = count(activation)
    z = score(gene)
    x = sum(selected)/length(selected)
    return x, y, z
end