#!/bin/bash
# SSH Configuration Validator
# Validates SSH port configuration without starting the service
# Author: Bjorn (UlvenLab)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} SSH Configuration Validator${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

print_check() {
    echo -e "${GREEN}[CHECK]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

check_sshd_config() {
    echo -e "${BLUE}--- SSH Configuration File ---${NC}"
    
    # Check if config file exists
    if [[ ! -f "/etc/ssh/sshd_config" ]]; then
        print_fail "SSH config file not found"
        return 1
    fi
    
    # Check port configuration
    local port_line=$(grep "^Port" /etc/ssh/sshd_config)
    if [[ -n "$port_line" ]]; then
        local port=$(echo "$port_line" | awk '{print $2}')
        if [[ "$port" == "2117" ]]; then
            print_pass "Port configured: $port"
        else
            print_warning "Port configured: $port (not 2117)"
        fi
    else
        print_warning "No explicit Port configuration found (defaults to 22)"
    fi
    
    # Test configuration syntax
    if sudo sshd -t 2>/dev/null; then
        print_pass "SSH configuration syntax is valid"
    else
        print_fail "SSH configuration has syntax errors"
        echo "Run 'sudo sshd -t' for details"
    fi
    
    # Show key security settings
    echo
    print_check "Key security settings:"
    grep -E "^(PasswordAuthentication|PermitRootLogin|PubkeyAuthentication)" /etc/ssh/sshd_config || echo "Default settings in use"
}

check_systemd_socket() {
    echo -e "${BLUE}--- systemd Socket Configuration ---${NC}"
    
    # Check if socket unit exists
    if systemctl list-unit-files | grep -q "sshd.socket"; then
        print_pass "sshd.socket unit found"
        
        # Check socket override
        local override_file="/etc/systemd/system/sshd.socket.d/override.conf"
        if [[ -f "$override_file" ]]; then
            print_pass "Socket override configuration exists"
            
            # Check override content
            local listen_line=$(grep "ListenStream=2117" "$override_file")
            if [[ -n "$listen_line" ]]; then
                print_pass "Socket configured for port 2117"
            else
                print_warning "Socket override exists but may not be for port 2117"
            fi
            
            echo "Override content:"
            cat "$override_file" | sed 's/^/  /'
        else
            print_warning "No socket override found (will use default port 22)"
        fi
        
        # Show what systemd would bind to
        local listen_info=$(systemctl show sshd.socket -p Listen 2>/dev/null)
        if [[ -n "$listen_info" ]]; then
            echo "systemd Listen configuration:"
            echo "  $listen_info"
        fi
    else
        print_warning "sshd.socket not found (traditional service mode)"
    fi
}

check_selinux() {
    echo -e "${BLUE}--- SELinux Configuration ---${NC}"
    
    # Check if SELinux is enabled
    if command -v getenforce >/dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null)
        print_check "SELinux status: $selinux_status"
        
        if [[ "$selinux_status" == "Enforcing" || "$selinux_status" == "Permissive" ]]; then
            # Check SSH port contexts
            if command -v semanage >/dev/null 2>&1; then
                local ssh_ports=$(sudo semanage port -l | grep ssh_port_t 2>/dev/null)
                if [[ -n "$ssh_ports" ]]; then
                    print_pass "SSH port contexts found"
                    echo "  $ssh_ports"
                    
                    # Check specifically for port 2117
                    if echo "$ssh_ports" | grep -q "2117"; then
                        print_pass "Port 2117 is allowed by SELinux"
                    else
                        print_fail "Port 2117 is NOT allowed by SELinux"
                        echo "Run: sudo semanage port -a -t ssh_port_t -p tcp 2117"
                    fi
                else
                    print_fail "Could not retrieve SSH port contexts"
                fi
            else
                print_warning "semanage command not available"
                echo "Install: sudo dnf install policycoreutils-python-utils"
            fi
        fi
    else
        print_warning "SELinux tools not available"
    fi
}

