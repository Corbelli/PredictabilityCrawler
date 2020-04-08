FROM jupyter/datascience-notebook@sha256:b672f926e0f2ddb4b68172d33c0fea64f8f66651e86e233dc12894ddf7299b98

# Creating workspace
ENV WORKSPACE=/home/jovyan/work/
RUN mkdir -p $WORKSPACE
WORKDIR $WORKSPACE

## Buiding Jupyter Lab
RUN pip install jupyterlab==1.2 "ipywidgets==7.5"
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@1.1 --no-build
RUN jupyter labextension uninstall @bokeh/jupyter_bokeh --no-build
RUN jupyter labextension install plotlywidget@1.4.0 --no-build
RUN jupyter labextension install jupyterlab-plotly@1.4.0 --no-build
RUN jupyter lab build --minimize=False --debug

## Project dependency
COPY . .
RUN  julia requirements.jl

CMD jupyter lab 