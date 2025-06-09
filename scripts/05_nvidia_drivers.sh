#!/bin/bash
# Do NOT download drivers from Nvidia’s website.
sudo dnf install kmodtool akmods mokutil openssl 
sudo kmodgenca -a 
sudo mokutil --import /etc/pki/akmods/certs/public_key.der 
sudo reboot
# MOK manager will ask you, if you want to proceed with boot, or import the key. Pick import the key, type in a password
sudo dnf install gcc kernel-headers kernel-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686 
modinfo -F version nvidia 

# [Reddit: Fedora Nvidia Secure Boot Guide](https://www.reddit.com/r/Fedora/comments/18bj1kt/fedora_nvidia_secure_boot/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)

