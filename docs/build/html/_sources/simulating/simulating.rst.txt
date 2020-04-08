=========================================
Simulating Random and Predictable Signals
=========================================

The PCrawl library comes with functions to simulate simple predictable and 
unpredictable patterns. The function to simulate random noise and ar1 innovations
are respectivly wn and ar1, and are avaiable once the library has been imported. 
They can be combined in the same expression to generate a simulation with both
predictable and unpredictable patterns, and output the simulated signal togheter
with a reference signal that is 1 for predictable samples and 0 otherwise. 
An example utilization would be::

    using PCrawl

    simulation = [wn(100);ar1(100);wn(200)]
    signal = simulation[:, 1]
    reference = simulation[:, 2];

If the signals and reference series are plotted::

    pty.plot(signal, pty.Layout(title="Simulated Signal"))


.. image:: img/signal.png
    :align:   center
    :width: 600

The function plot_predictability can be used to combine the two, highlighting
the predictable periodos in the series::

    plot_predcitability(signal, reference, title="Predictable Periods")

.. image:: img/predictable_periods.png
    :align:   center
    :width: 600


This example can be found in the examples/SimulatingSignals.ipynb file.




Simulated Signals Reference
===========================

.. function:: wn(nr_samples::Int64 [, \sigma=2])

    Generates a series of random observation from a zero-mean Gaussian distribution.
    Arguments:

    - nr_samples = Number of samples in the simulation
    - :math:`\sigma`  = The variance of the Gaussian distribution

    Returns a [nr_samples, 2] vector, where the first column is the simulated signal 
    and the second column is a reference signal of 0s, indicating non-predictability.
    Location : Utils/simulate.jl

.. function:: wn2(nr_samples::Int64 [, bound=4])

    Generates a series of random observation from a zero-mean Uniform distribution.
    Arguments:

    - nr_samples = Number of samples in the simulation
    - bound  = The value for the upper and lower bound of the Uniform function

    Returns a [nr_samples, 2] vector, where the first column is the simulated signal 
    and the second column is a reference signal of 0s, indicating non-predictability.
    Location : Utils/simulate.jl


.. function:: ar1(nr_samples::Int64 [, \phi=.7, \sigma=2])

    Generates a series of random observation from the AR1 process.

    :math:`y_{t} = y_{t-1} * \phi + \eta_{t}`

    Where :math:`\phi` is the fist lag coefficient and :math:`\sigma` is the normal
    innovations variance.

    Arguments:

    - nr_samples = Number of samples in the simulation
    - ::math:`\phi`  = Number of samples in the simulation
    - ::math:`\eta`  = Variances for the zero-mean normal innovations :math:`\eta_{t}` 

    Returns a [nr_samples, 2] vector, where the first column is the simulated signal 
    and the second column is a reference signal of 1s, indicating predictability.
    Location : Utils/simulate.jl


.. function:: plot_predictability(signal, reference [, title=nothing])

    Plot the signal highlighting the periods where the reference mark a predictable pattern.

    Arguments:

    - signal = The time-series to be plotted
    - reference  = A boolean vector (or of 0s and 1s) determining the predictability of each sample
    - title = The title of the plot.

    Returns time-series plot of the series with the highlighted predictable zones. If no title is provided,
    the title is just the coverage of the reference (percentage of predicatable samples).
    Location : Utils/visualization.jl
