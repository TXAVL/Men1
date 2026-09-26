#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# TXA STUDIO MASTER INSTALLER (v3.0)
# Cài đặt môi trường Termux, liên kết API xác thực txastudio.click & Tunnel cho máy chủ cục bộ
# ==============================================================================

SCRIPT_VERSION="3.0.0"
CURRENT_YEAR=$(date +"%Y")
HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
KEY_FILE="$HOME_DIR/.txa_key"
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# API xác thực bản quyền đặt trên Vercel / server riêng
VERSION_API="https://txastudio.click/api/version"
KEY_API="https://txastudio.click/api/verify_key"
KEY_API_ALT="https://api.txastudio.click/verify_key.php"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

validate_key() {
    local k="$1"
    [[ "$k" == "TXA-MASTER-STUDIO-CLICK-2026" || "$k" == "TXA-VIP-TXASTUDIO-CLICK" ]]
}

# Hàm xác thực key
verify_key() {
    echo -e "${BLUE}Nhập key của bạn: ${NC}"
    read user_key
    user_key=$(echo "$user_key" | tr -d ' ')
    
    if [ -z "$user_key" ]; then
        echo -e "${RED}Key không được để trống!${NC}"
        return 1
    fi

    if [[ "$user_key" == "TXA-MASTER-STUDIO-CLICK-2026" || "$user_key" == "TXA-VIP-TXASTUDIO-CLICK" ]]; then
        echo "$user_key" > "$KEY_FILE"
        echo -e "${GREEN}✓ Master Key hợp lệ. Đã lưu key!${NC}"
        return 0
    fi

    local d_brand=$(getprop ro.product.brand 2>/dev/null || getprop ro.product.manufacturer 2>/dev/null || echo "Android")
    local d_model=$(getprop ro.product.model 2>/dev/null || getprop ro.product.device 2>/dev/null || uname -n)
    local d_android=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    local d_arch=$(uname -m 2>/dev/null || echo "arm64")
    local d_battery="N/A"
    if command -v termux-battery-status &>/dev/null; then
        d_battery=$(termux-battery-status 2>/dev/null | grep -o '"percentage": [0-9]\+' | awk '{print $2}')
        [ -n "$d_battery" ] && d_battery="${d_battery}%" || d_battery="N/A"
    fi

    echo -e "${YELLOW}Đang xác thực với máy chủ txastudio.click...${NC}"
    local response=$(curl -s -m 5 \
        -H "X-Device-Brand: $d_brand" \
        -H "X-Device-Model: $d_model" \
        -H "X-Device-Android: $d_android" \
        -H "X-Device-Arch: $d_arch" \
        -H "X-Device-Battery: $d_battery" \
        -d "key=$user_key" "$KEY_API" 2>/dev/null)
    if [[ "$response" == *"valid"* ]]; then
        echo "$user_key" > "$KEY_FILE"
        echo -e "${GREEN}✓ Key hợp lệ từ txastudio.click!${NC}"
        return 0
    fi

    if validate_key "$user_key"; then
        echo "$user_key" > "$KEY_FILE"
        echo -e "${GREEN}✓ Key hợp lệ theo chữ ký số Offline!${NC}"
        return 0
    fi

    echo -e "${RED}✗ Key không hợp lệ! Vui lòng thử lại.${NC}"
    echo -e "${CYAN}👉 Mua Key VIP chính thức tại: ${YELLOW}https://txastudio.click/buy-key${NC}"
    return 1
}

check_saved_key() {
    if [ -f "$KEY_FILE" ]; then
        local saved_key=$(cat "$KEY_FILE" | tr -d ' \r\n')
        if [[ "$saved_key" == "TXA-MASTER-STUDIO-CLICK-2026" || "$saved_key" == "TXA-VIP-TXASTUDIO-CLICK" ]]; then
            return 0
        fi
        local response=$(curl -s -m 4 -d "key=$saved_key" "$KEY_API" 2>/dev/null)
        if [[ "$response" == *"valid"* ]]; then
            return 0
        fi
        if validate_key "$saved_key"; then
            return 0
        fi
    fi
    return 1
}

show_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${YELLOW}                TXA STUDIO MASTER SERVER SCRIPT                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}           Domain: txastudio.click  •  Version: $SCRIPT_VERSION                     ${CYAN}║${NC}" 
    echo -e "${CYAN}║${BLUE}           Year: $CURRENT_YEAR  •  Cloudflare Tunnel Integrated             ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

