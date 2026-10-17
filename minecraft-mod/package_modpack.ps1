# Script dong goi Modpack hoan chinh
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modpackName = "Advancement_PvP_Modpack_Fabric_26.3"
$distDir = "$PSScriptRoot\dist\$modpackName"

if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
New-Item -ItemType Directory -Force -Path "$distDir\mods" | Out-Null
New-Item -ItemType Directory -Force -Path "$distDir\resourcepacks" | Out-Null

# 1. Copy Mod
Copy-Item -Path "$PSScriptRoot\build\UnlockAdvancements-1.0.0.jar" -Destination "$distDir\mods\" -Force

# 2. Copy Resource Pack
Copy-Item -Path "$PSScriptRoot\resourcepacks\DarkNeon_PvP_Pack.zip" -Destination "$distDir\resourcepacks\" -Force

# 3. Tạo manifest.json (chuẩn modpack)
$manifest = @"
{
  "name": "Advancement & DarkNeon PvP Modpack",
  "version": "1.0.0",
  "gameVersion": "26.3",
  "modLoader": {
    "type": "fabric",
    "version": "0.19.5"
  },
  "author": "asbyxa",
  "description": "Modpack ket hop giua Mod mo khoa toan bo thanh tuu (Shift+7) va Goi tai nguyen Dark Neon PvP xịn xò.",
  "mods": [
    {
      "name": "Unlock All Advancements",
      "file": "UnlockAdvancements-1.0.0.jar",
      "required": true
    }
  ],
  "resourcepacks": [
    {
      "name": "Dark Neon PvP Pack",
      "file": "DarkNeon_PvP_Pack.zip",
      "recommended": true
    }
  ]
}
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$distDir\modpack.json", $manifest, $utf8NoBom)

# 4. Tạo script 1-click installer cho người khác hoặc sao chép
$installerContent = @"
@echo off
title Cai dat Modpack Minecraft Fabric 26.3
echo ========================================================
echo    DANG CAI DAT ADVANCEMENT & DARK NEON PVP MODPACK
echo ========================================================

set TARGET_GAME=%APPDATA%\.tlauncher\legacy\Minecraft\game
if not exist "%TARGET_GAME%" set TARGET_GAME=%APPDATA%\.minecraft

echo Thu muc game: %TARGET_GAME%
if not exist "%TARGET_GAME%\mods" mkdir "%TARGET_GAME%\mods"
if not exist "%TARGET_GAME%\resourcepacks" mkdir "%TARGET_GAME%\resourcepacks"

echo [1/2] Dang sao chep Mods...
copy /Y "mods\*.jar" "%TARGET_GAME%\mods\"

echo [2/2] Dang sao chep Resource Packs...
copy /Y "resourcepacks\*.zip" "%TARGET_GAME%\resourcepacks\"

echo ========================================================
echo   CAI DAT HOAN TAT! HAY MO LAUNCHER VA VAO GAME THUONG THUC.
echo ========================================================
pause
"@
[System.IO.File]::WriteAllText("$distDir\Install_Modpack.bat", $installerContent, [System.Text.Encoding]::ASCII)

# 5. Nén toàn bộ Modpack thành file ZIP chia sẻ
$modpackZip = "$PSScriptRoot\dist\$modpackName.zip"
if (Test-Path $modpackZip) { Remove-Item -Force $modpackZip }
[System.IO.Compression.ZipFile]::CreateFromDirectory($distDir, $modpackZip)

Write-Host "Dong goi Modpack thanh cong!" -ForegroundColor Green
Write-Host "Thu muc Modpack: $distDir" -ForegroundColor Cyan
Write-Host "File Zip Modpack chia se: $modpackZip" -ForegroundColor Yellow
