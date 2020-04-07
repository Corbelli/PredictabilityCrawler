FROM jupyter/datascience-notebook:6c3390a9292e

# Creating workspace
ENV WORKSPACE=/home/jovyan/work/
RUN mkdir -p $WORKSPACE
WORKDIR $WORKSPACE

# Project dependency
RUN jupyter labextension install @jupyterlab/plotly-extension
COPY requirements.jl requirements.jl
RUN  julia requirements.jl

CMD jupyter lab