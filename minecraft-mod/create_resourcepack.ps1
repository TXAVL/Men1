# Script tao Goi Tai Nguyen (Resource Pack) Dark Neon PvP cho Minecraft
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$packName = "DarkNeon_PvP_Pack"
$packDir = "$PSScriptRoot\resourcepacks\$packName"

if (Test-Path $packDir) { Remove-Item -Recurse -Force $packDir }
New-Item -ItemType Directory -Force -Path "$packDir\assets\minecraft\textures\gui\sprites\hud" | Out-Null
New-Item -ItemType Directory -Force -Path "$packDir\assets\minecraft\textures\item" | Out-Null
New-Item -ItemType Directory -Force -Path "$packDir\assets\minecraft\lang" | Out-Null

# 1. pack.mcmeta - min_format 65.0 va max_format 97.1 tuong thich tuyet doi Minecraft 26.3 (Khong con bi do)
$mcmeta = @'
{
  "pack": {
    "min_format": [65, 0],
    "max_format": [97, 1],
    "description": "\u00a7b\u00a7lDark Neon PvP \u00a77- T\u00e2m ng\u1eafm Dot, Ki\u1ebfm ng\u1eafn \u0026 Hi\u1ec7u \u1ee9ng s\u1eafc n\u00e9t"
  }
}
'@
[System.IO.File]::WriteAllText("$packDir\pack.mcmeta", $mcmeta, [System.Text.Encoding]::ASCII)

# 2. Ngon ngu tuy bien
$viLang = @'
{
  "menu.singleplayer": "\u00a7a\u25b6 Ch\u01a1i \u0110\u01a1n (Sinh T\u1ed3n)",
  "menu.multiplayer": "\u00a7b\u2694 Ch\u01a1i M\u1ea1ng (M\u00e1y Ch\u1ee7)",
  "menu.options": "\u00a76\u2699 C\u00e0i \u0110\u1eb7t",
  "menu.quit": "\u00a7c\u2716 Tho\u00e1t Game",
  "item.minecraft.diamond_sword": "\u00a7b\u2726 Thanh Ki\u1ebfm Neon Diamond \u2726",
  "item.minecraft.netherite_sword": "\u00a75\u2726 Thanh Ki\u1ebfm Neon Netherite \u2726"
}
'@
[System.IO.File]::WriteAllText("$packDir\assets\minecraft\lang\vi_vn.json", $viLang, [System.Text.Encoding]::ASCII)
[System.IO.File]::WriteAllText("$packDir\assets\minecraft\lang\en_us.json", $viLang, [System.Text.Encoding]::ASCII)

# 3. Tao pack.png
$packBmp = New-Object System.Drawing.Bitmap(64, 64)
$g = [System.Drawing.Graphics]::FromImage($packBmp)
$g.Clear([System.Drawing.Color]::FromArgb(255, 18, 22, 34))

$cyanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0, 240, 255), 2)
$g.DrawRectangle($cyanPen, 2, 2, 59, 59)

for ($i = 0; $i -lt 24; $i++) {
    $x = 48 - $i
    $y = 14 + $i
    $packBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, 255, 255, 255))
    $packBmp.SetPixel($x - 1, $y, [System.Drawing.Color]::FromArgb(255, 0, 235, 255))
    $packBmp.SetPixel($x, $y + 1, [System.Drawing.Color]::FromArgb(255, 0, 200, 255))
}
$packBmp.SetPixel(23, 39, [System.Drawing.Color]::FromArgb(255, 240, 190, 50))
$packBmp.SetPixel(22, 40, [System.Drawing.Color]::FromArgb(255, 240, 190, 50))
$packBmp.SetPixel(24, 40, [System.Drawing.Color]::FromArgb(255, 200, 150, 30))
$packBmp.SetPixel(21, 41, [System.Drawing.Color]::FromArgb(255, 120, 70, 20))
$packBmp.SetPixel(20, 42, [System.Drawing.Color]::FromArgb(255, 80, 40, 10))

