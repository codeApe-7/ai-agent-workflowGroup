# ================================================================
# aiGroup 项目 - Skills 更新脚本 (Windows PowerShell)
# 用法: .\scripts\update-skills.ps1 [-Target all|ccpm|simone|engineering|manual]
# ================================================================

param(
    [ValidateSet("all", "ccpm", "pm", "simone", "engineering", "manual")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"
$SkillsDir = ".cursor\skills"
$TempDir = Join-Path $env:TEMP "aigroup-skills-update"

function Write-Info  { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Update-FromGitHub {
    param(
        [string]$Repo,
        [string]$TargetName
    )

    Write-Info "正在从 github.com/$Repo 更新 $TargetName ..."

    $cloneDir = Join-Path $TempDir ($Repo -replace "/", "_")

    if (-not (Test-Path $cloneDir)) {
        git clone --depth 1 "https://github.com/$Repo.git" $cloneDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Err "克隆 $Repo 失败，跳过"
            return
        }
    }

    $targetPath = Join-Path $SkillsDir $TargetName
    if (Test-Path $targetPath) { Remove-Item $targetPath -Recurse -Force }
    Copy-Item $cloneDir $targetPath -Recurse -Force
    # 清理 .git
    $gitDir = Join-Path $targetPath ".git"
    if (Test-Path $gitDir) { Remove-Item $gitDir -Recurse -Force }

    Write-Info "$TargetName 已更新"
}

function Update-EngineeringTeam {
    $repo = "alirezarezvani/claude-skills"
    $cloneDir = Join-Path $TempDir "alirezarezvani_claude-skills"

    Write-Info "正在从 github.com/$repo 更新 Engineering Team ..."

    if (-not (Test-Path $cloneDir)) {
        git clone --depth 1 "https://github.com/$repo.git" $cloneDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Err "克隆 $repo 失败"
            return
        }
    }

    $skills = @(
        "aws-solution-architect", "code-reviewer", "ms365-tenant-manager",
        "senior-architect", "senior-backend", "senior-computer-vision",
        "senior-data-engineer", "senior-data-scientist", "senior-devops",
        "senior-fullstack", "senior-ml-engineer", "senior-prompt-engineer",
        "senior-secops", "senior-security", "tech-stack-evaluator"
    )

    $updated = 0
    foreach ($skill in $skills) {
        # 在克隆目录中搜索 skill
        $found = Get-ChildItem -Path $cloneDir -Directory -Recurse -Filter $skill -Depth 3 |
                 Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
                 Select-Object -First 1

        if ($found) {
            $targetPath = Join-Path $SkillsDir $skill
            if (Test-Path $targetPath) { Remove-Item $targetPath -Recurse -Force }
            Copy-Item $found.FullName $targetPath -Recurse -Force
            Write-Host "  + $skill" -ForegroundColor Green
            $updated++
        } else {
            Write-Host "  - $skill (未找到，保留现有版本)" -ForegroundColor Yellow
        }
    }

    Write-Info "Engineering Team: $updated/$($skills.Count) 个 skill 已更新"
}

function Show-ManualSkills {
    Write-Warn "以下 skill 来自 SkillsMP 技能市场，需要手动更新："
    Write-Host "  - ui-ux-pro-max (Ella: UI/UX 设计工具)"
    Write-Host "  - senior-qa (Kyle: QA 技能包)"
    Write-Host "  - tdd-guide (Kyle: TDD 指南)"
    Write-Host "  - senior-frontend (Ella: 前端技能包)"
    Write-Host ""
    Write-Host "  请访问 SkillsMP 技能市场下载最新版本后替换对应目录。"
}

# 创建临时目录
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }

Write-Host "======================================"
Write-Host "  aiGroup Skills 更新工具"
Write-Host "======================================"
Write-Host ""

switch ($Target) {
    "all" {
        Update-FromGitHub -Repo "automazeio/ccpm" -TargetName "ccpm"
        Update-FromGitHub -Repo "mohitagw15856/pm-claude-skills" -TargetName "pm-claude-skills"
        Update-FromGitHub -Repo "Helmi/claude-simone" -TargetName "claude-simone"
        Update-EngineeringTeam
        Write-Host ""
        Show-ManualSkills
    }
    "ccpm" {
        Update-FromGitHub -Repo "automazeio/ccpm" -TargetName "ccpm"
    }
    "pm" {
        Update-FromGitHub -Repo "mohitagw15856/pm-claude-skills" -TargetName "pm-claude-skills"
    }
    "simone" {
        Update-FromGitHub -Repo "Helmi/claude-simone" -TargetName "claude-simone"
    }
    "engineering" {
        Update-EngineeringTeam
    }
    "manual" {
        Show-ManualSkills
    }
}

Write-Host ""
Write-Info "更新完成！"

# 更新 manifest 时间戳
$manifestPath = Join-Path $SkillsDir "skills-manifest.json"
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    $manifest._updated = (Get-Date -Format "yyyy-MM-dd")
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding UTF8
    Write-Info "manifest 时间戳已更新"
}

# 清理临时目录
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
