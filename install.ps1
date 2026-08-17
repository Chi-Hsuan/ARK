#Requires -Version 5.1
<#
.SYNOPSIS
    ARK 安裝指令（Windows）

.DESCRIPTION
    把 ARK 的 agent、skill 與中立層複製到目標專案。
    複製完成後，在該專案叫用 Ark 總管執行導入，完成設定與文件骨架建立。

    行為與 install.sh 相同。

.EXAMPLE
    在目標專案資料夾執行
        git clone --depth 1 <ARK repo URL> $env:TEMP\ark
        & "$env:TEMP\ark\install.ps1"

.EXAMPLE
    指定目標路徑
        & "$env:TEMP\ark\install.ps1" -Target C:\projects\my-project

.EXAMPLE
    不安裝 Claude Code 轉接層（只給 Copilot 與 Codex 用的環境）
        & "$env:TEMP\ark\install.ps1" -NoClaude

.NOTES
    若出現「無法載入檔案，因為這個系統上已停用指令碼執行」，改用：
        powershell -ExecutionPolicy Bypass -File .\install.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target = (Get-Location).Path,

    [Alias('y')]
    [switch]$Yes,

    # 跳過 .claude/ 與 CLAUDE.md。既有的檔案不會被刪除，只是不更新。
    [switch]$NoClaude
)

$ErrorActionPreference = 'Stop'

function Write-Err {
    param([string]$Message)
    Write-Host '錯誤 ' -ForegroundColor Red -NoNewline
    Write-Host $Message
    exit 1
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $Message"
}

$ArkSrc = $PSScriptRoot

# --- 檢查 -------------------------------------------------------------------

if (-not (Test-Path (Join-Path $ArkSrc '.ark\VERSION'))) {
    Write-Err "來源不是完整的 ARK repo：$ArkSrc"
}
if (-not (Test-Path $Target -PathType Container)) {
    Write-Err "目標資料夾不存在：$Target"
}

