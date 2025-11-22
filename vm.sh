#!/bin/bash
set -euo pipefail

# =============================
# Enhanced Multi-VM Manager
# POWERED BY HOPINGBOYZ
# =============================

# -------------------------
# Color Definitions
# -------------------------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
ORANGE='\033[38;5;208m'
PURPLE='\033[38;5;93m'
RESET='\033[0m'

# -------------------------
# ASCII Art and Animations
# -------------------------
display_header() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║  ██╗  ██╗ ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗ ██████╗  ██████╗ ██╗  ║
║  ██║  ██║██╔═══██╗██╔══██╗██║████╗  ██║██╔════╝ ██╔══██╗██╔═══██╗╚██╗ ║
║  ███████║██║   ██║██████╔╝██║██╔██╗ ██║██║  ███╗██████╔╝██║   ██║ ██║ ║
║  ██╔══██║██║   ██║██╔══██╗██║██║╚██╗██║██║   ██║██╔══██╗██║   ██║ ██║ ║
║  ██║  ██║╚██████╔╝██║  ██║██║██║ ╚████║╚██████╔╝██████╔╝╚██████╔╝██╔╝ ║
║  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ║
║                                                                        ║
║                  🚀 POWERED BY HOPINGBOYZ 🚀                          ║
║              Multi-OS Virtual Machine Management                      ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    
    # System info
    echo -e "${YELLOW}System Info:${RESET} $(uname -srm) | ${GREEN}VM Directory:${RESET} $VM_DIR"
    echo -e "${YELLOW}Date:${RESET} $(date) | ${GREEN}Active VMs:${RESET} $(find "$VM_DIR" -name "*.conf" 2>/dev/null | wc -l)"
    echo
}

# Spinner animation
spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='|/-\'
    
    echo -ne "  ${CYAN}${message}... ${RESET}"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Progress bar
progress_bar() {
    local duration=$1
    local message="$2"
    local blocks=50
    local sleep_interval=$(echo "scale=3; $duration/$blocks" | bc)
    
    echo -ne "  ${CYAN}${message}${RESET}\n  ["
    
    for ((i=0; i<=blocks; i++)); do
        printf "▰"
        sleep $sleep_interval
    done
    
    printf "] ${GREEN}Done!${RESET}\n"
}

# Print colored status messages
print_status() {
    local type=$1
    local message=$2
    
    case $type in
        "INFO") echo -e "  ${BLUE}🄸 ${RESET} ${BLUE}${message}${RESET}" ;;
        "WARN") echo -e "  ${YELLOW}⚠ ${RESET} ${YELLOW}${message}${RESET}" ;;
        "ERROR") echo -e "  ${RED}✗ ${RESET} ${RED}${message}${RESET}" ;;
        "SUCCESS") echo -e "  ${GREEN}✓ ${RESET} ${GREEN}${message}${RESET}" ;;
        "INPUT") echo -e "  ${CYAN}? ${RESET} ${CYAN}${message}${RESET}" ;;
        "DEBUG") echo -e "  ${PURPLE}⚙ ${RESET} ${PURPLE}${message}${RESET}" ;;
        *) echo "  [$type] $message" ;;
    esac
}

