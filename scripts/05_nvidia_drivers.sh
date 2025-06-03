#!/bin/bash

# Do NOT download drivers from Nvidia’s website.
# First, try installing via DNF.
sudo dnf install -y akmod-nvidia
sudo dnf install -y xorg-x11-drv-nvidia-cuda

# Wait at least 5–10 minutes before rebooting to allow the kernel module to finish building.
echo "Please wait 5–10 minutes before rebooting to allow the kernel module to finish building."

# Check if the driver installed successfully.
modinfo -F version nvidia

# If you see a version number (e.g., 570.153.02), the installation was successful.
# If not, see: 
# [Reddit: Fedora Nvidia Secure Boot Guide](https://www.reddit.com/r/Fedora/comments/18bj1kt/fedora_nvidia_secure_boot/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)