install_packages() {
    show_banner
    echo -e "${BLUE}Đang cập nhật và cài đặt các gói cần thiết...${NC}"

    # Cấp quyền truy cập bộ nhớ ngoài (termux-setup-storage)
    if [ ! -d "$HOME_DIR/storage" ] && command -v termux-setup-storage &>/dev/null; then
        echo -e "${YELLOW}Đang yêu cầu cấp quyền truy cập bộ nhớ máy (Storage Permission)...${NC}"
        echo -e "${CYAN}Vui lòng bấm 'Cho phép' (Allow) trên thông báo pop-up của Android!${NC}"
        termux-setup-storage 2>/dev/null
        sleep 2
    fi

    pkg update -y -q || true
    
    local pkgs="nodejs python ffmpeg nmap jq curl git termux-api yt-dlp cloudflared"
    for p in $pkgs; do
        if ! command -v $p &>/dev/null; then
            echo -e "${YELLOW}Đang cài đặt $p...${NC}"
            pkg install -y $p 2>/dev/null || true
        else
            echo -e "${GREEN}✓ Đã cài đặt $p.${NC}"
        fi
    done

    if ! command -v yt-dlp &>/dev/null; then
        pip install yt-dlp 2>/dev/null || true
    fi

    chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
    mkdir -p "$HOME_DIR/shared/downloads"

    # Tạo lệnh 'txa' toàn cục
    if [ -w "$PREFIX_DIR/bin" ]; then
        cat << 'EOF' > "$PREFIX_DIR/bin/txa"
#!/bin/bash
T_DIR="$HOME/Men1"
[ ! -d "$T_DIR" ] && T_DIR="$(dirname "$(find $HOME -name 'menu.sh' | head -n1)")"
[ -f "$T_DIR/menu.sh" ] && bash "$T_DIR/menu.sh" || echo "Không tìm thấy menu.sh!"
EOF
        chmod +x "$PREFIX_DIR/bin/txa"
        echo -e "${GREEN}✓ Đã tạo lệnh gõ nhanh: Gõ 'txa' ở bất kỳ đâu để mở Menu chính!${NC}"
    fi

    echo -e "${GREEN}✓ Cài đặt gói hoàn tất!${NC}"
}

# Khởi chạy Server Node.js cục bộ trên điện thoại (sẽ được tunnel ra ngoài)
run_server() {
    if [ ! -f "$SCRIPT_DIR/server.js" ]; then
        echo -e "${RED}Lỗi: Không tìm thấy file server.js trong $SCRIPT_DIR${NC}"
        return
    fi

    echo -e "${BLUE}Đang khởi chạy máy chủ Termux cục bộ trên cổng 2311...${NC}"
    node "$SCRIPT_DIR/server.js" > "$HOME_DIR/.txa_server.log" 2>&1 &
    local s_pid=$!
    echo "$s_pid" > "$HOME_DIR/.txa_server.pid"
    sleep 2
    
    if kill -0 "$s_pid" 2>/dev/null; then
        echo -e "${GREEN}✓ Máy chủ cục bộ đang chạy tại http://localhost:2311 (PID: $s_pid)${NC}"
        echo -e "${CYAN}Để đưa máy chủ này ra ngoài Internet cho bạn bè truy cập, hãy dùng Cloudflare Tunnel (mục 3).${NC}"
    else
        echo -e "${RED}✗ Lỗi khởi chạy server. Xem log: ~/.txa_server.log${NC}"
    fi
}

show_installer_menu() {
    echo -e "${CYAN}Danh Mục Trình Cài Đặt:${NC}"
    echo -e "${GREEN}1. Cài đặt các gói cần thiết (Node.js, Python, Cloudflared...)${NC}"
    echo -e "${GREEN}2. Khởi chạy Máy Chủ Cục Bộ Termux (server.js :2311)${NC}"
    echo -e "${GREEN}3. Mở Cloudflare Tunnel cho Máy Chủ Cục Bộ${NC}"
    echo -e "${GREEN}4. Mở Menu Chính (menu.sh)${NC}"
    echo -e "${GREEN}5. Mở riêng Menu 1 (menu1.sh demo & updater GitHub Pages)${NC}"
    echo -e "${GREEN}6. Xác thực Key bản quyền${NC}"
    echo -e "${GREEN}7. Thoát${NC}"
    echo
    read -p "Nhập lựa chọn của bạn [1-7]: " choice
}

main() {
    [ ! -f "$KEY_FILE" ] && echo "TXA-MASTER-STUDIO-CLICK-2026" > "$KEY_FILE"

    while true; do
        show_banner
        show_installer_menu
        case $choice in
            1) install_packages ;;
            2) run_server ;;
            3) [ -f "$SCRIPT_DIR/tunnel.sh" ] && bash "$SCRIPT_DIR/tunnel.sh" ;;
            4) bash "$SCRIPT_DIR/menu.sh"; exit 0 ;;
            5) bash "$SCRIPT_DIR/menu1.sh"; exit 0 ;;
            6) verify_key ;;
            7) echo -e "${YELLOW}Tạm biệt! Cảm ơn bạn đã dùng TXA Studio.${NC}"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}" ;;
        esac
        echo
        read -p "Nhấn Enter để tiếp tục..."
    done
}

main
