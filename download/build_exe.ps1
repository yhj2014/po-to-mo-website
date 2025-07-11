<#
.SYNOPSIS
将Python PO到MO转换器打包为Windows可执行文件

.DESCRIPTION
此脚本会自动安装所需依赖并将Python脚本打包为单个EXE文件
#>

# 检查是否以管理员身份运行
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员身份运行此脚本!" -ForegroundColor Red
    exit
}

# 设置变量
$SCRIPT_NAME = "po_to_mo_converter.py"
$EXE_NAME = "POtoMOConverter"
$OUTPUT_DIR = "dist_exe"
$ICON_PATH = ""

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

# 检查PyInstaller是否安装
if (-not (python -m pip show pyinstaller)) {
    Write-Host "正在安装PyInstaller..." -ForegroundColor Yellow
    python -m pip install --upgrade pip
    python -m pip install pyinstaller
}

# 创建输出目录
if (Test-Path $OUTPUT_DIR) {
    Remove-Item $OUTPUT_DIR -Recurse -Force
}
New-Item -ItemType Directory -Path $OUTPUT_DIR | Out-Null

# 构建EXE文件
Write-Host "正在构建EXE文件..." -ForegroundColor Green

$buildArgs = @(
    "--onefile",
    "--windowed",
    "--name=$EXE_NAME",
    "--distpath=$OUTPUT_DIR"
)

if ($ICON_PATH -and (Test-Path $ICON_PATH)) {
    $buildArgs += "--icon=$ICON_PATH"
}

pyinstaller $buildArgs $SCRIPT_NAME

# 检查构建结果
if (Test-Path "$OUTPUT_DIR\$EXE_NAME.exe") {
    Write-Host "构建成功! EXE文件位于: $OUTPUT_DIR\$EXE_NAME.exe" -ForegroundColor Green
} else {
    Write-Host "构建失败，请检查错误信息" -ForegroundColor Red
}
