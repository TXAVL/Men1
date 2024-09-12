#!/bin/bash

VERSION="1.1.7"
SCRIPT_URL="https://txavl.github.io/Men1/menu.sh"
KEY_FILE="$HOME/.txa_key"
API_URL="https://key.txavideo.online/api/validate_key.php"
USER_INFO_FILE="$HOME/.txa_user_info"
VERSION_FILE="$HOME/.txa_version"
WARNING_ACCEPTED_FILE="$HOME/.txa_warning_accepted"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ... (các hàm khác giữ nguyên)

# Function to display warning and request confirmation
show_warning() {
    if [ -f "$WARNING_ACCEPTED_FILE" ]; then
        return 0  # Warning already accepted, proceed
    fi
    
    while true; do
        show_header
        echo -e "${RED}WARNING:${NC}"
        echo -e "${YELLOW}After installing v$VERSION, all Termux permissions and features will belong to TxaServer.${NC}"
        echo -e "${YELLOW}If you want to revert to the original state, please reinstall Termux.${NC}"
        echo
        echo -e "${CYAN}1. Accept and continue${NC}"
        echo -e "${CYAN}2. Decline and exit${NC}"
        echo
        read -p "Enter your choice (1 or 2): " choice
        case $choice in
            1)
                touch "$WARNING_ACCEPTED_FILE"
                echo -e "${GREEN}Warning accepted. Proceeding with the script.${NC}"
                sleep 2
                return 0
                ;;
            2)
                echo -e "${RED}Installation cancelled. Exiting...${NC}"
                sleep 2
                exit 1
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Main function
main() {
    check_and_install_packages
    check_update
    show_warning  # Chỉ hiển thị cảnh báo một lần
    
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
