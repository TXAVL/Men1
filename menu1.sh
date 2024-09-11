#!/bin/bash

# Đường dẫn đến file chứa phiên bản hiện tại
VERSION_FILE="$HOME/.txa_version"

# URL tải script từ server
SCRIPT_URL="https://txavl.github.io/Men1/menu1.sh"

# Phiên bản hiện tại của script
VERSION="1.1.0"

# Màu sắc cho thông báo
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Không màu

# Hàm so sánh phiên bản
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
    
    # Tải script mới về tệp tạm thời
    if curl -s "$SCRIPT_URL" -o "$temp_file"; then
        local latest_version=$(grep "^VERSION=" "$temp_file" | cut -d'"' -f2)
        
        # Kiểm tra nếu không thể tìm thấy phiên bản mới
        if [[ -z "$latest_version" ]]; then
            echo -e "${RED}Không thể xác định phiên bản mới từ server.${NC}"
            rm -f "$temp_file"
            return
        fi
        
        # So sánh phiên bản hiện tại và phiên bản mới
        if version_greater "$latest_version" "$current_version"; then
            echo -e "${GREEN}Có phiên bản mới: $latest_version${NC}"
            read -p "Bạn có muốn cập nhật không? (y/n): " choice
            if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                mv "$temp_file" "$0"
                chmod +x "$0"
                echo "$latest_version" > "$VERSION_FILE"
                echo -e "${GREEN}Đã cập nhật script. Vui lòng chạy lại.${NC}"
                exit 0
            fi
        else
            echo -e "${GREEN}Bạn đang sử dụng phiên bản mới nhất.${NC}"
        fi
    else
        echo -e "${RED}Không thể kiểm tra cập nhật. Vui lòng thử lại sau.${NC}"
    fi
    rm -f "$temp_file"
}

# Hàm chính để chạy script
main() {
    echo -e "${GREEN}Chào mừng đến với script v${VERSION}${NC}"
    
    # Kiểm tra cập nhật trước khi chạy
    check_update
    
    # Thêm các lệnh chính tại đây
    echo -e "${YELLOW}Script đang chạy...${NC}"
    # Ví dụ: kiểm tra các gói đã cài đặt hoặc thực hiện các tác vụ khác

    echo -e "${GREEN}Hoàn thành công việc.${NC}"
}

# Chạy hàm chính
main
