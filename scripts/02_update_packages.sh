#!/bin/bash

# Check for and install firmware updates using fwupd
# This updates firmware for supported devices like UEFI, SSDs, etc.

set -e  # Exit on any error

echo "Checking for firmware updates..."

# Refresh the firmware metadata
echo "Refreshing firmware database..."
sudo fwupdmgr refresh --force

# List devices that support firmware updates
echo ""
echo "Devices that support firmware updates:"
sudo fwupdmgr get-devices

# Check for available updates
echo ""
echo "Checking for available firmware updates..."
if sudo fwupdmgr get-updates; then
    echo ""
    read -p "Install available firmware updates? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo fwupdmgr update
        echo "Firmware updates completed!"
    else
        echo "Firmware updates skipped."
    fi
else
    echo "No firmware updates available."
fi