# Validate user input
validate_input() {
    local type=$1
    local value=$2
    
    case $type in
        "number")
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                print_status "ERROR" "Must be a number"
                return 1
            fi
            ;;
        "size")
            if ! [[ "$value" =~ ^[0-9]+[GgMm]$ ]]; then
                print_status "ERROR" "Must be a size with unit (e.g., 100G, 512M)"
                return 1
            fi
            ;;
        "port")
            if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 23 ] || [ "$value" -gt 65535 ]; then
                print_status "ERROR" "Must be a valid port number (23-65535)"
                return 1
            fi
            ;;
        "name")
            if ! [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_status "ERROR" "VM name can only contain letters, numbers, hyphens, and underscores"
                return 1
            fi
            ;;
        "username")
            if ! [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                print_status "ERROR" "Username must start with a letter or underscore, and contain only letters, numbers, hyphens, and underscores"
                return 1
            fi
            ;;
        "ip")
            if ! [[ "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                print_status "ERROR" "Must be a valid IP address"
                return 1
            fi
            ;;
    esac
    return 0
}

# Check system dependencies
check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img" "curl")
    local missing_deps=()
    
    print_status "INFO" "Checking system dependencies..."
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "ERROR" "Missing dependencies: ${missing_deps[*]}"
        echo
        print_status "INFO" "Installation commands:"
        echo -e "  ${CYAN}Ubuntu/Debian:${RESET} sudo apt update && sudo apt install qemu-system cloud-image-utils wget curl"
        echo -e "  ${CYAN}CentOS/RHEL:${RESET} sudo yum install qemu-kvm cloud-utils wget curl"
        echo -e "  ${CYAN}Arch Linux:${RESET} sudo pacman -S qemu cloud-utils wget curl"
        echo
        read -p "$(print_status "INPUT" "Press Enter to exit or 'i' to attempt installation: ")" -n 1 choice
        echo
        if [[ "$choice" == "i" ]]; then
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y qemu-system cloud-image-utils wget curl
            elif command -v yum &> /dev/null; then
                sudo yum install -y qemu-kvm cloud-utils wget curl
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm qemu cloud-utils wget curl
            else
                print_status "ERROR" "Cannot determine package manager. Please install dependencies manually."
                exit 1
            fi
        else
            exit 1
        fi
    fi
    print_status "SUCCESS" "All dependencies satisfied"
}

# Enhanced OS Options with more distributions
declare -A OS_OPTIONS=(
    # Ubuntu Family
    ["Ubuntu 22.04 LTS (Jammy Jellyfish)"]="ubuntu|jammy|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu22|ubuntu|ubuntu"
    ["Ubuntu 24.04 LTS (Noble Numbat)"]="ubuntu|noble|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu24|ubuntu|ubuntu"
    ["Ubuntu 20.04 LTS (Focal Fossa)"]="ubuntu|focal|https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img|ubuntu20|ubuntu|ubuntu"
    
    # Debian Family
    ["Debian 12 (Bookworm)"]="debian|bookworm|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2|debian12|debian|debian"
    ["Debian 11 (Bullseye)"]="debian|bullseye|https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2|debian11|debian|debian"
    ["Debian 10 (Buster)"]="debian|buster|https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2|debian10|debian|debian"
    
    # Fedora Family
    ["Fedora 40"]="fedora|40|https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-40-1.14.x86_64.qcow2|fedora40|fedora|fedora"
    ["Fedora 39"]="fedora|39|https://download.fedoraproject.org/pub/fedora/linux/releases/39/Cloud/x86_64/images/Fedora-Cloud-Base-39-1.5.x86_64.qcow2|fedora39|fedora|fedora"
    ["Fedora 38"]="fedora|38|https://download.fedoraproject.org/pub/fedora/linux/releases/38/Cloud/x86_64/images/Fedora-Cloud-Base-38-1.6.x86_64.qcow2|fedora38|fedora|fedora"
    
    # CentOS Family
    ["CentOS Stream 9"]="centos|stream9|https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2|centos9|centos|centos"
    ["CentOS Stream 8"]="centos|stream8|https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-latest.x86_64.qcow2|centos8|centos|centos"
    
    # AlmaLinux
    ["AlmaLinux 9"]="almalinux|9|https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2|almalinux9|alma|alma"
    ["AlmaLinux 8"]="almalinux|8|https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2|almalinux8|alma|alma"
    
    # Rocky Linux
    ["Rocky Linux 9"]="rockylinux|9|https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2|rocky9|rocky|rocky"
    ["Rocky Linux 8"]="rockylinux|8|https://download.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud.latest.x86_64.qcow2|rocky8|rocky|rocky"
    
    # OpenSUSE
    ["openSUSE Leap 15.5"]="opensuse|leap15.5|https://download.opensuse.org/distribution/leap/15.5/appliances/openSUSE-Leap-15.5-JeOS.x86_64-Cloud.qcow2|opensuse15|opensuse|opensuse"
    ["openSUSE Tumbleweed"]="opensuse|tumbleweed|https://download.opensuse.org/tumbleweed/appliances/openSUSE-Tumbleweed-JeOS.x86_64-Cloud.qcow2|tumbleweed|opensuse|opensuse"
    
    # Arch Linux
    ["Arch Linux"]="arch|latest|https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2|archlinux|arch|arch"
    
    # Alpine Linux
    ["Alpine Linux 3.19"]="alpine|3.19|https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.0-x86_64.iso|alpine319|alpine|alpine"
    ["Alpine Linux 3.18"]="alpine|3.18|https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-virt-3.18.4-x86_64.iso|alpine318|alpine|alpine"
    
    # Kali Linux
    ["Kali Linux 2024.1"]="kali|2024.1|https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-genericcloud-amd64.qcow2|kali2024|kali|kali"
    
    # FreeBSD
    ["FreeBSD 14.0"]="freebsd|14.0|https://download.freebsd.org/ftp/releases/VM-IMAGES/14.0-RELEASE/amd64/Latest/FreeBSD-14.0-RELEASE-amd64.qcow2|freebsd14|freebsd|freebsd"
    
    # NetBSD
    ["NetBSD 9.3"]="netbsd|9.3|https://cdn.netbsd.org/pub/NetBSD/NetBSD-9.3/images/NetBSD-9.3-amd64.qcow2|netbsd9|netbsd|netbsd"
    
    # Gentoo Linux
    ["Gentoo Linux"]="gentoo|latest|https://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-openstack.txt|gentoo|gentoo|gentoo"
    
    # Manjaro Linux
    ["Manjaro Linux"]="manjaro|latest|https://osdn.net/projects/manjaro/storage/x86_64/22.1.0/manjaro-x86_64-22.1.0-20241102-linux67.qcow2|manjaro|manjaro|manjaro"
)

