# Script cai dat va dong goi Ultra Shader Modpack (Toi uu cho RTX 3070 va 16GB RAM)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modpackName = "Ultra_Shader_Modpack_Fabric_26.3"
$distDir = "$PSScriptRoot\dist\$modpackName"

if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
New-Item -ItemType Directory -Force -Path "$distDir\mods" | Out-Null
New-Item -ItemType Directory -Force -Path "$distDir\shaderpacks" | Out-Null
New-Item -ItemType Directory -Force -Path "$distDir\resourcepacks" | Out-Null

$gameMods = "$env:APPDATA\.tlauncher\legacy\Minecraft\game\mods"
$gameShaders = "$env:APPDATA\.tlauncher\legacy\Minecraft\game\shaderpacks"
$gameResourcepacks = "$env:APPDATA\.tlauncher\legacy\Minecraft\game\resourcepacks"

if (!(Test-Path $gameMods)) { New-Item -ItemType Directory -Force -Path $gameMods | Out-Null }
if (!(Test-Path $gameShaders)) { New-Item -ItemType Directory -Force -Path $gameShaders | Out-Null }
if (!(Test-Path $gameResourcepacks)) { New-Item -ItemType Directory -Force -Path $gameResourcepacks | Out-Null }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   DANG TAI VA CAI DAT ULTRA SHADER MODPACK (FABRIC 26.3) " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

