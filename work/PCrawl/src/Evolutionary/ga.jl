using ..PCrawl.Utils: uniq_rand, sample_pop!, random_chance, sample
using ..PCrawl: plt
using DSP
using Random
using Distributions

struct GASetting
    samplesize::Int64
    minsamples::Int64
    groupsize::Int64
end

GA(samplesize::Int64;minsamples::Int64=70, groupsize::Int64=10) = GASetting(samplesize, minsamples, groupsize)

struct Gene
    dna::BitArray{1}
    settings::GASetting
end

function Gene(samplesize::Int64, minsamples::Int64, groupsize::Int64)
    nr_alphas, offset = divrem(samplesize, groupsize)
    offset != 0 && (nr_alphas += 1)
    setsize =  Int64(ceil(minsamples/groupsize)) + 1
    indices = collect(1:nr_alphas)
    sampled = sample_pop!(indices, setsize)
    alphas = fill(false, nr_alphas)
    [alphas[j] = true for j in sampled]
    Gene(BitArray(alphas), GASetting(samplesize, minsamples, groupsize))
end

function init_genes(nr_genes::Int64, settings::GASetting)
    samplesize=settings.samplesize; groupsize=settings.groupsize; minsamples=settings.minsamples
    nr_alphas, offset = divrem(samplesize, groupsize)
    offset != 0 && (nr_alphas += 1)
    setsize =  Int64(ceil(minsamples/groupsize)) + 1
    indices = collect(1:nr_alphas)
    genes = Vector{Gene}(undef, nr_genes)
    for i=1:nr_genes 
        if length(indices) < setsize
            remaining = setsize - length(indices)
            sampled = indices
            indices = collect(1:nr_alphas)
            sampled = [sampled;sample_pop!(indices, remaining)]
        else
            sampled = sample_pop!(indices, setsize)
        end
        alphas = fill(false, nr_alphas)
        [alphas[j] = true for j in sampled]
        genes[i] = Gene(BitArray(alphas), GASetting(samplesize, minsamples, groupsize))
    end
    return genes
end


Gene(settings::GASetting) = Gene(settings.samplesize, settings.minsamples, settings.groupsize)
getoffset(gene::Gene) = rem(gene.settings.samplesize, gene.settings.groupsize);
distance(gene1::Gene, gene2::Gene) = count(xor.(gene1.dna, gene2.dna))

function activate(gene::Gene)
    values = copy(gene.dna)
    sizes = fill(gene.settings.groupsize, length(values))
    getoffset(gene) != 0 && (sizes[1] = getoffset(gene))
    return convert(BitArray{1}, vcat(fill.(values, sizes)...))
end 

choke(x, threshold) = [sample > threshold ? threshold : sample for sample in x]

function init_population(popsize::Int64, settings::GASetting) 
    pop = Vector{Gene}(undef, popsize)
    [pop[i] = Gene(settings) for i in 1:popsize]
    return pop
end

function resetpop(population::Vector{Gene}, scores::Vector{Float64}, nr_to_keep::Int64=1)
    popsize = length(population)
    best = deepcopy(population[sortperm(scores, rev=true)[1:nr_to_keep]])
    pop = init_population(popsize-nr_to_keep, best[1].settings);
    new_pop = [pop; best]
    return new_pop
end
    
function get_size_snr(population::Vector{Gene}, reference::BitArray{1}, scorefunction::Function)
   scores_pop = sort(collect(zip(scorefunction(population), population)), by=x->x[1], rev=true)
   best = scores_pop[1][2]
   size = count(activate(best))
   solution = activate(best)
   snr = count((.!xor.(reference, solution))[solution])/count(solution)
   return size, snr
end

function crossover2p(gene1::Gene, gene2::Gene)
    dna1 = copy(gene1.dna)
    dna2 = copy(gene2.dna)
    size = length(dna1)
    point1, point2 = sort(uniq_rand(1:size, 2))   
    temp = dna1[point1:point2]
    dna1[point1:point2] = dna2[point1:point2]
    dna2[point1:point2] = temp    
    return Gene(dna1, gene1.settings), Gene(dna2, gene2.settings)
end
    
function crossover1p(gene1::Gene, gene2::Gene)
    dna1 = deepcopy(gene1.dna)
    dna2 = deepcopy(gene2.dna)
    size = length(dna1) - 1
    point1 = rand(1:size, 1)[1]
    temp = dna1[1:point1]
    dna1[1:point1] = dna2[1:point1]
    dna2[1:point1] = temp
    return Gene(dna1, gene1.settings), Gene(dna2, gene2.settings)
end
    
crossover(gene1::Gene, gene2::Gene) = crossover1p(gene1::Gene, gene2::Gene)

flip(x) = [sample ? false : true for sample in x]

function mutate(gene::Gene)
    dna = copy(gene.dna)
    size = length(dna)
    [dna[i] = !dna[i] for i in 1:size if random_chance(10/size)]
    mutated = Gene(dna, gene.settings)
end