#!/bin/bash
# SSH Security Hardening Script for Fedora 41
# Version: 2.0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SSH_CONFIG="/etc/ssh/sshd_config"
BACKUP_DIR="/etc/ssh/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if we're on Fedora
check_fedora() {
    if ! grep -q "Fedora" /etc/os-release; then
        print_warning "This script is optimized for Fedora systems"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Create backup
create_backup() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        print_status "Created backup directory: $BACKUP_DIR"
    fi
    
    cp "$SSH_CONFIG" "$BACKUP_DIR/sshd_config.backup.$TIMESTAMP"
    print_status "Backup created: $BACKUP_DIR/sshd_config.backup.$TIMESTAMP"
}

# Validate port number
get_ssh_port() {
    while true; do
        read -p "Enter the desired SSH port (1024-65535, default 2222): " SSH_PORT
        SSH_PORT=${SSH_PORT:-2222}
        
        if [[ ! $SSH_PORT =~ ^[0-9]+$ ]]; then
            print_error "Please enter a valid number"
            continue
        fi
        
        if ((SSH_PORT >= 1024 && SSH_PORT <= 65535)); then
            # Check if port is already in use
            if ss -tuln | grep -q ":$SSH_PORT "; then
                print_warning "Port $SSH_PORT appears to be in use"
                read -p "Continue anyway? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    break
                fi
            else
                print_status "Valid port selected: $SSH_PORT"
                break
            fi
        else
            print_error "Port must be between 1024 and 65535"
        fi
    done
}

# Check if SSH keys exist
check_ssh_keys() {
    local has_keys=false
    
    # Check for authorized_keys files
    for user_home in /home/*; do
        if [[ -f "$user_home/.ssh/authorized_keys" && -s "$user_home/.ssh/authorized_keys" ]]; then
            has_keys=true
            break
        fi
    done
    
    # Check root's authorized_keys
    if [[ -f "/root/.ssh/authorized_keys" && -s "/root/.ssh/authorized_keys" ]]; then
        has_keys=true
    fi
    
    if [[ "$has_keys" == false ]]; then
        print_warning "No SSH keys found! Disabling password authentication will lock you out."
        print_warning "Please set up SSH keys before running this script."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_status "SSH keys detected"
    fi
}

# Configure SELinux for custom SSH port
configure_selinux() {
    if command -v semanage >/dev/null 2>&1; then
        print_status "Configuring SELinux for port $SSH_PORT"
        semanage port -a -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || \
        semanage port -m -t ssh_port_t -p tcp "$SSH_PORT"
        print_status "SELinux configured for SSH port $SSH_PORT"
    else
        print_warning "SELinux management tools not found. Install policycoreutils-python-utils if needed"
    fi
}

# Configure firewall
configure_firewall() {
    if systemctl is-active --quiet firewalld; then
        print_status "Configuring firewall for SSH port $SSH_PORT"
        firewall-cmd --permanent --add-port="$SSH_PORT/tcp"
        firewall-cmd --permanent --remove-service=ssh 2>/dev/null || true
        firewall-cmd --reload
        print_status "Firewall configured"
    else
        print_warning "Firewalld not active. Please configure your firewall manually"
    fi
}

# Apply SSH hardening
apply_ssh_hardening() {
    print_status "Applying SSH security configurations..."
    
    # Use a more robust configuration approach
    cat > /tmp/ssh_additions << EOF

# Security hardening applied $(date)
Port $SSH_PORT
AddressFamily inet
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security settings
X11Forwarding no
PrintMotd no
TCPKeepAlive no
Compression no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 2
LoginGraceTime 30

# Allow only specific users (uncomment and modify as needed)
# AllowUsers your_username

# Ciphers and algorithms (modern, secure options)
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
EOF

    # Remove old Port directive and add new configuration
    sed -i '/^#\?Port /d' "$SSH_CONFIG"
    sed -i '/^#\?PasswordAuthentication /d' "$SSH_CONFIG"
    sed -i '/^#\?PermitRootLogin /d' "$SSH_CONFIG"
    sed -i '/^#\?AddressFamily /d' "$SSH_CONFIG"
    
    # Append new configuration
    cat /tmp/ssh_additions >> "$SSH_CONFIG"
    rm /tmp/ssh_additions
    
    print_status "SSH configuration updated"
}

# Test SSH configuration
test_ssh_config() {
    print_status "Testing SSH configuration..."
    if sshd -t; then
        print_status "SSH configuration is valid"
    else
        print_error "SSH configuration has errors!"
        print_status "Restoring backup..."
        cp "$BACKUP_DIR/sshd_config.backup.$TIMESTAMP" "$SSH_CONFIG"
        exit 1
    fi
}

# Restart SSH service
restart_ssh() {
    print_status "Restarting SSH service..."
    systemctl restart sshd
    if systemctl is-active --quiet sshd; then
        print_status "SSH service restarted successfully"
    else
        print_error "Failed to restart SSH service!"
        systemctl status sshd
        exit 1
    fi
}

# Display final information
show_final_info() {
    echo
    print_status "SSH hardening completed successfully!"
    echo
    print_warning "IMPORTANT NOTES:"
    echo "1. SSH is now running on port $SSH_PORT"
    echo "2. Password authentication is disabled"
    echo "3. Root login is disabled"
    echo "4. Connect using: ssh -p $SSH_PORT username@hostname"
    echo "5. Backup saved to: $BACKUP_DIR/sshd_config.backup.$TIMESTAMP"
    echo
    print_warning "Test your SSH connection in a NEW terminal before closing this one!"
}

# Main execution
main() {
    print_status "Starting SSH Security Hardening for Fedora 41"
    
    check_root
    check_fedora
    
    if [[ ! -f "$SSH_CONFIG" ]]; then
        print_error "SSH configuration file not found: $SSH_CONFIG"
        exit 1
    fi
    
    create_backup
    get_ssh_port
    check_ssh_keys
    apply_ssh_hardening
    test_ssh_config
    configure_selinux
    configure_firewall
    restart_ssh
    show_final_info
}

# Run main function
main "$@"