# Function to categorize and display OS options
show_os_categories() {
    local categories=(
        "Ubuntu Family"
        "Debian Family" 
        "Fedora Family"
        "CentOS Family"
        "Enterprise Linux"
        "SUSE Family"
        "Arch Family"
        "Security & Pentesting"
        "BSD Family"
        "Other Distributions"
    )
    
    declare -A os_categories=(
        ["Ubuntu Family"]="Ubuntu 22.04 LTS (Jammy Jellyfish) Ubuntu 24.04 LTS (Noble Numbat) Ubuntu 20.04 LTS (Focal Fossa)"
        ["Debian Family"]="Debian 12 (Bookworm) Debian 11 (Bullseye) Debian 10 (Buster)"
        ["Fedora Family"]="Fedora 40 Fedora 39 Fedora 38"
        ["CentOS Family"]="CentOS Stream 9 CentOS Stream 8"
        ["Enterprise Linux"]="AlmaLinux 9 AlmaLinux 8 Rocky Linux 9 Rocky Linux 8"
        ["SUSE Family"]="openSUSE Leap 15.5 openSUSE Tumbleweed"
        ["Arch Family"]="Arch Linux Manjaro Linux"
        ["Security & Pentesting"]="Kali Linux 2024.1"
        ["BSD Family"]="FreeBSD 14.0 NetBSD 9.3"
        ["Other Distributions"]="Alpine Linux 3.19 Alpine Linux 3.18 Gentoo Linux"
    )
    
    echo -e "${CYAN}Available Operating Systems:${RESET}"
    echo
    
    local option_count=1
    for category in "${categories[@]}"; do
        if [ -n "${os_categories[$category]}" ]; then
            echo -e "  ${YELLOW}${category}:${RESET}"
            for os in ${os_categories[$category]}; do
                if [ -n "${OS_OPTIONS[$os]}" ]; then
                    echo -e "    ${GREEN}$option_count)${RESET} $os"
                    ((option_count++))
                fi
            done
            echo
        fi
    done
}

# Get OS by number selection
get_os_by_number() {
    local choice=$1
    local current=1
    
    for os in "${!OS_OPTIONS[@]}"; do
        if [ $current -eq $choice ]; then
            echo "$os"
            return 0
        fi
        ((current++))
    done
    return 1
}

