#!/bin/bash

VERSION="1.1.5"
SCRIPT_URL="https://txavl.github.io/Men1/menu.sh"
KEY_FILE="$HOME/.txa_key"
API_URL="https://key.txavideo.online/api/validate_key.php"
USER_INFO_FILE="$HOME/.txa_user_info"
VERSION_FILE="$HOME/.txa_version"

# Định nghĩa các mã màu ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Danh sách các gói cần thiết
REQUIRED_PACKAGES="curl nmap jq"

# Hàm kiểm tra và cài đặt các gói cần thiết
check_and_install_packages() {
    echo -e "${YELLOW}Đang kiểm tra các gói cần thiết...${NC}"
    for package in $REQUIRED_PACKAGES; do
        if ! command -v $package &> /dev/null; then
            echo -e "${RED}$package chưa được cài đặt. Đang cài đặt...${NC}"
            pkg install -y $package
        else
            echo -e "${GREEN}$package đã được cài đặt.${NC}"
        fi
    done
    echo -e "${GREEN}Tất cả các gói cần thiết đã được cài đặt.${NC}"
}

# Hàm so sánh phiên bản
compare_versions() {
    local ver1=$1
    local ver2=$2
    if [[ "$ver1" == "$ver2" ]]; then
        return 0  # bằng nhau
    elif [[ "$(printf '%s\n' "$ver1" "$ver2" | sort -V | head -n1)" == "$ver1" ]]; then
        return 1  # ver1 nhỏ hơn ver2
    else
        return 2  # ver1 lớn hơn ver2
    fi
}

# Hàm kiểm tra cập nhật
check_update() {
    echo -e "${YELLOW}Đang kiểm tra cập nhật...${NC}"
    local temp_file=$(mktemp)
    
    # Kiểm tra nếu đã có tệp phiên bản
    if [ -f "$VERSION_FILE" ]; then
        local current_version=$(cat "$VERSION_FILE")
    else
        local current_version="0.0.0"
    fi
    
    if curl -s "$SCRIPT_URL" -o "$temp_file"; then
        local latest_version=$(grep "^VERSION=" "$temp_file" | cut -d'"' -f2)
        if [[ -z "$latest_version" ]]; then
            echo -e "${RED}Không thể xác định phiên bản mới từ server.${NC}"
            rm -f "$temp_file"
            return
        fi
        
        # So sánh phiên bản chính xác
        compare_versions "$current_version" "$latest_version"
        case $? in
            1)
                echo -e "${GREEN}Có phiên bản mới: $latest_version${NC}"
                read -p "Bạn có muốn cập nhật không? (y/n): " choice
                if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                    mv "$temp_file" "$0"
                    chmod +x "$0"
                    echo "$latest_version" > "$VERSION_FILE"
                    echo -e "${GREEN}Đã cập nhật script. Vui lòng chạy lại.${NC}"
                    exit 0
                fi
                ;;
            2)
                echo -e "${GREEN}Bạn đang sử dụng phiên bản mới nhất.${NC}"
                ;;
            *)
                echo -e "${RED}Có lỗi khi so sánh phiên bản.${NC}"
                ;;
        esac
    else
        echo -e "${RED}Không thể kiểm tra cập nhật. Vui lòng thử lại sau.${NC}"
    fi
    rm -f "$temp_file"
}
# Hàm hiển thị tiêu đề
show_header() {
    clear
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${YELLOW}           TXA Advanced Script         ${RED}║${NC}"
    echo -e "${RED}║${GREEN}        Copyright © 2024 TXA            ${RED}║${NC}"
    echo -e "${RED}║${BLUE}           Version: $VERSION             ${RED}║${NC}"
    echo -e "${RED}╚═════════════════════════════════════════╝${NC}"
    echo
}

# Hàm thông báo quyền hạn và yêu cầu xác nhận
show_warning() {
    echo -e "${RED}Sau khi cài đặt, mọi quyền hạn và tính năng của Termux sẽ thuộc về TxaServer.${NC}"
    echo -e "${RED}Nếu bạn muốn quay về ban đầu, hãy cài đặt lại Termux.${NC}"
    echo
    read -p "Bạn có muốn tiếp tục? [Y/N]: " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo -e "${RED}Cài đặt đã bị hủy.${NC}"
        exit 1
    fi
}

# Hàm hiển thị menu chính
show_main_menu() {
    echo -e "${CYAN}Menu Chính:${NC}"
    echo -e "${BLUE}1. Open Menu${NC}"
    echo -e "${BLUE}2. Nhập Key${NC}"
    echo -e "${BLUE}3. Exit${NC}"
    echo
}

# Hàm hiển thị submenu
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

