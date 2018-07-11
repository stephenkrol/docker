# docker

## Description
This builds a Docker image off of Ubuntu:latest that sets up a Jupyter Notebook that includes:
  * Anaconda3 with a bunch of extra R and Python packages for data science
    * See anaconda.txt for the full list!
  * Beakerx (https://github.com/twosigma/beakerx) which gives kernels for Clojure, Java, Scala, Sql, Kotlin, and Groovy
  * SciJava (https://github.com/scijava/scijava-jupyter-kernel) providing Clojure, Groovy, ImageJ, Python, JavaScript, and R within the same notebook

-----

## Build
docker something something

-----

## Misc
The final image is about 12gb, but Docker blows up to a bit over 50gb to build it.
