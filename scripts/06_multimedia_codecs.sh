#!/bin/bash

# Install multimedia codecs for audio and video playback
# Enables support for MP3, H.264, and other common media formats

set -e  # Exit on any error

echo "Installing multimedia codecs..."

# Check if RPM Fusion is enabled
if ! dnf repolist | grep -q rpmfusion; then
    echo "ERROR: RPM Fusion repositories not found!"
    echo "Please run 01_enable_repos.sh first."
    exit 1
fi

# Install multimedia group packages
echo "Installing multimedia group packages..."
sudo dnf group install -y multimedia

# Replace free ffmpeg with full-featured version
echo "Installing full-featured FFmpeg..."
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

# Upgrade multimedia packages with better codec support
echo "Upgrading multimedia packages..."
sudo dnf upgrade -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# Install sound and video applications
echo "Installing sound and video applications..."
sudo dnf group install -y sound-and-video

echo ""
echo "Multimedia codecs installation completed!"
echo "Your system now supports common audio and video formats including:"
echo "  - MP3, AAC, FLAC audio"
echo "  - H.264, H.265 video"
echo "  - And many other multimedia formats"