<#
.SYNOPSIS
    aiGroup Skills Update Tool
.DESCRIPTION
    Update skills from GitHub repositories
.PARAMETER Target
    Which skills to update: all, ccpm, pm, simone, engineering, manual
.EXAMPLE
    .\scripts\update-skills.ps1 -Target all
#>

param(
    [ValidateSet('all', 'ccpm', 'pm', 'simone', 'engineering', 'manual')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
$SkillsDir = '.cursor\skills'
$TempDir = Join-Path $env:TEMP 'aigroup-skills-update'

function Write-Info  { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Update-FromGitHub {
    param(
        [string]$Repo,
        [string]$TargetName
    )

    Write-Info "Updating $TargetName from github.com/$Repo ..."

    $cloneDir = Join-Path $TempDir ($Repo -replace '/', '_')

    if (-not (Test-Path $cloneDir)) {
        $env:GIT_TERMINAL_PROMPT = '0'
        $prevPref = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        & git clone --depth 1 --quiet "https://github.com/$Repo.git" $cloneDir 2>&1 | Out-Null
        $cloneResult = $LASTEXITCODE
        $ErrorActionPreference = $prevPref
        if ($cloneResult -ne 0) {
            Write-Err "Failed to clone $Repo, skipping"
            return
        }
    }

    $targetPath = Join-Path $SkillsDir $TargetName
    if (Test-Path $targetPath) {
        Remove-Item $targetPath -Recurse -Force
    }
    Copy-Item $cloneDir $targetPath -Recurse -Force

    $gitDir = Join-Path $targetPath '.git'
    if (Test-Path $gitDir) {
        Remove-Item $gitDir -Recurse -Force
    }

    Write-Info "$TargetName updated successfully"
}

function Update-EngineeringTeam {
    $repo = 'alirezarezvani/claude-skills'
    $cloneDir = Join-Path $TempDir 'alirezarezvani_claude-skills'

    Write-Info "Updating Engineering Team from github.com/$repo ..."

    if (-not (Test-Path $cloneDir)) {
        $env:GIT_TERMINAL_PROMPT = '0'
        $prevPref = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        & git clone --depth 1 --quiet "https://github.com/$repo.git" $cloneDir 2>&1 | Out-Null
        $cloneResult = $LASTEXITCODE
        $ErrorActionPreference = $prevPref
        if ($cloneResult -ne 0) {
            Write-Err "Failed to clone $repo"
            return
        }
    }

    $skills = @(
        'aws-solution-architect', 'code-reviewer', 'ms365-tenant-manager',
        'senior-architect', 'senior-backend', 'senior-computer-vision',
        'senior-data-engineer', 'senior-data-scientist', 'senior-devops',
        'senior-fullstack', 'senior-ml-engineer', 'senior-prompt-engineer',
        'senior-secops', 'senior-security', 'tech-stack-evaluator'
    )

    $updated = 0
    foreach ($skill in $skills) {
        $found = Get-ChildItem -Path $cloneDir -Directory -Recurse -Filter $skill -Depth 3 -ErrorAction SilentlyContinue |
                 Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
                 Select-Object -First 1

        if ($found) {
            $targetPath = Join-Path $SkillsDir $skill
            if (Test-Path $targetPath) {
                Remove-Item $targetPath -Recurse -Force
            }
            Copy-Item $found.FullName $targetPath -Recurse -Force
            Write-Host "  + $skill" -ForegroundColor Green
            $updated++
        }
        else {
            Write-Host "  - $skill (not found, keeping current)" -ForegroundColor Yellow
        }
    }

    Write-Info "Engineering Team: $updated/$($skills.Count) skills updated"
}

function Show-ManualSkills {
    Write-Warn 'The following skills are from SkillsMP and need manual update:'
    Write-Host '  - ui-ux-pro-max (Ella: UI/UX design tool)'
    Write-Host '  - senior-qa (Kyle: QA skill pack)'
    Write-Host '  - tdd-guide (Kyle: TDD guide)'
    Write-Host '  - senior-frontend (Ella: Frontend skill pack)'
    Write-Host ''
    Write-Host '  Please download the latest version from SkillsMP marketplace.'
}

# Create temp dir
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

Write-Host '======================================'
Write-Host '  aiGroup Skills Update Tool'
Write-Host '======================================'
Write-Host ''

switch ($Target) {
    'all' {
        Update-FromGitHub -Repo 'automazeio/ccpm' -TargetName 'ccpm'
        Update-FromGitHub -Repo 'mohitagw15856/pm-claude-skills' -TargetName 'pm-claude-skills'
        Update-FromGitHub -Repo 'Helmi/claude-simone' -TargetName 'claude-simone'
        Update-EngineeringTeam
        Write-Host ''
        Show-ManualSkills
    }
    'ccpm' {
        Update-FromGitHub -Repo 'automazeio/ccpm' -TargetName 'ccpm'
    }
    'pm' {
        Update-FromGitHub -Repo 'mohitagw15856/pm-claude-skills' -TargetName 'pm-claude-skills'
    }
    'simone' {
        Update-FromGitHub -Repo 'Helmi/claude-simone' -TargetName 'claude-simone'
    }
    'engineering' {
        Update-EngineeringTeam
    }
    'manual' {
        Show-ManualSkills
    }
}

Write-Host ''
Write-Info 'Update complete!'

# Update manifest timestamp
$manifestPath = Join-Path $SkillsDir 'skills-manifest.json'
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    $manifest._updated = (Get-Date -Format 'yyyy-MM-dd')
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding UTF8
    Write-Info 'Manifest timestamp updated'
}

# Cleanup
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
