# fedora41-setup

This project provides a collection of scripts to automate the setup of a fresh Fedora 41 installation. Each script is designed to perform specific tasks that enhance the functionality and usability of the system. Below is a brief description of each script included in the `scripts` directory.

---

## Scripts Overview

### 01_enable_repos.sh
This script enables third-party repositories for Fedora 41, allowing access to additional software like Steam and Discord.

### 02_update_packages.sh
This script updates all installed packages on the system using DNF.

### 03_firmware_updates.sh
This script checks for and applies firmware updates for supported devices.

### 04_flatpak_support.sh
This script enables the Flathub repository for Flatpak applications.

### 05_nvidia_drivers.sh
This script installs the Nvidia GPU drivers using DNF, ensuring the correct installation method is followed.

### 06_multimedia_codecs.sh
This script installs common multimedia codecs for audio and video playback.

### 07_video_acceleration.sh
This script sets up hardware video acceleration for different CPU types and installs OpenH264 support.

### 08_gnome_extensions.md
This markdown file lists useful GNOME extensions with links for installation.

### 09_useful_packages.sh
This script installs a collection of useful packages for various tasks.

### 10_proton_setup.md
This markdown file provides instructions for setting up Proton for gaming on Linux.

### 11_hosts_file.sh
This script replaces the system's hosts file with an updated version to block unwanted domains.

---

## Usage

To use the scripts, navigate to the `scripts` directory and execute the desired script in the terminal. For example:

```bash
bash 01_enable_repos.sh
```

Make sure to run the scripts with appropriate permissions (e.g., using `sudo` where necessary) to ensure they can make the required changes to the system.

---

## Note

Always review the scripts before executing them to understand the changes they will make to your system.