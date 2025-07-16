#!/bin/bash

# Setup hardware video acceleration for Intel and AMD graphics
# Improves video playback performance and reduces CPU usage

set -e  # Exit on any error

echo "Setting up hardware video acceleration..."

# Install base video acceleration libraries
echo "Installing video acceleration libraries..."
sudo dnf install -y ffmpeg-libs libva libva-utils

# Detect graphics hardware
echo "Detecting graphics hardware..."
if lspci | grep -i intel | grep -i vga; then
    echo "Intel graphics detected"
    INTEL_GPU=true
fi

if lspci | grep -i amd | grep -i vga; then
    echo "AMD graphics detected"  
    AMD_GPU=true
fi

# Install AMD-specific drivers
if [[ $AMD_GPU == true ]]; then
    echo "Installing AMD video acceleration drivers..."
    sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
    sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
    
    # Install 32-bit libraries for Steam/gaming
    sudo dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 2>/dev/null || true
    sudo dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 2>/dev/null || true
fi

# Install Intel-specific drivers
if [[ $INTEL_GPU == true ]]; then
    echo "Installing Intel video acceleration drivers..."
    sudo dnf install -y intel-media-driver libva-intel-driver
fi

# Install OpenH264 codec support
echo "Installing OpenH264 codec support..."
sudo dnf config-manager --set-enabled fedora-cisco-openh264
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264

echo ""
echo "Video acceleration setup completed!"
echo ""
echo "To verify hardware acceleration is working:"
echo "  vainfo                    # Check VA-API support"
echo "  vdpauinfo                 # Check VDPAU support (AMD/NVIDIA)"
echo ""
echo "For Firefox OpenH264 support:"
echo "  Open about:addons > Plugins and ensure OpenH264 is enabled"