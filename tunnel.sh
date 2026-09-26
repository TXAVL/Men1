#!/bin/bash
# ==============================================================================
# TXA STUDIO CLOUDFLARE TUNNEL MANAGER (v3.0)
# Tích hợp Cloudflare Tunnel đưa máy chủ Termux ra Internet (Domain: txastudio.click)
# ==============================================================================

HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
TUNNEL_URL_FILE="$HOME_DIR/.txa_tunnel.url"
TUNNEL_LOG_FILE="$HOME_DIR/.txa_tunnel.log"
TUNNEL_PID_FILE="$HOME_DIR/.txa_tunnel.pid"
TUNNEL_TOKEN_FILE="$HOME_DIR/.txa_tunnel_token"
DOMAIN_TARGET="txastudio.click"
DEFAULT_PORT=2311

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Kiểm tra và cài đặt cloudflared
install_cloudflared() {
    if command -v cloudflared &> /dev/null; then
        echo -e "${GREEN}✓ Cloudflared đã được cài đặt: $(cloudflared --version | head -n1)${NC}"
        return 0
    fi

    echo -e "${YELLOW}Đang cài đặt Cloudflared cho Termux Android...${NC}"
    
    # Cách 1: Cài qua pkg Termux
    if pkg install -y cloudflared 2>/dev/null; then
        echo -e "${GREEN}✓ Đã cài đặt cloudflared thành công qua pkg!${NC}"
        return 0
    fi

    # Cách 2: Tải binary ARM64 chính thức từ Cloudflare
    echo -e "${CYAN}Đang tải binary ARM64 từ Cloudflare Releases...${NC}"
    mkdir -p "$HOME_DIR/.bin"
    local bin_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    if curl -L -s "$bin_url" -o "$HOME_DIR/.bin/cloudflared"; then
        chmod +x "$HOME_DIR/.bin/cloudflared"
        # Đưa vào PATH nếu chưa có
        if ! grep -q "$HOME_DIR/.bin" "$HOME_DIR/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME_DIR/.bashrc"
        fi
        export PATH="$HOME_DIR/.bin:$PATH"
        echo -e "${GREEN}✓ Đã tải và cài đặt cloudflared vào ~/.bin/cloudflared${NC}"
        return 0
    else
        echo -e "${RED}✗ Không thể tải cloudflared. Vui lòng kiểm tra kết nối mạng!${NC}"
        return 1
    fi
}

