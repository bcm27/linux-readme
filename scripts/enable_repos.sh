#!/bin/bash

# Enable RPM Fusion repositories for Fedora 41
# Provides access to additional software like Steam, Discord, and multimedia codecs

set -e  # Exit on any error

echo "Enabling RPM Fusion repositories..."

# Install RPM Fusion free and non-free repositories
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Update the core group packages
echo "Updating core group packages..."
sudo dnf group upgrade -y core