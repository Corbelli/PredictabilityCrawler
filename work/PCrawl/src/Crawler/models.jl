using XGBoost

# Visual inspection on the variation of predictability of the model on the data
function halfsample(x, y, model, name::String="")
    idloss(loss, a, b) = loss
    sizes = [1000]
    prevloss = idloss;
    pipe = Pipeline(model, rmae);
    algo = Algorithm(prevloss, minsamples=500, k=3);
    scorefunction = training(x, y, algo, pipe);
    xreal, yreal = random_points(500, sizes, length(y), scorefunction);
    histreal = pty.histogram(x=yreal, opacity=.7, name=name, histnorm="probability density");
    pty.plot([histreal], 
             pty.Layout(title="Half-sample Histogram for $name Data", barmode="overlay"))
end

# Train the classifier and use it to find new predictable samples
function classifynew(x, signal, outofsample_x; thresh::Float64=.5, num_round=500)
    param = ["max_depth" => 6, "eta" => .8, "subsample" => 1, "objective" => "binary:logistic"]
    previsible = xgboost(convert(Matrix, x), num_round, label=signal, param=param, silent=1);
    predicted = XGBoost.predict(previsible, convert(Matrix,outofsample_x))
    predicted .>= thresh
end

function boostgrid(x, y; nr_rounds::Int64=50)
    param = gridoptmodel(x, y, nr_rounds=nr_rounds) # 50
    model = XgBoostModel(Dict(:params=>param, :nr_round=>nr_rounds)); # 500
end

boostcrawlerparam = ["max_depth"=>2, "eta"=>.6, "subsample"=>1, "objective"=>"reg:linear"]
boostcrawler = XgBoostModel(Dict(:params => boostcrawlerparam, :nr_round => 10));


function rfgrid(x, y; ntrees=40)
    params = rfgridmodel(x, y, ntrees=ntrees)
    model = RandomForestModel(Dict(:params => params));
end

rfcrawlerparam = Dict(:maxdepth=>10, :nfeatures=>30, :sampleportion=>1.0, :ntrees=>10)
rfcrawler = RandomForestModel(Dict(:params => rfcrawlerparam));

function crossmase(x, y, model)
    pipe = Pipeline(model, rmae)
    train, test = crossvalidation!(pipe, x, y , k=5)
end