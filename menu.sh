#!/bin/bash
# ==============================================================================
# TXA ADVANCED SCRIPT (MENU CHÍNH - v3.0)
# Tích hợp API Xác thực Key trên txastudio.click & Cloudflare Tunnel cho Termux Hub
# Bản quyền © 2026 TXA Studio (txastudio.click)
# ==============================================================================

VERSION="3.0.0"
SCRIPT_URL="https://txavl.github.io/Men1/menu.sh"
DOMAIN_TARGET="txastudio.click"
# API xác thực bản quyền đặt trên Vercel / server riêng
API_URL="https://txastudio.click/api/validate_key"
API_URL_ALT="https://api.txastudio.click/api/validate_key.php"

HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
KEY_FILE="$HOME_DIR/.txa_key"
USER_INFO_FILE="$HOME_DIR/.txa_user_info"
VERSION_FILE="$HOME_DIR/.txa_version"
TUNNEL_URL_FILE="$HOME_DIR/.txa_tunnel.url"
DOWNLOAD_DIR="$HOME_DIR/shared/downloads"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

REQUIRED_PACKAGES="curl nmap jq termux-api nodejs"

# Kiểm tra Master Key nội bộ
validate_key() {
    local k="$1"
    [[ "$k" == "TXA-MASTER-STUDIO-CLICK-2026" || "$k" == "TXA-VIP-TXASTUDIO-CLICK" ]]
}

mkdir -p "$DOWNLOAD_DIR"

check_storage_permission() {
    if [ ! -d "$HOME_DIR/storage" ] && command -v termux-setup-storage &>/dev/null; then
        echo -e "${YELLOW}Đang yêu cầu quyền truy cập bộ nhớ ngoài (Storage)...${NC}"
        echo -e "${CYAN}Vui lòng bấm 'Cho phép' (Allow) trên thông báo pop-up của Android!${NC}"
        termux-setup-storage 2>/dev/null
        sleep 2
    fi
}

check_and_install_packages() {
    check_storage_permission
    for package in $REQUIRED_PACKAGES; do
        if ! command -v $package &> /dev/null; then
            echo -e "${YELLOW}Cài đặt gói thiếu: $package...${NC}"
            pkg install -y $package 2>/dev/null || true
        fi
    done
}

# So sánh phiên bản và cập nhật từ GitHub Pages
compare_versions() {
    local ver1=$1
    local ver2=$2
    if [[ "$ver1" == "$ver2" ]]; then
        return 0
    elif [[ "$(printf '%s\n' "$ver1" "$ver2" | sort -V | head -n1)" == "$ver1" ]]; then
        return 1
    else
        return 2
    fi
}

check_update() {
    local silent=${1:-false}
    if [ "$silent" = false ]; then
        echo -e "${YELLOW}Kiểm tra cập nhật Menu chính từ GitHub Pages (${SCRIPT_URL})...${NC}"
    fi
    local temp_file=$(mktemp)

    local current_version="$VERSION"
    [ -f "$VERSION_FILE" ] && current_version=$(cat "$VERSION_FILE")

    if curl -s "$SCRIPT_URL" -o "$temp_file"; then
        local latest_version=$(grep "^VERSION=" "$temp_file" | head -n1 | cut -d'"' -f2)
        if [[ -n "$latest_version" ]]; then
            compare_versions "$current_version" "$latest_version"
            if [ $? -eq 1 ]; then
                echo -e "${GREEN}Có phiên bản mới: $latest_version (Hiện tại: $current_version)${NC}"
                read -p "Cập nhật ngay? (y/n): " choice
                if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                    mv "$temp_file" "$0"
                    chmod +x "$0"
                    echo "$latest_version" > "$VERSION_FILE"
                    echo -e "${GREEN}Đã cập nhật script. Khởi động lại...${NC}"
                    exit 0
                fi
            elif [ "$silent" = false ]; then
                echo -e "${GREEN}Bạn đang ở phiên bản mới nhất (v${current_version}).${NC}"
            fi
        fi
    fi
    rm -f "$temp_file"
}

auto_update_check() {
    while true; do
        sleep 3600
        check_update true
    done
}

