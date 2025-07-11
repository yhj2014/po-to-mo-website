<#
.SYNOPSIS
将Python PO到MO转换器打包为Android APK文件

.DESCRIPTION
此脚本使用BeeWare的briefcase工具将Python应用打包为Android APK
#>

# 检查是否以管理员身份运行
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员身份运行此脚本!" -ForegroundColor Red
    exit
}

# 设置变量
$PROJECT_NAME = "POtoMOConverter"
$OUTPUT_DIR = "dist_apk"
$APP_NAME = "com.example.potomoconverter"
$APP_VERSION = "1.0.0"

# 检查Python是否安装
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "未检测到Python，正在安装Python..." -ForegroundColor Yellow
    
    # 下载并安装最新版Python
    $pythonInstaller = "$env:TEMP\python_installer.exe"
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/latest/python-3.x.x-amd64.exe" -OutFile $pythonInstaller
    Start-Process -FilePath $pythonInstaller -Args "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    
    # 刷新PATH环境变量
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # 验证安装
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "Python安装失败，请手动安装Python后重试" -ForegroundColor Red
        exit
    }
}

# 检查Java JDK是否安装
if (-not (Get-Command javac -ErrorAction SilentlyContinue)) {
    Write-Host "未检测到Java JDK，正在安装OpenJDK 11..." -ForegroundColor Yellow
    
    # 下载并安装OpenJDK
    $jdkInstaller = "$env:TEMP\openjdk.msi"
    Invoke-WebRequest -Uri "https://aka.ms/download-jdk/microsoft-jdk-11-windows-x64.msi" -OutFile $jdkInstaller
    Start-Process -FilePath "msiexec.exe" -Args "/i $jdkInstaller /quiet" -Wait
    
    # 设置JAVA_HOME环境变量
    $javaPath = "C:\Program Files\Microsoft\jdk-11.*.*-windows-x64"
    [Environment]::SetEnvironmentVariable("JAVA_HOME", (Get-Item $javaPath).FullName, "Machine")
    $env:JAVA_HOME = (Get-Item $javaPath).FullName
    $env:Path += ";$env:JAVA_HOME\bin"
    
    # 验证安装
    if (-not (Get-Command javac -ErrorAction SilentlyContinue)) {
        Write-Host "Java JDK安装失败，请手动安装后重试" -ForegroundColor Red
        exit
    }
}

# 检查Android SDK是否安装
if (-not (Test-Path "$env:LOCALAPPDATA\Android\Sdk")) {
    Write-Host "未检测到Android SDK，正在安装..." -ForegroundColor Yellow
    
    # 下载并安装Android Studio
    $androidInstaller = "$env:TEMP\android-studio.exe"
    Invoke-WebRequest -Uri "https://redirector.gvt1.com/edgedl/android/studio/install/2022.3.1.20/android-studio-2022.3.1.20-windows.exe" -OutFile $androidInstaller
    Start-Process -FilePath $androidInstaller -Args "/S" -Wait
    
    # 设置ANDROID_HOME环境变量
    $sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "Machine")
    $env:ANDROID_HOME = $sdkPath
    $env:Path += ";$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\tools\bin"
    
    # 安装必要的Android平台工具
    Write-Host "正在通过sdkmanager安装必要的Android工具..." -ForegroundColor Yellow
    Start-Process -FilePath "sdkmanager" -Args "platform-tools" -Wait
    Start-Process -FilePath "sdkmanager" -Args "platforms;android-33" -Wait
    Start-Process -FilePath "sdkmanager" -Args "build-tools;33.0.0" -Wait
    Start-Process -FilePath "sdkmanager" -Args "ndk;25.1.8937393" -Wait
}

# 检查BeeWare是否安装
if (-not (python -m pip show briefcase)) {
    Write-Host "正在安装BeeWare工具..." -ForegroundColor Yellow
    python -m pip install --upgrade pip
    python -m pip install briefcase
}

# 创建输出目录
if (Test-Path $OUTPUT_DIR) {
    Remove-Item $OUTPUT_DIR -Recurse -Force
}
New-Item -ItemType Directory -Path $OUTPUT_DIR | Out-Null

# 初始化BeeWare项目
if (-not (Test-Path "pyproject.toml")) {
    Write-Host "正在初始化BeeWare项目..." -ForegroundColor Green
    briefcase new
}

# 配置pyproject.toml文件
$pyprojectContent = @"
[build-system]
requires = ["briefcase"]

[tool.briefcase]
project_name = "$PROJECT_NAME"
bundle = "$APP_NAME"
version = "$APP_VERSION"
url = "http://example.com"
license = "MIT"
author = "Your Name"
author_email = "your@email.com"

[tool.briefcase.app.$APP_NAME]
formal_name = "$PROJECT_NAME"
description = "PO to MO File Converter"
sources = ["po_to_mo_converter.py"]
requires = []

[tool.briefcase.app.$APP_NAME.android]
permissions = []
"@

Set-Content -Path "pyproject.toml" -Value $pyprojectContent

# 构建Android APK
Write-Host "正在构建Android APK..." -ForegroundColor Green
briefcase create android
briefcase build android
briefcase package android --output "$OUTPUT_DIR"

# 检查构建结果
if (Test-Path "$OUTPUT_DIR\$APP_NAME-*-debug.apk") {
    $apkFile = (Get-Item "$OUTPUT_DIR\$APP_NAME-*-debug.apk").FullName
    Write-Host "构建成功! APK文件位于: $apkFile" -ForegroundColor Green
} else {
    Write-Host "构建失败，请检查错误信息" -ForegroundColor Red
}