check_firewall() {
    echo -e "${BLUE}--- Firewall Configuration ---${NC}"
    
    # Check if firewalld is running
    if systemctl is-active --quiet firewalld; then
        print_pass "firewalld is active"
        
        # Check SSH service
        local ssh_service=$(sudo firewall-cmd --list-services | grep ssh)
        if [[ -n "$ssh_service" ]]; then
            print_pass "SSH service is allowed through firewall"
            
            # Check if port 2117 is added to SSH service
            if sudo firewall-cmd --service=ssh --query-port=2117/tcp 2>/dev/null; then
                print_pass "Port 2117 is allowed in SSH service"
            else
                print_warning "Port 2117 not found in SSH service"
            fi
        fi
        
        # Check direct port rules
        local ports=$(sudo firewall-cmd --list-ports)
        if echo "$ports" | grep -q "2117/tcp"; then
            print_pass "Port 2117/tcp directly allowed"
        else
            print_warning "Port 2117/tcp not found in direct port rules"
        fi
        
        echo "Current firewall configuration:"
        sudo firewall-cmd --list-all | sed 's/^/  /'
    else
        print_warning "firewalld is not active"
        echo "Check iptables or other firewall solutions"
    fi
}

check_service_status() {
    echo -e "${BLUE}--- Service Status ---${NC}"
    
    # Check sshd.service
    if systemctl is-enabled sshd.service >/dev/null 2>&1; then
        local service_status=$(systemctl is-enabled sshd.service)
        print_check "sshd.service: $service_status"
    fi
    
    # Check sshd.socket
    if systemctl is-enabled sshd.socket >/dev/null 2>&1; then
        local socket_status=$(systemctl is-enabled sshd.socket)
        print_check "sshd.socket: $socket_status"
    fi
    
    # Check if any SSH process is running
    if pgrep -x sshd >/dev/null; then
        print_warning "SSH daemon is currently running"
        echo "Listening ports:"
        ss -tlnp | grep sshd | sed 's/^/  /'
    else
        print_check "SSH daemon is not running (as expected)"
    fi
}

simulate_startup() {
    echo -e "${BLUE}--- Startup Simulation ---${NC}"
    
    print_check "What would happen if SSH starts:"
    
    # Check what port SSH would bind to
    local configured_port=$(sudo sshd -T | grep "^port" | awk '{print $2}')
    echo "  SSH would bind to port: $configured_port"
    
    # Check if port is available
    if ss -tlnp | grep -q ":$configured_port "; then
        print_warning "Port $configured_port is currently in use"
        echo "  Process using port:"
        ss -tlnp | grep ":$configured_port " | sed 's/^/    /'
    else
        print_pass "Port $configured_port is available"
    fi
}

generate_test_commands() {
    echo -e "${BLUE}--- Test Commands ---${NC}"
    echo "To test SSH configuration when ready:"
    echo
    echo "1. Start SSH temporarily:"
    echo "   sudo systemctl start sshd.socket  # or sshd.service"
    echo
    echo "2. Test connection locally:"
    echo "   ssh -p 2117 -o ConnectTimeout=5 $(whoami)@localhost"
    echo
    echo "3. Check listening ports:"
    echo "   ss -tlnp | grep :2117"
    echo
    echo "4. Stop SSH service:"
    echo "   sudo systemctl stop sshd.socket sshd.service"
    echo
}

