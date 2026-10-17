#!/bin/bash
# ==============================================================================
# TXA JARVIS AI - TERMUX CYBER-AI ASSISTANT & TUNNEL AGENT
# ==============================================================================
# Tác giả: TXA Studio
# Hệ sinh thái Termux Android - AI điều khiển phần cứng & Mở cổng Tunnel toàn cầu
# ==============================================================================

AI_PORT=2312
HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_SERVER_JS="$SCRIPT_DIR/ai_server.js"
TUNNEL_URL_FILE="$HOME_DIR/.txa_tunnel.url"
AI_PID_FILE="$HOME_DIR/.txa_ai.pid"
TUNNEL_PID_FILE="$HOME_DIR/.txa_ai_tunnel.pid"
TUNNEL_LOG_FILE="$HOME_DIR/.txa_ai_tunnel.log"
CONFIG_FILE="$HOME_DIR/.txa_ai_config.json"

# Màu sắc ANSI Neon & Cyberpunk
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Kiểm tra và cài đặt các phụ thuộc cốt lõi
check_dependencies() {
    echo -e "${CYAN}Đang kiểm tra môi trường Termux...${NC}"
    local missing=()

    command -v node &>/dev/null || missing+=("nodejs")
    command -v curl &>/dev/null || missing+=("curl")
    command -v jq &>/dev/null || missing+=("jq")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Đang cài đặt các gói cần thiết: ${missing[*]}...${NC}"
        pkg update -y && pkg install -y "${missing[@]}"
    fi

    # Kiểm tra termux-api
    if ! command -v termux-battery-status &>/dev/null; then
        echo -e "${YELLOW}Đang cài đặt termux-api...${NC}"
        pkg install -y termux-api
        echo -e "${GREEN}✓ Đã cài đặt termux-api CLI!${NC}"
        echo -e "${MAGENTA}⚠️ LƯU Ý: Chắc chắn bạn đã cài ứng dụng 'Termux:API' trên Android (tải từ F-Droid/GitHub) và cấp đủ quyền Máy ảnh, Vị trí!${NC}"
    fi

    # Kiểm tra cloudflared
    install_cloudflared
}

# Cài đặt cloudflared ARM64
install_cloudflared() {
    if command -v cloudflared &>/dev/null; then
        return 0
    fi

    if [ -f "$HOME_DIR/.bin/cloudflared" ]; then
        export PATH="$HOME_DIR/.bin:$PATH"
        return 0
    fi

    echo -e "${YELLOW}Đang thiết lập Cloudflared để mở Tunnel toàn cầu...${NC}"
    if pkg install -y cloudflared 2>/dev/null; then
        echo -e "${GREEN}✓ Cài đặt cloudflared qua pkg thành công!${NC}"
        return 0
    fi

    mkdir -p "$HOME_DIR/.bin"
    local bin_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    echo -e "${CYAN}Đang tải binary ARM64 từ Cloudflare Releases...${NC}"
    if curl -L -s "$bin_url" -o "$HOME_DIR/.bin/cloudflared"; then
        chmod +x "$HOME_DIR/.bin/cloudflared"
        export PATH="$HOME_DIR/.bin:$PATH"
        if ! grep -q "$HOME_DIR/.bin" "$HOME_DIR/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME_DIR/.bashrc"
        fi
        echo -e "${GREEN}✓ Đã cài đặt cloudflared vào ~/.bin/cloudflared${NC}"
        return 0
    else
        echo -e "${RED}✗ Lỗi tải cloudflared. Vui lòng kiểm tra kết nối mạng!${NC}"
        return 1
    fi
}

# Dừng toàn bộ tiến trình AI & Tunnel
stop_all() {
    echo -e "${YELLOW}Đang dọn dẹp và dừng các tiến trình...${NC}"
    if [ -f "$AI_PID_FILE" ]; then
        local pid=$(cat "$AI_PID_FILE")
        kill -9 "$pid" 2>/dev/null
        rm -f "$AI_PID_FILE"
    fi
    if [ -f "$TUNNEL_PID_FILE" ]; then
        local tpid=$(cat "$TUNNEL_PID_FILE")
        kill -9 "$tpid" 2>/dev/null
        rm -f "$TUNNEL_PID_FILE"
    fi
    pkill -f "ai_server.js" 2>/dev/null
    pkill -f "cloudflared tunnel --url" 2>/dev/null
    rm -f "$TUNNEL_URL_FILE"
    echo -e "${GREEN}✓ Đã dừng hoàn toàn AI Server và Cloudflare Tunnel!${NC}"
}