$Target = (Resolve-Path $Target).Path.TrimEnd('\')
$ArkSrc = $ArkSrc.TrimEnd('\')

if ($Target -eq $ArkSrc -or $Target.StartsWith("$ArkSrc\")) {
    Write-Err "目標不能是 ARK repo 本身或其子目錄：$Target"
}

$Version = (Get-Content (Join-Path $ArkSrc '.ark\VERSION') -Raw).Trim()
$TargetVersionFile = Join-Path $Target '.ark\VERSION'

Write-Host ''
if (Test-Path $TargetVersionFile) {
    $Old = (Get-Content $TargetVersionFile -Raw).Trim()
    $Mode = '更新'
    Write-Host "ARK $Old -> $Version"
} else {
    $Mode = '安裝'
    Write-Host "ARK $Version"
}

Write-Host "目標專案：$Target"
Write-Host ''
Write-Host "將$Mode 下列項目："
Write-Info '.ark/                    流程、角色、技能、範本、套件規範、工具'
Write-Info '.github/agents/Ark*      Copilot 角色'
Write-Info '.github/skills/          Copilot 技能'
if (-not $NoClaude) {
    Write-Info '.claude/agents/ark-*     Claude Code 角色'
    Write-Info '.claude/skills/          Claude Code 技能'
}
Write-Info 'AGENTS.md                Codex 入口'
if (-not $NoClaude) {
    Write-Info 'CLAUDE.md                Claude Code 入口'
}
Write-Host ''
Write-Host '不會動到：專案既有的文件、其他 agent 檔、.ark/config.yml'
if ($NoClaude) {
    Write-Host '已指定 -NoClaude：跳過 .claude/ 與 CLAUDE.md（既有的不會被刪除，但也不會更新）'
}
Write-Host ''

if (-not $Yes) {
    $reply = Read-Host '繼續？[y/N]'
    if ($reply -notmatch '^[yY]') {
        Write-Host '已取消'
        exit 0
    }
}

# --- 複製 -------------------------------------------------------------------

Write-Host ''

# .ark/ ——中立層，除了 config.yml 之外全部覆寫
$ArkDir = Join-Path $Target '.ark'
New-Item -ItemType Directory -Path $ArkDir -Force | Out-Null

foreach ($item in @('VERSION', 'CHANGELOG.md', 'workflow.md', 'roles', 'skills', 'templates', 'standards', 'tools')) {
    $srcItem = Join-Path $ArkSrc ".ark\$item"
    if (-not (Test-Path $srcItem)) { continue }
    $dstItem = Join-Path $ArkDir $item
    if (Test-Path $dstItem) { Remove-Item $dstItem -Recurse -Force }
    Copy-Item $srcItem -Destination $ArkDir -Recurse -Force
}
Write-Info '已寫入 .ark/'

if (Test-Path (Join-Path $ArkDir 'config.yml')) {
    Write-Info '保留既有 .ark/config.yml'
} else {
    Write-Info '未建立 .ark/config.yml（稍後由 Ark 總管依你的回答產生）'
}

# Copilot 轉接層——只動 ARK 自己的檔案
$AgentsDir = Join-Path $Target '.github\agents'
New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
Get-ChildItem (Join-Path $ArkSrc '.github\agents') -Filter 'Ark*.agent.md' -File |
    ForEach-Object { Copy-Item $_.FullName -Destination $AgentsDir -Force }
Write-Info '已寫入 .github/agents/'

$SkillsDir = Join-Path $Target '.github\skills'
New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
Get-ChildItem (Join-Path $ArkSrc '.github\skills') -Directory | ForEach-Object {
    $dstSkill = Join-Path $SkillsDir $_.Name
    if (Test-Path $dstSkill) { Remove-Item $dstSkill -Recurse -Force }
    Copy-Item $_.FullName -Destination $SkillsDir -Recurse -Force
}
Write-Info '已寫入 .github/skills/'

# Claude Code 轉接層——只動 ARK 自己的檔案
if ($NoClaude) {
    Write-Info '略過 .claude/（-NoClaude）'
} else {
    $ClaudeAgents = Join-Path $Target '.claude\agents'
    New-Item -ItemType Directory -Path $ClaudeAgents -Force | Out-Null
    Get-ChildItem (Join-Path $ArkSrc '.claude\agents') -Filter 'ark-*.md' -File |
        ForEach-Object { Copy-Item $_.FullName -Destination $ClaudeAgents -Force }
    Write-Info '已寫入 .claude/agents/'

    $ClaudeSkills = Join-Path $Target '.claude\skills'
    New-Item -ItemType Directory -Path $ClaudeSkills -Force | Out-Null
    Get-ChildItem (Join-Path $ArkSrc '.claude\skills') -Directory | ForEach-Object {
        $dstSkill = Join-Path $ClaudeSkills $_.Name
        if (Test-Path $dstSkill) { Remove-Item $dstSkill -Recurse -Force }
        Copy-Item $_.FullName -Destination $ClaudeSkills -Recurse -Force
    }
    Write-Info '已寫入 .claude/skills/'
}

# 入口檔——專案已有自己的版本時不覆寫，另存待合併
$EntryFiles = if ($NoClaude) { @('AGENTS.md') } else { @('AGENTS.md', 'CLAUDE.md') }
$NeedsMerge = @()
foreach ($file in $EntryFiles) {
    $src = Join-Path $ArkSrc $file
    $dst = Join-Path $Target $file
    $isArk = $true
    if (Test-Path $dst) {
        $isArk = [bool]((Get-Content $dst -TotalCount 5) | Where-Object { $_ -match '^#\s*ARK\s*$' })
    }
    if ((Test-Path $dst) -and -not $isArk) {
        $alt = Join-Path $Target ($file -replace '\.md$', '.ark.md')
        Copy-Item $src -Destination $alt -Force
        Write-Info "偵測到既有 ${file}，ARK 的版本另存為 $(Split-Path $alt -Leaf)"
        $NeedsMerge += $file
    } else {
        Copy-Item $src -Destination $dst -Force
        Write-Info "已寫入 $file"
    }
}

# --- 後續 -------------------------------------------------------------------

Write-Host ''
Write-Host "$Mode 完成" -ForegroundColor Green
Write-Host ''
$ReloadNote = if ($NoClaude) { 'Copilot 才會載入 ARK 的 agent' } else { 'Copilot 才會載入 ARK 的 agent；Claude Code 需重開對話' }
$CommitList = if ($NoClaude) { '.ark/、.github/、AGENTS.md' } else { '.ark/、.github/、.claude/、AGENTS.md、CLAUDE.md' }

Write-Host '接下來：'
Write-Host "  1. 用 VS Code 開啟 $Target"
Write-Host "  2. Reload Window（${ReloadNote}）"
Write-Host '  3. 叫用 Ark 總管，選擇「導入 / 升級 ARK」完成設定'
Write-Host "  4. 確認無誤後把 ${CommitList} 與文件資料夾提交進版控"

if ($NeedsMerge.Count -gt 0) {
    Write-Host ''
    Write-Host '注意 ' -ForegroundColor Yellow -NoNewline
    Write-Host "這個專案原本就有：$($NeedsMerge -join ', ')"
    Write-Host '     這些工具各自只讀自己的入口檔，請把 *.ark.md 的內容併入後刪除該檔，'
    Write-Host '     否則對應的工具不會知道這是 ARK 專案。'
}

Write-Host ''
