#!/bin/bash

# Check for devices that support firmware updates
sudo fwupdmgr refresh --force
sudo fwupdmgr get-devices    # Lists devices with available updates
sudo fwupdmgr get-updates     # Fetches list of available updates
sudo fwupdmgr update          # Applies the firmware updates