# Thu thập thông số thiết bị thật trên Android
get_device_telemetry() {
    D_BRAND=$(getprop ro.product.brand 2>/dev/null || getprop ro.product.manufacturer 2>/dev/null || echo "Android")
    D_MODEL=$(getprop ro.product.model 2>/dev/null || getprop ro.product.device 2>/dev/null || uname -n)
    D_ANDROID=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    D_ARCH=$(uname -m 2>/dev/null || echo "arm64")
    D_KERNEL=$(uname -r 2>/dev/null || echo "Unknown")
    D_BATTERY="N/A"
    if command -v termux-battery-status &>/dev/null; then
        D_BATTERY=$(termux-battery-status 2>/dev/null | grep -o '"percentage": [0-9]\+' | awk '{print $2}')
        [ -n "$D_BATTERY" ] && D_BATTERY="${D_BATTERY}%" || D_BATTERY="N/A"
    fi
}

# Xác thực Key qua API txastudio.click
is_key_valid() {
    [ ! -f "$KEY_FILE" ] && return 1
    local key=$(cat "$KEY_FILE" 2>/dev/null | tr -d ' \r\n')
    [ -z "$key" ] && return 1

    # 1. Master Keys
    if [[ "$key" == "TXA-MASTER-STUDIO-CLICK-2026" || "$key" == "TXA-VIP-TXASTUDIO-CLICK" ]]; then
        return 0
    fi

    # Lấy thông số thiết bị thật
    get_device_telemetry

    # 2. Gọi API máy chủ txastudio.click kèm thông số máy chi tiết
    local response=$(curl -s -m 5 -X POST \
        -H "Content-Type: application/json" \
        -H "X-Device-Brand: $D_BRAND" \
        -H "X-Device-Model: $D_MODEL" \
        -H "X-Device-Android: $D_ANDROID" \
        -H "X-Device-Arch: $D_ARCH" \
        -H "X-Device-Kernel: $D_KERNEL" \
        -H "X-Device-Battery: $D_BATTERY" \
        -d "{\"key\":\"$key\",\"device\":{\"brand\":\"$D_BRAND\",\"model\":\"$D_MODEL\",\"android\":\"$D_ANDROID\",\"arch\":\"$D_ARCH\",\"battery\":\"$D_BATTERY\"}}" \
        "$API_URL" 2>/dev/null)
    if echo "$response" | jq -e '.valid == true' > /dev/null 2>&1; then
        return 0
    fi
    
    # Thử qua endpoint dự phòng
    response=$(curl -s -m 4 -X POST \
        -H "X-Device-Brand: $D_BRAND" \
        -H "X-Device-Model: $D_MODEL" \
        -H "X-Device-Android: $D_ANDROID" \
        -H "X-Device-Battery: $D_BATTERY" \
        -d "key=$key" "$API_URL_ALT" 2>/dev/null)
    if echo "$response" | jq -e '.valid == true' > /dev/null 2>&1; then
        return 0
    fi

    # 3. Fallback Offline chữ ký số
    if validate_key "$key"; then
        return 0
    fi

    return 1
}

input_key() {
    echo -e "${CYAN}--- NHẬP KEY XÁC THỰC BẢN QUYỀN ---${NC}"
    echo -e "Mua Key VIP chính thức tại: ${YELLOW}https://txastudio.click/buy-key${NC}"
    echo -e "Key trải nghiệm: ${GREEN}TXA-VIP-TXASTUDIO-CLICK${NC}"
    echo
    read -p "Nhập key của bạn: " key
    key=$(echo "$key" | tr -d ' ')
    if [ -z "$key" ]; then
        echo -e "${RED}Key không được để trống!${NC}"
        return
    fi
    echo "$key" > "$KEY_FILE"
    
    echo -e "${YELLOW}Đang gửi yêu cầu xác minh tới txastudio.click...${NC}"
    if is_key_valid; then
        echo -e "${GREEN}✓ Key hợp lệ! Đã kích hoạt đầy đủ tính năng.${NC}"
        update_user_info
    else
        echo -e "${RED}✗ Key không hợp lệ! Vui lòng mua key chính thức tại: https://txastudio.click/buy-key${NC}"
        rm -f "$KEY_FILE"
    fi
}

update_user_info() {
    if [ -f "$KEY_FILE" ]; then
        local key=$(cat "$KEY_FILE" | tr -d ' \r\n')
        local response=$(curl -s -m 5 -X GET "$API_URL?action=get_user_info&key=$key" 2>/dev/null)
        if [ -n "$response" ] && echo "$response" | jq . >/dev/null 2>&1; then
            echo "$response" > "$USER_INFO_FILE"
        else
            echo "{\"status\":\"success\",\"user\":\"TXA VIP Member\",\"domain\":\"txastudio.click\",\"key\":\"$key\"}" > "$USER_INFO_FILE"
        fi
    fi
}

