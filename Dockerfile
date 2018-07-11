FROM ubuntu:latest
LABEL maintainer="stephenkrol"
LABEL version=".3"
LABEL description="Jupyter Notebook with kernels Python2/3, SciJava, Java, and R via \ 
	Anaconda3-5.2.0. Includes many common Python and R data science libraries. Adapted from \ 
	https://github.com/andreivmaksimov/python_data_science/blob/master/Dockerfile. Note: Requires \
	internet access to build. Try Dockerfile.restricted for local creation."
	

# Update Packages
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y openssl && \
	rm -rf /var/lib/apt/lists/*
	
# Install Anaconda3 to /opt
WORKDIR /opt
ADD https://repo.anaconda.com/archive/Anaconda3-5.2.0-Linux-x86_64.sh /opt
RUN	chmod +x Anaconda3-5.2.0-Linux-x86_64.sh && \
	bash Anaconda3-5.2.0-Linux-x86_64.sh -b -p /opt/Anaconda && \
	export PATH="/opt/anaconda/bin:$PATH" && \
	rm Anaconda3-5.2.0-Linux-x86_64.sh
	
# Update Anaconda
RUN /opt/Anaconda/bin/conda update conda -y && \
	/opt/Anaconda/bin/conda update --all -y
	
# Install Anaconda Environment with Data Science Packages
COPY cfg/anaconda.txt ./
RUN /opt/Anaconda/bin/conda install --file anaconda.txt && \
	/opt/Anaconda/bin/conda clean --all -y && \
	rm anaconda.txt
	
# Set up Jupyter 
# Notes: Notebooks saved with Anaconda
#		 SSL key good for one year
RUN mkdir /root/.jupyter
WORKDIR /root/.jupyter
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout mykey.key -out mycert.pem -batch
COPY cfg/jupyter_notebook_config.py ./

# Add Tini
# Tini operates as a process subreaper for jupyter. This prevents kernel crashes.
ENV TINI_VERSION v0.6.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]


# Open Port for Jupyter
# Note: Change this if you change c.NotebookApp.port in cfg/jupyter_notebook_config.py
EXPOSE 8888 

# Store for Notebooks 
VOLUME /opt/Anaconda/notebooks

# Start Jupyter Notebook
CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]