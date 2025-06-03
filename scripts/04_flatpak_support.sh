#!/bin/bash

# Enable Flathub repository for Flatpak applications
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Flathub repository has been enabled for Flatpak applications."