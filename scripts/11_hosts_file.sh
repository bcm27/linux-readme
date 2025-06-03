#!/bin/bash

# Backup the current hosts file
sudo cp '/etc/hosts' '/etc/hosts-bak'

# Download the updated hosts file to a temporary location
curl -o '/tmp/hosts-tmp' 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts'

# Move the new hosts file to the correct location
sudo mv '/tmp/hosts-tmp' '/etc/hosts'

# Restore SELinux context for the hosts file
sudo restorecon -F -I -R '/etc/hosts'

# Ensure all changes are written to disk
sync