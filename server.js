/**
 * ==============================================================================
 * TXA CYBER-STUDIO HUB - TERMUX LOCAL SERVER & WEB CONTROL PANEL (v3.0)
 * ==============================================================================
 * Máy chủ cục bộ chạy trên Termux (Android) - Được đưa ra ngoài Internet bằng Cloudflare Tunnel
 * Tính năng:
 * - Điều khiển phần cứng Android từ xa (Đèn pin, Rung, Giọng nói TTS, Camera, Thông báo)
 * - Giám sát Telemetry điện thoại: Pin %, Nhiệt độ máy, RAM, Dung lượng
 * - Trình tải Video đa nền tảng yt-dlp + ffmpeg
 * - Quản lý tệp tin và tải file từ xa ($HOME/shared/downloads)
 * ==============================================================================
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');
const url = require('url');

const PORT = process.env.PORT || 2311;
const HOME = process.env.HOME || process.cwd();
const SHARED_DIR = path.join(HOME, 'shared');
const DOWNLOAD_DIR = path.join(SHARED_DIR, 'downloads');
const TUNNEL_URL_FILE = path.join(HOME, '.txa_tunnel.url');

if (!fs.existsSync(SHARED_DIR)) fs.mkdirSync(SHARED_DIR, { recursive: true });
if (!fs.existsSync(DOWNLOAD_DIR)) fs.mkdirSync(DOWNLOAD_DIR, { recursive: true });

let downloadTasks = [];

function runCmd(cmd) {
    return new Promise((resolve) => {
        exec(cmd, { timeout: 10000 }, (error, stdout, stderr) => {
            if (error) {
                resolve({ success: false, output: stderr || error.message });
            } else {
                resolve({ success: true, output: stdout.trim() });
            }
        });
    });
}

async function getBatteryInfo() {
    try {
        const res = await runCmd('termux-battery-status');
        if (res.success && res.output) {
            return JSON.parse(res.output);
        }
    } catch (e) {}
    return { percentage: 100, status: 'Plugged / Emulated', health: 'GOOD', temperature: 300 };
}

async function getDiskUsage() {
    const res = await runCmd(`df -h ${HOME} | awk 'NR==2 {print $2, $3, $4, $5}'`);
    if (res.success && res.output) {
        const parts = res.output.split(/\s+/);
        return { total: parts[0] || 'N/A', used: parts[1] || 'N/A', free: parts[2] || 'N/A', percent: parts[3] || 'N/A' };
    }
    return { total: 'N/A', used: 'N/A', free: 'N/A', percent: 'N/A' };
}

function getTunnelUrl() {
    try {
        if (fs.existsSync(TUNNEL_URL_FILE)) {
            const content = fs.readFileSync(TUNNEL_URL_FILE, 'utf8').trim();
            if (content) return content;
        }
    } catch (e) {}
    return null;
}

const server = http.createServer(async (req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;

    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    // 1. API: Telemetry & Trạng thái phần cứng
    if (pathname === '/api/status' && req.method === 'GET') {
        const battery = await getBatteryInfo();
        const disk = await getDiskUsage();
        const tunnelUrl = getTunnelUrl();
        const totalMem = (os.totalmem() / 1024 / 1024 / 1024).toFixed(2);
        const freeMem = (os.freemem() / 1024 / 1024 / 1024).toFixed(2);
        const usedMem = (totalMem - freeMem).toFixed(2);

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
            hostname: os.hostname(),
            platform: os.platform(),
            arch: os.arch(),
            uptime: Math.floor(os.uptime()),
            cpu: os.cpus()[0] ? os.cpus()[0].model : 'ARM64 Octa-Core',
            memory: { total: totalMem + ' GB', free: freeMem + ' GB', used: usedMem + ' GB' },
            battery,
            disk,
            tunnelUrl: tunnelUrl || 'Chưa khởi chạy Cloudflare Tunnel',
            port: PORT
        }));
        return;
    }

    // 2. API: Tương tác phần cứng Termux:API
    if (pathname === '/api/action' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', async () => {
            try {
                const data = JSON.parse(body || '{}');
                let cmd = '';

                switch (data.action) {
                    case 'torch_on':
                        cmd = 'termux-torch on';
                        break;
                    case 'torch_off':
                        cmd = 'termux-torch off';
                        break;
                    case 'vibrate':
                        cmd = `termux-vibrate -d ${parseInt(data.duration) || 500}`;
                        break;
                    case 'tts':
                        const text = (data.text || 'Xin chào từ TXA Studio').replace(/"/g, '\\"');
                        cmd = `termux-tts-speak "${text}"`;
                        break;
                    case 'notify':
                        const title = (data.title || 'TXA Studio Alert').replace(/"/g, '\\"');
                        const content = (data.content || 'Thông báo từ máy chủ').replace(/"/g, '\\"');
                        cmd = `termux-notification -t "${title}" -c "${content}" --vibrate 500`;
                        break;
                    case 'camera_photo':
                        const photoName = `photo_${Date.now()}.jpg`;
                        const photoPath = path.join(DOWNLOAD_DIR, photoName);
                        cmd = `termux-camera-photo -c 0 "${photoPath}"`;
                        break;
                    default:
                        res.writeHead(400, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ error: 'Hành động không hợp lệ' }));
                        return;
                }

                const result = await runCmd(cmd);
                res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
                res.end(JSON.stringify({ success: true, action: data.action, output: result.output }));
            } catch (err) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: err.message }));
            }
        });
        return;
    }

    // 3. API: Tải Media qua yt-dlp
    if (pathname === '/api/download' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', async () => {
            try {
                const data = JSON.parse(body || '{}');
                const mediaUrl = data.url;
                const isAudio = data.format === 'audio';

                if (!mediaUrl) {
                    res.writeHead(400, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'URL không được để trống' }));
                    return;
                }

                const taskId = Date.now().toString();
                const task = { id: taskId, url: mediaUrl, status: 'Đang tải...', time: new Date().toLocaleTimeString() };
                downloadTasks.unshift(task);

                const formatFlag = isAudio ? '-x --audio-format mp3' : '-f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"';
                const outputTemplate = path.join(DOWNLOAD_DIR, '%(title).60s.%(ext)s');
                const dlCmd = `yt-dlp ${formatFlag} -o "${outputTemplate}" "${mediaUrl}"`;

                exec(dlCmd, (err, stdout, stderr) => {
                    const target = downloadTasks.find(t => t.id === taskId);
                    if (target) target.status = err ? 'Lỗi tải: ' + (stderr || err.message).slice(0, 80) : 'Hoàn tất!';
                });

                res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
                res.end(JSON.stringify({ success: true, taskId, message: 'Đã bắt đầu tải về thiết bị' }));
            } catch (err) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: err.message }));
            }
        });
        return;
    }

    // 4. API: Quản lý File trong $HOME/shared/downloads
    if (pathname === '/api/files' && req.method === 'GET') {
        try {
            const files = fs.readdirSync(DOWNLOAD_DIR).map(f => {
                const fullPath = path.join(DOWNLOAD_DIR, f);
                const stat = fs.statSync(fullPath);
                return {
                    name: f,
                    size: (stat.size / 1024 / 1024).toFixed(2) + ' MB',
                    time: stat.mtime.toLocaleString()
                };
            });
            res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
            res.end(JSON.stringify(files));
        } catch (e) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify([]));
        }
        return;
    }

    // Tải file trực tiếp
    if (pathname.startsWith('/api/files/download/')) {
        const fileName = path.basename(decodeURIComponent(pathname.replace('/api/files/download/', '')));
        const filePath = path.join(DOWNLOAD_DIR, fileName);
        if (fs.existsSync(filePath)) {
            res.writeHead(200, {
                'Content-Disposition': `attachment; filename="${fileName}"`,
                'Content-Type': 'application/octet-stream'
            });
            fs.createReadStream(filePath).pipe(res);
            return;
        } else {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('File không tồn tại');
            return;
        }
    }

    // Giao diện Cyberpunk Web Dashboard
    if (pathname === '/' || pathname === '/index.html') {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(renderDashboardHtml());
        return;
    }

    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('404 Not Found - TXA Local Hub');
});

function renderDashboardHtml() {
    return `<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TXA CYBER-STUDIO HUB | Termux Remote Panel</title>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@500;700;900&family=Rajdhani:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-deep: #060913;
            --panel-bg: rgba(13, 20, 36, 0.8);
            --card-border: rgba(0, 243, 255, 0.25);
            --cyan: #00f3ff;
            --magenta: #ff0055;
            --green: #00ff88;
            --yellow: #ffd000;
            --text-main: #f0f6fc;
            --text-dim: #8b9bb4;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background-color: var(--bg-deep);
            background-image: 
                radial-gradient(circle at 15% 20%, rgba(0, 243, 255, 0.08) 0%, transparent 40%),
                radial-gradient(circle at 85% 80%, rgba(255, 0, 85, 0.08) 0%, transparent 40%);
            color: var(--text-main);
            font-family: 'Rajdhani', sans-serif;
            min-height: 100vh;
            padding: 20px;
        }
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--card-border);
            padding-bottom: 15px;
            margin-bottom: 25px;
            flex-wrap: wrap;
            gap: 15px;
        }
        .brand { display: flex; align-items: center; gap: 15px; }
        .logo-box {
            background: linear-gradient(135deg, var(--cyan), var(--magenta));
            padding: 8px 14px;
            border-radius: 8px;
            font-family: 'Orbitron', monospace;
            font-weight: 900;
            font-size: 1.2rem;
            color: #000;
        }
        h1 { font-family: 'Orbitron', sans-serif; font-size: 1.35rem; color: var(--cyan); text-shadow: 0 0 10px rgba(0, 243, 255, 0.4); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px; }
        .card {
            background: var(--panel-bg);
            border: 1px solid var(--card-border);
            border-radius: 12px;
            padding: 20px;
            backdrop-filter: blur(16px);
        }
        .card-title { font-family: 'Orbitron', sans-serif; font-size: 1.05rem; color: var(--cyan); margin-bottom: 15px; }
        .stat-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .stat-box { background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.07); border-radius: 8px; padding: 10px; }
        .stat-label { font-size: 0.75rem; color: var(--text-dim); text-transform: uppercase; }
        .stat-value { font-size: 1.15rem; font-weight: 700; color: var(--text-main); margin-top: 4px; }
        .btn-group { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 10px; }
        button {
            background: rgba(0, 243, 255, 0.1);
            color: var(--cyan);
            border: 1px solid var(--cyan);
            border-radius: 6px;
            padding: 9px 16px;
            font-family: 'Rajdhani', sans-serif;
            font-size: 0.95rem;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
        }
        button:hover { background: var(--cyan); color: #000; box-shadow: 0 0 15px rgba(0, 243, 255, 0.5); }
        button.btn-danger { background: rgba(255, 0, 85, 0.1); color: var(--magenta); border-color: var(--magenta); }
        button.btn-danger:hover { background: var(--magenta); color: #fff; }
        input, select {
            width: 100%;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 6px;
            padding: 10px 12px;
            color: #fff;
            font-family: inherit;
            margin-bottom: 10px;
            outline: none;
        }
        .tunnel-box {
            background: rgba(0, 255, 136, 0.08);
            border: 1px solid var(--green);
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 15px;
            word-break: break-all;
        }
        .file-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px;
            background: rgba(255, 255, 255, 0.02);
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }
    </style>
</head>
<body>
    <header>
        <div class="brand">
            <div class="logo-box">TXA</div>
            <div>
                <h1>TERMUX CYBER-HUB</h1>
                <div style="font-size:0.85rem; color:var(--text-dim);">Máy Chủ Cục Bộ Điều Khiển Thiết Bị Android Qua Tunnel</div>
            </div>
        </div>
        <div>
            <span style="color:var(--green); font-weight:700;">⚡ CLOUDFLARE TUNNEL LIVE</span>
        </div>
    </header>

    <div class="grid">
        <div class="card">
            <div class="card-title">📊 TELEMETRY PHẦN CỨNG</div>
            <div class="stat-grid">
                <div class="stat-box">
                    <div class="stat-label">PIN MÁY</div>
                    <div class="stat-value" id="s-bat" style="color:var(--green);">--%</div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">NHIỆT ĐỘ</div>
                    <div class="stat-value" id="s-temp" style="color:var(--yellow);">--°C</div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">RAM</div>
                    <div class="stat-value" id="s-ram">--</div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">BỘ NHỚ TRỐNG</div>
                    <div class="stat-value" id="s-disk">--</div>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-title">📱 ĐIỀU KHIỂN THIẾT BỊ ANDROID</div>
            <div class="btn-group">
                <button onclick="sendAction('torch_on')">🔦 Bật Đèn Pin</button>
                <button class="btn-danger" onclick="sendAction('torch_off')">💡 Tắt Đèn Pin</button>
                <button onclick="sendAction('vibrate', { duration: 600 })">📳 Rung Máy</button>
                <button onclick="sendAction('camera_photo')">📸 Chụp Ảnh Cam</button>
            </div>
            <div style="margin-top:12px;">
                <input type="text" id="tts-input" value="Xin chào từ TXA Cyber Studio">
                <button onclick="sendTTS()">🗣️ Đọc Tiếng Việt (TTS)</button>
            </div>
        </div>

        <div class="card">
            <div class="card-title">🌐 CLOUDFLARE TUNNEL CỦA SCRIPT</div>
            <div class="tunnel-box">
                <div style="font-size:0.75rem; color:var(--text-dim);">LINK TRUY CẬP TỪ XA:</div>
                <strong id="t-url" style="color:var(--cyan); font-size:1.05rem;">Đang tải...</strong>
            </div>
            <button onclick="window.open(document.getElementById('t-url').innerText, '_blank')">🚀 Mở Trong Tab Mới</button>
        </div>

        <div class="card">
            <div class="card-title">📥 TRÌNH TẢI VIDEO YT-DLP</div>
            <input type="text" id="dl-url" placeholder="Dán URL YouTube, TikTok, Facebook...">
            <div style="display:flex; gap:10px;">
                <select id="dl-fmt">
                    <option value="video">🎬 Video MP4</option>
                    <option value="audio">🎵 Tách Nhạc MP3</option>
                </select>
                <button onclick="startDL()" style="flex:1;">⬇️ Tải Về Máy</button>
            </div>
        </div>

        <div class="card" style="grid-column: 1 / -1;">
            <div class="card-title">📁 TỆP TIN ĐÃ TẢI VỀ THIẾT BỊ ($HOME/shared/downloads)</div>
            <button onclick="loadFiles()" style="margin-bottom:10px;">🔄 Làm Mới Tệp</button>
            <div id="file-list"></div>
        </div>
    </div>

    <script>
        async function fetchStatus() {
            try {
                const res = await fetch('/api/status');
                const d = await res.json();
                document.getElementById('s-bat').innerText = (d.battery.percentage || 100) + '%';
                document.getElementById('s-temp').innerText = (d.battery.temperature ? (d.battery.temperature / 10).toFixed(1) : 32) + '°C';
                document.getElementById('s-ram').innerText = d.memory.used + ' / ' + d.memory.total;
                document.getElementById('s-disk').innerText = d.disk.free;
                document.getElementById('t-url').innerText = d.tunnelUrl || window.location.origin;
            } catch(e) {}
        }

        async function sendAction(action, extra = {}) {
            await fetch('/api/action', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ action, ...extra })
            });
            alert('Đã gửi lệnh: ' + action);
        }

        function sendTTS() {
            const text = document.getElementById('tts-input').value;
            sendAction('tts', { text });
        }

        async function startDL() {
            const url = document.getElementById('dl-url').value;
            const format = document.getElementById('dl-fmt').value;
            if(!url) return alert('Nhập URL!');
            await fetch('/api/download', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ url, format })
            });
            alert('Đang tải trong nền!');
            setTimeout(loadFiles, 4000);
        }

        async function loadFiles() {
            const res = await fetch('/api/files');
            const files = await res.json();
            const box = document.getElementById('file-list');
            if(!files.length) { box.innerHTML = '<div style="color:#888;">Chưa có tệp nào.</div>'; return; }
            box.innerHTML = files.map(f => \`
                <div class="file-item">
                    <div><strong>\${f.name}</strong> (\${f.size})</div>
                    <a href="/api/files/download/\${encodeURIComponent(f.name)}" style="color:var(--cyan); text-decoration:none; font-weight:700;">⬇️ Tải về máy</a>
                </div>
            \`).join('');
        }

        fetchStatus();
        loadFiles();
        setInterval(fetchStatus, 5000);
    </script>
</body>
</html>`;
}

server.listen(PORT, '0.0.0.0', () => {
    console.log(`====================================================`);
    console.log(`📱 TXA LOCAL HUB CHẠY TRÊN TERMUX TẠI CỔNG: ${PORT}`);
    console.log(`🔗 Local Address: http://localhost:${PORT}`);
    console.log(`🌐 Dùng tunnel.sh để broadcast ra Internet qua Cloudflare`);
    console.log(`====================================================`);
});
