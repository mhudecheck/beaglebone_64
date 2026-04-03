mcasp0_out.dts -> Working .dts file for activating stereo playback/out on mcasp0 pins. Device is set as clock slave, but this can be fixed by 1. changing direction of bit and frame clocks to out and 2. adding a line to activate P9.25 as master clock

setup-wiim.sh -> Example bash script for configuring the usb c port as a usb gadget
