FROM ubuntu:latest
LABEL maintainer="stephenkrol"
LABEL version=".5"
LABEL description="Jupyter Notebook with kernels: Clojure, Groovy, Java, Kotlin, Python 2/3, R, SQL, Scala, and SciJava. Includes many common Python and R data science libraries. Adapted from https://github.com/andreivmaksimov/python_data_science/blob/master/Dockerfile. Note: Requires internet access to build."

# Update packages
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y openssl openjdk-8-jre python2.7-minimal python-pip unzip && \
	rm -rf /var/lib/apt/lists/*
	
# Install Anaconda3 to /opt/Anaconda
WORKDIR /opt
ADD https://repo.anaconda.com/archive/Anaconda3-5.2.0-Linux-x86_64.sh /opt
RUN	chmod +x Anaconda3-5.2.0-Linux-x86_64.sh && \
	bash Anaconda3-5.2.0-Linux-x86_64.sh -b -p /opt/Anaconda && \
	export PATH="/opt/anaconda/bin:$PATH" && \
	rm Anaconda3-5.2.0-Linux-x86_64.sh
	
# Update Anaconda
RUN /opt/Anaconda/bin/conda update conda -y && \
	/opt/Anaconda/bin/conda update --all -y
	
# Install Anaconda environment with data science packages
COPY cfg/anaconda.txt ./
RUN /opt/Anaconda/bin/conda install --file anaconda.txt && \
	/opt/Anaconda/bin/conda clean --all -y && \
	rm anaconda.txt && \
	/opt/Anaconda/bin/conda remove _nb_ext_conf -y # This breaks kernels per env but removes duplicate kernels in that sense.
	
# Add Python2 kernel
RUN python2 -m pip install --upgrade pip && \
	python2 -m pip install ipykernel && \
	python2 -m ipykernel install --user 
	
# Add newer H2O to /opt/h2o
# Note: Add the r package manually via Jupyter if desired
ADD http://h2o-release.s3.amazonaws.com/h2o/rel-wright/3/h2o-3.20.0.3.zip /opt
RUN mkdir /opt/h2o && \
	unzip h2o-3.20.0.3.zip && \
	mv /opt/h2o-3.20.0.3/* /opt/h2o && \
	rm -rf /opt/h2o-3.20.0.3/ && \
	rm -rf /opt/h2o/python/
	
# Set up Jupyter 
# Notes: Notebooks saved with Anaconda
#		 SSL key good for one year
RUN mkdir /root/.jupyter
WORKDIR /root/.jupyter
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout mykey.key -out mycert.pem -batch
COPY cfg/jupyter_notebook_config.py ./
RUN jupyter nbextension enable beakerx --py --sys-prefix

# Add Tini
# Tini operates as a process subreaper for Jupyter. This prevents kernel crashes.
# Taken from Jupyter 5.5.0 documentation
ENV TINI_VERSION v0.6.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

# Open port for Jupyter
# Note: Change this if you change c.NotebookApp.port in cfg/jupyter_notebook_config.py
EXPOSE 8888 

# Store for notebooks 
VOLUME /opt/Anaconda/notebooks

# Start Jupyter Notebook
CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]