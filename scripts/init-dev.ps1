#Requires -Version 7
<#
.SYNOPSIS
    初始化 OpenTune 开发环境
.DESCRIPTION
    下载并配置所有必需的依赖项，包括：
    - JUCE 框架
    - ASIO SDK
    - ONNX Runtime (CPU + DirectML)
    - Git LFS 文件拉取
.NOTES
    需要 PowerShell 7+、Git、CMake 3.22+、MSVC 2022
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = $PSScriptRoot,

    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'juce', 'asio', 'onnx', 'lfs')]
    [string]$Step = 'all'
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "`n`e[36m=== $Message `e[0m" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "`e[32m✓ $Message`e[0m" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "`e[33m⚠ $Message`e[0m" -ForegroundColor Yellow
}

function Test-Command {
    param([string]$Name)
    $exists = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $exists) {
        Write-Warning-Custom "未找到命令: $Name"
        return $false
    }
    return $true
}

# ============================================================================
# 前置检查
# ============================================================================
if ($Step -in @('all', 'juce', 'asio', 'onnx')) {
    Write-Step '检查前置工具'

    $tools = @('git', 'cmake')
    foreach ($tool in $tools) {
        if (-not (Test-Command $tool)) {
            throw "缺少必需工具: $tool。请先安装后再运行此脚本。"
        }
    }

    # 检查 MSVC
    $vsWhere = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -format json 2>$null
    if (-not $vsWhere) {
        Write-Warning-Custom '未检测到 Visual Studio 2022 带 C++ 工作负载'
        Write-Host '  请安装 Visual Studio 2022 并确保选中 "使用 C++ 的桌面开发" 工作负载'
    } else {
        Write-Success 'Visual Studio 2022 已安装'
    }
}

# ============================================================================
# 1. 拉取 Git LFS 文件
# ============================================================================
if ($Step -in @('all', 'lfs')) {
    Write-Step '拉取 Git LFS 文件'

    Push-Location $ProjectRoot
    try {
        git lfs pull
        if ($LASTEXITCODE -eq 0) {
            Write-Success 'Git LFS 文件拉取完成'
        } else {
            throw 'Git LFS pull 失败'
        }
    } finally {
        Pop-Location
    }
}

# ============================================================================
# 2. 下载 JUCE 框架
# ============================================================================
if ($Step -in @('all', 'juce')) {
    Write-Step '下载 JUCE 框架'

    Push-Location $ProjectRoot
    try {
        $juceUrl = 'https://github.com/juce-framework/JUCE/archive/refs/tags/8.0.12.zip'
        $juceZip = 'juce-8.0.12.zip'
        $juceDir = 'JUCE-master'

        if (Test-Path $juceDir) {
            Write-Warning-Custom "$juceDir 已存在，跳过下载"
        } else {
            Write-Host "  下载 JUCE 8.0.12..."
            Invoke-WebRequest -Uri $juceUrl -OutFile $juceZip
            
            Write-Host '  解压...'
            Expand-Archive -Path $juceZip -DestinationPath '.' -Force
            Rename-Item -Path 'JUCE-8.0.12' -NewName $juceDir -Force
            Remove-Item $juceZip
            
            Write-Success "JUCE 框架已下载到 $juceDir"
        }
    } finally {
        Pop-Location
    }
}

