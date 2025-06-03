#!/bin/bash

# Install necessary libraries for hardware video acceleration
sudo dnf install -y ffmpeg-libs libva libva-utils

# For AMD CPUs: Install the necessary drivers for video acceleration
sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
sudo dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
sudo dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686

# For Intel CPUs: (Research required for exact package names)
# Add commands here if needed

# Install OpenH264 support
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

# Instructions for enabling OpenH264 plugin in Firefox
echo "After installation, enable the OpenH264 plugin in Firefox’s settings (about:preferences)."