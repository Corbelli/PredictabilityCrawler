function pcrawlerevol(x, y, model; minsamples::Int64=500, plot::String="progress")
    acceptable = [2000, 4000, 6000]
    intervals = [1:2000, 2001:4000, 4001:6000]
    modelloss = rmae
    explainedmae(loss, prevy, datasetsize) =  (length(prevy)/datasetsize)*0.1 + (1- loss)
    prevloss = explainedmae
    pipe = Pipeline(model, modelloss);
    algo = Algorithm(prevloss, minsamples=minsamples, k=3);
    evolsettings = EvolSettings(;pressure=2, mutation_p=10, crossover_p=80, elitism=1);
    gasettings = GA(2000 ;minsamples=minsamples, groupsize=40);
    totalsize = size(x, 1)
    !(totalsize in acceptable) && throw("Acceptable sizes: 2000, 4000 or 6000. Keep it simple, ok?")
    nrruns = div(totalsize, 2000)
    runintervals = intervals[1:nrruns]
    signal = []
    for interval in runintervals
        xtemp = x[interval, :]
        ytemp = y[interval, :]
        scorefunction = training(xtemp, ytemp, algo, pipe);
        pop = init_genes(100, gasettings)
        pop, graphs = evolution(pop, scorefunction, 100, evolsettings, plot, knn=5);
        scores = scorefunction(pop);
        best = pop[sortperm(scores, rev=true)[1]];
        push!(signal, convert(Vector{Bool}, activate(best)))
    end
    return vcat(signal...)
end

function pcrawlerpso(x, y, model; minsamples::Int64=400, plot::String="progress")
    acceptable = [2000, 4000, 6000]
    intervals = [1:2000, 2001:4000, 4001:6000]
    modelloss = rmae
    explainedmae(loss, prevy, datasetsize) =  (length(prevy)/datasetsize)*0.3 + (1- loss)
    prevloss = explainedmae
    pipe = Pipeline(model, modelloss);
    algo = Algorithm(prevloss, minsamples=minsamples, k=3);
    settings = PSO(phip=.5, phig=1, w=.5, K=5, max_iter=100)
    nrparticles = 100; groupsize = 40; minsamples =minsamples;
    totalsize = size(x, 1)
    !(totalsize in acceptable) && throw("Acceptable sizes: 2000, 4000 or 6000. Keep it simple, ok?")
    nrruns = div(totalsize, 2000)
    runintervals = intervals[1:nrruns]
    signal = []
    for interval in runintervals
        xtemp = x[interval, :]
        ytemp = y[interval, :]
        scorefunction = training(xtemp, ytemp, algo, pipe);
        particles = Particle.(random_init(nrparticles, groupsize, x, minsamples=minsamples), scorefunction);
        particles, graphs = pso(particles, scorefunction, settings, plot)
        push!(signal, convert(Vector{Bool}, classify(particles)))
    end
    return vcat(signal...)
end
