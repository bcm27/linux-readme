#!/bin/bash

SCRIPTS_DIR="$(dirname "$0")"
SCRIPTS=(
    "01_enable_repos.sh"
    "02_update_packages.sh"
    "03_firmware_updates.sh"
    "04_flatpak_support.sh"
    "05_nvidia_drivers.sh"
    "06_multimedia_codecs.sh"
    "07_video_acceleration.sh"
    "09_useful_packages.sh"
    "11_hosts_file.sh"
    "12_ssh_hardening.sh"
)
DOCS=(
    "08_gnome_extensions.md"
    "10_proton_setup.md"
)

show_menu() {
    echo "Fedora 41 Setup Menu"
    echo "--------------------"
    local i=1
    for script in "scripts/${SCRIPTS[@]}"; do
        echo "$i) Run $script"
        ((i++))
    done
    for doc in "${DOCS[@]}"; do
        echo "$i) View $doc"
        ((i++))
    done
    echo "$i) Run ALL scripts (recommended order)"
    ((i++))
    echo "$i) Exit"
}

run_script() {
    local script="$1"
    if [[ -x "$SCRIPTS_DIR/$script" ]]; then
        bash "$SCRIPTS_DIR/$script"
    else
        chmod +x "$SCRIPTS_DIR/$script"
        bash "$SCRIPTS_DIR/$script"
    fi
}

view_doc() {
    local doc="$1"
    less "$SCRIPTS_DIR/$doc"
}

run_all() {
    for script in "${SCRIPTS[@]}"; do
        echo "----------------------------------------"
        echo "Running $script"
        echo "----------------------------------------"
        run_script "$script"
        echo
        read -p "Press Enter to continue to the next script..."
    done
}

while true; do
    show_menu
    echo
    read -p "Select an option [1-$((${#SCRIPTS[@]}+${#DOCS[@]}+2))]: " choice
    echo

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        if (( choice >= 1 && choice <= ${#SCRIPTS[@]} )); then
            run_script "${SCRIPTS[$((choice-1))]}"
        elif (( choice > ${#SCRIPTS[@]} && choice <= $((${#SCRIPTS[@]}+${#DOCS[@]})) )); then
            doc_idx=$((choice - ${#SCRIPTS[@]} - 1))
            view_doc "${DOCS[$doc_idx]}"
        elif (( choice == $((${#SCRIPTS[@]}+${#DOCS[@]}+1)) )); then
            run_all
        elif (( choice == $((${#SCRIPTS[@]}+${#DOCS[@]}+2)) )); then
            echo "Exiting."
            exit 0
        else
            echo "Invalid option."
        fi
    else
        echo "Invalid input."
    fi
    echo
done