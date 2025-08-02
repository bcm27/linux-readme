#!/usr/bin/env bash

# SSH Configuration Validation Script for Fedora 42+
# Validates SSHD config syntax, SELinux rules, firewalld port access, and systemd socket overrides.

set -euo pipefail

SSH_PORT=2117
CONFIG_FILE="/etc/ssh/sshd_config"
CONFIG_SCORE=0
ANALYSIS_EXIT=0

color() {
    local code="$1"; shift
    echo -e "\033[${code}m$*\033[0m"
}

header() {
    echo -e "\n$(color 1; echo "$1")\n$(color 1; echo "$(printf -- '-%.0s' {1..60})")"
}

check_config_file() {
    header "Checking SSH configuration file syntax"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        color 31 "FAIL: $CONFIG_FILE does not exist."
        return 1
    fi

    if ! sshd -t -f "$CONFIG_FILE" 2>/dev/null; then
        color 31 "FAIL: SSH config has syntax errors."
        return 1
    else
        color 32 "PASS: SSH config syntax is valid."
        return 0
    fi
}

check_port_in_config() {
    header "Checking for Port $SSH_PORT in SSH config"
    if grep -Eiq "^\s*Port\s+$SSH_PORT" "$CONFIG_FILE"; then
        color 32 "PASS: Port $SSH_PORT is configured."
        return 0
    else
        color 33 "WARN: Port $SSH_PORT not found in $CONFIG_FILE."
        return 1
    fi
}

check_socket_override() {
    header "Checking for systemd socket override"
    local socket_dir="/etc/systemd/system/sshd.socket.d"
    local override_file="$socket_dir/override.conf"

    if [[ -f "$override_file" ]]; then
        if grep -q "ListenStream=$SSH_PORT" "$override_file"; then
            color 32 "PASS: override.conf correctly specifies ListenStream=$SSH_PORT"
            return 0
        else
            color 31 "FAIL: override.conf does not specify ListenStream=$SSH_PORT"
            return 1
        fi
    else
        color 33 "WARN: No override.conf found for sshd.socket."
        return 1
    fi
}

check_socket_or_service() {
    header "Checking if sshd is running as a socket or service"

    if systemctl is-enabled sshd.socket &>/dev/null; then
        color 34 "INFO: sshd.socket is enabled. Checking override."
        check_socket_override && return 0 || return 1
    else
        color 34 "INFO: sshd.service is enabled."
        return 0
    fi
}

check_firewalld_rules() {
    header "Checking firewalld for SSH port $SSH_PORT"

    if ! firewall-cmd --state &>/dev/null; then
        color 33 "WARN: firewalld is not active. Skipping firewall checks."
        return 1
    fi

    if firewall-cmd --list-ports | grep -q "\b$SSH_PORT/tcp\b"; then
        color 32 "PASS: firewalld allows port $SSH_PORT/tcp"
        return 0
    else
        color 31 "FAIL: firewalld does not allow port $SSH_PORT/tcp"
        return 1
    fi
}

check_selinux_port() {
    header "Checking SELinux for custom SSH port $SSH_PORT"
    if ! command -v semanage &>/dev/null; then
        color 33 "WARN: semanage not available. Install policycoreutils-python-utils."
        return 1
    fi

    if semanage port -l | grep ssh_port_t | awk '{print $3}' | grep -qw "$SSH_PORT"; then
        color 32 "PASS: SELinux allows port $SSH_PORT for sshd"
        return 0
    else
        color 31 "FAIL: SELinux does not allow port $SSH_PORT for sshd"
        return 1
    fi
}

check_socket_conflict() {
    header "Checking for port conflicts on $SSH_PORT"
    if ss -tlnp | awk '{print $5}' | grep -qE ":$SSH_PORT$"; then
        color 32 "PASS: Port $SSH_PORT is being listened to."
        return 0
    else
        color 31 "FAIL: No service appears to be listening on port $SSH_PORT"
        return 1
    fi
}

check_service_state() {
    header "Checking sshd service state"

    if systemctl is-active sshd &>/dev/null; then
        color 32 "PASS: sshd is running"
    else
        color 33 "WARN: sshd is not currently running"
    fi

    if systemctl is-enabled sshd &>/dev/null; then
        color 32 "PASS: sshd is enabled on boot"
    else
        color 33 "WARN: sshd is not enabled on boot"
    fi
}

analyze_configuration() {
    CONFIG_SCORE=0

    check_config_file && ((CONFIG_SCORE+=1))
    check_port_in_config && ((CONFIG_SCORE+=1))
    check_socket_or_service && ((CONFIG_SCORE+=1))
    check_selinux_port && ((CONFIG_SCORE+=1))
    check_firewalld_rules && ((CONFIG_SCORE+=1))
    check_socket_conflict && ((CONFIG_SCORE+=1))

    header "SSH Hardening Summary"
    echo "Checks Passed: $CONFIG_SCORE/6"

    if [[ "$CONFIG_SCORE" -lt 6 ]]; then
        color 31 "SSH configuration incomplete or insecure."
        ANALYSIS_EXIT=1
    else
        color 32 "SSH configuration appears secure."
        ANALYSIS_EXIT=0
    fi
}

print_manual_test_instructions() {
    header "Manual Testing Suggestion"
    echo "Use the following command to test SSH connectivity before restarting services:"
    echo "\n  ssh -p $SSH_PORT <username>@<hostname>\n"
    echo "This ensures you can connect before applying changes."
}

main() {
    analyze_configuration
    check_service_state
    print_manual_test_instructions
    exit "$ANALYSIS_EXIT"
}

main "$@"
