# ⚡ TXA CYBER-STUDIO SUITE (v3.0)

<div align="center">

```
████████╗██╗  ██╗ █████╗     ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗ 
╚══██╔══╝╚██╗██╔╝██╔══██╗    ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗
   ██║    ╚███╔╝ ███████║    ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║
   ██║    ██╔██╗ ██╔══██║    ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║
   ██║   ██╔╝ ██╗██║  ██║    ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ 
```

**Trạm Điều Khiển Di Động Termux Android • API Server Xác Thực Key Vercel • Cloudflare Tunnel Cho Máy Chủ Cục Bộ**

[![Platform](https://img.shields.io/badge/Platform-Termux%20Android-green?style=for-the-badge&logo=android)](https://termux.dev)
[![API Auth](https://img.shields.io/badge/API%20Auth-Vercel%20%E2%80%A2%20txastudio.click-black?style=for-the-badge&logo=vercel)](https://txastudio.click)
[![Script Tunnel](https://img.shields.io/badge/Script%20Tunnel-Cloudflare-orange?style=for-the-badge&logo=cloudflare)](https://cloudflare.com)
[![GitHub Pages](https://img.shields.io/badge/Auto--Update-GitHub%20Pages-blue?style=for-the-badge&logo=github)](https://txavl.github.io/Men1/)

</div>

---

## 🎯 Sơ Đồ Kiến Trúc Hệ Thống (Tách Biệt Rõ Ràng)

Hệ thống được chia làm **3 thành phần hoàn toàn độc lập**:

```
 1. API SERVER XÁC THỰC BẢN QUYỀN (Vercel / txastudio.click)
 ┌────────────────────────────────────────────────────────────────────────┐
 │ Thư mục: api/ (Chạy độc lập trên Vercel của domain txastudio.click)   │
 │ • https://txastudio.click/api/validate_key                             │
 │ • https://txastudio.click/api/verify_key                               │
 │ • https://txastudio.click/api/version                                  │
 └────────────────────────────────────────────────────────────────────────┘
                                     ▲
                     (Gửi curl kiểm tra bản quyền)
                                     │
 2. SCRIPT TRÊN ĐIỆN THOẠI TERMUX & CLOUDFLARE TUNNEL CỦA SCRIPT
 ┌────────────────────────────────────────────────────────────────────────┐
 │  server.js (Web Hub Cục Bộ Chạy Trên Termux - Port :2311)              │
 │  • Giám sát phần cứng: Pin %, Nhiệt độ, RAM, Dung lượng               │
 │  • Điều khiển Android: Đèn pin, Rung máy, Giọng nói TTS, Camera, Báo rung│
 │  • Trình tải video đa nền tảng yt-dlp & chia sẻ file $HOME/shared     │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │
                    (Được Tunnel đưa ra Internet)
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │  tunnel.sh (Cloudflare Tunnel của Script)                              │
 │  • Đưa Web Hub / Server trên điện thoại Termux ra ngoài Internet       │
 │  • Tạo Subdomain riêng (vd: hub.txastudio.click) hoặc Quick Tunnel     │
 └────────────────────────────────────────────────────────────────────────┘

 3. HAI MENU ĐỘC LẬP
 ┌──────────────────────────────────────┐  ┌──────────────────────────────┐
 │               menu.sh                │  │           menu1.sh           │
 │            (Menu Chính)              │  │      (Menu 1 Thử Nghiệm)     │
 │ • Xác thực key qua txastudio.click   │  │ • Chạy độc lập hoàn toàn     │
 │ • Điều khiển Web Hub & Tunnel script │  │ • Giữ nguyên luồng cập nhật  │
 │ • Tự update từ txavl.github.io/      │  │   từ txavl.github.io/        │
 │   Men1/menu.sh                       │  │   Men1/menu1.sh              │
 └──────────────────────────────────────┘  └──────────────────────────────┘
```

---

## 📂 Danh Sách Các Tệp Tin

| Tệp tin | Vai trò & Mục đích sử dụng |
|---|---|
| [api/validate_key.js](file:///c:/Users/admin/Desktop/Code/api/validate_key.js) | Serverless Function trên Vercel xử lý xác thực key cho `menu.sh`. |
| [api/verify_key.js](file:///c:/Users/admin/Desktop/Code/api/verify_key.js) | Serverless Function trên Vercel xử lý xác thực key cho `install.sh`. |
| [api/version.js](file:///c:/Users/admin/Desktop/Code/api/version.js) | Serverless Function trên Vercel trả về thông tin phiên bản mới nhất. |
| [server.js](file:///c:/Users/admin/Desktop/Code/server.js) | Máy chủ Web Hub & Điều Khiển Cục Bộ chạy trên điện thoại Termux (port 2311). |
| [tunnel.sh](file:///c:/Users/admin/Desktop/Code/tunnel.sh) | Script chạy Cloudflare Tunnel để đưa máy chủ cục bộ trên Termux ra ngoài Internet (gắn vào subdomain `*.txastudio.click` hoặc Quick Tunnel). |
| [menu.sh](file:///c:/Users/admin/Desktop/Code/menu.sh) | **Menu chính**: Giao tiếp với API xác thực `txastudio.click`, điều khiển phần cứng Termux:API, quản lý máy chủ cục bộ và tunnel. |
| [menu1.sh](file:///c:/Users/admin/Desktop/Code/menu1.sh) | **Menu 1 (Thử nghiệm & Demo riêng)**: Hoàn toàn độc lập, tự động cập nhật từ GitHub Pages `https://txavl.github.io/Men1/menu1.sh`. |
| [install.sh](file:///c:/Users/admin/Desktop/Code/install.sh) | Trình cài đặt tự động môi trường Termux và tạo lệnh gõ tắt `txa`. |

---

## ⚡ Hướng Dẫn Kích Hoạt API & Trang Quản Trị Admin Trên Vercel

Vì domain `txastudio.click` của bạn đã được trỏ về **Vercel**:
1. Đẩy các file trong thư mục [api/](file:///c:/Users/admin/Desktop/Code/api) và [vercel.json](file:///c:/Users/admin/Desktop/Code/vercel.json) lên dự án Vercel của bạn.
2. Vercel sẽ tự động tạo các endpoint:
   - **Trang Quản Trị Viên (Admin Panel):** 👉 `https://txastudio.click/api/admin` *(hoặc `/admin`)*
     * Có màn hình khóa bảo mật & ô nhập mật khẩu admin: `txa_admin_2026`
     * **Quản lý Key:** Xem danh sách, tạo key mới, khóa/mở khóa key tức thì.
     * **Báo cáo Crash/Lỗi:** Hiển thị chi tiết thiết bị thật (Samsung S23, Xiaomi, Android 14, mức Pin, IP, Key nhập sai, Stack trace lỗi).
   - **API Xác thực Key:** `https://txastudio.click/api/validate_key`
   - **API Kiểm tra Version:** `https://txastudio.click/api/version`

---

## 🌐 Hướng Dẫn Sử Dụng Cloudflare Tunnel Cho Server Termux

Cloudflare Tunnel trong dự án này dùng để **đưa Web Hub trên điện thoại ra Internet**:

### Chế độ 1: Quick Tunnel (Dùng ngay trong 3 giây)
- Vào Menu ➔ Chọn mục Tunnel ➔ Bật Quick Tunnel.
- Cloudflare sẽ cấp một URL ngẫu nhiên `https://xxxx.trycloudflare.com` có HTTPS để bạn truy cập vào Web Hub trên điện thoại.

### Chế độ 2: Subdomain riêng (*.txastudio.click)
- Tạo một Tunnel trên [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) trỏ subdomain (ví dụ: `hub.txastudio.click` hoặc `phone.txastudio.click`) về `http://localhost:2311`.
- Lấy chuỗi **Token** dán vào `tunnel.sh` trên Termux.
- Máy chủ điện thoại của bạn sẽ online tại `https://hub.txastudio.click`!

---

## 🚀 Cài Đặt Trên Termux

```bash
pkg update -y && pkg install -y git
git clone https://github.com/TXAVL/Men1.git ~/Men1
cd ~/Men1
chmod +x *.sh
./install.sh
```

- Mở Menu chính: gõ `txa` hoặc `./menu.sh`
- Mở Menu 1 thử nghiệm: gõ `./menu1.sh`
