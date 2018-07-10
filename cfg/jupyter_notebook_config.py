# Jupyter Configuration File
# Adapted from https://github.com/andreivmaksimov/python_data_science/blob/master/conf/.jupyter/jupyter_notebook_config.py

c = get_config()  # get the config object
c.IPKernelApp.pylab = 'inline'  # in-line figure when using Matplotlib
c.NotebookApp.ip = '*'  
c.NotebookApp.open_browser = False  # do not open a browser window by default when using notebooks
c.NotebookApp.notebook_dir = '/opt/Anaconda/notebooks'
c.NotebookApp.allow_root = True # Allow to run Jupyter from root user inside Docker container
c.NotebookApp.allow_origin = '*' # Allow any IP as origin
c.NotebookApp.certfile = u'/root/.jupyter/mycert.pem' # SSL/TLS certificate
c.NotebookApp.keyfile = u'/root/.jupyter/mykey.key'

# Additional Common Options:

# Add a password if desired
# Get the hash by running ipython: 
#	from IPython.lib import passwd
#	passwd()
#c.NotebookApp.password = u'sha1:<hash>'

# Change port if desired
# c.NotebookApp.port = 8888

# Prevent changing password from UI if desired
# c.NotebookApp.allow_password_change = False

# Add SSL/TLS client authentication
# c.NotebookApp.client_ca = ''
