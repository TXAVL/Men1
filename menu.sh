#!/bin/bash

# Định nghĩa các mã màu ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Hàm hiển thị tiêu đề
show_header() {
    clear
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${YELLOW}           TXA Basic Script            ${RED}║${NC}"
    echo -e "${RED}║${GREEN}        Copyright © 2024 TXA           ${RED}║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo
}

# Hàm hiển thị menu
show_menu() {
    echo -e "${CYAN}Chọn một tùy chọn:${NC}"
    echo -e "${BLUE}1. Hiển thị thông tin hệ thống${NC}"
    echo -e "${BLUE}2. Kiểm tra kết nối mạng${NC}"
    echo -e "${BLUE}3. Hiển thị ngày giờ hiện tại${NC}"
    echo -e "${BLUE}4. Thoát${NC}"
    echo
}

# Hàm xử lý lựa chọn của người dùng
handle_choice() {
    local choice=$1
    case $choice in
        1)
            echo -e "${YELLOW}Thông tin hệ thống:${NC}"
            uname -a
            ;;
        2)
            echo -e "${YELLOW}Kiểm tra kết nối mạng:${NC}"
            ping -c 4 google.com
            ;;
        3)
            echo -e "${YELLOW}Ngày giờ hiện tại:${NC}"
            date
            ;;
        4)
            echo -e "${GREEN}Cảm ơn bạn đã sử dụng script. Tạm biệt!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}"
            ;;
    esac
    echo
    read -p "Nhấn Enter để tiếp tục..."
}

# Vòng lặp chính của script
while true; do
    show_header
    show_menu
    read -p "Nhập lựa chọn của bạn: " choice
    handle_choice $choice
done