show_user_info() {
    echo -e "${CYAN}--- THÔNG TIN NGƯỜI DÙNG & BẢN QUYỀN ---${NC}"
    [ -f "$USER_INFO_FILE" ] && cat "$USER_INFO_FILE" | jq . 2>/dev/null || update_user_info
}

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${YELLOW}                   TXA ADVANCED CONTROL SYSTEM                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}               Bản quyền © 2026 TXA Studio (txastudio.click)          ${CYAN}║${NC}"
    echo -e "${CYAN}║${BLUE}            Version: v${VERSION}  •  GitHub Pages Auto-Update               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    local key_status="${RED}Chưa Kích Hoạt${NC}"
    is_key_valid && key_status="${GREEN}VIP (HỢP LỆ)${NC}"

    local t_status="${RED}CHƯA CHẠY${NC}"
    [ -f "$TUNNEL_URL_FILE" ] && t_status="${GREEN}$(cat "$TUNNEL_URL_FILE" | cut -c1-35)...${NC}"

    echo -e "Bản quyền: $key_status | Tunnel Script: $t_status"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────${NC}"
}

# Điều khiển phần cứng và tính năng nâng cao
advanced_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}⚡ MENU TÍNH NĂNG NÂNG CAO:${NC}"
        echo -e "${BLUE}1.${NC} 🔦 Đèn pin (Torch ON/OFF)"
        echo -e "${BLUE}2.${NC} 📳 Rung máy (Haptic Vibrate)"
        echo -e "${BLUE}3.${NC} 🗣️ Trợ lý đọc tiếng Việt (TTS Speak)"
        echo -e "${BLUE}4.${NC} 🔔 Bắn thông báo Push Android (Notification)"
        echo -e "${BLUE}5.${NC} 📸 Chụp ảnh camera ẩn"
        echo -e "${BLUE}6.${NC} 🔍 Quét cổng dịch vụ mạng (Nmap Scan)"
        echo -e "${BLUE}7.${NC} 📥 Tải video/nhạc YouTube, TikTok (yt-dlp)"
        echo -e "${BLUE}8.${NC} 💎 Mua Key VIP & Nâng Cấp Bản Quyền (txastudio.click/buy-key)"
        echo -e "${BLUE}0.${NC} Quay lại"
        echo
        read -p "Chọn [0-8]: " adv_c
        case $adv_c in
            1)
                echo "1. Bật đèn | 2. Tắt đèn"
                read -p "Chọn: " tc
                [ "$tc" == "1" ] && termux-torch on 2>/dev/null || termux-torch off 2>/dev/null
                ;;
            2) termux-vibrate -d 600 2>/dev/null && echo -e "${GREEN}✓ Đã rung máy!${NC}" ;;
            3)
                read -p "Nhập câu nói: " say_txt
                termux-tts-speak "${say_txt:-Xin chào từ TXA Studio}" 2>/dev/null
                ;;
            4)
                termux-notification -t "TXA Studio" -c "Máy chủ cục bộ đang hoạt động!" 2>/dev/null
                echo -e "${GREEN}✓ Đã gửi thông báo!${NC}"
                ;;
            5)
                local p_out="$DOWNLOAD_DIR/snap_$(date +%s).jpg"
                termux-camera-photo -c 0 "$p_out" 2>/dev/null && echo -e "${GREEN}✓ Đã lưu ảnh: $p_out${NC}"
                ;;
            6)
                read -p "IP/Domain quét cổng: " sip
                [ -n "$sip" ] && nmap -F "$sip"
                ;;
            7)
                read -p "URL video tải về: " vurl
                [ -n "$vurl" ] && yt-dlp -o "$DOWNLOAD_DIR/%(title).60s.%(ext)s" "$vurl"
                ;;
            8)
                echo -e "${CYAN}Trang mua Key VIP chính thức:${NC} ${YELLOW}https://txastudio.click/buy-key${NC}"
                termux-open-url "https://txastudio.click/buy-key" 2>/dev/null
                ;;
            0) return ;;
        esac
        read -p "Nhấn Enter để tiếp tục..."
    done
}

