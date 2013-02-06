MocoApplication v 1.1

This software is doing parallelized motion correction of (real-time) fMRI data. 
In offline mode nifti-4D images can be loaded. The input for online correction is
TCP/IP.

MocoApplication uses registration routines from ITK (please see ITK license).

License: GNU public license (see LICENSE)

Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
M.Hollmann



INSTALLATION 

- The provided code compiles with the following software installed:
  
  1. InsightToolkit-4.2.1 (standard built)
  2. boost 1.47 (built multithreaded)
  3. via (www.cs.ubc.ca/labs/lci/vista/vista/html)
  4. CorePlot 1.0
  5. Isis (https://github.com/isis-group/isis.git, built with tcp/ip-plugin and ITKAdapter)