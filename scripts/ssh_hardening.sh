#!/bin/bash

# SSH Security Hardening for Fedora 41
# Improves SSH security by changing port, disabling password auth, and applying security settings

set -e  # Exit on any error

SSH_CONFIG="/etc/ssh/sshd_config"
DEFAULT_PORT=2222

echo "SSH Security Hardening Script"
echo "============================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Get SSH port from user
read -p "Enter SSH port (1024-65535) [default: $DEFAULT_PORT]: " SSH_PORT
SSH_PORT=${SSH_PORT:-$DEFAULT_PORT}

# Validate port
if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [[ $SSH_PORT -lt 1024 ]] || [[ $SSH_PORT -gt 65535 ]]; then
    echo "ERROR: Invalid port number"
    exit 1
fi

# Check for SSH keys
echo "Checking for SSH keys..."
HAS_KEYS=false
for user_home in /home/* /root; do
    if [[ -f "$user_home/.ssh/authorized_keys" ]] && [[ -s "$user_home/.ssh/authorized_keys" ]]; then
        HAS_KEYS=true
        break
    fi
done

if [[ "$HAS_KEYS" == false ]]; then
    echo ""
    echo "WARNING: No SSH keys found!"
    echo "Disabling password authentication will lock you out."
    echo "Make sure to set up SSH keys before running this script."
    echo ""
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Backup SSH config
echo "Creating backup..."
cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

# Apply SSH hardening configuration
echo "Applying SSH security settings..."
cat > /tmp/ssh_hardening << EOF

# Security hardening applied $(date)
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no

# Secure algorithms
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
EOF

# Remove old conflicting settings and append new ones
sed -i '/^#\?Port /d; /^#\?PermitRootLogin /d; /^#\?PasswordAuthentication /d' "$SSH_CONFIG"
cat /tmp/ssh_hardening >> "$SSH_CONFIG"
rm /tmp/ssh_hardening

# Test SSH configuration
echo "Testing SSH configuration..."
if ! sshd -t; then
    echo "ERROR: SSH configuration is invalid! Restoring backup..."
    cp "$SSH_CONFIG.backup."* "$SSH_CONFIG"
    exit 1
fi

# Configure SELinux for new port
if command -v semanage >/dev/null; then
    echo "Configuring SELinux..."
    semanage port -a -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || \
    semanage port -m -t ssh_port_t -p tcp "$SSH_PORT"
fi

# Configure firewall
if systemctl is-active --quiet firewalld; then
    echo "Configuring firewall..."
    firewall-cmd --permanent --add-port="$SSH_PORT/tcp"
    firewall-cmd --permanent --remove-service=ssh 2>/dev/null || true
    firewall-cmd --reload
fi

# Restart SSH service
echo "Restarting SSH service..."
systemctl restart sshd

echo ""
echo "SSH hardening completed!"
echo ""
echo "IMPORTANT:"
echo "- SSH now runs on port $SSH_PORT"
echo "- Password authentication disabled"
echo "- Root login disabled"
echo "- Connect with: ssh -p $SSH_PORT username@hostname"
echo ""
echo "TEST YOUR CONNECTION in a new terminal before closing this one!"