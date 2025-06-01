# linux-readme

A guide to my Fedora 41 Linux customizations and setup steps.

---

## 1. Enable 3rd Party Repositories

This gives you access to software like Steam, Discord, and more.

```bash
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

Update app-stream metadata:

```bash
sudo dnf group upgrade core
sudo dnf4 group install core
```

---

## 2. Update Installed Packages

```bash
sudo dnf -y update
```

Restart your system after updating.

---

## 3. Firmware Updates

Check for devices (like SSDs) that support firmware updates:

```bash
sudo fwupdmgr refresh --force
sudo fwupdmgr get-devices    # Lists devices with available updates
sudo fwupdmgr get-updates    # Fetches list of available updates
sudo fwupdmgr update
```

---

## 4. Flatpak Support

**What is Flatpak?**  
Flatpak is a framework for distributing desktop applications across various Linux distributions. It works best on systems with internet access.

Enable Flathub (the main Flatpak repository):

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

---

## 5. Nvidia GPU Drivers

**Do NOT download drivers from Nvidia’s website.**  
First, try installing via DNF:

```bash
sudo dnf install akmod-nvidia
sudo dnf install xorg-x11-drv-nvidia-cuda
```

Wait at least 5–10 minutes before rebooting to allow the kernel module to finish building.

Check if the driver installed successfully:

```bash
modinfo -F version nvidia
```

If you see a version number (e.g., 570.153.02), the installation was successful.

If not, see:  
[Reddit: Fedora Nvidia Secure Boot Guide](https://www.reddit.com/r/Fedora/comments/18bj1kt/fedora_nvidia_secure_boot/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)

---

## 6. Multimedia Codecs

Install common multimedia codecs for video and audio files:

```bash
sudo dnf4 group install multimedia
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing
sudo dnf upgrade @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf group install -y sound-and-video
```

---

## 7. Hardware Video Acceleration (e.g., for YouTube)

```bash
sudo dnf install ffmpeg-libs libva libva-utils

# For AMD CPUs:
sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
sudo dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
sudo dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686

# For Intel CPUs:
# (Research required for exact package names)

# OpenH264 support:
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
```

After this, enable the OpenH264 plugin in Firefox’s settings (`about:preferences`).

---

## 8. Useful GNOME Extensions

- [Vitals](https://extensions.gnome.org/extension/1460/vitals/)
- [Wireless HID](https://extensions.gnome.org/extension/4228/wireless-hid/)

---

## 9. Useful Packages

| Package         | Description                                 |
|-----------------|---------------------------------------------|
| unzip           | Extract .zip archives                       |
| p7zip           | 7-Zip file archiver (command-line)          |
| p7zip-plugins   | Additional formats for 7-Zip                |
| unrar           | Extract .rar archives                       |
| discord         | Chat and voice app for communities          |
| steam           | Gaming duh                   |
| timeshift       | System restore utility (like Windows System Restore) |
| git             | Distributed version control system          |
| rawtherapee     | Advanced photo/raw image editor             |
| inkscape        | Vector graphics editor (SVG)                |
| krita           | Digital painting and illustration app       |
| lm_sensors      | Hardware monitoring (temperatures, voltages)|
| terminator      | Advanced terminal emulator                  |

Install all at once:
```bash
sudo dnf install -y unzip p7zip p7zip-plugins unrar discord steam timeshift git rawtherapee inkscape krita lm_sensors terminator
```

---

## 10. Setting Up Proton for Linux Gaming

[Proton](https://www.protondb.com/) is a compatibility layer that allows you to run Windows games on Linux.

**Steps to enable Proton in Steam:**

1. . **Enable Proton:**
   - Go to `Steam` > `Settings` > `Compatibility`.
   - Check **"Enable Steam Play for supported titles"**.
   - (Optional) Check **"Enable Steam Play for all other titles"** to use Proton for all games.
   - Select the latest Proton version from the dropdown (Proton Experimental is recommended for best compatibility).

4. **Restart Steam** to apply the changes.

5. **(Optional) Install Additional Proton Versions:**
   - In Steam, go to `Library` > search for "Proton".
   - Right-click on a Proton version (e.g., Proton Experimental) and install it.

6. **Check Game Compatibility:**  
   Visit [ProtonDB](https://www.protondb.com/) to see how well your games run with Proton and for any extra tweaks.

---
