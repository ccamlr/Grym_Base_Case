# Grym_Base_Case

Base Case implementation of the Grym.

### A few points about this repository

- The folder calibration contains some preliminary parameter values, as discussed during EMM

### About the code as it is now

- I remember Dale saying that my 'Grym_dates' function was problematic - something to do with timestep I believe, but can't really remember the details. I think it would be nice to have something in the grym that would enable us to enter actual dates.
- I know that, for now, the focus is on 48.1, but from our perspective, testing things on the 3 subareas is trivial. Keeping an eye on all of them would also ensure we're getting results that are consistent with our expectations regarding the differences between these areas. 
- I have vaguely tried to use Doug's values in there. About that, if Doug could add some stuff in the Calibration folder that'd be great. Those tables from your FSA paper for example.
- the code needs a bit of work, since for now I am getting really low gammas. Errors are either in the main code (maybe B0logsd?), or in the computation of gammas at the end of the code (see section '## Results').
- I will start working on a document to describe the calibration as described during EMM
- It would be great if we could add a lot of comments to the code, we need this to be easy to read 
- Make sure to set 'Nits' and 'Ncores' before you run.

 