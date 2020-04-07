==========================
Setting Up the Environment
==========================

Code Base
=========

The code for the application is written in Julia. The examples are displayed in 
Jupyter Lab. You can choose to install Julia and Jupyter Lab in your machine locally,
but the source code comes with a docker image that can be used to run the examples and code
in your machine. It also comes with a Makefile with usefull comands (only works out-of-the-box in
Linux and Mac).



.. tip:: 
   The setup was created with the Docker approach in mind, so it shoul be easier to use.

To install Julia and Jupyter Lab in your computer, follow the instructions:

- `Install the Julia Language executable <https://julialang.org/downloads/>`_
- `Install Python <https://www.python.org/downloads/>`_
- `Install Jupyter Lab <https://jupyterlab.readthedocs.io/en/stable/getting_started/installation.html/>`_
- Configure Julia to run with Jupyter Lab (link pending)

Instead, the setup for using the Docker image is as simple as:

- `Install the Docker client <https://docs.docker.com/install/>`_


Running with Docker
-------------------

If you are in a Linux/Mac environment, after you have Docker, you can cd into the code root
directory and type in the terminal::

    make start 

At the first time, docker will download the image first, so this can take a while, but will be
pretty fast afterwards. After the containers have start, type::

    make link 

A link will appear in your terminal. Click the link or paste it in the browser.