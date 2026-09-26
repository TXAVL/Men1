# BRIEF: TXA Studio — Nhiem vu danh cho AI tiep theo

## NHIEM VU
Fix + deploy API Vercel cho repo ZeroGrid-QuantumShift (txastudio.click) de menu.sh xac thuc key duoc.

---

## CAU TRUC REPO
Clone tai may: C:\Users\admin\.cache\ZeroGrid-QuantumShift
GitHub: https://github.com/TXAVL/ZeroGrid-QuantumShift

```
ZeroGrid-QuantumShift/
|-- vercel.json              <- Config Vercel (rewrites /api/*, SPA fallback)
|-- web/
|   |-- package.json         <- "type": "module" — BAT BUOC ESM
|   |-- api/                 <- Serverless functions
|   |   |-- validate_key.js  <- DUNG require() — LOI TREN VERCEL
|   |   |-- verify_key.js
|   |   |-- version.js
|   |   |-- orders.js
|   |   |-- admin.js
|   |   |-- logs.js
|   |   `-- logger.js
|   |-- src/                 <- Vue 3 source
|   `-- dist/                <- Vite build output
`-- supabase/schema.sql      <- DB schema
```

---

## LOI HIEN TAI

### Vercel Deploy Failed: "require is not defined in ES module"
- web/package.json co "type": "module" -> Node xu ly .js nhu ESM
- Nhung web/api/*.js van dung require('crypto'), module.exports = ... -> CJS
- -> Vercel crash khi co request

### Vercel Dashboard Settings hien tai:
- Framework: Vite
- Root Directory: ./
- Build Command: npm run build
- Install Command: npm install
- Output Directory: web/dist
- Van de: Root ./ khong co package.json -> npm install treo/fail

---

## CACH FIX DUNG

### Option A — Don gian nhat: Doi Root Directory = "web" trong Vercel Dashboard

1. Vercel Dashboard -> Project Settings -> General -> Root Directory: doi thanh "web"
2. Build Command: npm run build
3. Install Command: npm install
4. Output Directory: dist
5. web/vercel.json se la config hop le (khi root = web)

Sau do chuyen doi web/api/*.js sang ESM:

```js
// TRUOC (CommonJS - LOI):
const crypto = require('crypto');
module.exports = async (req, res) => { ... };

// SAU (ESM - DUNG):
import crypto from 'crypto';
export default async function handler(req, res) { ... }
```

File can convert (theo thu tu):
1. logger.js    <- convert truoc vi cac file khac import no
2. validate_key.js
3. verify_key.js
4. version.js
5. orders.js
6. admin.js
7. logs.js

---

## API MA menu.sh GOI

File: C:\Users\admin\Desktop\Code\menu.sh

```
API_URL="https://txastudio.click/api/validate_key"
API_URL_ALT="https://api.txastudio.click/api/validate_key.php"
```

Script gui POST request:
```
curl -s -m 5 -X POST \
    -H "Content-Type: application/json" \
    -H "X-Device-Brand: $D_BRAND" \
    -H "X-Device-Model: $D_MODEL" \
    -H "X-Device-Android: $D_ANDROID" \
    -H "X-Device-Arch: $D_ARCH" \
    -H "X-Device-Battery: $D_BATTERY" \
    -d '{"key":"<KEY>","device":{"brand":"...","model":"..."}}' \
    "https://txastudio.click/api/validate_key"

# API phai tra ve:
{ "valid": true }   <- key hop le
{ "valid": false }  <- key sai
```

---

## LOGIC XAC THUC KEY TRONG API

```js
const SALT = "TXA_STUDIO_CYBER_2026_CLICK";

const MASTER_KEYS = [
    "TXA-MASTER-STUDIO-CLICK-2026",
    "TXA-VIP-TXASTUDIO-CLICK",
    "TXA-DEV-PASS-2026"
];

function isValidKey(key) {
    if (MASTER_KEYS.includes(key)) return true;
    
    // Format: TXA-{TIER}-{RAND_ID}-{CHECKSUM}
    const parts = key.split('-');
    if (parts.length !== 4) return false;
    const [prefix, tier, randId, checksum] = parts;
    if (prefix !== 'TXA') return false;
    
    const payload = "TXA-" + tier + "-" + randId;
    const expectedChecksum = crypto
        .createHash('sha256')
        .update(payload + ":" + SALT)
        .digest('hex')
        .substring(0, 8)
        .toUpperCase();
    
    return checksum.toUpperCase() === expectedChecksum;
}
```

---

## SUPABASE

- Dang nhap bang TXAVLOG
- Schema: C:\Users\admin\.cache\ZeroGrid-QuantumShift\supabase\schema.sql
- Tables: txa_keys, txa_orders, txa_system_configs
- API co the tra cuu key trong Supabase thay vi hardcode

---

## GIT COMMIT ON DINH

Repo: https://github.com/TXAVL/ZeroGrid-QuantumShift
Branch: main
Stable commit: bba5782c1c7b83ed702671048b278e072c997d35  (ADD API)
Hien main dang o dung commit nay (da force reset ve day).

---

## FILE LIEN QUAN

| File               | Duong dan                                                                      |
|--------------------|--------------------------------------------------------------------------------|
| Script Termux      | C:\Users\admin\Desktop\Code\menu.sh                                            |
| API handlers       | C:\Users\admin\.cache\ZeroGrid-QuantumShift\web\api\*.js                       |
| Vercel config      | C:\Users\admin\.cache\ZeroGrid-QuantumShift\vercel.json                        |
| DB Schema          | C:\Users\admin\.cache\ZeroGrid-QuantumShift\supabase\schema.sql                |