$packBmp.Save("$packDir\pack.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$packBmp.Dispose()

# 4. Tam ngam Dot PvP (Crosshair Dot 15x15)
$crosshair = New-Object System.Drawing.Bitmap(15, 15)
$neonCyan = [System.Drawing.Color]::FromArgb(255, 0, 255, 220)
$darkBorder = [System.Drawing.Color]::FromArgb(200, 0, 0, 0)
$whiteCenter = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)

$crosshair.SetPixel(7, 7, $whiteCenter)
$crosshair.SetPixel(6, 7, $neonCyan)
$crosshair.SetPixel(8, 7, $neonCyan)
$crosshair.SetPixel(7, 6, $neonCyan)
$crosshair.SetPixel(7, 8, $neonCyan)

$crosshair.SetPixel(4, 7, $darkBorder)
$crosshair.SetPixel(3, 7, $neonCyan)
$crosshair.SetPixel(10, 7, $darkBorder)
$crosshair.SetPixel(11, 7, $neonCyan)
$crosshair.SetPixel(7, 4, $darkBorder)
$crosshair.SetPixel(7, 3, $neonCyan)
$crosshair.SetPixel(7, 10, $darkBorder)
$crosshair.SetPixel(7, 11, $neonCyan)

$crosshair.Save("$packDir\assets\minecraft\textures\gui\sprites\hud\crosshair.png", [System.Drawing.Imaging.ImageFormat]::Png)
$crosshair.Dispose()

# 5. Kiem Kim Cuong Ngan
$swordBmp = New-Object System.Drawing.Bitmap(16, 16)
$bladeCore = [System.Drawing.Color]::FromArgb(255, 240, 255, 255)
$bladeMain = [System.Drawing.Color]::FromArgb(255, 60, 220, 240)
$bladeEdge = [System.Drawing.Color]::FromArgb(255, 20, 130, 170)
$guardGold = [System.Drawing.Color]::FromArgb(255, 245, 195, 60)
$hiltWood = [System.Drawing.Color]::FromArgb(255, 110, 65, 30)
$hiltBottom = [System.Drawing.Color]::FromArgb(255, 60, 35, 15)

$swordBmp.SetPixel(2, 13, $hiltBottom)
$swordBmp.SetPixel(3, 12, $hiltWood)
$swordBmp.SetPixel(4, 11, $guardGold)
$swordBmp.SetPixel(3, 10, $guardGold)
$swordBmp.SetPixel(5, 12, $guardGold)

$swordBmp.SetPixel(5, 10, $bladeMain)
$swordBmp.SetPixel(6, 9, $bladeCore)
$swordBmp.SetPixel(7, 8, $bladeCore)
$swordBmp.SetPixel(8, 7, $bladeCore)
$swordBmp.SetPixel(9, 6, $bladeCore)
$swordBmp.SetPixel(10, 5, $bladeCore)
$swordBmp.SetPixel(11, 4, $bladeMain)
$swordBmp.SetPixel(12, 3, $bladeEdge)

$swordBmp.SetPixel(4, 9, $bladeEdge)
$swordBmp.SetPixel(5, 8, $bladeEdge)
$swordBmp.SetPixel(6, 7, $bladeEdge)
$swordBmp.SetPixel(7, 6, $bladeEdge)
$swordBmp.SetPixel(8, 5, $bladeEdge)
$swordBmp.SetPixel(9, 4, $bladeEdge)
$swordBmp.SetPixel(10, 3, $bladeEdge)
$swordBmp.SetPixel(11, 2, $bladeEdge)

$swordBmp.SetPixel(6, 10, $bladeMain)
$swordBmp.SetPixel(7, 9, $bladeMain)
$swordBmp.SetPixel(8, 8, $bladeMain)
$swordBmp.SetPixel(9, 7, $bladeMain)
$swordBmp.SetPixel(10, 6, $bladeMain)

