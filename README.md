# linux-readme
A description of my linux customizations:

After setting up my main Fedora 41 OS.

- Enable 3rd party repos (access to steam, discord, etc)

```bash 
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```
install app-stream metadata by
```bash
sudo dnf group upgrade core
sudo dnf4 group install core
```

Then once youve done the above youll want to update your installed packages.

```bash
sudo dnf -y update
```

Then restart.

If youd like to check for devices that support firmware updates. Note: this includes ssd, and other lower level devices. My computer only supported one device.

```bash
sudo fwupdmgr refresh --force
sudo fwupdmgr get-devices # Lists devices with available updates.
sudo fwupdmgr get-updates # Fetches list of available updates.
sudo fwupdmgr update
```

Some versions of Fedora wont prompt you to enable flatpaks.
What is a flatpak? : Flatpak is a framework for distributing desktop applications across various Linux distributions. I run into issues trying to get these to run on a system thats not connected to the internet. But if your machine has internet access than these are great! 

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

Next if you have a Nvidia GPU youll want to install its drivers. DO NOT download the drivers from the website. First try these steps:
```bash
sudo dnf install akmod-nvidia
sudo dnf install xorg-x11-drv-nvidia-cuda
```
Wait for atleast 5-10 mins before rebooting once you install the above, this is required to let the kernel module finish rebuilding in the background.

To check if succesful run this command.
```bash 
modinfo -F version nvidia
``` 
If it displays something like 570.153.02 then youre golden.

If the above does NOT work:

[Follow this guide:](https://www.reddit.com/r/Fedora/comments/18bj1kt/fedora_nvidia_secure_boot/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)

These commands will install common multimedia codexs for video and audio files.

```bash
sudo dnf4 group install multimedia
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing # Switch to full FFMPEG.
sudo dnf upgrade @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin # Installs gstreamer components. Required if you use Gnome Videos and other dependent applications.
sudo dnf group install -y sound-and-video # Installs useful Sound and Video complementary packages.
```

Now for enabling H/W Video Acceleration on web browser videos (aka youtube lol)

```bash
sudo dnf install ffmpeg-libs libva libva-utils

# then if you have an AMD CPU

sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
sudo dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
sudo dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686

# I did not research what the Intel ones are

sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
```
After this enable the OpenH264 Plugin in Firefox's settings. (firefox/settings search)

Some gnome plugins I found to be useful:

https://extensions.gnome.org/extension/1460/vitals/
https://extensions.gnome.org/extension/4228/wireless-hid/

```bash
# useful packages

sudo dnf install -y unzip p7zip p7zip-plugins unrar discord steam timeshift git rawtherapee inkscape krita lm_sensors terminator

#  