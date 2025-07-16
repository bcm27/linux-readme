#!/bin/bash

# Install NVIDIA drivers for Fedora 41
# IMPORTANT: Do NOT download drivers from NVIDIA's website - use RPM Fusion instead
# This script handles secure boot by setting up driver signing

set -e  # Exit on any error

echo "Installing NVIDIA drivers..."
echo "IMPORTANT: Make sure RPM Fusion repositories are enabled first!"
echo ""

# Check if RPM Fusion is enabled
if ! dnf repolist | grep -q rpmfusion; then
    echo "ERROR: RPM Fusion repositories not found!"
    echo "Please run 01_enable_repos.sh first."
    exit 1
fi

# Install required tools for driver signing (needed for secure boot)
echo "Installing driver signing tools..."
sudo dnf install -y kmodtool akmods mokutil openssl

# Generate signing keys
echo "Generating driver signing certificate..."
sudo kmodgenca -a

# Import the key for secure boot
echo "Setting up secure boot key import..."
sudo mokutil --import /etc/pki/akmods/certs/public_key.der

echo ""
echo "SECURE BOOT SETUP:"
echo "1. A reboot is required to import the MOK (Machine Owner Key)"
echo "2. During boot, MOK Manager will appear"
echo "3. Select 'Enroll MOK' and follow the prompts"
echo "4. Enter a password when prompted (you'll create this)"
echo "5. After enrolling the key, the system will continue booting"
echo ""

read -p "Reboot now to enroll the MOK key? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting... Run this script again after reboot to complete driver installation."
    sudo reboot
else
    echo ""
    echo "Reboot manually when ready, then run this script again to install the drivers."
    echo "Or continue with driver installation if MOK is already enrolled..."
    echo ""
    
    read -p "Continue with driver installation? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Install NVIDIA drivers
echo "Installing NVIDIA drivers and libraries..."
sudo dnf install -y \
    gcc kernel-headers kernel-devel \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-libs \
    xorg-x11-drv-nvidia-libs.i686

echo ""
echo "NVIDIA driver installation completed!"
echo ""
echo "To verify installation, run:"
echo "  modinfo -F version nvidia"
echo ""
echo "You may need to reboot for the drivers to load properly."