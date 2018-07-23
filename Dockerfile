FROM ubuntu:latest
LABEL maintainer="stephenkrol"
LABEL version=".4"
LABEL description="Jupyter Notebook with kernels: Clojure, Groovy, Java, Kotlin, Python 2/3, R, SQL, Scala, and SciJava. Includes many common Python and R data science libraries. Adapted from https://github.com/andreivmaksimov/python_data_science/blob/master/Dockerfile. Note: Requires internet access to build."

# Environment variables:
# This section is mostly set up for making easy changes as desired. Don't change CONDA_BIN.
# You may also want to change the SSL certificate options in the "Set up Jupyter" section.
# Directories
ENV INSTALL_BASE /opt \
	CONDA_DIR ${INSTALL_BASE}/conda \
	CONDA_BIN ${CONDA_DIR}/bin \
	H2O_DIR ${INSTALL_BASE}/h2o \
	JUPYTER_CFG_DIR /root/.jupyter \
	NOTEBOOKS_DIR ${CONDA_DIR}/notebooks \
	# Apt packages
	APT_PKGS "openssl openjdk-8-jre python2.7-minimal python-pip unzip" \
	# Additional options
	JUPYTER_PORT 8888 \
	# Software
	TINI_VERSION v0.18.0 \
	H2O_VERSION 3.20.0.3 \
	CONDA Anaconda3 \
	CONDA_VERSION 5.2.0 \
	CONDA_URL https://repo.anaconda.com/archive
# For Miniconda, uncomment these lines and delete the three lines above
#ENV CONDA Miniconda3 \
#ENV CONDA_VERSION latest \
#ENV CONDA_URL https://repo.continuum.io/miniconda

# Move over required files
RUN mkdir -p ${JUPYTER_CFG_DIR}/nbconfig
COPY cfg/anaconda.txt ${INSTALL_BASE}/
COPY cfg/jupyter_notebook_config.py ${JUPYTER_CFG_DIR}/
ADD ${CONDA_URL}/${CONDA}-${CONDA_VERSION}-Linux-x86_64.sh ${INSTALL_BASE}/
ADD http://h2o-release.s3.amazonaws.com/h2o/rel-wright/3/h2o-$H2O_VERSION.zip ${INSTALL_BASE}/

# Update packages
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y $APT_PKGS && \
	rm -rf /var/lib/apt/lists/* && \
	apt-get clean && \
	
	# Install $CONDA to $CONDA_DIR
	bash ${INSTALL_BASE}/${CONDA}-${CONDA_VERSION}-Linux-x86_64.sh -b -p $CONDA_DIR && \
	rm ${INSTALL_BASE}/${CONDA}-${CONDA_VERSION}-Linux-x86_64.sh && \
	
	# Update Anaconda
	${CONDA_BIN}/conda update conda -y && \
	${CONDA_BIN}/conda update --all -y && \
	
	# Install Anaconda environment with data science packages
	${CONDA_BIN}/conda install --file ${INSTALL_BASE}/anaconda.txt && \
	${CONDA_BIN}/conda clean --all -y && \
	rm ${INSTALL_BASE}/anaconda.txt && \
	${CONDA_BIN}/jupyter nbextension disable _nb_ext_conf && \
	
	# Python2 kernel setup
	python2 -m pip install --upgrade pip && \
	python2 -m pip install ipykernel && \
	python2 -m ipykernel install --user && \
	
	# Add newer H2O to $H2O_DIR
	# Note: Add the r package manually via Jupyter if desired
	mkdir $H2O_DIR && \
	unzip ${INSTALL_BASE}/h2o-${H2O_VERSION}.zip && \
	# mv ${INSTALL_BASE}/h2o-${H2O_VERSION}/ $H2O_DIR && \
	# rm -rf ${INSTALL_BASE}/h2o-${H2O_VERSION}/ && \
	# rm -rf ${H2O_DIR}/python/ && \
	
	# Sparkmagic kernel setup
	$CONDA_BIN/jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
	# The following is a config file with a bunch of options. Uncomment and change directory to grab the example from GitHub
	# ADD https://raw.githubusercontent.com/jupyter-incubator/sparkmagic/master/sparkmagic/example_config.json /home/ubuntu/.sparkmagic/config.json 
	# Uncomment to enable server extension so that clusters can be changed
	# RUN ${CONDA_BIN}/jupyter serverextension enable --py sparkmagic

	# Set up Jupyter 
	# Note: SSL key good for one year
	# mkdir $JUPYTER_CFG_DIR && \
	# mkdir ${JUPYTER_CFG_DIR}/nbconfig && \
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${JUPYTER_CFG_DIR}/mykey.key -out ${JUPYTER_CFG_DIR}/mycert.pem -batch && \
	${CONDA_BIN}/jupyter nbextension enable beakerx --py --sys-prefix && \
	${CONDA_BIN}/jupyter nbextension enable jupyter_dashboards --py --sys-prefix && \
	${CONDA_BIN}/jupyter nbextensions_configurator enable --user

# Add Tini
# Tini operates as a process subreaper for Jupyter. This prevents kernel crashes.
# Taken from Jupyter 5.5.0 documentation
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

# Open port for Jupyter
# Note: Change this if you change c.NotebookApp.port in cfg/jupyter_notebook_config.py
EXPOSE $JUPYTER_PORT

# Store for notebooks 
VOLUME $NOTEBOOKS_DIR

# Start Jupyter Notebook
CMD ["jupyter", "notebook", "--port=${JUPYTER_PORT}", "--no-browser", "--ip=0.0.0.0"]
