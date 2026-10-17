#!/bin/bash
# ==============================================================================
# TXA NEXHUB - TERMUX CYBERPUNK CONTROL CENTER (v3.1)
# ==============================================================================
# Bảng điều khiển đa sắc ASCII: Giám sát Telemetry, Audit quyền Termux:API,
# Tích hợp Web Hub, AI Assistant & Cloudflare Tunnel + QR Code Terminal
# ==============================================================================

HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_JS="$SCRIPT_DIR/server.js"
AI_SH="$SCRIPT_DIR/ai.sh"
TUNNEL_SH="$SCRIPT_DIR/tunnel.sh"
TUNNEL_URL_FILE="$HOME_DIR/.txa_tunnel.url"

# Mã màu Neon Cyberpunk
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

show_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${MAGENTA}   ████████╗██╗  ██╗ █████╗     ███╗   ██╗███████╗██╗  ██╗██╗   ██╗██████╗    ${CYAN}║${NC}"
    echo -e "${CYAN}║${MAGENTA}   ╚══██╔══╝╚██╗██╔╝██╔══██╗    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔══██╗   ${CYAN}║${NC}"
    echo -e "${CYAN}║${CYAN}      ██║    ╚███╔╝ ███████║    ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║██████╔╝   ${CYAN}║${NC}"
    echo -e "${CYAN}║${CYAN}      ██║    ██╔██╗ ██╔══██║    ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║██╔══██╗   ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}      ██║   ██╔╝ ██╗██║  ██║    ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝██████╔╝   ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}      ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝    ${CYAN}║${NC}"
    echo -e "${CYAN}║${YELLOW}           CYBERPUNK CONTROL CENTER  •  ANDROID TERMUX HUB (v3.1)       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

audit_permissions() {
    echo -e "${YELLOW}┌─ [AUDIT QUYỀN HỆ THỐNG TERMUX & ANDROID] ──────────────────────────┐${NC}"
    
    # 1. Storage
    if [ -d "$HOME_DIR/storage/shared" ]; then
        echo -e "${YELLOW}│${NC} Bộ nhớ ngoài (Internal Storage):  ${GREEN}✓ ĐÃ CẤP QUYỀN${NC}"
    else
        echo -e "${YELLOW}│${NC} Bộ nhớ ngoài (Internal Storage):  ${RED}✗ CHƯA CẤP (chạy: termux-setup-storage)${NC}"
    fi

    # 2. Termux API CLI
    if command -v termux-battery-status &>/dev/null; then
        echo -e "${YELLOW}│${NC} Gói Termux:API CLI:              ${GREEN}✓ ĐÃ CÀI ĐẶT${NC}"
    else
        echo -e "${YELLOW}│${NC} Gói Termux:API CLI:              ${RED}✗ CHƯA CÀI (chạy: pkg install termux-api)${NC}"
    fi

    # 3. Node.js & Cloudflared
    local node_st="${RED}✗ CHƯA CÀI${NC}"
    command -v node &>/dev/null && node_st="${GREEN}✓ ĐÃ CÀI ($(node -v))${NC}"
    echo -e "${YELLOW}│${NC} Môi trường Node.js:               $node_st"

    local cf_st="${RED}✗ CHƯA CÀI${NC}"
    (command -v cloudflared &>/dev/null || [ -f "$HOME_DIR/.bin/cloudflared" ]) && cf_st="${GREEN}✓ SẴN SÀNG${NC}"
    echo -e "${YELLOW}│${NC} Cloudflare Tunnel Engine:         $cf_st"

    # 4. Telemetry Pin
    if command -v termux-battery-status &>/dev/null; then
        local bat=$(termux-battery-status 2>/dev/null)
        if [ -n "$bat" ]; then
            local p=$(echo "$bat" | grep -o '"percentage": [0-9]\+' | head -n1 | awk '{print $2}')
            local temp=$(echo "$bat" | grep -o '"temperature": [0-9]\+' | head -n1 | awk '{print $2}')
            echo -e "${YELLOW}│${NC} Mức Pin / Nhiệt độ thiết bị:      ${CYAN}${p}% / $(echo "scale=1; $temp/10" | bc 2>/dev/null || echo "$temp")°C${NC}"
        fi
    fi

    echo -e "${YELLOW}└────────────────────────────────────────────────────────────────────┘${NC}"
}

main_menu() {
    while true; do
        show_banner
        audit_permissions
        echo

        local t_url="Chưa mở Tunnel"
        [ -f "$TUNNEL_URL_FILE" ] && t_url=$(cat "$TUNNEL_URL_FILE")
        echo -e "${CYAN}🌐 Cloudflare Tunnel:${NC} ${YELLOW}$t_url${NC}"
        echo

        echo -e "${BOLD}${BLUE}1.${NC} 🤖 ${BOLD}Mở TXA JARVIS AI (AI Companion, Mở Cổng Ra Toàn Cầu, Loa TTS)${NC}"
        echo -e "${BOLD}${BLUE}2.${NC} 🚀 Khởi chạy Web Hub Cục Bộ (server.js :2311)"
        echo -e "${BOLD}${BLUE}3.${NC} 🌐 Quản lý Cloudflare Tunnel (Mở link HTTPS ra Internet)"
        echo -e "${BOLD}${BLUE}4.${NC} 📱 Mở Menu Chính Nâng Cao (menu.sh)"
        echo -e "${BOLD}${BLUE}5.${NC} 📂 Cấp quyền bộ nhớ thiết bị (termux-setup-storage)"
        echo -e "${BOLD}${BLUE}0.${NC} ❌ Thoát"
        echo
        read -p "Chọn chức năng [0-5]: " opt

        case $opt in
            1)
                [ -f "$AI_SH" ] && bash "$AI_SH"
                ;;
            2)
                if [ -f "$SERVER_JS" ]; then
                    node "$SERVER_JS" > "$HOME_DIR/.txa_server.log" 2>&1 &
                    echo $! > "$HOME_DIR/.txa_server.pid"
                    echo -e "${GREEN}✓ Đã khởi chạy Web Hub tại http://localhost:2311${NC}"
                    sleep 2
                fi
                ;;
            3)
                [ -f "$TUNNEL_SH" ] && bash "$TUNNEL_SH"
                ;;
            4)
                [ -f "$SCRIPT_DIR/menu.sh" ] && bash "$SCRIPT_DIR/menu.sh"
                ;;
            5)
                termux-setup-storage
                echo -e "${GREEN}✓ Đã gửi yêu cầu cấp quyền bộ nhớ! Hãy bấm Cho Phép trên màn hình.${NC}"
                sleep 2
                ;;
            0) exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}"; sleep 1 ;;
        esac
    done
}

main_menu
