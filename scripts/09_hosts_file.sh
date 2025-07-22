#!/bin/bash

# Replace system hosts file with StevenBlack's unified hosts file
# Blocks ads, malware, and tracking domains at the system level

set -e  # Exit on any error

echo "Updating system hosts file for ad and malware blocking..."
echo "This will download Steven Black's unified hosts file."
echo ""

# Backup current hosts file
echo "Creating backup of current hosts file..."
sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)

# Download the updated hosts file
echo "Downloading updated hosts file..."
curl -s -o /tmp/hosts-new https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts

# Verify the download
if [[ ! -s /tmp/hosts-new ]]; then
    echo "ERROR: Failed to download hosts file"
    exit 1
fi

# Replace the hosts file
echo "Installing new hosts file..."
sudo mv /tmp/hosts-new /etc/hosts

# Restore SELinux context (important for Fedora)
echo "Restoring SELinux context..."
sudo restorecon -F -I -R /etc/hosts

# Ensure changes are written to disk
sync

echo ""
echo "Hosts file updated successfully!"
echo "Your system will now block ads and malware domains at the DNS level."
echo ""
echo "Backup saved as: /etc/hosts.backup.*"
echo "To revert: sudo cp /etc/hosts.backup.* /etc/hosts"