# Khởi chạy AI Server và Cloudflare Tunnel
start_ai_tunnel() {
    check_dependencies
    stop_all

    echo
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         🚀 KHỞI ĐỘNG TXA JARVIS AI & CLOUDFLARE TUNNEL        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"

    # 1. Chạy Node.js Server
    echo -e "${YELLOW}[1/3] Đang khởi chạy AI Backend trên cổng $AI_PORT...${NC}"
    node "$AI_SERVER_JS" > "$HOME_DIR/.txa_ai.log" 2>&1 &
    local server_pid=$!
    echo "$server_pid" > "$AI_PID_FILE"

    sleep 2
    if ! kill -0 "$server_pid" 2>/dev/null; then
        echo -e "${RED}✗ Không thể khởi chạy ai_server.js! Xem log tại: $HOME_DIR/.txa_ai.log${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ AI Server đã sẵn sàng tại: http://127.0.0.1:$AI_PORT${NC}"

    # 2. Khởi chạy Cloudflare Quick Tunnel
    echo -e "${YELLOW}[2/3] Đang kết nối mạng lưới Cloudflare để cấp URL toàn cầu...${NC}"
    rm -f "$TUNNEL_LOG_FILE" "$TUNNEL_URL_FILE"
    cloudflared tunnel --url "http://127.0.0.1:$AI_PORT" > "$TUNNEL_LOG_FILE" 2>&1 &
    local tunnel_pid=$!
    echo "$tunnel_pid" > "$TUNNEL_PID_FILE"

    local count=0
    local tunnel_url=""
    echo -e "${CYAN}Đang chờ cấp chứng chỉ SSL và tên miền công khai...${NC}"
    while [ $count -lt 25 ]; do
        sleep 1
        count=$((count + 1))
        tunnel_url=$(grep -o 'https://[-a-zA-Z0-9@:%._\+~#=]\+\.trycloudflare\.com' "$TUNNEL_LOG_FILE" | head -n1)
        if [ -n "$tunnel_url" ]; then
            break
        fi
    done

    if [ -z "$tunnel_url" ]; then
        echo -e "${RED}✗ Chưa nhận được URL từ Cloudflare sau 25s. Kiểm tra log: $TUNNEL_LOG_FILE${NC}"
        echo -e "${YELLOW}Bạn vẫn có thể truy cập nội bộ (LAN) tại: http://127.0.0.1:$AI_PORT${NC}"
        return 1
    fi

    echo "$tunnel_url" > "$TUNNEL_URL_FILE"

    # 3. Thông báo bằng giọng nói trên điện thoại
    if command -v termux-tts-speak &>/dev/null; then
        termux-tts-speak -l vi-VN "Jarvis AI đã online. Mời sếp quét mã để truy cập từ mọi nơi." 2>/dev/null &
    fi

    # 4. Hiển thị kết quả & QR Code
    echo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║               ✨ TXA JARVIS AI ĐÃ ONLINE TOÀN CẦU!                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BOLD}${CYAN}🌐 ĐỊA CHỈ TRUY CẬP TỪ XA:${NC} ${BOLD}${YELLOW}$tunnel_url${NC}"
    echo -e "${CYAN}📍 Địa chỉ cục bộ (Local):${NC} http://127.0.0.1:$AI_PORT"
    echo -e "${MAGENTA}💡 Bạn có thể gửi link này cho bạn bè hoặc mở trên Laptop/iPhone ở bất cứ đâu!${NC}"
    echo

    # In QR Code ra màn hình Console
    echo -e "${YELLOW}📲 QUÉT MÃ QR DƯỚI ĐÂY ĐỂ MỞ NHANH TRÊN THIẾT BỊ KHÁC:${NC}"
    echo
    if command -v qrencode &>/dev/null; then
        qrencode -t ANSIUTF8 "$tunnel_url"
    else
        # Dùng dịch vụ render ASCII QR nhẹ
        curl -s -m 5 "https://qrenco.de/$tunnel_url" || echo -e "${CYAN}Hãy copy link phía trên vào trình duyệt: $tunnel_url${NC}"
    fi
    echo
}

