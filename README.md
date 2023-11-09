# CYGNSS GNSS-R Raw Intermediate Frequency Data Processing
# Reflectometry with Galileo signals

Set of Matlab scripts to process the Galileo E1B reflected signals present 
in CYGNSS Level 1 Raw Intermediate Frequency Data Records.

## Description

Processing of the binary data in the registers to obatin a time series of 
delay Doppler maps (DDMs) for Galileo E1B signals. Also, it plots the 
ground tracks of the reflections and their estimated SNR. The input files 
are the CYGNSS Level 1 Raw Intermediate Frequency Data Record, that 
contains the samples of the signal to process, the CYGNSS Level 1 Science 
Data Record netCDF file from the same date and CYGNSS satellite as the Raw 
IF record file. Both type of registers are available to the public: 
https://podaac.jpl.nasa.gov/CYGNSS?tab=mission-objectives&sections=about%2Bdata.
The netCDF file contains the DDMs processed on board during that day, as 
well as relevant information for processing and geolocation of the 
reflections. The important variables values during the time of the Raw IF 
record (reported in its metadata) is read from the netCDF file and used 
during the calculation of the DDMs. Also, it requires a rinex Galileo
navigation file to get the satellite orbits and estimate specular 
reflection points position, delay and Doppler shift.

The processing parameters are completely configurable, such as coherent and
non-coherent integration time, delay and Doppler resolution, etc.

### Executing program

If processing a new register (or using the script for the first time) 
follow these steps to prepare the data files:
* First, store the Raw If binary file, the Level 1 Science Data 
Record netCDF file and the rinex Galileo navigation file in the same directory.
* Edit config.m with the appropiate files directory in the variable folder_path.
* Edit case_selector.m to add a new case with the corresponding file names,
preferred channel to process and Galileo satellite identification number. 
Read case_selector.m comments for more details in the case
definition.

DDM Processing
* Edit config.m to set the desired processing parameters. The configurable 
parameters are the total processing time, coherent and non-coherent 
integration time, decimation ratio which determines the delay resolution, 
and the resolution, maximum value and optional central offset for the 
Doppler bins. These are defined in the "Input parameters" section of the 
script.
* Set plot_tracks flag to 1 to plot the ground tracks of the 4 GPS DDMs 
processed on board while reading the netCDF file before processing the 
binary data and the ground track of the selected Galileo reflection.
* After configuration, run the script main.m. It will calculate the Galileo
DDMs during the processing time and plot the results.
