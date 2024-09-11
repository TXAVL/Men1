#!/data/data/com.termux/files/usr/bin/bash

# Tạo thư mục log nếu không tồn tại
LOG_DIR="/storage/emulated/0/Log"
LOG_FILE="$LOG_DIR/open.txa.log"
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# Kiểm tra và cài đặt các gói cần thiết
check_and_install_packages() {
    packages="wget curl unzip"
    missing_packages=""
    echo "Đang kiểm tra các gói cần thiết..."
    for pkg in $packages; do
        if ! command -v $pkg > /dev/null 2>&1; then
            missing_packages="$missing_packages $pkg"
        fi
    done
    if [ -n "$missing_packages" ]; then
        echo "Các gói sau đây chưa được cài đặt:$missing_packages"
        echo "Đang cài đặt các gói thiếu..."
        pkg install -y $missing_packages
        echo "Cài đặt hoàn tất. Nhấn phím bất kỳ để quay lại menu chính."
    else
        echo "Tất cả các gói cần thiết đã được cài đặt."
        echo "Nhấn phím bất kỳ để quay lại menu chính."
    fi
    read -n 1
}

# Tải file APK từ MediaFire
download_apk() {
    read -p "Nhập URL MediaFire của file APK: " url
    read -p "Nhập tên file để lưu (ví dụ: app.apk): " output
    echo "Đang tải file từ $url..."
    wget "$url" -O "$output"
    if [ $? -eq 0 ]; then
        echo "Tải file thành công: $output"
    else
        echo "Lỗi khi tải file."
    fi
    echo "Nhấn phím bất kỳ để quay lại menu chính."
    read -n 1
}

# Mở ứng dụng Free Fire Max nếu đã cài đặt và ghi log nếu lỗi
open_app() {
    echo "Đang cố gắng mở ứng dụng Free Fire Max..."
    if command -v am > /dev/null 2>&1; then
        am start -n com.dts.freefiremax/com.dts.freefiremax.ui.activities.MainActivity
        if [ $? -eq 0 ]; then
            echo "Ứng dụng Free Fire Max đã được mở nếu nó đã được cài đặt."
        else
            echo "Không thể mở ứng dụng Free Fire Max. Ghi lỗi vào log."
            echo "$(date): Không thể mở Free Fire Max" >> "$LOG_FILE"
        fi
    else
        echo "Lệnh am không có sẵn. Ghi lỗi vào log."
        echo "$(date): Lệnh am không có sẵn" >> "$LOG_FILE"
    fi
    echo "Nhấn phím bất kỳ để quay lại menu chính."
    read -n 1
}

# Hiển thị tiêu đề menu
show_menu() {
    clear
    echo -e "\033[1;32mMode menu by TXA\033[0m"
    echo "1. How to guide"
    echo "2. Check and install necessary packages"
    echo "3. Download APK from MediaFire"
    echo "4. Open Free Fire Max"
    echo "0. Exit"
}

# Hiển thị hướng dẫn
show_guide() {
    clear
    echo -e "\033[1;34m--- How to Guide ---\033[0m"
    echo -e "\033[1;33m1. Mở ứng dụng Termux.\033[0m"
    echo -e "\033[1;32m2. Chạy lệnh tương ứng để thực hiện các chức năng.\033[0m"
    echo -e "\033[1;36m3. Xem tài liệu hướng dẫn chi tiết tại trang web của chúng tôi.\033[0m"
    echo -e "\033[1;31m--- Bản quyền thuộc về TXA ---\033[0m"
    echo ""
    echo "Nhấn phím bất kỳ để quay lại menu chính."
    read -n 1
}

# Hàm để chạy menu chính
main_menu() {
    while true; do
        show_menu
        read -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                show_guide
                ;;
            2)
                check_and_install_packages
                ;;
            3)
                download_apk
                ;;
            4)
                open_app
                ;;
            0)
                echo "Thoát chương trình."
                exit 0
                ;;
            *)
                echo "Tùy chọn không hợp lệ. Vui lòng chọn lại."
                echo "Nhấn phím bất kỳ để quay lại menu chính."
                read -n 1
                ;;
        esac
    done
}

# Chạy menu chính
main_menu