$mods = @(
    @{ name = "Fabric API"; file = "fabric-api-0.161.0+26.3.jar"; url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/bNnaTiuM/fabric-api-0.161.0%2B26.3.jar" },
    @{ name = "Sodium (Toi uu FPS)"; file = "sodium-fabric-0.9.3-alpha.1+mc26.3.jar"; url = "https://cdn.modrinth.com/data/AANobbMI/versions/v4PSXean/sodium-fabric-0.9.3-alpha.1%2Bmc26.3.jar" },
    @{ name = "Iris Shaders (Ho tro Shaders)"; file = "iris-fabric-1.11.7+mc26.3.jar"; url = "https://cdn.modrinth.com/data/YL57xq9U/versions/vTN4NRGW/iris-fabric-1.11.7%2Bmc26.3.jar" },
    @{ name = "Lithium (Toi uu CPU)"; file = "lithium-fabric-0.26.2+mc26.3.jar"; url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/xS0Q8LSi/lithium-fabric-0.26.2%2Bmc26.3.jar" },
    @{ name = "Mod Menu (Quan ly Mod)"; file = "modmenu-21.0.0.jar"; url = "https://cdn.modrinth.com/data/mOgUt4GM/versions/kyy7dbrZ/modmenu-21.0.0.jar" },
    @{ name = "JEI (Cong thuc che tao)"; file = "jei-26.3-fabric-31.8.0.49.jar"; url = "https://cdn.modrinth.com/data/u6dRKJwZ/versions/N2UbrNk9/jei-26.3-fabric-31.8.0.49.jar" },
    @{ name = "Xaeros Minimap (Ban do mini)"; file = "xaerominimap-fabric-26.3-26.5.3.jar"; url = "https://cdn.modrinth.com/data/1bokaNcj/versions/YPkAliDt/xaerominimap-fabric-26.3-26.5.3.jar" }
)

foreach ($m in $mods) {
    $dest = "$distDir\mods\$($m.file)"
    Write-Host "-> Dang tai $($m.name)..." -ForegroundColor Green
    Invoke-WebRequest -Uri $m.url -OutFile $dest -TimeoutSec 45
    Copy-Item -Path $dest -Destination "$gameMods\$($m.file)" -Force
}

# Mod mo khoa thanh tuu
Copy-Item -Path "$PSScriptRoot\build\UnlockAdvancements-1.0.0.jar" -Destination "$distDir\mods\" -Force
Copy-Item -Path "$PSScriptRoot\build\UnlockAdvancements-1.0.0.jar" -Destination "$gameMods\" -Force

# Danh sach Shaders
$shaders = @(
    @{ name = "Complementary Shaders (Unbound)"; file = "ComplementaryUnbound_r5.9.3.zip"; url = "https://cdn.modrinth.com/data/R6NEzAwj/versions/B1kyfoUZ/ComplementaryUnbound_r5.9.3.zip" },
    @{ name = "BSL Shaders"; file = "BSL_v10.1.8.zip"; url = "https://cdn.modrinth.com/data/Q1vvjJYV/versions/Y68yiql9/BSL_v10.1.8.zip" }
)

foreach ($s in $shaders) {
    $dest = "$distDir\shaderpacks\$($s.file)"
    Write-Host "-> Dang tai Shaderpack $($s.name)..." -ForegroundColor Magenta
    Invoke-WebRequest -Uri $s.url -OutFile $dest -TimeoutSec 90
    Copy-Item -Path $dest -Destination "$gameShaders\$($s.file)" -Force
}

# Copy Resource Pack
Copy-Item -Path "$PSScriptRoot\resourcepacks\DarkNeon_PvP_Pack.zip" -Destination "$distDir\resourcepacks\" -Force
Copy-Item -Path "$PSScriptRoot\resourcepacks\DarkNeon_PvP_Pack.zip" -Destination "$gameResourcepacks\" -Force

# Tao manifest modpack.json
$manifest = @'
{
  "name": "Ultra Shader & Adventure Modpack",
  "version": "1.0.0",
  "gameVersion": "26.3",
  "loader": "fabric",
  "author": "asbyxa",
  "recommendedRam": "4GB - 6GB (Phu hop may 16GB RAM)",
  "features": [
    "Sodium + Lithium: FPS cuc muot 200+ FPS",
    "Iris Shaders: Ho tro Shaders do hoa dien anh",
    "2 Sieu Shader co san: Complementary Unbound & BSL",
    "Xaeros Minimap: Ban do goc man hinh va Waypoint",
    "JEI: Tra cuu cong thuc che do moi vat pham",
    "Mod Menu: Giao dien chinh mod truc quan",
    "UnlockAdvancements: Phim tat Shift+7, F7, /unlockall mo khoa toan bo thanh tuu",
    "Dark Neon PvP: Goi tai nguyen tam ngam Dot va kiem ngan neon"
  ]
}
'@
[System.IO.File]::WriteAllText("$distDir\modpack.json", $manifest, [System.Text.Encoding]::ASCII)

# Tao file installer .bat
$bat = @'
@echo off
title Cai dat Ultra Shader Modpack Fabric 26.3
set TARGET_GAME=%APPDATA%\.tlauncher\legacy\Minecraft\game
if not exist "%TARGET_GAME%" set TARGET_GAME=%APPDATA%\.minecraft

if not exist "%TARGET_GAME%\mods" mkdir "%TARGET_GAME%\mods"
if not exist "%TARGET_GAME%\shaderpacks" mkdir "%TARGET_GAME%\shaderpacks"
if not exist "%TARGET_GAME%\resourcepacks" mkdir "%TARGET_GAME%\resourcepacks"

echo Dang cai dat Mods...
copy /Y "mods\*.jar" "%TARGET_GAME%\mods\"

echo Dang cai dat Shaderpacks...
copy /Y "shaderpacks\*.zip" "%TARGET_GAME%\shaderpacks\"

echo Dang cai dat Resourcepacks...
copy /Y "resourcepacks\*.zip" "%TARGET_GAME%\resourcepacks\"

echo CAI DAT HOAN TAT!
pause
'@
[System.IO.File]::WriteAllText("$distDir\Install.bat", $bat, [System.Text.Encoding]::ASCII)

# Zip toan bo modpack
$zipOut = "$PSScriptRoot\dist\$modpackName.zip"
if (Test-Path $zipOut) { Remove-Item -Force $zipOut }
[System.IO.Compression.ZipFile]::CreateFromDirectory($distDir, $zipOut)

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " CAI DAT HOAN TAT! SHADERS & MODS DA CO SAN TRONG GAME!   " -ForegroundColor Green
Write-Host " Thu muc Modpack: $distDir" -ForegroundColor Cyan
Write-Host " File Zip chia se: $zipOut" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