handle_submenu() {
    while true; do
        show_header
        echo -e "${CYAN}Danh Mục Tiện Ích:${NC}"
        echo -e "${BLUE}1.${NC} Thông tin hệ thống thiết bị"
        echo -e "${BLUE}2.${NC} Ping kiểm tra mạng"
        echo -e "${BLUE}3.${NC} Kiểm tra IP công khai (GeoIP)"
        echo -e "${BLUE}4.${NC} ⚡ Menu Nâng Cao (Yêu cầu Key)"
        echo -e "${BLUE}5.${NC} Thông tin người dùng & Bản quyền"
        echo -e "${BLUE}6.${NC} 🌐 Bật Cloudflare Tunnel cho Web Hub thiết bị"
        echo -e "${BLUE}7.${NC} ⬅️ Chuyển sang Menu 1 (menu1.sh demo)"
        echo -e "${BLUE}0.${NC} Quay lại"
        echo
        read -p "Chọn [0-7]: " sub_c
        case $sub_c in
            1)
                echo "OS: $(uname -s) | Kernel: $(uname -r) | Arch: $(uname -m)"
                echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
                if command -v termux-battery-status &>/dev/null; then
                    echo "Pin: $(termux-battery-status | grep -o '"percentage": [0-9]\+' | awk '{print $2}')%"
                fi
                ;;
            2) ping -c 3 1.1.1.1 ;;
            3) curl -s https://ipinfo.io/json | jq . 2>/dev/null || curl -s ifconfig.me ;;
            4)
                if is_key_valid; then
                    advanced_menu
                else
                    echo -e "${RED}Cần kích hoạt key trước để mở tính năng nâng cao!${NC}"
                    input_key
                fi
                ;;
            5) show_user_info ;;
            6) [ -f "$SCRIPT_DIR/tunnel.sh" ] && bash "$SCRIPT_DIR/tunnel.sh" ;;
            7) [ -f "$SCRIPT_DIR/menu1.sh" ] && bash "$SCRIPT_DIR/menu1.sh" && exit 0 ;;
            0) return ;;
        esac
        read -p "Nhấn Enter để tiếp tục..."
    done
}

main() {
    check_and_install_packages
    check_update false
    auto_update_check &

    [ ! -f "$KEY_FILE" ] && echo "TXA-MASTER-STUDIO-CLICK-2026" > "$KEY_FILE"

    while true; do
        show_header
        echo -e "${CYAN}MENU CHÍNH (TXA STUDIO):${NC}"
        echo -e "${BLUE}1.${NC} 📂 Mở Danh Mục Tiện Ích & Nâng Cao"
        echo -e "${BLUE}2.${NC} 🔑 Nhập Key Bản Quyền (Xác thực txastudio.click)"
        echo -e "${BLUE}3.${NC} 🌐 Quản Lý Cloudflare Tunnel Cho Script Cục Bộ"
        echo -e "${BLUE}4.${NC} 🚀 Khởi chạy Web Hub cục bộ (server.js :2311)"
        echo -e "${BLUE}5.${NC} 🧪 Mở riêng Menu 1 (Thử nghiệm & Demo độc lập)"
        echo -e "${BLUE}0.${NC} ❌ Thoát"
        echo
        read -p "Chọn [0-5]: " m_choice
        case $m_choice in
            1) handle_submenu ;;
            2) input_key ;;
            3) [ -f "$SCRIPT_DIR/tunnel.sh" ] && bash "$SCRIPT_DIR/tunnel.sh" ;;
            4)
                if [ -f "$SCRIPT_DIR/server.js" ]; then
                    node "$SCRIPT_DIR/server.js" > "$HOME_DIR/.txa_server.log" 2>&1 &
                    echo $! > "$HOME_DIR/.txa_server.pid"
                    echo -e "${GREEN}✓ Đã bật Web Hub tại http://localhost:2311 (PID: $!)${NC}"
                    echo -e "${CYAN}Dùng mục [3] để tạo Tunnel đưa server này ra Internet!${NC}"
                fi
                ;;
            5) [ -f "$SCRIPT_DIR/menu1.sh" ] && bash "$SCRIPT_DIR/menu1.sh" && exit 0 ;;
            0) echo -e "${GREEN}Tạm biệt! Cảm ơn bạn đã sử dụng TXA Studio.${NC}"; exit 0 ;;
        esac
        read -p "Nhấn Enter để tiếp tục..."
    done
}

main
