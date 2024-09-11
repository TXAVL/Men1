#!/bin/bash

VERSION="1.0.0"
SCRIPT_URL="https://txavl.github.io/Men1/menu.sh"

# Định nghĩa các mã màu ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Hàm kiểm tra cập nhật
check_update() {
    echo -e "${YELLOW}Đang kiểm tra cập nhật...${NC}"
    local latest_version=$(curl -s "$SCRIPT_URL" | grep "VERSION=" | cut -d'"' -f2)
    if [[ "$latest_version" > "$VERSION" ]]; then
        echo -e "${GREEN}Có phiên bản mới: $latest_version${NC}"
        read -p "Bạn có muốn cập nhật không? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            curl -L "$SCRIPT_URL" -o "$0"
            echo -e "${GREEN}Đã cập nhật script. Vui lòng chạy lại.${NC}"
            exit 0
        fi
    else
        echo -e "${GREEN}Bạn đang sử dụng phiên bản mới nhất.${NC}"
    fi
}

# Hàm hiển thị tiêu đề
show_header() {
    clear
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${YELLOW}           TXA Advanced Script         ${RED}║${NC}"
    echo -e "${RED}║${GREEN}        Copyright © 2024 TXA           ${RED}║${NC}"
    echo -e "${RED}║${BLUE}           Version: $VERSION            ${RED}║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo
}

# Hàm hiển thị menu chính
show_main_menu() {
    echo -e "${CYAN}Menu Chính:${NC}"
    echo -e "${BLUE}1. Thông tin hệ thống${NC}"
    echo -e "${BLUE}2. Công cụ mạng${NC}"
    echo -e "${BLUE}3. Quản lý tệp tin${NC}"
    echo -e "${BLUE}4. Kiểm tra cập nhật${NC}"
    echo -e "${BLUE}5. Thoát${NC}"
    echo
}

# Hàm hiển thị menu con cho công cụ mạng
show_network_menu() {
    echo -e "${CYAN}Menu Công cụ Mạng:${NC}"
    echo -e "${BLUE}1. Kiểm tra kết nối mạng${NC}"
    echo -e "${BLUE}2. Hiển thị địa chỉ IP${NC}"
    echo -e "${BLUE}3. Quét cổng${NC}"
    echo -e "${BLUE}4. Quay lại menu chính${NC}"
    echo
}

# Hàm hiển thị menu con cho quản lý tệp tin
show_file_menu() {
    echo -e "${CYAN}Menu Quản lý Tệp tin:${NC}"
    echo -e "${BLUE}1. Liệt kê tệp tin${NC}"
    echo -e "${BLUE}2. Tạo thư mục mới${NC}"
    echo -e "${BLUE}3. Xóa tệp tin/thư mục${NC}"
    echo -e "${BLUE}4. Quay lại menu chính${NC}"
    echo
}

# Hàm xử lý menu chính
handle_main_menu() {
    local choice
    read -p "Nhập lựa chọn của bạn: " choice
    case $choice in
        1) show_system_info ;;
        2) network_menu ;;
        3) file_menu ;;
        4) check_update ;;
        5) echo -e "${GREEN}Cảm ơn bạn đã sử dụng script. Tạm biệt!${NC}"; exit 0 ;;
        *) echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}" ;;
    esac
}

# Hàm xử lý menu công cụ mạng
network_menu() {
    while true; do
        show_header
        show_network_menu
        local choice
        read -p "Nhập lựa chọn của bạn: " choice
        case $choice in
            1) ping -c 4 google.com ;;
            2) curl ifconfig.me ;;
            3) read -p "Nhập địa chỉ IP để quét: " ip
               nmap $ip ;;
            4) return ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}" ;;
        esac
        read -p "Nhấn Enter để tiếp tục..."
    done
}

# Hàm xử lý menu quản lý tệp tin
file_menu() {
    while true; do
        show_header
        show_file_menu
        local choice
        read -p "Nhập lựa chọn của bạn: " choice
        case $choice in
            1) ls -la ;;
            2) read -p "Nhập tên thư mục mới: " dirname
               mkdir -p $dirname ;;
            3) read -p "Nhập tên tệp tin/thư mục cần xóa: " filename
               rm -ri $filename ;;
            4) return ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}" ;;
        esac
        read -p "Nhấn Enter để tiếp tục..."
    done
}

# Hàm hiển thị thông tin hệ thống
show_system_info() {
    echo -e "${YELLOW}Thông tin hệ thống:${NC}"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Hostname: $(hostname)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -f 2 -d ":")"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk Usage: $(df -h / | awk '/\// {print $(NF-1)}')"
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm chính
main() {
    check_update
    while true; do
        show_header
        show_main_menu
        handle_main_menu
    done
}

# Chạy hàm chính
main