# Dừng tunnel đang chạy
stop_tunnel() {
    if [ -f "$TUNNEL_PID_FILE" ]; then
        local pid=$(cat "$TUNNEL_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            echo -e "${YELLOW}Đã dừng tiến trình Cloudflare Tunnel (PID: $pid).${NC}"
        fi
        rm -f "$TUNNEL_PID_FILE"
    fi
    pkill -f "cloudflared" 2>/dev/null
    rm -f "$TUNNEL_URL_FILE"
    echo -e "${GREEN}Đã giải phóng toàn bộ kết nối Cloudflare Tunnel.${NC}"
}

# Chạy Quick Tunnel (trycloudflare.com)
start_quick_tunnel() {
    stop_tunnel
    install_cloudflared || return 1

    echo -e "${CYAN}Đang khởi tạo Quick Cloudflare Tunnel tới cổng $DEFAULT_PORT...${NC}"
    rm -f "$TUNNEL_LOG_FILE" "$TUNNEL_URL_FILE"
    
    cloudflared tunnel --url "http://127.0.0.1:$DEFAULT_PORT" > "$TUNNEL_LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$TUNNEL_PID_FILE"
    
    echo -e "${YELLOW}Đang đợi Cloudflare cấp phát URL bảo mật SSL...${NC}"
    local count=0
    local tunnel_url=""
    
    while [ $count -lt 25 ]; do
        sleep 1
        count=$((count + 1))
        tunnel_url=$(grep -o 'https://[-a-zA-Z0-9@:%._\+~#=]\+\.trycloudflare\.com' "$TUNNEL_LOG_FILE" | head -n1)
        if [ -n "$tunnel_url" ]; then
            break
        fi
    done
    
    if [ -n "$tunnel_url" ]; then
        echo "$tunnel_url" > "$TUNNEL_URL_FILE"
        echo
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           CLOUDFLARE QUICK TUNNEL ĐÃ SẴN SÀNG!                ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "${CYAN}🌐 Địa chỉ công khai:${NC} ${YELLOW}$tunnel_url${NC}"
        echo -e "${MAGENTA}💡 Để gắn vào domain ${DOMAIN_TARGET}, hãy sử dụng mục [2] Cấu hình Token.${NC}"
        echo
    else
        echo -e "${RED}Chưa nhận được URL sau 25s. Xem log tại $TUNNEL_LOG_FILE${NC}"
    fi
}

# Chạy Custom Tunnel với Token (Domain: *.txastudio.click)
start_token_tunnel() {
    install_cloudflared || return 1
    
    local token=""
    if [ -f "$TUNNEL_TOKEN_FILE" ]; then
        token=$(cat "$TUNNEL_TOKEN_FILE")
    fi

    if [ -z "$token" ]; then
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║     CẤU HÌNH SUBDOMAIN CHO DOMAIN: ${DOMAIN_TARGET}       ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "${YELLOW}Hướng dẫn lấy Tunnel Token miễn phí từ Cloudflare:${NC}"
        echo -e "1. Vào https://one.dash.cloudflare.com (Cloudflare Zero Trust)."
        echo -e "2. Chọn Networks -> Tunnels -> Add a Tunnel -> Chọn Cloudflared."
        echo -e "3. Đặt tên (vd: termux-txa) -> Copy chuỗi token trong lệnh cài đặt."
        echo -e "4. Cấu hình Public Hostname:"
        echo -e "   - Subdomain: ${GREEN}hub${NC} hoặc ${GREEN}server${NC}"
        echo -e "   - Domain: ${GREEN}${DOMAIN_TARGET}${NC}"
        echo -e "   - Service: Type: ${GREEN}HTTP${NC} | URL: ${GREEN}localhost:2311${NC}"
        echo
        read -p "Nhập Cloudflare Tunnel Token của bạn: " input_token
        if [ -z "$input_token" ]; then
            echo -e "${RED}Token không được để trống!${NC}"
            return 1
        fi
        token="$input_token"
        echo "$token" > "$TUNNEL_TOKEN_FILE"
        echo -e "${GREEN}✓ Đã lưu token thành công!${NC}"
    fi

    stop_tunnel
    echo -e "${CYAN}Đang khởi động Cloudflare Tunnel liên kết Subdomain (*.${DOMAIN_TARGET})...${NC}"
    
    cloudflared tunnel run --token "$token" > "$TUNNEL_LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$TUNNEL_PID_FILE"
    
    echo "https://hub.${DOMAIN_TARGET}" > "$TUNNEL_URL_FILE"
    
    sleep 3
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${GREEN}✓ Tunnel đang hoạt động với PID: $pid${NC}"
        echo -e "${CYAN}🌐 Subdomain của bạn đã online tại:${NC} ${YELLOW}https://hub.${DOMAIN_TARGET}${NC} (hoặc subdomain bạn đã cấu hình trên Cloudflare)"
    else
        echo -e "${RED}✗ Lỗi khởi chạy. Vui lòng kiểm tra lại token và xem log: $TUNNEL_LOG_FILE${NC}"
    fi
}

# Xem trạng thái
show_status() {
    echo -e "${CYAN}--- TRẠNG THÁI CLOUDFLARE TUNNEL ---${NC}"
    if [ -f "$TUNNEL_PID_FILE" ]; then
        local pid=$(cat "$TUNNEL_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}✓ Đang chạy (PID: $pid)${NC}"
            if [ -f "$TUNNEL_URL_FILE" ]; then
                echo -e "URL hiện tại: ${YELLOW}$(cat $TUNNEL_URL_FILE)${NC}"
            fi
            return
        fi
    fi
    echo -e "${RED}○ Chưa khởi chạy hoặc đã dừng.${NC}"
}

# Menu CLI nếu chạy trực tiếp
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║     TXA CLOUDFLARE TUNNEL MANAGER - ${DOMAIN_TARGET}    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        show_status
        echo
        echo -e "${BLUE}1.${NC} Bật Quick Tunnel miễn phí (URL *.trycloudflare.com)"
        echo -e "${BLUE}2.${NC} Chạy Subdomain riêng (*.${DOMAIN_TARGET}) bằng Token"
        echo -e "${BLUE}3.${NC} Cập nhật lại Cloudflare Tunnel Token"
        echo -e "${BLUE}4.${NC} Dừng Tunnel"
        echo -e "${BLUE}5.${NC} Xem Log kết nối"
        echo -e "${BLUE}6.${NC} Thoát"
        echo
        read -p "Chọn chức năng [1-6]: " choice
        case $choice in
            1) start_quick_tunnel ;;
            2) start_token_tunnel ;;
            3) rm -f "$TUNNEL_TOKEN_FILE"; start_token_tunnel ;;
            4) stop_tunnel ;;
            5) [ -f "$TUNNEL_LOG_FILE" ] && tail -n 25 "$TUNNEL_LOG_FILE" || echo "Chưa có log." ;;
            6) exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}" ;;
        esac
        read -p "Nhấn Enter để tiếp tục..."
    done
fi
