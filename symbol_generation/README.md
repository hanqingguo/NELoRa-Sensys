# Symbol Generation

This module provides the codes for the symbol generation, including the packet identification and the offset recovery for chirp symbol generation.

It first detects incoming LoRa packets, then divides the payload of each packet into some chirp symbols, which are further fed to the DNN demodulator.


- Functionalities of primary files 
main_src.m		Matlab scripts of main controller of NELoRa's packet identification
param_configs.m		Parameter configuration table
input/pt1           PHY samples of recived LoRa signal (multiple packets)

- A running example
Operate step-by-step as follow:
a. open Matlab (version R2018a [or above])
b. set the working directory of Matlab to the dir of packet detection program
c. run main_src.m

- After runing main_src.m, the program will detect LoRa packets from the PHY 
samples, and then divide the payload of each packet into some chirp symbols 
for feding to the DNN demodulator.

- Default parameters 
The default program is configured for LoRa packets with Spreading Factor SF=12, Bandwith 
BW=125kHz, Sampling rate Fs=1e6 Samples per second. You can find and change the parameters
in file "param_configs.m".