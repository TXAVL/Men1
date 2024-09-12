#!/data/data/com.termux/files/usr/bin/bash

# Định nghĩa màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Thông tin script
SCRIPT_VERSION="1.2"
CURRENT_YEAR=$(date +"%Y")
VERSION_API="https://key.txavideo.online/version.php"

# Hàm hiển thị banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  _____  __   __    _    __     __ _     ____   ____"
    echo " |_   _| \ \ / /   / \    \ \   / /| |   / __ \ / ___| "
    echo "   | |    \ V /   / _ \    \ \ / / | |  / / _\` | |  _"
    echo "   | |     | |   / ___ \    \ V /  | | | | (_| | |_| |"
    echo "   |_|     |_|  /_/   \_\    \_/   |_|  \ \__,_|\____|"
    echo "                                         \____/"
    echo -e "${NC}"
    echo -e "${YELLOW}======== Server Script v${SCRIPT_VERSION} (${CURRENT_YEAR}) ========${NC}"
    echo
}

# Hàm hiển thị menu
show_menu() {
    echo -e "${GREEN}1. Kiểm tra cập nhật${NC}"
    echo -e "${GREEN}2. Cài đặt/Cập nhật server${NC}"
    echo -e "${GREEN}3. Chạy server${NC}"
    echo -e "${GREEN}4. Xem changelog${NC}"
    echo -e "${GREEN}5. Thoát${NC}"
    echo
    echo -n "Chọn một tùy chọn: "
}

# Hàm hiển thị thanh tiến trình
show_progress() {
    local duration=$1
    local steps=$2
    local width=50
    local progress=0
    for ((i=0; i<steps; i++)); do
        let progress=i*width/steps
        printf "\r[%-${width}s] %d%%" $(printf '=' %.0s $(seq 1 $progress)) $((100*i/steps))
        sleep $(echo "$duration/$steps" | bc -l)
    done
    echo
}

# Hàm kiểm tra cập nhật
check_update() {
    echo -e "${BLUE}Kiểm tra cập nhật...${NC}"
    response=$(curl -s $VERSION_API)
    latest_version=$(echo $response | jq -r '.version')
    min_supported_version=$(echo $response | jq -r '.min_supported_version')
    update_url=$(echo $response | jq -r '.update_url')
    maintenance_mode=$(echo $response | jq -r '.maintenance_mode')
    announcement=$(echo $response | jq -r '.announcement')

    if [ "$maintenance_mode" = true ]; then
        echo -e "${RED}Hệ thống đang trong chế độ bảo trì. Vui lòng thử lại sau.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}$announcement${NC}"

    if [[ "$SCRIPT_VERSION" < "$min_supported_version" ]]; then
        echo -e "${RED}Phiên bản script của bạn quá cũ và không còn được hỗ trợ.${NC}"
        echo -e "${RED}Vui lòng cập nhật lên phiên bản mới nhất tại: $update_url${NC}"
        exit 1
    elif [[ "$latest_version" > "$SCRIPT_VERSION" ]]; then
        echo -e "${YELLOW}Có phiên bản mới: $latest_version${NC}"
        echo -e "${YELLOW}Phiên bản hiện tại của bạn: $SCRIPT_VERSION${NC}"
        echo -e "${YELLOW}Vui lòng tải phiên bản mới tại: $update_url${NC}"
    else
        echo -e "${GREEN}Bạn đang sử dụng phiên bản mới nhất.${NC}"
    fi
}

# Hàm cài đặt các gói cần thiết
install_packages() {
    echo -e "${BLUE}Đang cài đặt các gói cần thiết...${NC}"
    pkg update -y
    pkg install -y python nodejs jq
    npm install -g http-server
    show_progress 5 10
    echo -e "${GREEN}Cài đặt hoàn tất!${NC}"
}

# Hàm chạy server
run_server() {
    echo -e "${BLUE}Đang chạy server...${NC}"
    
    # Tạo một trang HTML đơn giản
    cat > index.html << EOL
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TXA VLOG Server</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px; 
            background-color: #f0f0f0;
        }
        h1 { 
            color: #4CAF50; 
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
        }
        .container {
            background-color: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>TXA VLOG Server đang chạy!</h1>
        <p>Phiên bản: ${SCRIPT_VERSION}</p>
        <p>Năm: ${CURRENT_YEAR}</p>
    </div>
</body>
</html>
EOL
    
    # Lấy địa chỉ IP của thiết bị
    ip_address=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    
    # Chạy HTTP server trên cổng 8080
    http-server -p 8080 &
    
    echo -e "${GREEN}Server đang chạy tại:${NC}"
    echo -e "${YELLOW}HTTP Server: http://$ip_address:8080${NC}"
}

# Hàm xem changelog
view_changelog() {
    echo -e "${BLUE}Đang tải changelog...${NC}"
    response=$(curl -s $VERSION_API)
    changelog=$(echo $response | jq -r '.changelog')
    echo -e "${GREEN}Changelog:${NC}"
    echo "$changelog" | jq -r 'to_entries | .[] | "\(.key): \(.value)"'
}

# Chương trình chính
main() {
    while true; do
        show_banner
        show_menu
        read choice
        case $choice in
            1) check_update ;;
            2) install_packages ;;
            3) run_server ;;
            4) view_changelog ;;
            5) echo -e "${YELLOW}Cảm ơn bạn đã sử dụng TXA VLOG Server Script!${NC}"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}" ;;
        esac
        echo
        read -p "Nhấn Enter để tiếp tục..."
    done
}

# Chạy chương trình chính
main