# Hàm kiểm tra key
is_key_valid() {
    if [ -f "$KEY_FILE" ]; then
        local key=$(cat "$KEY_FILE")
        local response=$(curl -s -X POST -d "key=$key" "$API_URL")
        # Kiểm tra phản hồi từ API
        if echo "$response" | jq -e '.valid == true' > /dev/null 2>&1; then
            return 0  # Key hợp lệ
        else
            return 1  # Key không hợp lệ
        fi
    fi
    return 1  # Key không hợp lệ hoặc không tồn tại
}

# Hàm nhập key
input_key() {
    clear
    show_header
    read -p "Nhập key của bạn: " key
    if [[ -z "$key" ]]; then
        echo -e "${RED}Key không được để trống. Vui lòng thử lại.${NC}"
        return
    fi
    echo "$key" > "$KEY_FILE"
    if is_key_valid; then
        echo -e "${GREEN}Key hợp lệ. Bạn đã có quyền truy cập vào các tính năng nâng cao.${NC}"
        update_user_info
    else
        echo -e "${RED}Key không hợp lệ. Vui lòng thử lại.${NC}"
        rm -f "$KEY_FILE"
    fi
}

# Hàm cập nhật thông tin người dùng
update_user_info() {
    if [ -f "$KEY_FILE" ]; then
        local key=$(cat "$KEY_FILE")
        local response=$(curl -s -X GET "$API_URL?action=get_user_info&key=$key")
        echo "$response" > "$USER_INFO_FILE"
        echo -e "${GREEN}Thông tin người dùng đã được cập nhật.${NC}"
    else
        echo -e "${RED}Không tìm thấy key. Vui lòng nhập key trước.${NC}"
    fi
}

# Hàm hiển thị thông tin người dùng
show_user_info() {
    clear
    show_header
    if [ -f "$USER_INFO_FILE" ]; then
        echo -e "${YELLOW}Thông tin người dùng:${NC}"
        cat "$USER_INFO_FILE"
    else
        echo -e "${RED}Không có thông tin người dùng. Vui lòng cập nhật.${NC}"
    fi
}

# Hàm xử lý submenu
handle_submenu() {
    while true; do
        show_header
        show_submenu
        local choice
        read -p "Nhập lựa chọn của bạn: " choice
        case $choice in
            1) show_system_info ;;
            2) ping_ip ;;
            3) check_ip ;;
            4) 
                if is_key_valid; then
                    advanced_menu
                else
                    echo -e "${RED}Bạn cần nhập key hợp lệ để truy cập menu nâng cao.${NC}"
                    input_key
                fi
                ;;
            5) show_user_info ;;
            6) return ;;
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
}

# Hàm ping IP
ping_ip() {
    read -p "Nhập địa chỉ IP để ping: " ip
    ping -c 4 $ip
}

# Hàm kiểm tra IP
check_ip() {
    echo "Địa chỉ IP của bạn là: $(curl -s ifconfig.me)"
}

# Hàm menu nâng cao (chỉ hiển thị khi có key hợp lệ)
advanced_menu() {
    echo -e "${CYAN}Menu Nâng Cao:${NC}"
    echo -e "${BLUE}1. Quét cổng${NC}"
    echo -e "${BLUE}2. Phân tích lưu lượng mạng${NC}"
    echo -e "${BLUE}3. Quay lại${NC}"
    
    local choice
    read -p "Nhập lựa chọn của bạn: " choice
    case $choice in
        1) port_scan ;;
        2) network_analysis ;;
        3) return ;;
        *) echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}" ;;
    esac
}

# Hàm quét cổng
port_scan() {
    read -p "Nhập địa chỉ IP để quét cổng: " ip
    nmap $ip
}

# Hàm phân tích lưu lượng mạng
network_analysis() {
    echo "Đang phân tích lưu lượng mạng..."
    # Thêm logic phân tích lưu lượng mạng ở đây
    echo "Chức năng này đang được phát triển."
}

# Hàm chạy trong nền để tự động kiểm tra cập nhật
auto_update_check() {
    while true; do
        sleep 300  # Kiểm tra mỗi giờ
        check_update
    done
}

# Hàm chính
main() {
show_warning
    check_and_install_packages
    check_update
    
    # Chạy auto_update_check trong nền
    auto_update_check &
    
    while true; do
        show_header
        show_main_menu
        local choice
        read -p "Nhập lựa chọn của bạn: " choice
        case $choice in
            1) handle_submenu ;;
            2) input_key ;;
            3) echo -e "${GREEN}Cảm ơn bạn đã sử dụng script. Tạm biệt!${NC}"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}" ;;
        esac
        read -p "Nhấn Enter để tiếp tục..."
    done
}

# Chạy hàm chính
main
