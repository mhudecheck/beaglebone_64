mcasp0_out.dts -> Working .dts file for activating stereo playback/out on mcasp0 pins. Device is set as clock slave, but this can be fixed by 1. changing direction of bit and frame clocks to out and 2. adding a line to activate P9.25 as master clock

setup-wiim.sh -> Example bash script for configuring the usb c port as a usb gadget

u_audio.c -> TI usb controller on AI64 has a bug where, when the usb c port is set as a usb gadget, it pads the incoming usb stream with 0s. This effectively doubles the frequency of the incoming stream (e.g., if you have 96k fixed in, it will pass to ALSA as 192k). The modified u_audio.c 1. removes this padding and 2. outputs debug information to dmesg. 

You need to copy over the canonical Github repository for u_audio.c. Then, replace with this version and run: sudo rmmod usb_f_uac2
sudo rmmod u_audio

make
sudo insmod ./u_audio.ko