# Enhanced VM creation with categories
create_new_vm() {
    print_status "INFO" "Creating a new Virtual Machine"
    echo
    
    # OS Selection with categories
    show_os_categories
    
    local total_os=${#OS_OPTIONS[@]}
    while true; do
        read -p "$(print_status "INPUT" "Enter your choice (1-$total_os): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $total_os ]; then
            local selected_os=$(get_os_by_number $choice)
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$selected_os]}"
            print_status "SUCCESS" "Selected: $selected_os"
            break
        else
            print_status "ERROR" "Invalid selection. Please enter a number between 1 and $total_os"
        fi
    done
    echo

    # VM Configuration with enhanced defaults
    while true; do
        read -p "$(print_status "INPUT" "Enter VM name (default: $DEFAULT_HOSTNAME): ")" VM_NAME
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            if [[ -f "$VM_DIR/$VM_NAME.conf" ]]; then
                print_status "ERROR" "VM with name '$VM_NAME' already exists"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Enter hostname (default: $VM_NAME): ")" HOSTNAME
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        if validate_input "name" "$HOSTNAME"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Enter username (default: $DEFAULT_USERNAME): ")" USERNAME
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        if validate_input "username" "$USERNAME"; then
            break
        fi
    done

    while true; do
        read -s -p "$(print_status "INPUT" "Enter password (default: $DEFAULT_PASSWORD): ")" PASSWORD
        PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
        echo
        if [ -n "$PASSWORD" ]; then
            break
        else
            print_status "ERROR" "Password cannot be empty"
        fi
    done

    # Enhanced configuration with recommendations
    echo
    print_status "INFO" "Resource Configuration (Recommended values shown)"
    
    while true; do
        read -p "$(print_status "INPUT" "Disk size (default: 20G, recommended: 20G-50G): ")" DISK_SIZE
        DISK_SIZE="${DISK_SIZE:-20G}"
        if validate_input "size" "$DISK_SIZE"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Memory in MB (default: 2048, recommended: 1024-4096): ")" MEMORY
        MEMORY="${MEMORY:-2048}"
        if validate_input "number" "$MEMORY"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Number of CPUs (default: 2, recommended: 1-4): ")" CPUS
        CPUS="${CPUS:-2}"
        if validate_input "number" "$CPUS"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "SSH Port (default: 2222): ")" SSH_PORT
        SSH_PORT="${SSH_PORT:-2222}"
        if validate_input "port" "$SSH_PORT"; then
            if ss -tln 2>/dev/null | grep -q ":$SSH_PORT "; then
                print_status "ERROR" "Port $SSH_PORT is already in use"
            else
                break
            fi
        fi
    done

    # Enhanced options
    while true; do
        read -p "$(print_status "INPUT" "Enable GUI mode? (y/n, default: n): ")" gui_input
        GUI_MODE=false
        gui_input="${gui_input:-n}"
        if [[ "$gui_input" =~ ^[Yy]$ ]]; then 
            GUI_MODE=true
            break
        elif [[ "$gui_input" =~ ^[Nn]$ ]]; then
            break
        else
            print_status "ERROR" "Please answer y or n"
        fi
    done

    # Additional network options
    read -p "$(print_status "INPUT" "Additional port forwards (e.g., 8080:80,8443:443, press Enter for none): ")" PORT_FORWARDS

    # Advanced options
    while true; do
        read -p "$(print_status "INPUT" "Enable accelerated graphics? (y/n, default: y): ")" accel_input
        accel_input="${accel_input:-y}"
        if [[ "$accel_input" =~ ^[Yy]$ ]]; then 
            ACCELERATED=true
            break
        elif [[ "$accel_input" =~ ^[Nn]$ ]]; then
            ACCELERATED=false
            break
        else
            print_status "ERROR" "Please answer y or n"
        fi
    done

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date '+%Y-%m-%d %H:%M:%S')"

    # Show configuration summary
    echo
    print_status "INFO" "Configuration Summary:"
    echo -e "  ${CYAN}OS:${RESET} $selected_os"
    echo -e "  ${CYAN}VM Name:${RESET} $VM_NAME"
    echo -e "  ${CYAN}Hostname:${RESET} $HOSTNAME"
    echo -e "  ${CYAN}Username:${RESET} $USERNAME"
    echo -e "  ${CYAN}Password:${RESET} ******"
    echo -e "  ${CYAN}Resources:${RESET} $MEMORY MB RAM, $CPUS CPUs, $DISK_SIZE disk"
    echo -e "  ${CYAN}SSH Port:${RESET} $SSH_PORT"
    echo -e "  ${CYAN}GUI Mode:${RESET} $GUI_MODE"
    echo -e "  ${CYAN}Accelerated:${RESET} $ACCELERATED"
    echo -e "  ${CYAN}Port Forwards:${RESET} ${PORT_FORWARDS:-None}"
    echo

    read -p "$(print_status "INPUT" "Proceed with VM creation? (y/N): ")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "INFO" "VM creation cancelled"
        return 1
    fi

    # Download and setup VM image
    setup_vm_image
    
    # Save configuration
    save_vm_config
}

