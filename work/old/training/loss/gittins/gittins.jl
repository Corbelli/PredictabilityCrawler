using JLD

file = load("previsibility-crawler/training/loss/gittins/gittins.jld")
coefs = file["coefs"];
mean_values = file["mean_values"];
G = file["G_400_1200_09"];

function get_closest_indices(vector, value)
    diffs = vector .- value
    index1 = findall(x -> x==min(abs.(diffs)...), abs.(diffs))[1]
    if value < vector[index1]
        return max(index1 - 1, 1), index1
    end
    return index1, min(index1 + 1, length(vector))
end

function λ_aprox_factory(i, coefs, λ_values)
    coefs_ = coefs[i]
    λ = λ_values[i]
    return function λ_aprox(n)
        y = coefs_[1] + coefs_[2]*n + (coefs_[3]/n)
        return (1/y) + λ
    end
end

function gittins_aprox_factory(coefs, mean_values)
    λ_values = collect(mean_values)
    return function gittins_aprox(α, β)
        total = α + β
        λ = α / total
        i1, i2 = get_closest_indices(λ_values, λ)
        λ1, λ2 = λ_values[i1], λ_values[i2]
        g1, g2 = λ_aprox_factory(i1, coefs, λ_values)(total), λ_aprox_factory(i2, coefs, λ_values)(total)
        return g1 + ((λ - λ1)/(λ2 - λ1))*(g2 - g1)
    end
end

gittins_aprox = gittins_aprox_factory(coefs, mean_values)

function gittins_index(α, β)
    total = α + β
    if α == 0 
        return 0
    end
    if β == 0 
        return 1
    end
    if total <= 400
        return G[Int(α), Int(β)]
    end
    return gittins_aprox(α, β)
end