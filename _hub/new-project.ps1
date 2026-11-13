<#
.SYNOPSIS
    在某个领域下新建独立项目：独立 git、skill 整目录联接、规则文件、协作文件，并登记到 skills-registry.json。
    领域自己的脚手架（如有）负责建内容目录，然后调用本脚本。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File D:/codex/workbuddy work\_hub\new-project.ps1 -Domain "工作类型1" -Name "项目1"
#>
param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter(Mandatory = $true)][string]$Name
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$domainDir = Join-Path $Root $Domain
if (-not (Test-Path $domainDir)) { throw "领域不存在: $domainDir（先运行 new-domain.ps1）" }
$dir = Join-Path $domainDir $Name
Write-Host "== 新建项目: $dir" -ForegroundColor Cyan
New-Item -ItemType Directory -Force $dir | Out-Null

New-FromTemplate 'AGENTS.md'  (Join-Path $dir 'AGENTS.md') $Name
$agents = Join-Path $dir 'AGENTS.md'
$text = [IO.File]::ReadAllText($agents, [Text.Encoding]::UTF8)
if ($text -notmatch '多 AI 协作纪律') {
    $rules = [IO.File]::ReadAllText((Join-Path $HubDir 'templates\协作纪律.md'), [Text.Encoding]::UTF8)
    Write-Utf8 $agents ($text.TrimEnd() + "`n`n" + $rules)
}
Add-InstallSection $agents $dir "- 本项目专属 skill 装本项目 ``.agents\skills\``；跨项目共享 skill 装所属领域 ``.agents\skills\``（sync-skills 自动挂进各项目）。``.claude/skills`` 只放同步脚本生成的联接。`n"
New-FromTemplate 'CLAUDE.md'  (Join-Path $dir 'CLAUDE.md')  $Name
New-FromTemplate 'TASKS.md'   (Join-Path $dir 'TASKS.md')   $Name
New-FromTemplate 'HANDOFF.md' (Join-Path $dir 'HANDOFF.md') $Name
Set-ClaudeMdExcludes $dir
Initialize-Git $dir @('.agents/skills/*/tools/')

# 领域 .gitignore 排除项目目录（项目有自己的 git）
$dgi = Join-Path $domainDir '.gitignore'
$line = "/$Name/"
$cur = if (Test-Path $dgi) { [IO.File]::ReadAllText($dgi, [Text.Encoding]::UTF8) } else { '' }
if ($cur -notmatch [regex]::Escape($line)) { Write-Utf8 $dgi ($cur.TrimEnd() + "`n" + $line + "`n") }

$reg = Read-Registry
$projects = @($reg.domains.$Domain.projects | Where-Object { $_ })
if ($projects -notcontains $Name) {
    $reg.domains.$Domain.projects = @($projects + $Name)
    Save-Registry $reg
    Write-Host "  [√] 已登记到 skills-registry.json"
}

& (Join-Path $HubDir 'sync-skills.ps1')
Write-Host "完成。请单独打开 $dir 开始工作。" -ForegroundColor Green