$swordBmp.Save("$packDir\assets\minecraft\textures\item\diamond_sword.png", [System.Drawing.Imaging.ImageFormat]::Png)

# 6. Kiem Netherite
$nBladeCore = [System.Drawing.Color]::FromArgb(255, 230, 210, 255)
$nBladeMain = [System.Drawing.Color]::FromArgb(255, 160, 80, 220)
$nBladeEdge = [System.Drawing.Color]::FromArgb(255, 65, 30, 95)
$nSwordBmp = New-Object System.Drawing.Bitmap(16, 16)

$nSwordBmp.SetPixel(2, 13, [System.Drawing.Color]::FromArgb(255, 30, 20, 40))
$nSwordBmp.SetPixel(3, 12, [System.Drawing.Color]::FromArgb(255, 80, 40, 90))
$nSwordBmp.SetPixel(4, 11, [System.Drawing.Color]::FromArgb(255, 180, 100, 230))
$nSwordBmp.SetPixel(3, 10, [System.Drawing.Color]::FromArgb(255, 180, 100, 230))
$nSwordBmp.SetPixel(5, 12, [System.Drawing.Color]::FromArgb(255, 180, 100, 230))

$nSwordBmp.SetPixel(5, 10, $nBladeMain)
$nSwordBmp.SetPixel(6, 9, $nBladeCore)
$nSwordBmp.SetPixel(7, 8, $nBladeCore)
$nSwordBmp.SetPixel(8, 7, $nBladeCore)
$nSwordBmp.SetPixel(9, 6, $nBladeCore)
$nSwordBmp.SetPixel(10, 5, $nBladeCore)
$nSwordBmp.SetPixel(11, 4, $nBladeMain)
$nSwordBmp.SetPixel(12, 3, $nBladeEdge)

$nSwordBmp.SetPixel(4, 9, $nBladeEdge)
$nSwordBmp.SetPixel(5, 8, $nBladeEdge)
$nSwordBmp.SetPixel(6, 7, $nBladeEdge)
$nSwordBmp.SetPixel(7, 6, $nBladeEdge)
$nSwordBmp.SetPixel(8, 5, $nBladeEdge)
$nSwordBmp.SetPixel(9, 4, $nBladeEdge)
$nSwordBmp.SetPixel(10, 3, $nBladeEdge)
$nSwordBmp.SetPixel(11, 2, $nBladeEdge)

$nSwordBmp.SetPixel(6, 10, $nBladeMain)
$nSwordBmp.SetPixel(7, 9, $nBladeMain)
$nSwordBmp.SetPixel(8, 8, $nBladeMain)
$nSwordBmp.SetPixel(9, 7, $nBladeMain)
$nSwordBmp.SetPixel(10, 6, $nBladeMain)

$nSwordBmp.Save("$packDir\assets\minecraft\textures\item\netherite_sword.png", [System.Drawing.Imaging.ImageFormat]::Png)
$swordBmp.Dispose()
$nSwordBmp.Dispose()

# 7. Nen thanh file .zip
$zipFile = "$PSScriptRoot\resourcepacks\$packName.zip"
if (Test-Path $zipFile) { Remove-Item -Force $zipFile }
[System.IO.Compression.ZipFile]::CreateFromDirectory($packDir, $zipFile)

# 8. Cai dat duy nhat file .zip vao thu muc game cua Minecraft
$mcRpDir = "$env:APPDATA\.tlauncher\legacy\Minecraft\game\resourcepacks"
if (Test-Path "$mcRpDir\$packName") { Remove-Item -Recurse -Force "$mcRpDir\$packName" }
Copy-Item -Path $zipFile -Destination "$mcRpDir\$packName.zip" -Force

Write-Host "Tao va cap nhat Resource Pack thanh cong!" -ForegroundColor Green
Write-Host "Vi tri file: $mcRpDir\$packName.zip" -ForegroundColor Cyan
