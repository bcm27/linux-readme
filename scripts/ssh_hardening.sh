#!/usr/bin/env bash

set -euo pipefail

# ===== Constants =====
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak.$(date +%s)"
SYSTEMD_SOCKET_DIR="/etc/systemd/system/sshd.socket.d"
SOCKET_OVERRIDE="$SYSTEMD_SOCKET_DIR/override.conf"

# ===== Functions =====

backup_config() {
    echo "[*] Backing up sshd_config to $BACKUP_CONFIG"
    cp "$SSHD_CONFIG" "$BACKUP_CONFIG"
}

prompt_for_ssh_port() {
    read -rp "Enter desired SSH port (default: 2222): " SSH_PORT
    SSH_PORT="${SSH_PORT:-2222}"
    if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && (( SSH_PORT >= 1 && SSH_PORT <= 65535 )); then
        echo "[*] Using port $SSH_PORT"
    else
        echo "[!] Invalid port."
        exit 1
    fi
}

check_for_ssh_keys() {
    if [[ ! -d "$HOME/.ssh" || -z $(ls "$HOME/.ssh/"*.pub 2>/dev/null) ]]; then
        echo "[!] No SSH public keys found in $HOME/.ssh/"
        echo "    Set up your SSH key before proceeding."
        exit 1
    fi
}

harden_sshd_config() {
    echo "[*] Hardening $SSHD_CONFIG"

    # Clean out existing conflicting lines
    sed -i -E '/^#?Port|^#?PermitRootLogin|^#?PasswordAuthentication|^#?ChallengeResponseAuthentication|^#?KbdInteractiveAuthentication|^#?UsePAM|^#?AllowUsers|^#?X11Forwarding|^#?PermitEmptyPasswords|^#?MaxAuthTries|^#?LoginGraceTime|^#?ClientAliveInterval|^#?ClientAliveCountMax|^#?AllowTcpForwarding|^#?Subsystem/d' "$SSHD_CONFIG"

    cat <<EOF >> "$SSHD_CONFIG"

# Hardened SSH Config
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
AllowUsers $USER
MaxAuthTries 3
LoginGraceTime 20
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
PermitEmptyPasswords no
AllowTcpForwarding no
KbdInteractiveAuthentication no

# Crypto Policies
KexAlgorithms curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com

Subsystem sftp internal-sftp
EOF
}

handle_socket_activation() {
    if systemctl is-enabled sshd.socket &>/dev/null; then
        echo "[*] Detected systemd socket activation for SSH."
        mkdir -p "$SYSTEMD_SOCKET_DIR"
        cp "$SOCKET_OVERRIDE" "$SOCKET_OVERRIDE.bak.$(date +%s)" 2>/dev/null || true
        cat <<EOF > "$SOCKET_OVERRIDE"
[Socket]
ListenStream=
ListenStream=$SSH_PORT
EOF
        systemctl daemon-reexec
        systemctl daemon-reload
        systemctl restart sshd.socket
    else
        echo "[*] Using traditional sshd service."
        systemctl restart sshd
    fi
}

configure_firewalld() {
    if command -v firewall-cmd &>/dev/null; then
        echo "[*] Configuring firewalld to allow port $SSH_PORT"
        firewall-cmd --permanent --remove-service=ssh || true
        firewall-cmd --permanent --add-port=${SSH_PORT}/tcp
        firewall-cmd --reload
    else
        echo "[!] firewalld not found; skipping firewall config"
    fi
}

configure_selinux() {
    if command -v semanage &>/dev/null; then
        echo "[*] Updating SELinux port contexts"
        semanage port -d -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || true
        semanage port -a -t ssh_port_t -p tcp "$SSH_PORT"
    else
        echo "[!] semanage not available, skipping SELinux config."
    fi
}

test_sshd_config() {
    echo "[*] Validating SSH config"
    sshd -t
}

final_warning() {
    echo
    echo "[!] IMPORTANT: Do not close your terminal until you verify the new SSH port works:"
    echo "    ssh -p $SSH_PORT $USER@<hostname_or_ip>"
    echo
}

# ===== Main =====

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run as root."
    exit 1
fi

prompt_for_ssh_port
check_for_ssh_keys
backup_config
harden_sshd_config
test_sshd_config
configure_firewalld
configure_selinux
handle_socket_activation
final_warning
