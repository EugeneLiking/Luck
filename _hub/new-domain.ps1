<#
.SYNOPSIS
    在 D:/codex/workbuddy work 下新建一个任务领域（独立 git、规则文件、协作文件、skill 目录），并登记到 skills-registry.json。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File D:/codex/workbuddy work\_hub\new-domain.ps1 -Name "工作类型1"
#>
param([Parameter(Mandatory = $true)][string]$Name)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$dir = Join-Path $Root $Name
Write-Host "== 新建领域: $dir" -ForegroundColor Cyan
New-Item -ItemType Directory -Force (Join-Path $dir '.agents\skills') | Out-Null

New-FromTemplate 'AGENTS.md'  (Join-Path $dir 'AGENTS.md') $Name
$agents = Join-Path $dir 'AGENTS.md'
$text = [IO.File]::ReadAllText($agents, [Text.Encoding]::UTF8)
if ($text -notmatch '多 AI 协作纪律') {
    $rules = [IO.File]::ReadAllText((Join-Path $HubDir 'templates\协作纪律.md'), [Text.Encoding]::UTF8)
    Write-Utf8 $agents ($text.TrimEnd() + "`n`n" + $rules)
}
Add-InstallSection $agents $dir
New-FromTemplate 'CLAUDE.md'  (Join-Path $dir 'CLAUDE.md')  $Name
New-FromTemplate 'TASKS.md'   (Join-Path $dir 'TASKS.md')   $Name
New-FromTemplate 'HANDOFF.md' (Join-Path $dir 'HANDOFF.md') $Name
Set-ClaudeMdExcludes $dir
Initialize-Git $dir @()

# 根 .gitignore 排除该领域（领域有自己的 git）
$rgi = Join-Path $Root '.gitignore'
$line = "/$Name/"
$cur = if (Test-Path $rgi) { [IO.File]::ReadAllText($rgi, [Text.Encoding]::UTF8) } else { '' }
if ($cur -notmatch [regex]::Escape($line)) { Write-Utf8 $rgi ($cur.TrimEnd() + "`n" + $line + "`n") }

$reg = Read-Registry
if (-not $reg.domains.$Name) {
    $reg.domains | Add-Member -NotePropertyName $Name -NotePropertyValue ([pscustomobject]@{ projects = @() })
    $reg.skills  | Add-Member -NotePropertyName $Name -NotePropertyValue ([pscustomobject]@{})
    Save-Registry $reg
    Write-Host "  [√] 已登记到 skills-registry.json"
}

& (Join-Path $HubDir 'sync-skills.ps1')
Write-Host "完成。请补全 $agents 的第 1 节，并在总管理会话安装该领域需要的 skill。" -ForegroundColor Green
