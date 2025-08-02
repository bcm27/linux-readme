#!/bin/bash
# SSH Security Hardening Script for Fedora 41+
# Version: 2.1 - Improved and Fedora-optimized

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} SSH Security Hardening - Fedora${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect Fedora version and SSH service
check_system() {
    if ! grep -q "Fedora" /etc/os-release; then
        print_warning "This script is optimized for Fedora systems"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check if SSH service exists and is enabled
    if ! systemctl is-enabled sshd &>/dev/null; then
        print_warning "SSH service is not enabled. Enabling now..."
        systemctl enable sshd
    fi
}

# Verify host keys exist
check_host_keys() {
    print_status "Checking SSH host keys..."
    local missing_keys=false
    
    for key_type in rsa ecdsa ed25519; do
        if [[ ! -f "/etc/ssh/ssh_host_${key_type}_key" ]]; then
            print_warning "Missing host key: ssh_host_${key_type}_key"
            missing_keys=true
        fi
    done
    
    if [[ "$missing_keys" == true ]]; then
        print_status "Generating missing host keys..."
        ssh-keygen -A
    else
        print_status "All required host keys present"
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
    local default_port=${1:-2222}
    
    while true; do
        read -p "Enter the desired SSH port (1024-65535, default $default_port): " SSH_PORT
        SSH_PORT=${SSH_PORT:-$default_port}
        
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

# Check if SSH keys exist for authentication
check_ssh_keys() {
    local has_keys=false
    local key_count=0
    
    print_status "Checking for SSH public keys..."
    
    # Check for authorized_keys files
    for user_home in /home/*; do
        if [[ -f "$user_home/.ssh/authorized_keys" && -s "$user_home/.ssh/authorized_keys" ]]; then
            local username=$(basename "$user_home")
            local keys=$(grep -c "^ssh-" "$user_home/.ssh/authorized_keys" 2>/dev/null || echo 0)
            if [[ $keys -gt 0 ]]; then
                print_status "Found $keys SSH key(s) for user: $username"
                has_keys=true
                ((key_count += keys))
            fi
        fi
    done
    
    # Check root's authorized_keys
    if [[ -f "/root/.ssh/authorized_keys" && -s "/root/.ssh/authorized_keys" ]]; then
        local root_keys=$(grep -c "^ssh-" "/root/.ssh/authorized_keys" 2>/dev/null || echo 0)
        if [[ $root_keys -gt 0 ]]; then
            print_status "Found $root_keys SSH key(s) for root"
            has_keys=true
            ((key_count += root_keys))
        fi
    fi
    
    if [[ "$has_keys" == false ]]; then
        print_error "No SSH keys found! Disabling password authentication will lock you out."
        print_warning "Please set up SSH keys before running this script."
        echo
        echo "To set up SSH keys:"
        echo "1. On your client: ssh-keygen -t ed25519"
        echo "2. Copy to server: ssh-copy-id -p $SSH_PORT user@server"
        echo
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_status "Total SSH keys found: $key_count"
    fi
}

# Build dynamic host key configuration
build_hostkey_config() {
    local hostkey_config=""
    
    for key_type in ed25519 ecdsa rsa; do
        if [[ -f "/etc/ssh/ssh_host_${key_type}_key" ]]; then
            hostkey_config="${hostkey_config}HostKey /etc/ssh/ssh_host_${key_type}_key\n"
        fi
    done
    
    echo -e "$hostkey_config"
}

# Apply SSH hardening configuration
apply_ssh_hardening() {
    print_status "Applying SSH security configurations..."
    
    local hostkey_config=$(build_hostkey_config)
    
    # Create new configuration
    cat > /tmp/ssh_hardening_config << EOF
# SSH Security Hardening Applied: $(date)
# Backup available at: $BACKUP_DIR/sshd_config.backup.$TIMESTAMP

# Network Configuration
Port $SSH_PORT
AddressFamily inet
ListenAddress 0.0.0.0

# Host Keys (dynamically detected)
$(echo -e "$hostkey_config")

# Authentication Settings
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Connection Settings
X11Forwarding no
PrintMotd no
TCPKeepAlive no
Compression no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10
MaxStartups 10:30:60
LoginGraceTime 30

# Security Features
AllowUsers $(whoami)
PermitUserEnvironment no
PermitTunnel no
GatewayPorts no
AllowAgentForwarding yes
AllowTcpForwarding local
PermitTTY yes

# Modern Cryptography (Fedora 41+ compatible)
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512

# Logging
SyslogFacility AUTHPRIV
LogLevel VERBOSE
EOF

    # Remove old problematic directives and apply new config
    cp "$SSH_CONFIG" "$SSH_CONFIG.temp"
    
    # Remove old Port, PasswordAuthentication, PermitRootLogin settings
    sed -i '/^#\?Port /d' "$SSH_CONFIG.temp"
    sed -i '/^#\?PasswordAuthentication /d' "$SSH_CONFIG.temp"
    sed -i '/^#\?PermitRootLogin /d' "$SSH_CONFIG.temp"
    sed -i '/^#\?AddressFamily /d' "$SSH_CONFIG.temp"
    sed -i '/^#\?HostKey /d' "$SSH_CONFIG.temp"
    
    # Append new hardened configuration
    cat /tmp/ssh_hardening_config >> "$SSH_CONFIG.temp"
    mv "$SSH_CONFIG.temp" "$SSH_CONFIG"
    
    # Clean up temp file
    rm -f /tmp/ssh_hardening_config
    
    print_status "SSH configuration updated"
}

# Test SSH configuration
test_ssh_config() {
    print_status "Testing SSH configuration..."
    if sshd -t; then
        print_status "SSH configuration is valid"
        return 0
    else
        print_error "SSH configuration has errors!"
        print_status "Restoring backup..."
        cp "$BACKUP_DIR/sshd_config.backup.$TIMESTAMP" "$SSH_CONFIG"
        return 1
    fi
}

# Configure SELinux for custom SSH port
configure_selinux() {
    if command -v semanage >/dev/null 2>&1; then
        print_status "Configuring SELinux for port $SSH_PORT"
        
        # Check if port is already configured
        if semanage port -l | grep -q "ssh_port_t.*$SSH_PORT"; then
            print_status "SELinux already configured for port $SSH_PORT"
        else
            semanage port -a -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || \
            semanage port -m -t ssh_port_t -p tcp "$SSH_PORT"
            print_status "SELinux configured for SSH port $SSH_PORT"
        fi
    else
        print_warning "SELinux management tools not found. Install policycoreutils-python-utils if needed"
    fi
}

# Configure firewall (firewalld on Fedora)
configure_firewall() {
    if systemctl is-active --quiet firewalld; then
        print_status "Configuring firewall for SSH port $SSH_PORT"
        
        # Add new port
        firewall-cmd --permanent --add-port="$SSH_PORT/tcp"
        
        # Remove default SSH service (port 22)
        firewall-cmd --permanent --remove-service=ssh 2>/dev/null || true
        
        # Reload firewall
        firewall-cmd --reload
        
        print_status "Firewall configured"
    else
        print_warning "Firewalld not active. Please configure your firewall manually"
        echo "Manual firewall rules needed:"
        echo "- Allow port $SSH_PORT/tcp"
        echo "- Block port 22/tcp"
    fi
}

# Restart SSH service
restart_ssh() {
    print_status "Restarting SSH service..."
    systemctl restart sshd
    
    if systemctl is-active --quiet sshd; then
        print_status "SSH service restarted successfully"
        print_status "SSH is running on port $SSH_PORT"
    else
        print_error "Failed to restart SSH service!"
        systemctl status sshd
        return 1
    fi
}

# Display final information
show_final_info() {
    echo
    print_header
    print_status "SSH hardening completed successfully!"
    echo
    print_warning "IMPORTANT NOTES:"
    echo "1. SSH is now running on port $SSH_PORT"
    echo "2. Password authentication is disabled"
    echo "3. Root login is disabled"
    echo "4. Only user '$(whoami)' can connect"
    echo "5. Connect using: ssh -p $SSH_PORT $(whoami)@$(hostname -I | awk '{print $1}')"
    echo "6. Backup saved to: $BACKUP_DIR/sshd_config.backup.$TIMESTAMP"
    echo
    print_warning "Test your SSH connection in a NEW terminal before closing this one!"
    echo
    echo "To restore original config if needed:"
    echo "sudo cp $BACKUP_DIR/sshd_config.backup.$TIMESTAMP $SSH_CONFIG"
    echo "sudo systemctl restart sshd"
}

# Main execution
main() {
    print_header
    
    check_root
    check_system
    check_host_keys
    create_backup
    
    # Get SSH port from command line or prompt
    if [[ -n "$1" && "$1" =~ ^[0-9]+$ ]]; then
        SSH_PORT="$1"
        print_status "Using SSH port from command line: $SSH_PORT"
    else
        get_ssh_port "$1"
    fi
    
    check_ssh_keys
    apply_ssh_hardening
    
    if test_ssh_config; then
        configure_selinux
        configure_firewall
        restart_ssh
        show_final_info
    else
        print_error "Configuration failed. Check the errors above."
        exit 1
    fi
}

# Run main function with all arguments
main "$@"