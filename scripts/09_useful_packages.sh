#!/bin/bash

# Install useful packages for development, gaming, and productivity
# Includes compression tools, creative apps, system utilities, and gaming platforms

set -e  # Exit on any error

echo "Installing useful packages..."

# Archive and compression tools
echo "Installing compression tools..."
sudo dnf install -y \
    unzip \
    p7zip \
    p7zip-plugins \

# Gaming platforms
echo "Installing gaming platforms..."
sudo dnf install -y \
    steam \
    discord

# Development and version control
echo "Installing development tools..."
sudo dnf install -y \
    git \
    terminator

# Creative applications
echo "Installing creative applications..."
sudo dnf install -y \
    rawtherapee \
    inkscape \
    krita

# System utilities
echo "Installing system utilities..."
sudo dnf install -y \
    timeshift \
    lm_sensors

echo ""
echo "Useful packages installation completed!"
echo ""
echo "Installed packages include:"
echo "  Compression: unzip, p7zip, unrar"
echo "  Gaming: Steam, Discord" 
echo "  Development: git, terminator"
echo "  Creative: RawTherapee, Inkscape, Krita"
echo "  System: Timeshift (backups), lm_sensors (temperature monitoring)"