# ============================================================================
# 3. 下载 ASIO SDK
# ============================================================================
if ($Step -in @('all', 'asio')) {
    Write-Step '下载 ASIO SDK'

    Push-Location $ProjectRoot
    try {
        $asioUrl = 'https://github.com/audiosdk/asio/archive/refs/heads/master.zip'
        $asioZip = 'asio-sdk.zip'
        $juceDir = 'JUCE-master'
        $asioDest = Join-Path $juceDir 'modules\juce_audio_devices\native\asio'

        if (Test-Path $asioDest) {
            Write-Warning-Custom "ASIO SDK 已存在于 $asioDest，跳过下载"
        } else {
            Write-Host '  下载 ASIO SDK...'
            Invoke-WebRequest -Uri $asioUrl -OutFile $asioZip
            
            Write-Host '  解压...'
            Expand-Archive -Path $asioZip -DestinationPath '.' -Force
            
            $asioRoot = Get-ChildItem -Directory | Where-Object { $_.Name -like 'asio-*' } | Select-Object -First 1
            if (-not $asioRoot) {
                throw 'ASIO SDK 解压后未找到'
            }

            Write-Host '  复制到 JUCE 目录...'
            New-Item -ItemType Directory -Force -Path $asioDest | Out-Null
            Copy-Item "$($asioRoot.FullName)\common\*" $asioDest -Recurse -Force
            Copy-Item "$($asioRoot.FullName)\asio\*" $asioDest -Recurse -Force
            Copy-Item "$($asioRoot.FullName)\host\*" $asioDest -Recurse -Force
            
            Remove-Item $asioZip
            Remove-Item $asioRoot.FullName -Recurse -Force
            
            Write-Success "ASIO SDK 已安装到 $asioDest"
        }
    } finally {
        Pop-Location
    }
}

# ============================================================================
# 4. 下载 ONNX Runtime
# ============================================================================
if ($Step -in @('all', 'onnx')) {
    Write-Step '下载 ONNX Runtime'

    Push-Location $ProjectRoot
    try {
        # 4.1 DirectML
        $ortDmlDir = 'onnxruntime-dml-1.24.4'
        $ortDmlNupkgUrl = 'https://api.nuget.org/v3-flatcontainer/microsoft.ml.onnxruntime.directml/1.24.4/microsoft.ml.onnxruntime.directml.1.24.4.nupkg'
        $ortDmlNupkg = 'onnxruntime-dml.nupkg'

        if (Test-Path $ortDmlDir) {
            Write-Warning-Custom "$ortDmlDir 已存在，跳过 DirectML 下载"
        } else {
            Write-Host '  下载 ONNX Runtime DirectML...'
            Invoke-WebRequest -Uri $ortDmlNupkgUrl -OutFile $ortDmlNupkg
            
            Write-Host '  解压 DirectML...'
            $tempDir = "${ortDmlDir}-temp"
            New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
            Expand-Archive -Path $ortDmlNupkg -DestinationPath $tempDir -Force
            Remove-Item $ortDmlNupkg
            Rename-Item $tempDir $ortDmlDir
            
            Write-Success "ONNX Runtime DirectML 已安装到 $ortDmlDir"
        }

        # 4.2 CPU
        $ortCpuDir = 'onnxruntime-win-x64-1.24.4'
        $ortCpuUrl = 'https://github.com/microsoft/onnxruntime/releases/download/v1.24.4/onnxruntime-win-x64-1.24.4.zip'
        $ortCpuZip = 'onnxruntime-cpu.zip'

        if (Test-Path $ortCpuDir) {
            Write-Warning-Custom "$ortCpuDir 已存在，跳过 CPU 下载"
        } else {
            Write-Host '  下载 ONNX Runtime CPU...'
            Invoke-WebRequest -Uri $ortCpuUrl -OutFile $ortCpuZip
            
            Write-Host '  解压 CPU Runtime...'
            Expand-Archive -Path $ortCpuZip -DestinationPath '.' -Force
            Remove-Item $ortCpuZip
            
            Write-Success "ONNX Runtime CPU 已安装到 $ortCpuDir"
        }
    } finally {
        Pop-Location
    }
}

# ============================================================================
# 完成
# ============================================================================
if ($Step -eq 'all') {
    Write-Step '初始化完成'
    Write-Host ''
    Write-Host '后续步骤:'
    Write-Host '  1. 配置 CMake: mkdir build && cd build'
    Write-Host '  2. cmake .. -G "Visual Studio 17 2022" -A x64'
    Write-Host '  3. cmake --build . --config Release'
    Write-Host ''
    Write-Host '或直接运行: .\scripts\build.ps1 (如果存在)'
    Write-Host ''
}
