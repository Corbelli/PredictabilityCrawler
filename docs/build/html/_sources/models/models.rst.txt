=========================================
Statistical Models for Series Forecasting
=========================================

The PCrawl library has a simple but extensible collection of statistical learning 
models to be used for predition. This section describes how to use the simulations
to test those models, and how they are structered.

Preparing Feature & Target Matrices
===================================

The PCrawl assumes a Feature & Target Matrices representation. This means that information about
the simulated time series up to instant t has to be embedded in a vector. A simple approach
is to use the last :math:`n` observations as a vector, a window summarizing past information. 
The target to be infered from this set is the next value of the series. Once the windowsize
has been settled, it is easy to transform the simulation data into a Feature, Target, and Reference
matrices::

    using PCrawl

    simulation = [wn(100);ar1(100);wn(200)]
    windowsize = 15
    x, y, reference = make_x_y_ref(simulation, 15)

Statistical Learning Models
===========================

In order to train a model, it is necessary to define some entities.

- The Loss function
- The Statistical Model
- The Processing Pipeline 

Well see how the PCrawl defines each one of those entities.

Loss functions
--------------

Loss functions define the numeric quantity to be minimized during the training. Although the PCrawl 
admits both loss functions for Regression and Classification, only regression loss functions are currently
avaible. Defining a new loss is very straightfoward, it just needs to be function that receives two target matrices
(y and y_hat) and output a number representing how close they are according to the chosen method. 
Example regressions loss functions are:

.. function:: mae(y_hat, y)

    returns :math:`\frac{1}{n}  \sum_{i=1}^{n} |y_{hat} - y|` 

.. function:: rmae(y_hat, y)

    returns :math:`\frac{\frac{1}{n}  \sum_{i=1}^{n} |y_{hat} - y|}{\frac{1}{n} \sum_{i=1}^{n} |y|}` 
    
    obs: when y and y_hat are innovations, the rmae is equivalent to the MASE of the integrated series
    
.. function:: mse(y_hat, y)

    returns :math:`\frac{1}{n}  \sum_{i=1}^{n} (y_{hat} - y)^{2}` 

.. function:: rmse(y_hat, y)

    returns :math:`\sqrt{\frac{1}{n}  \sum_{i=1}^{n} (y_{hat} - y)^{2}}` 

All loss functions are located at Utils/lossfunctions.jl


Statistical Models
------------------

The PCrawls models make use of the Julia Language inheritance capability. They all inherit from
a abstract base class Abstract model. This class defines a interface of methods every model have
to implement  in order to function. (In Julia, the ! at the end of a function means that the function
alters one of the parameters given, and the <: symbol means that the parameter is a class inherited
from the specifed type). Those methods are:

.. function:: trainmodel(model<:AbstractModel, x, y)
    
    Trains the model passed (altering the object) to fit the features x to the target y.
    
.. function:: modelpredict(model<:AbstractModel, x)
    
    Uses the model to predict targets based on the features x. Returns the predicted targets

Every model class has a internal dict named meta, where model parameters are stored.
Apart from the above functions, every models implements a custom form o hyperparmeter tunning,
and model specif methods, such as returning feature importances.
The statistical models implemented are RandomForest, the Gradient Boosting Model, and the LASSO.

Random Forests
^^^^^^^^^^^^^^

The hyper-parameter tunning implemented for the Random Forests model is 

.. function:: rfgridmodel(x, y, [depths=[2, 3, 4, 5], portions=[.3, .4, .5, .6, .7, .8, .9], 
             nfeatures=[5, 10, 15, 20], ntrees=10]) 
             
   Performs a grid search to determine the depth of the trees, the bootstraped portion of the
   dataset, and the number of features to use at each tree. The search optimizes the in-sample
   loss for data set (x, y).

   Return a dict of params that can be used as the model meta.

The Random Forest model is located at Learning/randomforests.jl

LASSO
^^^^^

