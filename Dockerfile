FROM jupyter/datascience-notebook

# Creating workspace
ENV WORKSPACE=/home/jovyan/work/
RUN mkdir -p $WORKSPACE
WORKDIR $WORKSPACE

# Project dependency
RUN jupyter labextension install @jupyterlab/plotly-extension
COPY requirements.jl requirements.jl
RUN  julia requirements.jl