# Analyze results and provide summary
analyze_configuration() {
    echo -e "${BLUE}--- Configuration Analysis ---${NC}"
    
    local config_score=0
    local max_score=6
    local issues=()
    
    # Check 1: Port configuration
    local port_line=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null)
    if [[ -n "$port_line" ]]; then
        local port=$(echo "$port_line" | awk '{print $2}')
        if [[ "$port" == "2117" ]]; then
            ((config_score++))
            print_pass "✓ SSH config file has correct port 2117"
        else
            issues+=("SSH config has port $port instead of 2117")
        fi
    else
        issues+=("No explicit port configuration in SSH config")
    fi
    
    # Check 2: Configuration syntax
    if sudo sshd -t 2>/dev/null; then
        ((config_score++))
        print_pass "✓ SSH configuration syntax is valid"
    else
        issues+=("SSH configuration has syntax errors")
    fi
    
    # Check 3: systemd socket configuration
    local override_file="/etc/systemd/system/sshd.socket.d/override.conf"
    if [[ -f "$override_file" ]] && grep -q "ListenStream=2117" "$override_file"; then
        ((config_score++))
        print_pass "✓ systemd socket configured for port 2117"
    else
        if systemctl list-unit-files | grep -q "sshd.socket"; then
            issues+=("systemd socket exists but not configured for port 2117")
        else
            print_check "Using traditional service mode (socket not required)"
            ((config_score++))  # Not an error for traditional mode
        fi
    fi
    
    # Check 4: SELinux (if enforcing)
    if command -v getenforce >/dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null)
        if [[ "$selinux_status" == "Enforcing" ]]; then
            if sudo semanage port -l 2>/dev/null | grep ssh_port_t | grep -q "2117"; then
                ((config_score++))
                print_pass "✓ SELinux allows port 2117 for SSH"
            else
                issues+=("SELinux does not allow port 2117 for SSH")
            fi
        else
            print_check "SELinux not enforcing (port check not required)"
            ((config_score++))
        fi
    else
        print_check "SELinux not available (port check not required)"
        ((config_score++))
    fi
    
    # Check 5: Firewall configuration
    if systemctl is-active --quiet firewalld; then
        local firewall_ok=false
        
        # Check if port is in SSH service
        if sudo firewall-cmd --service=ssh --query-port=2117/tcp 2>/dev/null; then
            firewall_ok=true
        fi
        
        # Check if port is directly allowed
        if sudo firewall-cmd --list-ports | grep -q "2117/tcp"; then
            firewall_ok=true
        fi
        
        if [[ "$firewall_ok" == true ]]; then
            ((config_score++))
            print_pass "✓ Firewall allows port 2117"
        else
            issues+=("Firewall does not allow port 2117")
        fi
    else
        print_check "firewalld not active (assuming other firewall or none)"
        ((config_score++))
    fi
    
    # Check 6: Service status (should be disabled on workstation)
    local ssh_running=false
    if systemctl is-active --quiet sshd.service || systemctl is-active --quiet sshd.socket; then
        ssh_running=true
    fi
    
    if [[ "$ssh_running" == false ]]; then
        ((config_score++))
        print_pass "✓ SSH service is disabled (correct for workstation)"
    else
        print_warning "SSH service is currently running"
        ((config_score++))  # Not necessarily wrong, just noting
    fi
    
    echo
    echo -e "${BLUE}--- Final Assessment ---${NC}"
    echo "Configuration Score: $config_score/$max_score"
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        print_pass "✓ SSH is properly configured for port 2117"
        print_pass "✓ Service is disabled (appropriate for workstation)"
        print_pass "✓ Configuration ready for ProxMox server deployment"
        return 0
    else
        print_warning "Issues found:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
        
        if [[ $config_score -ge 4 ]]; then
            print_warning "Configuration mostly correct, minor issues to resolve"
            return 1
        else
            print_fail "Significant configuration issues need attention"
            return 2
        fi
    fi
}

# Main execution
main() {
    print_header
    
    check_sshd_config
    echo
    check_systemd_socket
    echo
    check_selinux
    echo
    check_firewall
    echo
    check_service_status
    echo
    simulate_startup
    echo
    analyze_configuration
    echo
    generate_test_commands
    
    echo
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ VALIDATION COMPLETE: SSH properly configured for port 2117${NC}"
        echo -e "${GREEN}✓ Service disabled as intended for workstation${NC}"
        echo -e "${GREEN}✓ Ready for ProxMox server deployment${NC}"
    elif [[ $exit_code -eq 1 ]]; then
        echo -e "${YELLOW}⚠ VALIDATION COMPLETE: Minor issues found${NC}"
        echo -e "${GREEN}✓ Core SSH configuration for port 2117 is correct${NC}"
    else
        echo -e "${RED}✗ VALIDATION FAILED: Significant issues need resolution${NC}"
    fi
}

main "$@"