# Tương tác Chat trực tiếp trên Terminal
cli_chat() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           💬 CHAT TRỰC TIẾP VỚI TXA JARVIS (TERMINAL)         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Gợi ý ra lệnh phần cứng:${NC}"
    echo -e "• 'bật đèn' / 'tắt đèn'      • 'rung máy'       • 'kiểm tra pin'"
    echo -e "• 'chụp ảnh selfie'          • 'kể chuyện cười' • 'gõ exit để thoát'"
    echo

    # Khởi động server nền nếu chưa chạy
    if ! curl -s -m 2 "http://127.0.0.1:$AI_PORT/api/telemetry" &>/dev/null; then
        echo -e "${YELLOW}Đang khởi động AI server cục bộ...${NC}"
        node "$AI_SERVER_JS" > "$HOME_DIR/.txa_ai.log" 2>&1 &
        echo $! > "$AI_PID_FILE"
        sleep 2
    fi

    while true; do
        echo -ne "${BOLD}${GREEN}Bạn ❯ ${NC}"
        read -r user_prompt

        if [[ -z "$user_prompt" ]]; then
            continue
        fi

        if [[ "$user_prompt" == "exit" || "$user_prompt" == "quit" || "$user_prompt" == "thoat" ]]; then
            echo -e "${CYAN}Tạm biệt sếp! Hẹn gặp lại nhé!${NC}"
            break
        fi

        echo -ne "${CYAN}Jarvis đang xử lý...${NC}\r"

        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$(jq -n --arg p "$user_prompt" '{prompt: $p}')" \
            "http://127.0.0.1:$AI_PORT/api/chat")

        local reply=$(echo "$response" | jq -r '.reply // .error // "Không nhận được phản hồi"')
        local engine=$(echo "$response" | jq -r '.engine // "offline"')

        echo -e "${BOLD}${CYAN}Jarvis [${engine}] ❯ ${NC}${reply}"
        echo
    done
}

# Kiểm tra quyền và test phần cứng Termux:API
test_hardware() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          🔧 KIỂM TRA PHẦN CỨNG & QUYỀN TERMUX:API             ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"

    echo -ne "${YELLOW}1. Kiểm tra trạng thái Pin: ${NC}"
    if command -v termux-battery-status &>/dev/null; then
        local bat=$(termux-battery-status 2>/dev/null)
        if [ -n "$bat" ]; then
            local pct=$(echo "$bat" | jq -r '.percentage // "N/A"')
            local temp=$(echo "$bat" | jq -r '.temperature // 0')
            echo -e "${GREEN}✓ Hoạt động (${pct}%, $(echo "scale=1; $temp/10" | bc 2>/dev/null || echo "$temp")°C)${NC}"
        else
            echo -e "${RED}✗ Lỗi phản hồi (cần cấp quyền Termux:API)${NC}"
        fi
    else
        echo -e "${RED}✗ Chưa cài termux-api CLI${NC}"
    fi

    echo -ne "${YELLOW}2. Thử nghiệm Rung máy (1 giây): ${NC}"
    if termux-vibrate -d 1000 2>/dev/null; then
        echo -e "${GREEN}✓ Đã gửi lệnh rung!${NC}"
    else
        echo -e "${RED}✗ Thất bại${NC}"
    fi

    echo -ne "${YELLOW}3. Thử nghiệm Đèn Pin (Flashlight ON -> OFF): ${NC}"
    if termux-torch on 2>/dev/null; then
        sleep 1
        termux-torch off 2>/dev/null
        echo -e "${GREEN}✓ Đèn pin chớp sáng thành công!${NC}"
    else
        echo -e "${RED}✗ Cần cấp quyền Camera cho Termux:API${NC}"
    fi

    echo -ne "${YELLOW}4. Thử nghiệm Phát Giọng Nói (TTS): ${NC}"
    if termux-tts-speak -l vi-VN "Kiểm tra hệ thống âm thanh Termux hoàn tất" 2>/dev/null; then
        echo -e "${GREEN}✓ Đã phát âm thanh ra loa!${NC}"
    else
        echo -e "${RED}✗ Thất bại${NC}"
    fi

    echo
    read -p "Nhấn Enter để quay lại menu..."
}

# Cấu hình Gemini API Key
config_gemini() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         🔑 CẤU HÌNH GOOGLE GEMINI AI KEY (SIÊU TRÍ TUỆ)       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Hướng dẫn lấy API Key MIỄN PHÍ 100%:${NC}"
    echo -e "1. Mở trình duyệt vào: ${CYAN}https://aistudio.google.com${NC}"
    echo -e "2. Đăng nhập tài khoản Google -> Bấm 'Get API key' -> Tạo key mới."
    echo -e "3. Copy chuỗi key (bắt đầu bằng AIzaSy...)"
    echo
    echo -e "${MAGENTA}💡 Lưu ý: Nếu không nhập key, Jarvis sẽ tự động dùng Offline NLP Brain!${NC}"
    echo

    read -p "Nhập Google Gemini API Key (Enter để bỏ qua/xóa): " input_key

    mkdir -p "$HOME_DIR"
    local current_model="gemini-2.5-flash"
    local voice_state="true"

    if [ -f "$CONFIG_FILE" ]; then
        current_model=$(jq -r '.geminiModel // "gemini-2.5-flash"' "$CONFIG_FILE" 2>/dev/null || echo "gemini-2.5-flash")
        voice_state=$(jq -r '.voiceEnabled // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    fi

    cat <<EOF > "$CONFIG_FILE"
{
  "geminiApiKey": "$input_key",
  "geminiModel": "$current_model",
  "voiceEnabled": $voice_state,
  "ttsLang": "vi-VN"
}
EOF

    echo
    if [ -n "$input_key" ]; then
        echo -e "${GREEN}✓ Đã lưu Gemini API Key! Jarvis hiện đã được kích hoạt Siêu Trí Tuệ!${NC}"
    else
        echo -e "${YELLOW}✓ Đã cấu hình chạy ở chế độ Offline NLP Brain!${NC}"
    fi
    sleep 2
}

