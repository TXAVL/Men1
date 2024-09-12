#!/data/data/com.termux/files/usr/bin/bash

# Định nghĩa màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Thông tin script
SCRIPT_VERSION="1.7"
CURRENT_YEAR=$(date +"%Y")
VERSION_API="https://key.txavideo.online/version.php"

# Hàm kiểm tra yêu cầu hệ thống
check_system_requirements() {
    echo -e "${BLUE}Đang kiểm tra yêu cầu hệ thống...${NC}"
    
    # Kiểm tra RAM
    check_ram

    # Kiểm tra dung lượng trống
    check_free_space

    # Kiểm tra kiến trúc CPU
    check_cpu_architecture

    # Kiểm tra phiên bản Android
    check_android_version

    # Kiểm tra phiên bản Termux
    check_termux_version

    echo -e "${GREEN}Thiết bị của bạn đáp ứng tất cả yêu cầu hệ thống.${NC}"
    return 0
}

check_ram() {
    total_ram=$(free -b | awk '/^Mem:/{print $2}')
    if [ -z "$total_ram" ]; then
        echo -e "${RED}Lỗi: Không thể xác định dung lượng RAM.${NC}"
        exit 1
    fi
    total_ram_gb=$(awk "BEGIN {printf \"%.2f\", $total_ram/1024/1024/1024}")
    if (( $(echo "$total_ram_gb < 1" | bc -l) )); then
        echo -e "${RED}Lỗi: Thiết bị cần tối thiểu 1GB RAM. Hiện tại: ${total_ram_gb}GB${NC}"
        exit 1
    fi
}

check_free_space() {
    free_space=$(df -k $HOME | awk 'NR==2 {print $4}')
    if [ -z "$free_space" ]; then
        echo -e "${RED}Lỗi: Không thể xác định dung lượng trống.${NC}"
        exit 1
    fi
    free_space_gb=$(awk "BEGIN {printf \"%.2f\", $free_space/1024/1024}")
    if (( $(echo "$free_space_gb < 3" | bc -l) )); then
        echo -e "${RED}Lỗi: Cần tối thiểu 3GB dung lượng trống. Hiện tại: ${free_space_gb}GB${NC}"
        exit 1
    fi
}

check_cpu_architecture() {
    arch=$(uname -m)
    if [ -z "$arch" ]; then
        echo -e "${RED}Lỗi: Không thể xác định kiến trúc CPU.${NC}"
        exit 1
    fi
    if [[ $arch != *"64"* ]]; then
        echo -e "${RED}Lỗi: Yêu cầu CPU 64-bit. Hiện tại: $arch${NC}"
        exit 1
    fi
}

check_android_version() {
    android_version=$(getprop ro.build.version.release)
    if [ -z "$android_version" ]; then
        echo -e "${YELLOW}Cảnh báo: Không thể xác định phiên bản Android.${NC}"
        return
    fi
    if [ $(echo $android_version | cut -d. -f1) -lt 11 ]; then
        echo -e "${RED}Lỗi: Yêu cầu Android 11 trở lên. Hiện tại: Android $android_version${NC}"
        exit 1
    fi
}

check_termux_version() {
    termux_version=$(pkg list-installed | grep '^termux-tools' | awk -F' ' '{print $2}')
    if [ -z "$termux_version" ]; then
        echo -e "${YELLOW}Cảnh báo: Không thể xác định phiên bản Termux.${NC}"
        return
    fi
    required_version="0.134"  # Tương đương với 2024.08.29-134
    if [[ "$(printf '%s\n' "$required_version" "$termux_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo -e "${RED}Lỗi: Yêu cầu Termux phiên bản $required_version trở lên. Hiện tại: $termux_version${NC}"
        exit 1
    fi
}

show_banner() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${YELLOW}    TXA VLOG Server Script    ${NC}"
    echo -e "${CYAN}        Version $SCRIPT_VERSION        ${NC}"
    echo -e "${CYAN}================================${NC}"
}

show_menu() {
    echo -e "${GREEN}1. Kiểm tra yêu cầu hệ thống${NC}"
    echo -e "${GREEN}2. Kiểm tra cập nhật${NC}"
    echo -e "${GREEN}3. Cài đặt gói${NC}"
    echo -e "${GREEN}4. Chạy server${NC}"
    echo -e "${GREEN}5. Xem changelog${NC}"
    echo -e "${GREEN}6. Thoát${NC}"
    echo -e "${YELLOW}Nhập lựa chọn của bạn: ${NC}"
}

check_update() {
    clear
    show_banner
    echo -e "${BLUE}Đang kiểm tra cập nhật...${NC}"
    latest_version=$(curl -s $VERSION_API)
    if [ -z "$latest_version" ]; then
        echo -e "${RED}Lỗi: Không thể kiểm tra phiên bản mới nhất.${NC}"
        return
    fi
    if [ "$latest_version" != "$SCRIPT_VERSION" ]; then
        echo -e "${YELLOW}Có phiên bản mới: $latest_version${NC}"
        echo -e "${YELLOW}Phiên bản hiện tại của bạn: $SCRIPT_VERSION${NC}"
        echo -e "${YELLOW}Vui lòng cập nhật để có những tính năng mới nhất.${NC}"
    else
        echo -e "${GREEN}Bạn đang sử dụng phiên bản mới nhất.${NC}"
    fi
}

install_packages() {
    clear
    show_banner
    echo -e "${BLUE}Đang cài đặt các gói cần thiết...${NC}"
    pkg update -y -q
    pkg install -y -q python nodejs ffmpeg
    pip install -q yt-dlp
    npm install -g localtunnel
    echo -e "${GREEN}Cài đặt gói hoàn tất.${NC}"
}

run_server() {
    echo -e "${BLUE}Đang chạy server...${NC}"
    # Thêm lệnh để chạy server của bạn ở đây
    echo -e "${GREEN}Server đang chạy.${NC}"
}

view_changelog() {
    echo -e "${CYAN}Changelog:${NC}"
    echo -e "Version 1.7:"
    echo -e "- Cải thiện quá trình cài đặt gói để giảm cảnh báo"
    echo -e "Version 1.6:"
    echo -e "- Cải thiện kiểm tra yêu cầu hệ thống"
    echo -e "- Thêm hàm show_banner và show_menu"
    echo -e "- Sửa lỗi kiểm tra phiên bản Android"
    echo -e "- Cập nhật cách kiểm tra RAM và dung lượng trống"
    # Thêm thông tin changelog cho các phiên bản trước đó nếu cần
}

# Chương trình chính
main() {
    clear
    while true; do
        show_banner
        show_menu
        read choice
        case $choice in
            1) check_system_requirements ;;
            2) check_update ;;
            3) install_packages ;;
            4) run_server ;;
            5) view_changelog ;;
            6) echo -e "${YELLOW}Cảm ơn bạn đã sử dụng TXA VLOG Server Script!${NC}"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}" ;;
        esac
        echo
        read -p "Nhấn Enter để tiếp tục..."
    done
}

# Chạy chương trình chính
if check_system_requirements; then
    main
else
    echo -e "${RED}Thiết bị của bạn không đáp ứng yêu cầu hệ thống. Vui lòng kiểm tra và thử lại.${NC}"
    exit 1
fi