# [Rest of the functions remain similar but with enhanced visuals...]

# Enhanced main menu with better layout
main_menu() {
    while true; do
        display_header
        
        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}
        
        if [ $vm_count -gt 0 ]; then
            print_status "INFO" "Virtual Machines ($vm_count):"
            echo -e "  ${CYAN}No.  VM Name                 Status     OS Type${RESET}"
            echo -e "  ${CYAN}───  ────────────────────  ─────────  ────────────${RESET}"
            for i in "${!vms[@]}"; do
                local status="${RED}Stopped${RESET}"
                if is_vm_running "${vms[$i]}"; then
                    status="${GREEN}Running${RESET}"
                fi
                
                # Load VM config to get OS type
                if load_vm_config "${vms[$i]}" 2>/dev/null; then
                    local os_type="$OS_TYPE"
                else
                    local os_type="Unknown"
                fi
                
                printf "  ${GREEN}%2d${RESET}  %-20s  %-9s  %-15s\n" $((i+1)) "${vms[$i]}" "$status" "$os_type"
            done
            echo
        else
            print_status "INFO" "No virtual machines found. Create your first VM to get started!"
            echo
        fi
        
        echo -e "${CYAN}Main Menu:${RESET}"
        echo -e "  ${GREEN}1${RESET}) Create a new VM"
        if [ $vm_count -gt 0 ]; then
            echo -e "  ${GREEN}2${RESET}) Start a VM"
            echo -e "  ${GREEN}3${RESET}) Stop a VM"
            echo -e "  ${GREEN}4${RESET}) Show VM info"
            echo -e "  ${GREEN}5${RESET}) Edit VM configuration"
            echo -e "  ${GREEN}6${RESET}) Delete a VM"
            echo -e "  ${GREEN}7${RESET}) Resize VM disk"
            echo -e "  ${GREEN}8${RESET}) Show VM performance"
            echo -e "  ${GREEN}9${RESET}) Backup VM"
        fi
        echo -e "  ${GREEN}0${RESET}) Exit"
        echo
        
        read -p "$(print_status "INPUT" "Enter your choice: ")" choice
        
        case $choice in
            1) create_new_vm ;;
            2) if [ $vm_count -gt 0 ]; then start_vm_menu; fi ;;
            3) if [ $vm_count -gt 0 ]; then stop_vm_menu; fi ;;
            4) if [ $vm_count -gt 0 ]; then show_vm_info_menu; fi ;;
            5) if [ $vm_count -gt 0 ]; then edit_vm_config_menu; fi ;;
            6) if [ $vm_count -gt 0 ]; then delete_vm_menu; fi ;;
            7) if [ $vm_count -gt 0 ]; then resize_vm_disk_menu; fi ;;
            8) if [ $vm_count -gt 0 ]; then show_vm_performance_menu; fi ;;
            9) if [ $vm_count -gt 0 ]; then backup_vm_menu; fi ;;
            0) 
                print_status "SUCCESS" "Thank you for using HopingBoyz VM Manager! 🚀"
                echo
                exit 0 
                ;;
            *) 
                print_status "ERROR" "Invalid option. Please try again." 
                ;;
        esac
        
        echo
        read -p "$(print_status "INPUT" "Press Enter to continue...")"
    done
}

# Initialize the system
initialize_system() {
    print_status "INFO" "Initializing HopingBoyz VM Manager..."
    
    # Check dependencies
    check_dependencies
    
    # Create VM directory
    VM_DIR="${VM_DIR:-$HOME/hopingboyz-vms}"
    mkdir -p "$VM_DIR"
    
    # Create backups directory
    BACKUP_DIR="$VM_DIR/backups"
    mkdir -p "$BACKUP_DIR"
    
    print_status "SUCCESS" "System initialized successfully!"
    sleep 1
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Start the application
initialize_system
main_menu