The hyper-parameter tunning implemented for the LASSO model is:

.. function:: setlambda!(model, x, y)
             
   Uses the BIC loss criterion to determine the :math:`\lambda` to be used used in the model.
   This function is also used inside the trainmodel! function for the LASSO. But it can be choosen
   to use a pre-defined :math:`\lambda` to train

The LASSO model also has a convinience function 

.. function:: lassobic(x, y)
             
   Returns a trained LASSO with :math:`\lambda` the BIC criterion and on the dataset.

Once the LASSO model is trained, a number of functions can be used to extract information from it. 
Some examples are:


.. function:: lambda(model)
             
   Returns the :math:`\lambda` function of the model

.. function:: coefs(model)
             
   Returns the coefficients of the adjusted regression

These and others can be found at Learning/lasso.jl

XGBoost
^^^^^^^

The XGBoost is the gradient boosting implemented by the XGBoost library.
The hyper-parameter tunning implemented for the XGBoost model is

.. function:: gridoptmodel(x, y, [depths=[2, 3, 4, 5, 6], etas=[.3, .4, .5, .6, .7, .8], subs=[.3, .4, .5, .6, .7, .8]],
                      nr_rounds)
    
    Perform a grid-search to choose the depths of the trees, the normalizing eta parameterer, and the 
    amount of sub-sampling to use a each stage. The choice is made to minimize the in-sample error in the
    dataset (x, y) when training with nr_rounds trees.

    Returns a params dict that can be used as a meta to the XGBoost model. 

The above function can help determine all hyper-parameters except for the number of trees, 
which is very important. To do that, the model implements

.. function:: earlystopcv(x, y, nr_round, pipeline::Pipeline)

    This function Plots the evolution of the cross-validated loss function error from the 
    pipeline (see section below) containig a XGBoost model when the number of 
    trees grows from 1 to nr_round, and can be used to determine the optimal number of rounds to use.

Besides hyper-parameter tunning, the XGBoost model is capable of estimating a relative feature importance.
To use this capability as a feature-selection scheme, the code implements

.. function:: topfeatures(xmat, y, [nrfeatures=20])

    Given a feature matrix xmat, return only the columns refering the the top nrfeatures, 
    according to the feature importance of a XGBoost model with default hyperparameters 
    trained to minimize the rmae loss function adjusting xmat to y.

The functions refering to the XGBoost model can be found at Learning/xgboost.jl.

Data Treatment Pipeline 
-----------------------

A pipeline consists of a model, a loss function, and data transformations, along with the
choice of wether to compute the loss function in the original space or in the transformed one.
The data transformations are operations to be applied to both the feature and target before they
are fed to the model. If the original_space option is true, they are transformed back before the 
loss is computed, if not, the loss is computed right on the model output. 

Data Transforms
^^^^^^^^^^^^^^^

Data Transforms also make use of the Julia Language inheritance capability. The abstrac base class
AbstractTransform implements the methods

.. function:: fit!(transform<:AbstractTransform, x)

    Fits the given transform to the dataset x. Eg. calculates coeffs for PCA, mean and stds
    for normalization, etc...

.. function:: apply(transform<:AbstractTransform, x)

    Apply the fitted transform to x, returning the result

.. function:: reverse(transform<:AbstractTransform, x)

    Reverse the transformatio in x, returning the result

When those functions are implemented for a new transform, it can use

.. function:: fit_apply!(transform<:AbstractTransform, x)
    
    Fit and apply the transform to x

The implemented transforms avaiables are the NormTransform and the IdTransform.
They can be found at Learning/tranforms.jl

Pipeline Methods
^^^^^^^^^^^^^^^^

A pipeline has the methods 

- train!(pipe::Pipeline, x, y)
- predict(pipe::Pipeline, x)
- loss(pipe::Pipeline, x, y)
- getmodel(pipe::Pipeline)
- crossvalidation!(pipe::Pipeline, x, y; k=5)


Putting it all Together
=======================



