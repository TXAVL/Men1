#!/bin/bash
# ==============================================================================
# TXA STUDIO - MENU 1 (TEST & DEMO SUITE)
# Script Menu độc lập có cơ chế tự kiểm tra cập nhật qua GitHub Pages
# ==============================================================================

# Đường dẫn đến file chứa phiên bản hiện tại của menu 1
VERSION_FILE="$HOME/.txa_version1"

# URL tải script trực tiếp từ GitHub Pages
SCRIPT_URL="https://txavl.github.io/Men1/menu1.sh"

# Phiên bản hiện tại của script menu 1
VERSION="1.0.1"

# Màu sắc cho thông báo
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Không màu

# Hàm so sánh phiên bản (Semantic Versioning)
version_greater() {
    local ver1=(${1//./ })
    local ver2=(${2//./ })
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ ${ver1[i]} -gt ${ver2[i]:-0} ]]; then
            return 0
        elif [[ ${ver1[i]} -lt ${ver2[i]:-0} ]]; then
            return 1
        fi
    done
    return 1
}

# Hàm kiểm tra cập nhật từ GitHub Pages (txavl.github.io/Men1/menu1.sh)
check_update() {
    echo -e "${YELLOW}Đang kiểm tra cập nhật...${NC}"
    local temp_file=$(mktemp)
    
    # Kiểm tra nếu đã có tệp phiên bản
    if [ -f "$VERSION_FILE" ]; then
        local current_version=$(cat "$VERSION_FILE")
    else
        local current_version="$VERSION"
    fi
    
    # Tải script mới về tệp tạm thời
    if curl -s "$SCRIPT_URL" -o "$temp_file"; then
        local latest_version=$(grep "^VERSION=" "$temp_file" | head -n1 | cut -d'"' -f2)
        
        # Kiểm tra nếu không thể tìm thấy phiên bản mới
        if [[ -z "$latest_version" ]]; then
            echo -e "${RED}Không thể xác định phiên bản mới từ server.${NC}"
            rm -f "$temp_file"
            return
        fi
        
        # So sánh phiên bản hiện tại và phiên bản mới
        if version_greater "$latest_version" "$current_version"; then
            echo -e "${GREEN}Có phiên bản mới: $latest_version (Hiện tại: $current_version)${NC}"
            read -p "Bạn có muốn cập nhật không? (y/n): " choice
            if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                mv "$temp_file" "$0"
                chmod +x "$0"
                echo "$latest_version" > "$VERSION_FILE"
                echo -e "${GREEN}Đã cập nhật script menu 1. Vui lòng chạy lại.${NC}"
                exit 0
            fi
        else
            echo -e "${GREEN}Bạn đang sử dụng phiên bản mới nhất (v${current_version}).${NC}"
        fi
    else
        echo -e "${RED}Không thể kiểm tra cập nhật. Vui lòng thử lại sau.${NC}"
    fi
    rm -f "$temp_file"
}

# Menu chức năng riêng của Menu 1
show_menu1() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${YELLOW}         TXA TEST & DEMO MENU (MENU 1)                ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}         GitHub: txavl.github.io/Men1/menu1.sh        ${CYAN}║${NC}"
    echo -e "${CYAN}║${BLUE}         Version: v${VERSION}                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}1.${NC} Kiểm tra cập nhật Menu 1 từ GitHub Pages"
    echo -e "${BLUE}2.${NC} Kiểm tra trạng thái thiết bị nhanh (Fast Diagnostic)"
    echo -e "${BLUE}3.${NC} Kiểm tra kết nối Internet & Tốc độ Ping"
    echo -e "${BLUE}4.${NC} Chuyển sang Menu Chính (menu.sh)"
    echo -e "${BLUE}5.${NC} Thoát"
    echo
}

# Hàm chính để chạy script menu 1
main() {
    echo -e "${GREEN}Khởi động Menu 1 v${VERSION}...${NC}"
    
    # Kiểm tra cập nhật khi khởi động
    check_update

    while true; do
        show_menu1
        read -p "Nhập lựa chọn của bạn [1-5]: " choice
        case $choice in
            1)
                check_update
                ;;
            2)
                echo -e "${YELLOW}Thông số nhanh:${NC}"
                echo "• Kernel: $(uname -r)"
                echo "• Kiến trúc: $(uname -m)"
                echo "• Uptime: $(uptime -p 2>/dev/null || uptime)"
                ;;
            3)
                echo -e "${YELLOW}Ping kiểm tra kết nối:${NC}"
                ping -c 3 1.1.1.1
                ;;
            4)
                script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                if [ -f "$script_dir/menu.sh" ]; then
                    bash "$script_dir/menu.sh"
                    exit 0
                else
                    echo -e "${RED}Không tìm thấy menu.sh trong cùng thư mục!${NC}"
                fi
                ;;
            5)
                echo -e "${GREEN}Đã thoát Menu 1.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Lựa chọn không hợp lệ!${NC}"
                ;;
        esac
        echo
        read -p "Nhấn Enter để tiếp tục..."
    done
}

# Chạy hàm chính
main
