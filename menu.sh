#!/bin/bash

VERSION="1.1.6"
SCRIPT_URL="https://txavl.github.io/Men1/menu.sh"
KEY_FILE="$HOME/.txa_key"
API_URL="https://key.txavideo.online/api/validate_key.php"
USER_INFO_FILE="$HOME/.txa_user_info"
VERSION_FILE="$HOME/.txa_version"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Required packages
REQUIRED_PACKAGES="curl nmap jq"

# Function to check and install required packages
check_and_install_packages() {
    echo -e "${YELLOW}Checking required packages...${NC}"
    for package in $REQUIRED_PACKAGES; do
        if ! command -v $package &> /dev/null; then
            echo -e "${RED}$package is not installed. Installing...${NC}"
            pkg install -y $package
        else
            echo -e "${GREEN}$package is already installed.${NC}"
        fi
    done
    echo -e "${GREEN}All required packages are installed.${NC}"
}

# Function to compare versions
compare_versions() {
    local ver1=$1
    local ver2=$2
    if [[ "$ver1" == "$ver2" ]]; then
        return 0  # equal
    elif [[ "$(printf '%s\n' "$ver1" "$ver2" | sort -V | head -n1)" == "$ver1" ]]; then
        return 1  # ver1 is smaller
    else
        return 2  # ver1 is greater
    fi
}

# Function to check for updates
check_update() {
    echo -e "${YELLOW}Checking for updates...${NC}"
    local temp_file=$(mktemp)
    
    if [ -f "$VERSION_FILE" ]; then
        local current_version=$(cat "$VERSION_FILE")
    else
        local current_version="0.0.0"
    fi
    
    if curl -s "$SCRIPT_URL" -o "$temp_file"; then
        local latest_version=$(grep "^VERSION=" "$temp_file" | cut -d'"' -f2)
        if [[ -z "$latest_version" ]]; then
            echo -e "${RED}Unable to determine new version from server.${NC}"
            rm -f "$temp_file"
            return
        fi
        
        compare_versions "$current_version" "$latest_version"
        case $? in
            1)
                echo -e "${GREEN}New version available: $latest_version${NC}"
                read -p "Do you want to update? (y/n): " choice
                if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                    mv "$temp_file" "$0"
                    chmod +x "$0"
                    echo "$latest_version" > "$VERSION_FILE"
                    echo -e "${GREEN}Script updated. Please run again.${NC}"
                    exit 0
                fi
                ;;
            2)
                echo -e "${GREEN}You are using the latest version.${NC}"
                ;;
            *)
                echo -e "${RED}Error comparing versions.${NC}"
                ;;
        esac
    else
        echo -e "${RED}Unable to check for updates. Please try again later.${NC}"
    fi
    rm -f "$temp_file"
}

# Function to display header
show_header() {
    clear
    echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${YELLOW}               TXA Advanced Script             ${RED}║${NC}"
    echo -e "${RED}║${GREEN}            Copyright © 2024 TXA                ${RED}║${NC}"
    echo -e "${RED}║${BLUE}               Version: $VERSION                 ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
    echo
}

# Function to display warning and request confirmation
show_warning() {
    show_header
    echo -e "${RED}After installing v$VERSION, all Termux permissions and features will belong to TxaServer.${NC}"
    echo -e "${RED}If you want to revert to the original state, please reinstall Termux.${NC}"
    echo
    read -p "Do you want to continue? [Y/N]: " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 1
    fi
}

# Function to display main menu
show_main_menu() {
    echo -e "${CYAN}Main Menu:${NC}"
    echo -e "${BLUE}1. Open Menu${NC}"
    echo -e "${BLUE}2. Enter Key${NC}"
    echo -e "${BLUE}3. Exit${NC}"
    echo
}

# Function to display submenu
show_submenu() {
    echo -e "${CYAN}Submenu:${NC}"
    echo -e "${BLUE}1. System Info${NC}"
    echo -e "${BLUE}2. Ping IP${NC}"
    echo -e "${BLUE}3. Check IP${NC}"
    if is_key_valid; then
        echo -e "${BLUE}4. Advanced Menu${NC}"
    fi
    echo -e "${BLUE}5. User Info${NC}"
    echo -e "${BLUE}6. Back to Main Menu${NC}"
    echo
}

