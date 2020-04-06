include("../gene.jl");
include("../../utils/sample.jl");

using DSP
using Random
using Distributions

choke(x, threshold) = [sample > threshold ? threshold : sample for sample in x]

function generate_ga_gene(signal_size::Int64, min_samples::Int64, 
                                group_size::Int64, signal_density::Float64)
    mean_groups_expected = (signal_size*signal_density)/group_size
    min_groups = Int(ceil(min_samples/group_size))
    mean_groups_variance = mean_groups_expected/ 5
    n_groups_distribution = Normal(mean_groups_expected, mean_groups_variance)
    n_groups = Int(round(rand(n_groups_distribution)))
    n_groups = n_groups < min_groups ? min_groups : n_groups
    groups = shuffle!([repeat([1], n_groups); repeat([0], signal_size - n_groups)])
    gene = (choke(conv(groups, DSP.rect(group_size)), 1) .>= .5)[1:signal_size]
    ashure_minimum(gene, min_samples, group_size)
end

function ashure_minimum(gene, min_samples, group_size, max_iter=50)
    iter = 0
    n = length(gene)
    while count(gene) < min_samples && iter < max_iter
        mutation_start = rand(1:n)
        mutation_end = mutation_start + group_size > n ? n : mutation_start + group_size
        gene[mutation_start:mutation_end] = repeat([true], mutation_end - mutation_start + 1)
        iter += 1
    end
    return gene
end

struct GASetting
    min_samples::Int64
    group_size::Int64
    signal_density::Float64
end

Gene(size::Int64, settings::GASetting) = Gene(generate_ga_gene(
                                                                size,
                                                                settings.min_samples,
                                                                settings.group_size,
                                                                settings.signal_density),
                                              settings, size)

Gene(dna::BitArray{1}, settings::GASetting) = Gene(dna, settings, length(dna))

activation(values, ga_gene, settings::GASetting) = copy(ga_gene)

GA(;min_samples=70, group_size=10, signal_density=.1) = GASetting(min_samples, group_size, signal_density)
print(gene, settings::GASetting) = plot(gene)

function init_population(pop_size::Int64, settings::GASetting, gene_size::Int64) 
    pop = []
    for i= 1:pop_size
        push!(pop, Gene(gene_size, settings))
    end
    return pop
end

function crossover(gene1::Gene, gene2::Gene)
    dna1 = activate(nothing, gene1)
    dna2 = activate(nothing, gene2)
    size = length(dna1)
    point1, point2 = sort(uniq_rand(1:size, 2))   
    temp = dna1[point1:point2]
    dna1[point1:point2] = dna2[point1:point2]
    dna2[point1:point2] = temp    
    return Gene(dna1, gene1.settings), Gene(dna2, gene2.settings)
end

flip(x) = [sample ? false : true for sample in x]

function mutate(gene::Gene)
    dna = activate(nothing, gene)
    size = length(dna)
    point1, point2 = sort(uniq_rand(1:size, 2))
    dna[point1:point2] = flip(dna[point1:point2])    
    mutated = Gene(dna, gene.settings)
end