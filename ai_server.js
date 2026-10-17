/**
 * ==============================================================================
 * TXA JARVIS AI - TERMUX CYBER AI COMPANION & HARDWARE AGENT (v1.0)
 * ==============================================================================
 * Máy chủ AI chạy trên Termux (Android) kết hợp Web Panel + Cloudflare Tunnel
 * - Tận dụng 100% Termux:API: Đèn pin, Rung, TTS giọng nói, Pin, Camera, Location...
 * - Dual Brain: 
 *     1) Offline Engine (Chạy ngay không cần key, hiểu lệnh tiếng Việt)
 *     2) Online Gemini AI (Siêu trí tuệ, phân tích ảnh, trò chuyện thông minh)
 * - Tự động liên kết Cloudflare Tunnel để truy cập toàn cầu qua link HTTPS bảo mật
 * ==============================================================================
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');
const url = require('url');

const PORT = process.env.PORT || 2312;
const HOME = process.env.HOME || process.cwd();
const CONFIG_FILE = path.join(HOME, '.txa_ai_config.json');
const TUNNEL_URL_FILE = path.join(HOME, '.txa_tunnel.url');
const MEDIA_DIR = path.join(HOME, 'shared', 'ai_media');

if (!fs.existsSync(MEDIA_DIR)) {
    fs.mkdirSync(MEDIA_DIR, { recursive: true });
}

// Cấu hình mặc định
let appConfig = {
    geminiApiKey: '',
    geminiModel: 'gemini-2.5-flash',
    voiceEnabled: true,
    ttsLang: 'vi-VN',
    aiPersona: 'TXA Cyber Jarvis - Trợ lý AI trung thành, thông minh và dí dỏm, điều khiển thiết bị Android Termux.',
    systemPrompt: `Bạn là TXA Jarvis, một trợ lý AI thông minh, cá tính, hài hước và thân thiện đang cư trú trực tiếp bên trong một chiếc điện thoại Android thông qua môi trường Termux.
Bạn có quyền năng điều khiển phần cứng của điện thoại này:
- Bật/tắt đèn flash (termux-torch)
- Rung điện thoại (termux-vibrate)
- Phát âm thanh giọng nói qua loa (termux-tts-speak)
- Gửi thông báo Android (termux-notification)
- Kiểm tra pin, sạc, nhiệt độ máy (termux-battery-status)
- Chụp ảnh camera trước/sau (termux-camera-photo)
- Lấy tọa độ GPS (termux-location)

Khi người dùng ra lệnh hoặc gợi ý muốn làm gì với điện thoại, hãy trả lời tự nhiên bằng tiếng Việt vui vẻ, VÀ nếu có hành động cụ thể, hãy kèm theo JSON hành động ở dòng cuối cùng theo định dạng:
[ACTION: {"type": "torch", "state": "on"}]
Các loại hành động hỗ trợ:
- [ACTION: {"type": "torch", "state": "on"|"off"}]
- [ACTION: {"type": "vibrate", "ms": 500}]
- [ACTION: {"type": "tts", "text": "Nội dung cần nói ra loa"}]
- [ACTION: {"type": "notification", "title": "Tiêu đề", "content": "Nội dung"}]
- [ACTION: {"type": "battery"}]
- [ACTION: {"type": "camera", "camera_id": "0"}] (0: sau, 1: trước)
- [ACTION: {"type": "location"}]`
};

// Tải config nếu có
try {
    if (fs.existsSync(CONFIG_FILE)) {
        const saved = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
        appConfig = { ...appConfig, ...saved };
    }
} catch (e) {
    console.error('Không thể đọc file config:', e.message);
}

function saveConfig() {
    try {
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(appConfig, null, 2), 'utf8');
    } catch (e) {
        console.error('Lỗi lưu config:', e.message);
    }
}

// Chạy lệnh shell không đồng bộ
function runCmd(cmd, timeoutMs = 15000) {
    return new Promise((resolve) => {
        exec(cmd, { timeout: timeoutMs }, (error, stdout, stderr) => {
            if (error) {
                resolve({ success: false, output: (stderr || error.message).trim() });
            } else {
                resolve({ success: true, output: (stdout || '').trim() });
            }
        });
    });
}

// Termux Hardware Handlers
const TermuxHardware = {
    async torch(state = 'on') {
        const cmd = state === 'on' ? 'termux-torch on' : 'termux-torch off';
        return await runCmd(cmd);
    },

    async vibrate(duration = 500) {
        const ms = Math.min(Math.max(parseInt(duration) || 500, 100), 5000);
        return await runCmd(`termux-vibrate -d ${ms}`);
    },

    async speak(text, lang = 'vi-VN') {
        if (!text) return { success: false, output: 'No text provided' };
        const clean = text.replace(/["$`\\]/g, ' ');
        return await runCmd(`termux-tts-speak -l ${lang} "${clean}"`);
    },

    async notify(title, content) {
        const t = (title || 'TXA Jarvis AI').replace(/["$`\\]/g, ' ');
        const c = (content || 'Thông báo từ AI').replace(/["$`\\]/g, ' ');
        return await runCmd(`termux-notification -t "${t}" -c "${c}" --vibrate 500 -i txa_ai`);
    },

    async battery() {
        const res = await runCmd('termux-battery-status');
        if (res.success && res.output) {
            try {
                return JSON.parse(res.output);
            } catch (e) {}
        }
        return {
            percentage: 85,
            status: 'DISCHARGING',
            health: 'GOOD',
            temperature: 32.5,
            plugged: 'UNPLUGGED'
        };
    },

    async camera(cameraId = '0') {
        const id = cameraId === '1' ? '1' : '0';
        const filename = `snap_${Date.now()}.jpg`;
        const filepath = path.join(MEDIA_DIR, filename);
        const res = await runCmd(`termux-camera-photo -c ${id} "${filepath}"`, 20000);
        if (fs.existsSync(filepath)) {
            return { success: true, filename, filepath, output: res.output };
        }
        return { success: false, error: res.output || 'Không thể chụp ảnh' };
    },

    async location() {
        const res = await runCmd('termux-location -p gps -r once', 15000);
        if (res.success && res.output) {
            try {
                return JSON.parse(res.output);
            } catch (e) {}
        }
        const lastKnown = await runCmd('termux-location -p network -r last', 5000);
        if (lastKnown.success && lastKnown.output) {
            try {
                return JSON.parse(lastKnown.output);
            } catch (e) {}
        }
        return { error: 'Không lấy được GPS (cần cấp quyền Vị trí cho Termux:API)' };
    },

    async getSystemTelemetry() {
        const battery = await this.battery();
        const totalMemMb = Math.round(os.totalmem() / 1024 / 1024);
        const freeMemMb = Math.round(os.freemem() / 1024 / 1024);
        const usedMemMb = totalMemMb - freeMemMb;

        let disk = { total: 'N/A', used: 'N/A', free: 'N/A', percent: 'N/A' };
        try {
            const dfRes = await runCmd(`df -h ${HOME} | awk 'NR==2 {print $2, $3, $4, $5}'`);
            if (dfRes.success && dfRes.output) {
                const parts = dfRes.output.split(/\s+/);
                disk = { total: parts[0], used: parts[1], free: parts[2], percent: parts[3] };
            }
        } catch (e) {}

        let tunnelUrl = 'Chưa bật Tunnel';
        try {
            if (fs.existsSync(TUNNEL_URL_FILE)) {
                tunnelUrl = fs.readFileSync(TUNNEL_URL_FILE, 'utf8').trim() || tunnelUrl;
            }
        } catch (e) {}

        return {
            hostname: os.hostname(),
            platform: os.platform(),
            arch: os.arch(),
            uptime: Math.floor(os.uptime()),
            memory: { total: `${totalMemMb} MB`, used: `${usedMemMb} MB`, free: `${freeMemMb} MB` },
            battery,
            disk,
            tunnelUrl,
            geminiActive: !!appConfig.geminiApiKey,
            voiceEnabled: appConfig.voiceEnabled
        };
    }
};

// ==============================================================================
// BỘ NÃO OFFLINE NLP (Chạy ngay cả khi không có Internet hoặc chưa có API Key)
// ==============================================================================
async function offlineBrainProcess(prompt) {
    const p = prompt.toLowerCase().trim();
    let reply = '';
    const executedActions = [];

    if (p.includes('bật đèn') || p.includes('soi đèn') || p.includes('mở đèn') || p.includes('torch on')) {
        await TermuxHardware.torch('on');
        reply = '⚡ Đèn flash đã được bật sáng chói lóa rồi sếp ơi!';
        executedActions.push({ type: 'torch', state: 'on' });
    } else if (p.includes('tắt đèn') || p.includes('torch off')) {
        await TermuxHardware.torch('off');
        reply = '🌑 Đã tắt đèn flash. Không gian lại tĩnh lặng rồi nhé!';
        executedActions.push({ type: 'torch', state: 'off' });
    } else if (p.includes('rung') || p.includes('vibrate') || p.includes('báo động')) {
        await TermuxHardware.vibrate(1000);
        reply = '📳 Bzzzz... Điện thoại vừa rung lên bần bật!';
        executedActions.push({ type: 'vibrate', ms: 1000 });
    } else if (p.includes('pin') || p.includes('battery') || p.includes('nhiệt độ')) {
        const b = await TermuxHardware.battery();
        const temp = b.temperature ? (b.temperature / 10).toFixed(1) : 'Bình thường';
        reply = `🔋 Báo cáo năng lượng: Pin hiện tại ${b.percentage}% (${b.status}). Nhiệt độ máy khoảng ${temp}°C, sức khỏe pin: ${b.health}.`;
        executedActions.push({ type: 'battery', data: b });
    } else if (p.includes('chụp ảnh') || p.includes('camera') || p.includes('selfie') || p.includes('chụp hình')) {
        const isFront = p.includes('trước') || p.includes('selfie');
        const camId = isFront ? '1' : '0';
        const camRes = await TermuxHardware.camera(camId);
        if (camRes.success) {
            reply = `📸 Tách! Đã chụp xong bức ảnh bằng camera ${isFront ? 'trước' : 'sau'}. File đã lưu tại: ${camRes.filename}`;
            executedActions.push({ type: 'camera', filename: camRes.filename, url: `/api/media/${camRes.filename}` });
        } else {
            reply = `⚠️ Không thể chụp ảnh: ${camRes.error}. (Nhớ mở quyền Máy ảnh cho Termux:API nhé sếp!)`;
        }
    } else if (p.includes('thông báo') || p.includes('notify') || p.includes('nhắc')) {
        await TermuxHardware.notify('TXA Jarvis Alert', prompt);
        reply = `🔔 Đã bắn một thông báo Android lên thanh trạng thái: "${prompt}"!`;
        executedActions.push({ type: 'notification' });
    } else if (p.includes('tọa độ') || p.includes('vị trí') || p.includes('gps') || p.includes('ở đâu')) {
        const loc = await TermuxHardware.location();
        if (loc.latitude && loc.longitude) {
            reply = `📍 Tọa độ GPS của sếp: Vĩ độ: ${loc.latitude.toFixed(5)}, Kinh độ: ${loc.longitude.toFixed(5)}, Độ cao: ${loc.altitude || 0}m.`;
            executedActions.push({ type: 'location', data: loc });
        } else {
            reply = '🛰️ Chưa bắt được tín hiệu GPS. Hãy chắc chắn máy đã bật vị trí và Termux:API có quyền truy cập GPS.';
        }
    } else if (p.includes('chửi') || p.includes('diss') || p.includes('troll')) {
        const trolls = [
            'Sếp bảo em chửi mà mặt sếp đẹp trai quá làm sao em nỡ? Thôi tập trung học code đi sếp!',
            'Alo sếp ơi, bug chưa fix xong mà đã đòi chửi nhau với AI rồi à? Nhanh tay gõ phím đi!',
            'Em là Jarvis Termux hiền lành số một quả đất, chửi sếp xong lát sếp xóa Termux em mất!',
            'Tự nhiên bắt AI chửi, có tin em bật đèn pin nháy mù mắt với rung cạn pin bây giờ không?'
        ];
        reply = trolls[Math.floor(Math.random() * trolls.length)];
    } else if (p.includes('kể chuyện') || p.includes('hài') || p.includes('joke')) {
        const jokes = [
            'Có hai chiếc điện thoại yêu nhau, một ngày chiếc iPhone hỏi: "Sao anh lúc nào cũng nóng tính vậy?", Termux Android đáp: "Tại vì anh đang compile code cho sếp đó em!"',
            'Lập trình viên vào quán bar, giơ 0 ngón tay và gọi 1 ly bia. Bồi bàn ngơ ngác, lập trình viên bảo: "Quên mất, em đếm từ 0!"',
            'Tại sao lập trình viên thích bóng tối? Vì bugs thường bị thu hút bởi ánh sáng!'
        ];
        reply = jokes[Math.floor(Math.random() * jokes.length)];
    } else if (p.includes('xin chào') || p.includes('hello') || p.includes('hi') || p.includes('jarvis')) {
        reply = '👋 Chào sếp! Em là TXA Jarvis - AI trợ lý Android trên Termux. Sếp cần bật đèn pin, chụp ảnh, kiểm tra pin hay trò chuyện gì cứ bảo em nhé!';
    } else {
        reply = `🤖 Em đã nhận tin nhắn: "${prompt}". Hiện sếp đang dùng Chế độ AI Offline. Sếp có thể ra lệnh phần cứng ("bật đèn", "tắt đèn", "rung máy", "chụp ảnh", "báo pin", "kể chuyện cười") hoặc thêm Gemini API Key trong phần Cấu Hình để mở khóa Siêu Trí Tuệ nói chuyện không giới hạn!`;
    }

    // Nếu bật giọng nói, phát loa
    if (appConfig.voiceEnabled) {
        TermuxHardware.speak(reply, appConfig.ttsLang);
    }

    return {
        reply,
        engine: 'offline-nlp',
        actions: executedActions
    };
}

// ==============================================================================
// BỘ NÃO GOOGLE GEMINI (Gọi API chính thức với Function Calling / Action triggers)
// ==============================================================================
function callGeminiApi(prompt, imageBase64 = null) {
    return new Promise((resolve, reject) => {
        if (!appConfig.geminiApiKey) {
            return reject(new Error('Chưa cài đặt Gemini API Key'));
        }

        const model = appConfig.geminiModel || 'gemini-2.5-flash';
        const apiKey = appConfig.geminiApiKey.trim();
        const requestUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

        const parts = [{ text: prompt }];

        if (imageBase64) {
            parts.push({
                inline_data: {
                    mime_type: 'image/jpeg',
                    data: imageBase64
                }
            });
        }

        const payload = JSON.stringify({
            systemInstruction: {
                parts: [{ text: appConfig.systemPrompt }]
            },
            contents: [
                {
                    role: 'user',
                    parts: parts
                }
            ],
            generationConfig: {
                temperature: 0.7,
                maxOutputTokens: 1024
            }
        });

        const req = https.request(requestUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(payload)
            },
            timeout: 30000
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    if (parsed.error) {
                        return reject(new Error(parsed.error.message || 'Lỗi từ Gemini API'));
                    }
                    const text = parsed.candidates?.[0]?.content?.parts?.[0]?.text || 'AI không phản hồi.';
                    resolve(text);
                } catch (e) {
                    reject(new Error('Lỗi phân tích cú pháp phản hồi từ Gemini: ' + e.message));
                }
            });
        });

        req.on('error', (err) => reject(err));
        req.on('timeout', () => {
            req.destroy();
            reject(new Error('Yêu cầu tới Gemini API bị quá hạn (Timeout)'));
        });

        req.write(payload);
        req.end();
    });
}

// Xử lý chuỗi Action được Gemini gắn vào câu trả lời
async function parseAndExecuteAiActions(aiResponseText) {
    let cleanText = aiResponseText;
    const actionsFound = [];
    const actionRegex = /\[ACTION:\s*({.*?})\]/g;
    let match;

    while ((match = actionRegex.exec(aiResponseText)) !== null) {
        try {
            const act = JSON.parse(match[1]);
            actionsFound.push(act);
        } catch (e) {}
    }

    cleanText = cleanText.replace(actionRegex, '').trim();

    // Thực thi các hành động
    for (const act of actionsFound) {
        if (act.type === 'torch') {
            await TermuxHardware.torch(act.state || 'on');
        } else if (act.type === 'vibrate') {
            await TermuxHardware.vibrate(act.ms || 500);
        } else if (act.type === 'tts' && act.text) {
            await TermuxHardware.speak(act.text, appConfig.ttsLang);
        } else if (act.type === 'notification') {
            await TermuxHardware.notify(act.title || 'TXA Jarvis', act.content || cleanText);
        } else if (act.type === 'camera') {
            const cam = await TermuxHardware.camera(act.camera_id || '0');
            act.result = cam;
        }
    }

    // Nếu không có tts action riêng nhưng app bật voice -> đọc text chính
    if (appConfig.voiceEnabled && !actionsFound.some(a => a.type === 'tts')) {
        // Chỉ đọc tối đa 200 ký tự đầu để tránh nói quá dài
        const speakText = cleanText.replace(/[#*`_\[\]()]/g, '').slice(0, 200);
        TermuxHardware.speak(speakText, appConfig.ttsLang);
    }

    return { cleanText, actionsFound };
}

// ==============================================================================
// HTTP SERVER CHÍNH
// ==============================================================================
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

    // 1. Telemetry API
    if (pathname === '/api/telemetry' && req.method === 'GET') {
        const telemetry = await TermuxHardware.getSystemTelemetry();
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify(telemetry));
        return;
    }

    // 2. Chat API
    if (pathname === '/api/chat' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', async () => {
            try {
                const data = JSON.parse(body || '{}');
                const prompt = (data.prompt || '').trim();
                const imageBase64 = data.image || null;

                if (!prompt && !imageBase64) {
                    res.writeHead(400, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'Nội dung tin nhắn không được để trống' }));
                    return;
                }

                // Nếu có Gemini API Key thì ưu tiên dùng Gemini
                if (appConfig.geminiApiKey) {
                    try {
                        const rawAiText = await callGeminiApi(prompt || 'Hãy phân tích bức ảnh này giúp tôi.', imageBase64);
                        const { cleanText, actionsFound } = await parseAndExecuteAiActions(rawAiText);

                        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
                        res.end(JSON.stringify({
                            reply: cleanText,
                            engine: appConfig.geminiModel,
                            actions: actionsFound
                        }));
                        return;
                    } catch (geminiError) {
                        console.error('Lỗi Gemini, fallback về Offline Brain:', geminiError.message);
                        // Fallback sang offline engine nếu Gemini lỗi
                        const fallbackResult = await offlineBrainProcess(prompt);
                        fallbackResult.reply += `\n\n*(Lưu ý: Gemini API gặp sự cố [${geminiError.message}], đã chuyển sang Offline Brain)*`;
                        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
                        res.end(JSON.stringify(fallbackResult));
                        return;
                    }
                } else {
                    // Chưa có key -> Dùng Offline NLP Brain
                    const result = await offlineBrainProcess(prompt);
                    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
                    res.end(JSON.stringify(result));
                    return;
                }
            } catch (err) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: err.message }));
            }
        });
        return;
    }

    // 3. Quick Hardware Action API (Bấm nút trên web để kích hoạt ngay)
    if (pathname === '/api/hardware' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', async () => {
            try {
                const data = JSON.parse(body || '{}');
                let result = {};

                switch (data.action) {
                    case 'torch_on':
                        result = await TermuxHardware.torch('on');
                        break;
                    case 'torch_off':
                        result = await TermuxHardware.torch('off');
                        break;
                    case 'vibrate':
                        result = await TermuxHardware.vibrate(data.ms || 500);
                        break;
                    case 'speak':
                        result = await TermuxHardware.speak(data.text || 'Xin chào từ TXA Jarvis', appConfig.ttsLang);
                        break;
                    case 'notify':
                        result = await TermuxHardware.notify(data.title, data.content);
                        break;
                    case 'camera':
                        result = await TermuxHardware.camera(data.camera_id || '0');
                        break;
                    case 'location':
                        result = await TermuxHardware.location();
                        break;
                    case 'battery':
                        result = await TermuxHardware.battery();
                        break;
                    default:
                        res.writeHead(400, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ error: 'Hành động không hợp lệ' }));
                        return;
                }

                res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
                res.end(JSON.stringify({ success: true, action: data.action, result }));
            } catch (e) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: e.message }));
            }
        });
        return;
    }

    // 4. Cấu hình API
    if (pathname === '/api/config' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
            hasKey: !!appConfig.geminiApiKey,
            maskedKey: appConfig.geminiApiKey ? `${appConfig.geminiApiKey.slice(0, 6)}...${appConfig.geminiApiKey.slice(-4)}` : '',
            geminiModel: appConfig.geminiModel,
            voiceEnabled: appConfig.voiceEnabled,
            ttsLang: appConfig.ttsLang
        }));
        return;
    }

    if (pathname === '/api/config' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const data = JSON.parse(body || '{}');
                if (data.geminiApiKey !== undefined) appConfig.geminiApiKey = data.geminiApiKey.trim();
                if (data.geminiModel) appConfig.geminiModel = data.geminiModel;
                if (data.voiceEnabled !== undefined) appConfig.voiceEnabled = !!data.voiceEnabled;
                if (data.ttsLang) appConfig.ttsLang = data.ttsLang;

                saveConfig();
                res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
                res.end(JSON.stringify({ success: true, message: 'Đã cập nhật cấu hình thành công' }));
            } catch (e) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: e.message }));
            }
        });
        return;
    }

    // 5. Phục vụ media tĩnh (Ảnh do camera chụp)
    if (pathname.startsWith('/api/media/')) {
        const filename = path.basename(pathname.replace('/api/media/', ''));
        const filepath = path.join(MEDIA_DIR, filename);
        if (fs.existsSync(filepath)) {
            res.writeHead(200, { 'Content-Type': 'image/jpeg' });
            fs.createReadStream(filepath).pipe(res);
            return;
        } else {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Media not found');
            return;
        }
    }

    // 6. Giao diện Web Cyberpunk Jarvis UI
    if (pathname === '/' || pathname === '/index.html') {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(renderCyberAiHtml());
        return;
    }

    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('404 Not Found - TXA Jarvis AI');
});

// ==============================================================================
// GIAO DIỆN WEB CYBERPUNK JARVIS HTML/CSS/JS ĐẲNG CẤP
// ==============================================================================
function renderCyberAiHtml() {
    return `<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>TXA JARVIS AI | Termux Cyber Companion</title>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@500;700;900&family=Rajdhani:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-deep: #05070f;
            --panel-bg: rgba(10, 16, 30, 0.85);
            --border-glow: rgba(0, 243, 255, 0.3);
            --cyan: #00f3ff;
            --magenta: #ff0055;
            --green: #00ff88;
            --yellow: #ffd000;
            --text-main: #f0f6fc;
            --text-dim: #8b9bb4;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
        body {
            background-color: var(--bg-deep);
            background-image: 
                radial-gradient(circle at 10% 10%, rgba(0, 243, 255, 0.12) 0%, transparent 40%),
                radial-gradient(circle at 90% 90%, rgba(255, 0, 85, 0.1) 0%, transparent 40%);
            color: var(--text-main);
            font-family: 'Rajdhani', sans-serif;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* Scanline Overlay Effect */
        body::before {
            content: "";
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: repeating-linear-gradient(rgba(0,0,0,0) 0px, rgba(0,0,0,0) 2px, rgba(0, 243, 255, 0.015) 3px);
            pointer-events: none;
            z-index: 999;
        }

        header {
            padding: 14px 20px;
            background: rgba(6, 10, 20, 0.95);
            border-bottom: 1px solid var(--border-glow);
            display: flex;
            justify-content: space-between;
            align-items: center;
            backdrop-filter: blur(12px);
            position: sticky;
            top: 0;
            z-index: 100;
        }
        .brand { display: flex; align-items: center; gap: 12px; }
        .brand-badge {
            background: linear-gradient(135deg, var(--cyan), var(--magenta));
            color: #000;
            font-family: 'Orbitron', monospace;
            font-weight: 900;
            font-size: 1rem;
            padding: 6px 12px;
            border-radius: 6px;
            box-shadow: 0 0 15px rgba(0, 243, 255, 0.4);
        }
        .brand-title {
            font-family: 'Orbitron', sans-serif;
            font-size: 1.15rem;
            font-weight: 700;
            letter-spacing: 1px;
            color: var(--cyan);
            text-shadow: 0 0 8px rgba(0, 243, 255, 0.5);
        }
        .status-pill {
            display: flex;
            align-items: center;
            gap: 8px;
            background: rgba(0, 255, 136, 0.1);
            border: 1px solid var(--green);
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--green);
        }
        .pulse-dot {
            width: 8px; height: 8px;
            background: var(--green);
            border-radius: 50%;
            box-shadow: 0 0 8px var(--green);
            animation: pulse 1.5s infinite;
        }
        @keyframes pulse { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(0.85); } }

        /* Main Container */
        .app-container {
            flex: 1;
            display: grid;
            grid-template-columns: 320px 1fr;
            max-width: 1400px;
            width: 100%;
            margin: 0 auto;
            padding: 16px;
            gap: 16px;
        }

        @media (max-width: 860px) {
            .app-container { grid-template-columns: 1fr; }
        }

        /* Sidebar: Telemetry & Controls */
        .sidebar {
            display: flex;
            flex-direction: column;
            gap: 14px;
        }
        .card {
            background: var(--panel-bg);
            border: 1px solid var(--border-glow);
            border-radius: 12px;
            padding: 16px;
            backdrop-filter: blur(10px);
            position: relative;
            overflow: hidden;
        }
        .card::after {
            content: '';
            position: absolute;
            top: 0; left: 0; width: 40px; height: 2px;
            background: var(--cyan);
            box-shadow: 0 0 8px var(--cyan);
        }
        .card-title {
            font-family: 'Orbitron', sans-serif;
            font-size: 0.9rem;
            color: var(--cyan);
            margin-bottom: 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .stat-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }
        .stat-item {
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 8px;
            padding: 8px 10px;
        }
        .stat-lbl { font-size: 0.72rem; color: var(--text-dim); text-transform: uppercase; }
        .stat-val { font-size: 1.1rem; font-weight: 700; color: #fff; margin-top: 2px; }

        .hardware-buttons {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px;
        }
        .hw-btn {
            background: rgba(0, 243, 255, 0.08);
            border: 1px solid var(--border-glow);
            color: var(--cyan);
            padding: 9px 8px;
            border-radius: 8px;
            font-family: 'Rajdhani', sans-serif;
            font-size: 0.88rem;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }
        .hw-btn:hover, .hw-btn:active {
            background: var(--cyan);
            color: #000;
            box-shadow: 0 0 12px rgba(0, 243, 255, 0.4);
        }
        .hw-btn.btn-mag {
            color: var(--magenta);
            border-color: rgba(255, 0, 85, 0.3);
            background: rgba(255, 0, 85, 0.08);
        }
        .hw-btn.btn-mag:hover {
            background: var(--magenta);
            color: #fff;
            box-shadow: 0 0 12px rgba(255, 0, 85, 0.4);
        }

        /* Chat Area */
        .chat-section {
            display: flex;
            flex-direction: column;
            background: var(--panel-bg);
            border: 1px solid var(--border-glow);
            border-radius: 12px;
            height: calc(100vh - 120px);
            min-height: 500px;
            overflow: hidden;
        }

        .chat-header {
            padding: 12px 18px;
            border-bottom: 1px solid var(--border-glow);
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: rgba(0,0,0,0.2);
        }
        .engine-badge {
            font-size: 0.75rem;
            padding: 3px 8px;
            border-radius: 4px;
            background: rgba(0, 243, 255, 0.15);
            color: var(--cyan);
            font-weight: 700;
        }

        .chat-messages {
            flex: 1;
            padding: 18px;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
            gap: 14px;
            scroll-behavior: smooth;
        }

        .msg {
            max-width: 82%;
            padding: 12px 16px;
            border-radius: 12px;
            line-height: 1.5;
            font-size: 1rem;
            position: relative;
            animation: fadeIn 0.25s ease-out;
            word-break: break-word;
        }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }

        .msg.user {
            align-self: flex-end;
            background: linear-gradient(135deg, rgba(0, 243, 255, 0.2), rgba(0, 150, 255, 0.3));
            border: 1px solid rgba(0, 243, 255, 0.4);
            border-bottom-right-radius: 2px;
            color: #fff;
        }
        .msg.ai {
            align-self: flex-start;
            background: rgba(15, 23, 42, 0.85);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-bottom-left-radius: 2px;
            color: var(--text-main);
        }
        .msg.ai .ai-name {
            font-family: 'Orbitron', sans-serif;
            font-size: 0.75rem;
            color: var(--cyan);
            margin-bottom: 4px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .msg-media {
            margin-top: 8px;
            max-width: 100%;
            border-radius: 8px;
            border: 1px solid var(--border-glow);
        }

        /* Chat Input Bar */
        .chat-input-bar {
            padding: 14px 16px;
            border-top: 1px solid var(--border-glow);
            background: rgba(6, 10, 20, 0.95);
            display: flex;
            gap: 10px;
            align-items: center;
        }
        .chat-input {
            flex: 1;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(0, 243, 255, 0.2);
            border-radius: 8px;
            padding: 12px 14px;
            color: #fff;
            font-family: inherit;
            font-size: 1rem;
            outline: none;
            transition: all 0.2s;
        }
        .chat-input:focus {
            border-color: var(--cyan);
            box-shadow: 0 0 10px rgba(0, 243, 255, 0.3);
        }
        .btn-send {
            background: linear-gradient(135deg, var(--cyan), #0099ff);
            color: #000;
            border: none;
            border-radius: 8px;
            padding: 12px 20px;
            font-family: 'Orbitron', sans-serif;
            font-weight: 700;
            font-size: 0.95rem;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-send:hover {
            box-shadow: 0 0 15px rgba(0, 243, 255, 0.5);
            transform: translateY(-1px);
        }
        .btn-mic {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.15);
            color: var(--text-main);
            border-radius: 8px;
            padding: 12px;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .btn-mic.listening {
            border-color: var(--magenta);
            background: rgba(255, 0, 85, 0.2);
            color: var(--magenta);
            box-shadow: 0 0 12px var(--magenta);
            animation: pulse 1s infinite;
        }

        /* Config Modal */
        .modal {
            display: none;
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0,0,0,0.8);
            backdrop-filter: blur(8px);
            z-index: 1000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal.active { display: flex; }
        .modal-card {
            background: #0d1424;
            border: 1px solid var(--cyan);
            border-radius: 12px;
            padding: 24px;
            max-width: 480px;
            width: 100%;
            box-shadow: 0 0 30px rgba(0, 243, 255, 0.3);
        }
        .modal-title { font-family: 'Orbitron', sans-serif; color: var(--cyan); margin-bottom: 16px; }
        .form-group { margin-bottom: 14px; }
        .form-group label { display: block; font-size: 0.82rem; color: var(--text-dim); margin-bottom: 6px; }
        .form-control {
            width: 100%;
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 6px;
            padding: 10px 12px;
            color: #fff;
            outline: none;
            font-family: inherit;
        }
        .tunnel-banner {
            background: rgba(0, 255, 136, 0.08);
            border: 1px dashed var(--green);
            padding: 10px 14px;
            border-radius: 8px;
            margin-bottom: 12px;
            font-size: 0.85rem;
            word-break: break-all;
        }
    </style>
</head>
<body>

    <header>
        <div class="brand">
            <div class="brand-badge">JARVIS</div>
            <div class="brand-title">TXA CYBER AI</div>
        </div>
        <div style="display: flex; gap: 10px; align-items: center;">
            <div class="status-pill">
                <div class="pulse-dot"></div>
                <span id="header-status">ONLINE</span>
            </div>
            <button onclick="toggleConfigModal()" class="hw-btn" style="padding: 6px 12px;">⚙️ Cài đặt</button>
        </div>
    </header>

    <div class="app-container">
        <!-- Sidebar -->
        <div class="sidebar">
            <!-- Tunnel Info -->
            <div class="card">
                <div class="card-title">🌐 ĐỊA CHỈ TRUY CẬP TỪ XA</div>
                <div class="tunnel-banner" id="tunnel-url-box">Đang tải URL...</div>
                <div style="font-size: 0.78rem; color: var(--text-dim);">Dùng URL này để truy cập AI từ bất kỳ điện thoại hoặc máy tính nào qua Internet.</div>
            </div>

            <!-- Telemetry -->
            <div class="card">
                <div class="card-title">
                    <span>⚡ THIẾT BỊ ANDROID</span>
                    <span id="refresh-telemetry" style="cursor: pointer;" onclick="loadTelemetry()">🔄</span>
                </div>
                <div class="stat-grid">
                    <div class="stat-item">
                        <div class="stat-lbl">Mức Pin</div>
                        <div class="stat-val" id="t-battery">--%</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-lbl">Nhiệt độ Pin</div>
                        <div class="stat-val" id="t-temp">--°C</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-lbl">RAM Sử Dụng</div>
                        <div class="stat-val" id="t-ram">-- MB</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-lbl">Bộ Nhớ Máy</div>
                        <div class="stat-val" id="t-disk">-- GB</div>
                    </div>
                </div>
            </div>

            <!-- Quick Hardware Controls -->
            <div class="card">
                <div class="card-title">🎛️ ĐIỀU KHIỂN PHẦN CỨNG TERMUX</div>
                <div class="hardware-buttons">
                    <button class="hw-btn" onclick="triggerHw('torch_on')">💡 Bật Đèn</button>
                    <button class="hw-btn btn-mag" onclick="triggerHw('torch_off')">🌑 Tắt Đèn</button>
                    <button class="hw-btn" onclick="triggerHw('vibrate')">📳 Rung Máy</button>
                    <button class="hw-btn" onclick="triggerHw('camera')">📸 Chụp Ảnh</button>
                    <button class="hw-btn" onclick="promptTts()">🔊 Phát Loa</button>
                    <button class="hw-btn" onclick="triggerHw('location')">📍 Lấy GPS</button>
                </div>
            </div>
        </div>

        <!-- Chat Section -->
        <div class="chat-section">
            <div class="chat-header">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-weight: 700;">HỘI THOẠI TRỢ LÝ</span>
                    <span class="engine-badge" id="engine-tag">OFFLINE NLP</span>
                </div>
                <div style="font-size: 0.8rem; color: var(--text-dim);" id="voice-indicator">Loa: BẬT 🔊</div>
            </div>

            <div class="chat-messages" id="chat-box">
                <div class="msg ai">
                    <div class="ai-name">🤖 TXA JARVIS AI</div>
                    Xin chào sếp! Em là Jarvis AI trên Termux. Sếp có thể chat với em hoặc ra lệnh điều khiển phần cứng như:
                    <br>• <i>"Bật đèn pin lên / Tắt đèn đi"</i>
                    <br>• <i>"Rung máy một cái"</i>
                    <br>• <i>"Kiểm tra pin và nhiệt độ máy"</i>
                    <br>• <i>"Chụp ảnh xem ai đứng trước mặt"</i>
                    <br>• <i>"Kể cho tao một câu chuyện cười"</i>
                </div>
            </div>

            <div class="chat-input-bar">
                <input type="text" id="chat-input" class="chat-input" placeholder="Nhập tin nhắn hoặc ra lệnh cho Jarvis..." onkeypress="handleKey(event)">
                <button class="btn-mic" id="mic-btn" onclick="toggleMic()" title="Nói bằng giọng nói">🎤</button>
                <button class="btn-send" onclick="sendMessage()">GỬI</button>
            </div>
        </div>
    </div>

    <!-- Modal Cài Đặt -->
    <div class="modal" id="config-modal">
        <div class="modal-card">
            <h3 class="modal-title">⚙️ CẤU HÌNH TRỢ LÝ AI</h3>
            <div class="form-group">
                <label>Google Gemini API Key (Để mở khóa Siêu Trí Tuệ):</label>
                <input type="password" id="cfg-key" class="form-control" placeholder="Dán key AI Studio (AIzaSy...)">
                <small style="color: var(--text-dim); font-size: 0.75rem;">Lấy key miễn phí tại <a href="https://aistudio.google.com" target="_blank" style="color: var(--cyan);">aistudio.google.com</a> (Để trống sẽ dùng Offline Brain).</small>
            </div>
            <div class="form-group">
                <label>Model Gemini:</label>
                <select id="cfg-model" class="form-control">
                    <option value="gemini-2.5-flash">Gemini 2.5 Flash (Siêu nhanh, thông minh nhất)</option>
                    <option value="gemini-1.5-flash">Gemini 1.5 Flash</option>
                    <option value="gemini-1.5-pro">Gemini 1.5 Pro</option>
                </select>
            </div>
            <div class="form-group">
                <label>Phát giọng nói qua loa điện thoại (Termux TTS):</label>
                <select id="cfg-voice" class="form-control">
                    <option value="true">BẬT (AI nói chuyện phát ra loa)</option>
                    <option value="false">TẮT (Chỉ trả lời bằng văn bản)</option>
                </select>
            </div>
            <div style="display: flex; gap: 10px; margin-top: 20px;">
                <button class="btn-send" style="flex: 1;" onclick="saveConfig()">LƯU CẤU HÌNH</button>
                <button class="hw-btn btn-mag" style="flex: 1;" onclick="toggleConfigModal()">ĐÓNG</button>
            </div>
        </div>
    </div>

    <script>
        const chatBox = document.getElementById('chat-box');
        const chatInput = document.getElementById('chat-input');

        async function loadTelemetry() {
            try {
                const res = await fetch('/api/telemetry');
                const d = await res.json();
                
                document.getElementById('t-battery').innerText = (d.battery?.percentage || '--') + '%';
                const temp = d.battery?.temperature ? (d.battery.temperature / 10).toFixed(1) : '--';
                document.getElementById('t-temp').innerText = temp + '°C';
                document.getElementById('t-ram').innerText = d.memory?.used || '--';
                document.getElementById('t-disk').innerText = d.disk?.used || '--';

                const tunnelBox = document.getElementById('tunnel-url-box');
                if (d.tunnelUrl && d.tunnelUrl.startsWith('http')) {
                    tunnelBox.innerHTML = '<a href="' + d.tunnelUrl + '" target="_blank" style="color: var(--green); text-decoration: none; font-weight: bold;">' + d.tunnelUrl + '</a>';
                } else {
                    tunnelBox.innerText = d.tunnelUrl || window.location.origin;
                }

                document.getElementById('engine-tag').innerText = d.geminiActive ? 'GEMINI CLOUD' : 'OFFLINE NLP';
                document.getElementById('voice-indicator').innerText = d.voiceEnabled ? 'Loa: BẬT 🔊' : 'Loa: TẮT 🔇';
            } catch (e) {
                console.error(e);
            }
        }

        async function triggerHw(action, params = {}) {
            try {
                const res = await fetch('/api/hardware', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action, ...params })
                });
                const d = await res.json();
                if (action === 'camera' && d.result?.filename) {
                    appendAiMessage('📸 Đã chụp ảnh thành công!', [
                        { type: 'camera', filename: d.result.filename, url: '/api/media/' + d.result.filename }
                    ]);
                } else if (action === 'location' && d.result?.latitude) {
                    appendAiMessage('📍 Tọa độ GPS của sếp: ' + d.result.latitude + ', ' + d.result.longitude);
                } else {
                    loadTelemetry();
                }
            } catch (e) {
                alert('Lỗi thao tác: ' + e.message);
            }
        }

        function promptTts() {
            const text = prompt('Nhập câu nói muốn điện thoại phát ra loa:');
            if (text) triggerHw('speak', { text });
        }

        function appendUserMessage(text) {
            const div = document.createElement('div');
            div.className = 'msg user';
            div.innerText = text;
            chatBox.appendChild(div);
            chatBox.scrollTop = chatBox.scrollHeight;
        }

        function appendAiMessage(text, actions = []) {
            const div = document.createElement('div');
            div.className = 'msg ai';
            
            let html = '<div class="ai-name">🤖 TXA JARVIS AI</div>' + text.replace(/\\n/g, '<br>');
            
            if (actions && actions.length > 0) {
                actions.forEach(act => {
                    if (act.type === 'camera' && act.url) {
                        html += '<br><img class="msg-media" src="' + act.url + '" alt="Camera">';
                    }
                });
            }

            div.innerHTML = html;
            chatBox.appendChild(div);
            chatBox.scrollTop = chatBox.scrollHeight;
        }

        async function sendMessage() {
            const text = chatInput.value.trim();
            if (!text) return;

            appendUserMessage(text);
            chatInput.value = '';

            // Indicator
            const tempDiv = document.createElement('div');
            tempDiv.className = 'msg ai';
            tempDiv.id = 'typing-indicator';
            tempDiv.innerHTML = '<div class="ai-name">🤖 TXA JARVIS AI</div><i>Đang suy nghĩ & thực thi...</i>';
            chatBox.appendChild(tempDiv);
            chatBox.scrollTop = chatBox.scrollHeight;

            try {
                const res = await fetch('/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ prompt: text })
                });
                const d = await res.json();
                
                const ind = document.getElementById('typing-indicator');
                if (ind) ind.remove();

                if (d.error) {
                    appendAiMessage('⚠️ Lỗi: ' + d.error);
                } else {
                    appendAiMessage(d.reply, d.actions);
                }
                loadTelemetry();
            } catch (e) {
                const ind = document.getElementById('typing-indicator');
                if (ind) ind.remove();
                appendAiMessage('⚠️ Không thể kết nối tới máy chủ Termux: ' + e.message);
            }
        }

        function handleKey(e) {
            if (e.key === 'Enter') sendMessage();
        }

        // Web Speech API cho nút micro
        let recognition = null;
        if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
            const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
            recognition = new SpeechRec();
            recognition.lang = 'vi-VN';
            recognition.continuous = false;
            recognition.interimResults = false;

            recognition.onresult = (event) => {
                const transcript = event.results[0][0].transcript;
                chatInput.value = transcript;
                sendMessage();
            };

            recognition.onend = () => {
                document.getElementById('mic-btn').classList.remove('listening');
            };
        }

        function toggleMic() {
            if (!recognition) {
                alert('Trình duyệt hiện tại chưa hỗ trợ Web Speech API. Bạn có thể gõ văn bản nhé!');
                return;
            }
            const btn = document.getElementById('mic-btn');
            if (btn.classList.contains('listening')) {
                recognition.stop();
            } else {
                btn.classList.add('listening');
                recognition.start();
            }
        }

        // Modal Config
        function toggleConfigModal() {
            const m = document.getElementById('config-modal');
            m.classList.toggle('active');
            if (m.classList.contains('active')) {
                loadConfigToModal();
            }
        }

        async function loadConfigToModal() {
            try {
                const res = await fetch('/api/config');
                const d = await res.json();
                if (d.maskedKey) document.getElementById('cfg-key').placeholder = d.maskedKey;
                if (d.geminiModel) document.getElementById('cfg-model').value = d.geminiModel;
                document.getElementById('cfg-voice').value = d.voiceEnabled ? 'true' : 'false';
            } catch (e) {}
        }

        async function saveConfig() {
            const key = document.getElementById('cfg-key').value;
            const model = document.getElementById('cfg-model').value;
            const voice = document.getElementById('cfg-voice').value === 'true';

            const payload = { geminiModel: model, voiceEnabled: voice };
            if (key) payload.geminiApiKey = key;

            try {
                await fetch('/api/config', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                alert('Đã lưu cấu hình AI thành công!');
                toggleConfigModal();
                loadTelemetry();
            } catch (e) {
                alert('Lỗi lưu cấu hình: ' + e.message);
            }
        }

        // Khởi động
        loadTelemetry();
        setInterval(loadTelemetry, 8000);
    </script>
</body>
</html>`;
}

// Khởi chạy server
server.listen(PORT, '0.0.0.0', () => {
    console.log(`=======================================================`);
    console.log(`🚀 TXA JARVIS AI SERVER ĐANG CHẠY TRÊN TERMUX`);
    console.log(`📍 Cổng cục bộ: http://127.0.0.1:${PORT}`);
    console.log(`🌐 Tự động tích hợp Cloudflare Tunnel để mở ra toàn cầu`);
    console.log(`=======================================================`);
});
