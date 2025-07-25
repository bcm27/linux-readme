# Fedora Emergency Mode Recovery Guide - Nvidia akmods Fix

## Problem Description
After running `sudo dnf upgrade`, the system failed to boot with:
- Emergency mode with UUID error: `2fc6edaa-c716-401d-b16c-c76da8561130 does not exist`
- Error generating `/run/initramfs/rdsosreport.txt`
- Likely caused by kernel update breaking Nvidia akmods

## System Configuration
- **Root Partition**: LUKS encrypted (`/dev/nvme2n1p2`)
- **Boot Partition**: EFI (`/dev/nvme2n1p1`)
- **Filesystem**: btrfs with separate subvolumes
- **Graphics**: Nvidia with akmods drivers

## Recovery Steps

### 1. Boot from Fedora Live USB

### 2. Identify and Unlock LUKS Encrypted Root Partition

```bash
# Check partition layout
lsblk

# Verify partition types
sudo blkid | grep nvme2n1

# Unlock LUKS encrypted root partition
sudo cryptsetup luksOpen /dev/nvme2n1p2 fedora_root
# Enter your encryption passphrase when prompted

# Verify decryption worked
ls /dev/mapper/
# Should show: control fedora_root
```

### 3. Mount btrfs Root Subvolume

```bash
# First mount the btrfs filesystem to examine subvolumes
sudo mount /dev/mapper/fedora_root /mnt

# List all btrfs subvolumes
sudo btrfs subvolume list /mnt

# Unmount and mount the correct root subvolume
sudo umount /mnt
sudo mount -o subvol=root /dev/mapper/fedora_root /mnt

# Verify we have the correct root filesystem
ls /mnt
# Should show: bin boot dev etc home lib usr var etc.
```

### 4. Mount Additional btrfs Subvolumes

```bash
# Mount other important subvolumes to their proper locations
sudo mount -o subvol=home /dev/mapper/fedora_root /mnt/home
sudo mount -o subvol=tmp /dev/mapper/fedora_root /mnt/tmp
sudo mount -o subvol=opt /dev/mapper/fedora_root /mnt/opt
sudo mount -o subvol=log /dev/mapper/fedora_root /mnt/var/log
sudo mount -o subvol=cache /dev/mapper/fedora_root /mnt/var/cache
sudo mount -o subvol=spool /dev/mapper/fedora_root /mnt/var/spool
```

### 5. Mount EFI Boot Partition

```bash
sudo mount /dev/nvme2n1p1 /mnt/boot/efi
```

### 6. Mount System Filesystems for Chroot

```bash
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run
```

### 7. Enter Chroot Environment

```bash
sudo chroot /mnt
```

### 8. Rebuild initramfs and akmods (Inside Chroot)

```bash
# CRITICAL: Regenerate initramfs for all kernels (this fixes the UUID boot error)
dracut --regenerate-all --force
# Note: You may see "No '/dev/log' or 'logger'" errors - these are warnings and can be ignored

# Try to rebuild akmods (Nvidia drivers)
akmods --force
```

**If akmods fails with "kernel-devel package" errors:**
```bash
# Install missing kernel-devel packages
dnf install kernel-devel gcc kernel-headers

# If specific kernel versions fail, check what kernels you have:
ls /lib/modules/

# Install kernel-devel for your specific kernels:
dnf install kernel-devel-[your-kernel-version]

# Retry akmods
akmods --force
```

**If akmods still fails or dnf doesn't work:**
- Skip this step - you can fix Nvidia drivers after booting
- The critical part (dracut) is already complete

```bash
# Update GRUB configuration
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

### 9. Exit and Cleanup

```bash
# Exit chroot
exit

# Unmount all filesystems
sudo umount -R /mnt

# Close LUKS container
sudo cryptsetup luksClose fedora_root

# Reboot
sudo reboot
```

## Alternative: If akmods Rebuild Fails During Recovery

If the akmods rebuild fails during step 8, **you can still proceed with the reboot**. The `dracut --regenerate-all --force` command is the critical step that fixes the UUID boot error.

### Complete the recovery:
```bash
# Update GRUB (even if akmods failed)
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

# Exit chroot
exit

# Unmount all filesystems
sudo umount -R /mnt

# Close LUKS container
sudo cryptsetup luksClose fedora_root

# Reboot
sudo reboot
```

### After successful boot, fix Nvidia drivers:
```bash
# Remove any broken Nvidia packages
sudo dnf remove '*nvidia*' --exclude=nvidia-gpu-firmware

# Reinstall using your setup scripts
sudo bash scripts/05_nvidia_drivers.sh

# Or install manually:
sudo dnf install kmodtool akmods mokutil openssl 
sudo kmodgenca -a 
sudo mokutil --import /etc/pki/akmods/certs/public_key.der 
sudo dnf install gcc kernel-headers kernel-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686

# Rebuild akmods after boot
sudo akmods --force
```

## Alternative: If akmods Rebuild Fails

If the akmods rebuild fails, you may need to reinstall the Nvidia drivers:

```bash
# Inside chroot environment
dnf remove '*nvidia*' --exclude=nvidia-gpu-firmware

# Reinstall Nvidia drivers (from your setup scripts)
dnf install kmodtool akmods mokutil openssl 
kmodgenca -a 
mokutil --import /etc/pki/akmods/certs/public_key.der 
dnf install gcc kernel-headers kernel-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686

# Rebuild and update
akmods --force
dracut --regenerate-all --force
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

## Key Points

1. **LUKS Encryption**: The root partition is encrypted and must be unlocked before mounting
2. **btrfs Subvolumes**: Fedora uses separate subvolumes that need to be mounted individually
3. **UUID Match**: The error UUID `2fc6edaa-c716-401d-b16c-c76da8561130` matches the decrypted filesystem
4. **Critical Step**: `dracut --regenerate-all --force` is the most important command - it fixes the boot UUID error
5. **akmods Optional**: Nvidia akmods can be rebuilt after booting if it fails during recovery
6. **initramfs**: Regenerating initramfs fixes boot issues related to missing kernel modules

## Prevention

To avoid this issue in the future:
- Always reboot after major kernel updates
- Consider using `dnf update --exclude=kernel*` if you need partial updates
- Monitor akmods status after kernel updates: `sudo akmods --force`
