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

**Biến thiết bị Android Termux thành Trạm Máy Chủ Di Động & Trung Tâm Điều Khiển Cyberpunk**

[![Platform](https://img.shields.io/badge/Platform-Termux%20Android-green?style=for-the-badge&logo=android)](https://termux.dev)
[![Engine](https://img.shields.io/badge/Engine-TXA%20Studio-blue?style=for-the-badge)](https://txastudio.click)
[![Tunnel](https://img.shields.io/badge/Tunnel-Cloudflare-orange?style=for-the-badge&logo=cloudflare)](https://cloudflare.com)
[![Auto-Update](https://img.shields.io/badge/Auto--Update-GitHub%20Pages-lightgrey?style=for-the-badge&logo=github)](https://txavl.github.io/Men1/)

</div>

---

## 🌟 Giới Thiệu Tổng Quan

**TXA Cyber-Studio** là bộ công cụ tối thượng dành cho người dùng **Termux trên Android**. Hệ thống giúp biến chiếc điện thoại của bạn thành một trạm máy chủ cá nhân mạnh mẽ, tận dụng tối đa đặc quyền phần cứng và cho phép kết nối điều khiển từ xa qua Internet an toàn với Cloudflare Tunnel.

### ✨ Các Tính Năng Nổi Bật:
1. **📱 Đặc Quyền Phần Cứng Android (Termux:API):**
   - Bật / Tắt đèn pin (Flashlight Torch) từ xa.
   - Rung phản hồi xúc giác (Haptic Vibrate).
   - Trợ lý giọng nói Text-To-Speech (phát âm tiếng Việt to rõ trực tiếp từ loa máy).
   - Bắn thông báo Push Notification lên thanh trạng thái Android.
   - Chụp ảnh camera trước/sau, định vị tọa độ GPS.
   - Giám sát cảm biến thời gian thực: % Pin, nguồn sạc, nhiệt độ chip, RAM, bộ nhớ.
2. **🚀 Web Hub Cục Bộ (:2311):**
   - Bảng điều khiển giao diện Cyberpunk Neon Glassmorphism xem được trên cả máy tính và điện thoại.
   - Tích hợp trình quản lý và tải file chia sẻ trong `$HOME/shared`.
3. **🌐 Cloudflare Tunnel Tích Hợp Sẵn:**
   - Đưa máy chủ Web Hub trên điện thoại ra toàn cầu qua Quick Tunnel (`trycloudflare.com`) hoặc Subdomain riêng chỉ với 1 cú click.
4. **📥 Trình Tải Media Đa Nền Tảng (yt-dlp + ffmpeg):**
   - Tải video MP4 Full HD hoặc tách nhạc MP3 từ YouTube, TikTok không logo, Facebook... lưu thẳng vào bộ nhớ máy.
5. **🔍 Công Cụ Mạng & Bảo Mật:**
   - Quét cổng mạng Nmap, kiểm tra thông tin ISP & IP công khai, kiểm tra độ trễ Ping.

---

## 🎯 Kiến Trúc Hoạt Động

```
  ┌─────────────────────────────────┐
  │   THIẾT BỊ ANDROID (TERMUX)     │
  │   • Quản lý phần cứng           │
  │   • Web Hub cục bộ (:2311)      │
  │   • Tải video, chia sẻ file     │
  └────────────────┬────────────────┘
                   │
                   ▼ (Qua tunnel.sh)
  ┌─────────────────────────────────┐
  │   CLOUDFLARE SECURE TUNNEL      │
  │   • Mã hóa SSL HTTPS tự động    │
  │   • Quick Tunnel / Subdomain    │
  └────────────────┬────────────────┘
                   │
                   ▼
  ┌─────────────────────────────────┐
  │  TRUY CẬP ĐIỀU KHIỂN TỪ XA      │
  │  (Máy tính, Laptop, Điện thoại) │
  └─────────────────────────────────┘
```

---

## 🚀 Cài Đặt Nhanh 1-Chạm Trên Termux (Copy & Dán)

Mở ứng dụng Termux và dán một dòng lệnh duy nhất này vào để cài đặt tự động:

```bash
pkg update -y && pkg install -y git && git clone https://github.com/TXAVL/Men1.git ~/Men1 && cd ~/Men1 && chmod +x *.sh && ./install.sh
```

---

### Hoặc Cài Đặt Từng Bước (Nếu muốn xem chi tiết):

```bash
pkg update -y && pkg install -y git
git clone https://github.com/TXAVL/Men1.git ~/Men1
cd ~/Men1
chmod +x *.sh
./install.sh
```

> **Mẹo:** Sau khi cài đặt hoàn tất, bạn chỉ cần gõ lệnh sau ở bất kỳ đâu trong Termux để mở Menu:
> ```bash
> txa
> ```

---

## 📂 Danh Mục Các Tệp Tin Trong Repo

| Tệp tin | Chức năng & Vai trò |
|---|---|
| [install.sh](file:///c:/Users/admin/Desktop/Code/install.sh) | Trình cài đặt tự động 1-chạm: Kiểm tra máy, cài các gói cần thiết, tạo lệnh gọi nhanh `txa`. |
| [menu.sh](file:///c:/Users/admin/Desktop/Code/menu.sh) | **Menu chính nâng cao**: Điều khiển phần cứng Android, chạy Web Hub, kích hoạt Cloudflare Tunnel và quét mạng. |
| [menu1.sh](file:///c:/Users/admin/Desktop/Code/menu1.sh) | **Menu 1 (Thử nghiệm & Demo riêng)**: Menu độc lập, có cơ chế tự động kiểm tra và tải cập nhật từ GitHub Pages. |
| [server.js](file:///c:/Users/admin/Desktop/Code/server.js) | Máy chủ Web Hub điều khiển thiết bị chạy trên cổng 2311 của Termux. |
| [tunnel.sh](file:///c:/Users/admin/Desktop/Code/tunnel.sh) | Công cụ Cloudflare Tunnel giúp đưa Web Hub trên điện thoại ra ngoài Internet. |

---

## 🌐 Hướng Dẫn Sử Dụng Cloudflare Tunnel Cho Web Hub

Khi bạn muốn truy cập Web Hub trên điện thoại từ máy tính hoặc chia sẻ cho bạn bè:

* **Chế độ 1: Quick Tunnel (Dùng ngay lập tức)**
  - Trong Menu ➔ Chọn mục **Quản lý Cloudflare Tunnel** ➔ Bật **Quick Tunnel**.
  - Hệ thống sẽ cấp cho bạn một đường link bảo mật có đuôi `https://xxxx.trycloudflare.com` để mở giao diện Web Hub.
* **Chế độ 2: Tên miền / Subdomain riêng**
  - Hỗ trợ kết nối với Cloudflare Zero Trust qua Token để gán cố định vào tên miền riêng của bạn.

---

## 🔑 Kích Hoạt Bản Quyền & Mua Key VIP

Để mở khóa toàn bộ các tính năng nâng cao (Nmap, điều khiển phần cứng từ xa, tải media tốc độ cao):

1. **Mua Key Bản Quyền Chính Thức (VietQR Tự Động):**
   - Truy cập cổng mua Key VIP chính thức: 👉 **[https://txastudio.click/buy-key](https://txastudio.click/buy-key)**
   - Hỗ trợ thanh toán VietQR chuyển khoản ngân hàng tự động, upload biên lai và nhận Key VIP kích hoạt tức thì.
2. **Nhập Key:**
   - Trong Menu chính, chọn mục **[2] Nhập Key Bản Quyền**.
   - Dán mã key của bạn vào và nhấn Enter. Hệ thống sẽ tự động xác thực và kích hoạt vĩnh viễn trên thiết bị của bạn.

---

## 📱 Quyền Truy Cập Bộ Nhớ & Termux:API

1. **Cấp Quyền Bộ Nhớ Ngoài (Storage):**
   - Bộ cài đặt tự động yêu cầu quyền bộ nhớ thông qua `termux-setup-storage`.
   - Vui lòng bấm **"Cho phép" (Allow)** trên cửa sổ thông báo của Android để script lưu video tải về và ảnh chụp vào bộ nhớ máy (`$HOME/storage/shared`).
2. **Kích Hoạt Điều Khiển Phần Cứng (Termux:API):**
   - Tải và cài đặt ứng dụng bổ trợ **[Termux:API (file APK trên F-Droid)](https://f-droid.org/packages/com.termux.api/)**.
   - Vào Cài đặt điện thoại ➔ Quản lý ứng dụng ➔ **Termux:API** ➔ Cấp quyền: **Camera, Vị trí (Location), Thông báo (Notification)**.

---

<div align="center">

**Bản quyền © 2026 [TXA Studio](https://txastudio.click) • Mọi quyền được bảo lưu.**

</div>
