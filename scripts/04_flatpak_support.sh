#!/bin/bash

# Enable Flatpak support and add Flathub repository
# Allows installation of sandboxed applications from Flathub

set -e  # Exit on any error

echo "Setting up Flatpak support..."

# Ensure Flatpak is installed (should be by default on Fedora)
if ! command -v flatpak &> /dev/null; then
    echo "Installing Flatpak..."
    sudo dnf install -y flatpak
fi

# Add the Flathub repository
echo "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
echo "Removing Flatpak repository..."

flatpak remote-modify --disable fedora

echo ""
echo "Flatpak setup completed!"
echo "You can now install applications from Flathub using:"
echo "  flatpak install flathub <application-name>"
echo "Or browse applications at: https://flathub.org"