# Function to check key validity
is_key_valid() {
    if [ -f "$KEY_FILE" ]; then
        local key=$(cat "$KEY_FILE")
        local response=$(curl -s -X POST -d "key=$key" "$API_URL")
        if echo "$response" | jq -e '.valid == true' > /dev/null 2>&1; then
            return 0  # Valid key
        else
            return 1  # Invalid key
        fi
    fi
    return 1  # Invalid or non-existent key
}

# Function to input key
input_key() {
    show_header
    read -p "Enter your key: " key
    if [[ -z "$key" ]]; then
        echo -e "${RED}Key cannot be empty. Please try again.${NC}"
        return
    fi
    echo "$key" > "$KEY_FILE"
    echo -e "${YELLOW}Checking key...${NC}"
    sleep 2  # Simulate checking process
    if is_key_valid; then
        echo -e "${GREEN}Valid key. You now have access to advanced features.${NC}"
        update_user_info
    else
        echo -e "${RED}Invalid key. Please try again.${NC}"
        rm -f "$KEY_FILE"
    fi
    sleep 2
}

# Function to update user info
update_user_info() {
    if [ -f "$KEY_FILE" ]; then
        local key=$(cat "$KEY_FILE")
        local response=$(curl -s -X GET "$API_URL?action=get_user_info&key=$key")
        echo "$response" > "$USER_INFO_FILE"
        echo -e "${GREEN}User information updated.${NC}"
    else
        echo -e "${RED}Key not found. Please enter a key first.${NC}"
    fi
}

# Function to display user info
show_user_info() {
    show_header
    if [ -f "$USER_INFO_FILE" ]; then
        echo -e "${YELLOW}User Information:${NC}"
        cat "$USER_INFO_FILE"
    else
        echo -e "${RED}No user information available. Please update.${NC}"
    fi
}

# Function to handle submenu
handle_submenu() {
    while true; do
        show_header
        show_submenu
        local choice
        read -p "Enter your choice: " choice
        case $choice in
            1) show_system_info ;;
            2) ping_ip ;;
            3) check_ip ;;
            4) 
                if is_key_valid; then
                    advanced_menu
                else
                    echo -e "${RED}You need a valid key to access the advanced menu.${NC}"
                    input_key
                fi
                ;;
            5) show_user_info ;;
            6) return ;;
            *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Function to display system info
show_system_info() {
    show_header
    echo -e "${YELLOW}System Information:${NC}"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Hostname: $(hostname)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -f 2 -d ":")"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk Usage: $(df -h / | awk '/\// {print $(NF-1)}')"
}

# Function to ping IP
ping_ip() {
    show_header
    read -p "Enter IP address to ping: " ip
    ping -c 4 $ip
}

# Function to check IP
check_ip() {
    show_header
    echo "Your IP address is: $(curl -s ifconfig.me)"
}

# Function for advanced menu (only shown with valid key)
advanced_menu() {
    show_header
    echo -e "${CYAN}Advanced Menu:${NC}"
    echo -e "${BLUE}1. Port Scan${NC}"
    echo -e "${BLUE}2. Network Traffic Analysis${NC}"
    echo -e "${BLUE}3. Back${NC}"
    
    local choice
    read -p "Enter your choice: " choice
    case $choice in
        1) port_scan ;;
        2) network_analysis ;;
        3) return ;;
        *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
    esac
}

# Function for port scanning
port_scan() {
    show_header
    read -p "Enter IP address to scan: " ip
    nmap $ip
}

# Function for network traffic analysis
network_analysis() {
    show_header
    echo "Analyzing network traffic..."
    # Add network traffic analysis logic here
    echo "This feature is currently under development."
}

# Function to run in background for automatic update checks
auto_update_check() {
    while true; do
        sleep 3600  # Check every hour
        check_update
    done
}

# Main function
main() {
    show_warning
    check_and_install_packages
    check_update
    
    # Run auto_update_check in background
    auto_update_check &
    
    while true; do
        show_header
        show_main_menu
        local choice
        read -p "Enter your choice: " choice
        case $choice in
            1) handle_submenu ;;
            2) input_key ;;
            3) echo -e "${GREEN}Thank you for using the script. Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Run main function
main
