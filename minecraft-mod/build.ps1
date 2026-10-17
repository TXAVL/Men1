# Build script for UnlockAdvancements Fabric Mod
$ErrorActionPreference = "Stop"

$mcJar = "$env:APPDATA\.tlauncher\legacy\Minecraft\game\versions\Fabric 26.3\Fabric 26.3.jar"
$libs = Get-ChildItem -Path "$env:APPDATA\.tlauncher\legacy\Minecraft\game\libraries" -Recurse -Filter "*.jar" | ForEach-Object { $_.FullName }
$cp = ($libs -join ';') + ";$mcJar"

$javac = "C:\Users\admin\AppData\Roaming\.tlauncher\legacy\Minecraft\jre\java-runtime-epsilon\windows-x64\java-runtime-epsilon\bin\javac.exe"
$jarExe = "C:\Users\admin\AppData\Roaming\.tlauncher\legacy\Minecraft\jre\java-runtime-epsilon\windows-x64\java-runtime-epsilon\bin\jar.exe"

$buildDir = "$PSScriptRoot\build"
$classesDir = "$buildDir\classes"

if (Test-Path $classesDir) { Remove-Item -Recurse -Force $classesDir }
New-Item -ItemType Directory -Force -Path $classesDir | Out-Null

$srcFiles = Get-ChildItem -Path "$PSScriptRoot\src\main\java" -Recurse -Filter "*.java" | ForEach-Object { $_.FullName }

Write-Host "[1/3] Dang bien dich ma nguon..." -ForegroundColor Cyan
& $javac -cp "$cp" -d "$classesDir" -encoding UTF-8 $srcFiles

Write-Host "[2/3] Dang dong goi file .jar..." -ForegroundColor Cyan
Copy-Item -Path "$PSScriptRoot\src\main\resources\*" -Destination "$classesDir\" -Force
$outJar = "$buildDir\UnlockAdvancements-1.0.0.jar"
Push-Location $classesDir
& $jarExe -cf "$outJar" *
Pop-Location

Write-Host "[3/3] Dang cai vao thu muc mods cua game..." -ForegroundColor Cyan
$modsDir = "$env:APPDATA\.tlauncher\legacy\Minecraft\game\mods"
if (!(Test-Path $modsDir)) { New-Item -ItemType Directory -Force -Path $modsDir | Out-Null }
Copy-Item -Path "$outJar" -Destination $modsDir -Force

Write-Host "Hoan tat! Mod da duoc cai dat vao game: $modsDir\UnlockAdvancements-1.0.0.jar" -ForegroundColor Green
