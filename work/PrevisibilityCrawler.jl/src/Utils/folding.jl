using ResumableFunctions
using Random

# Usual K-folding
@resumable function kfold(x, nfolds::Int64)
    groupsize, rem = divrem(size(x, 1), nfolds)
    for i in 1:nfolds
        test = fill(false, size(x, 1))
        margin = i == nfolds ? rem : 0
        test[(i-1)*groupsize+1:i*groupsize+margin] = fill(true, groupsize+margin)
        train = .!test
        @yield train, test
    end
end

function kfolding(nfolds)
    temp_folding(x) = kfold(x, nfolds)
end

#Random Folding
@resumable function randomkfold(x, nfolds::Int64)
    n, r = divrem(size(x, 1), nfolds)
    folds = Random.shuffle!([repeat(1:nfolds, outer=n); 1:r])
    for i in 1:nfolds
        @yield folds .!= i , folds .== i
    end
end

function krandomfolding(nfolds)
    temp_folding(x) = randomkfold(x, nfolds)
end



# Bootstrapped folding with frac percentage of sample size and j bags
@resumable function jnfold(x, frac::Float64, j::Int64)
    n1 = Int(round(frac*size(x, 1)))
    n2 = size(x, 1) - n1
    for i = 1:j
        folds = Random.shuffle!([fill(0, n1); fill(1, n2)])
        @yield folds .== 0 , folds .== 1
    end
end

function jnfolding(train_frac, j)
    temp_folding(x) = jnfold(x, train_frac, j)
end