# Tạo phím tắt lệnh 'ai' trên toàn hệ thống Termux
setup_alias() {
    local bashrc="$HOME_DIR/.bashrc"
    if ! grep -q "alias ai=" "$bashrc" 2>/dev/null; then
        echo "alias ai=\"bash $SCRIPT_DIR/ai.sh\"" >> "$bashrc"
        echo "alias jarvis=\"bash $SCRIPT_DIR/ai.sh\"" >> "$bashrc"
        echo -e "${GREEN}✓ Đã tạo lệnh gọi tắt 'ai' và 'jarvis' trong Termux!${NC}"
    fi
}

# Menu chính
main_menu() {
    setup_alias
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${BOLD}${YELLOW}         TXA JARVIS AI — TERMUX CYBER-AGENT (v1.0)             ${CYAN}║${NC}"
        echo -e "${CYAN}║${GREEN}    AI Điều Khiển Phần Cứng Android & Mở Tunnel Toàn Cầu       ${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"

        # Kiểm tra trạng thái đang chạy
        if [ -f "$AI_PID_FILE" ] && kill -0 "$(cat "$AI_PID_FILE" 2>/dev/null)" 2>/dev/null; then
            echo -e "${GREEN}● AI Backend:${NC} ĐANG CHẠY (Port: $AI_PORT)"
        else
            echo -e "${RED}○ AI Backend:${NC} ĐANG TẮT"
        fi

        if [ -f "$TUNNEL_URL_FILE" ]; then
            echo -e "${GREEN}● URL Tunnel:${NC} ${YELLOW}$(cat "$TUNNEL_URL_FILE")${NC}"
        else
            echo -e "${RED}○ URL Tunnel:${NC} Chưa mở"
        fi
        echo

        echo -e "${BOLD}${BLUE}1.${NC} 🚀 ${BOLD}Khởi chạy AI Web Server & Mở Tunnel ra Toàn Cầu (Có QR Code)${NC}"
        echo -e "${BOLD}${BLUE}2.${NC} 💬 Chat trực tiếp với AI qua Terminal (Console Mode)"
        echo -e "${BOLD}${BLUE}3.${NC} 🔧 Kiểm tra quyền & Test phần cứng (Đèn, Rung, TTS, Pin)"
        echo -e "${BOLD}${BLUE}4.${NC} 🔑 Cấu hình Gemini API Key (Mở khóa Siêu Trí Tuệ)"
        echo -e "${BOLD}${BLUE}5.${NC} 🛑 Dừng toàn bộ AI Server & Giải phóng Tunnel"
        echo -e "${BOLD}${BLUE}6.${NC} 📋 Xem thông tin URL Tunnel hiện tại"
        echo -e "${BOLD}${BLUE}7.${NC} 🚪 Thoát"
        echo
        read -p "Chọn chức năng [1-7]: " opt

        case $opt in
            1) start_ai_tunnel; read -p "Nhấn Enter để quay lại menu..." ;;
            2) cli_chat ;;
            3) test_hardware ;;
            4) config_gemini ;;
            5) stop_all; sleep 1 ;;
            6) 
                if [ -f "$TUNNEL_URL_FILE" ]; then
                    echo -e "\n${GREEN}URL hiện tại:${NC} ${YELLOW}$(cat "$TUNNEL_URL_FILE")${NC}\n"
                else
                    echo -e "\n${RED}Tunnel chưa được mở.${NC}\n"
                fi
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            7) exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}"; sleep 1 ;;
        esac
    done
}

# Nếu chạy với tham số lệnh
case "$1" in
    start) start_ai_tunnel ;;
    stop) stop_all ;;
    chat) cli_chat ;;
    *) main_menu ;;
esac
