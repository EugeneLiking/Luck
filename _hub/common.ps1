# _hub 脚本共用函数（由 new-domain.ps1 / new-project.ps1 引入）

$HubDir   = $PSScriptRoot
$Root     = Split-Path $HubDir -Parent
$Registry = Join-Path $HubDir 'skills-registry.json'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8($path, $text) {
    [IO.File]::WriteAllText($path, $text, $Utf8NoBom)
}
function Read-Registry { Get-Content $Registry -Raw -Encoding UTF8 | ConvertFrom-Json }
function Save-Registry($reg) {
    Write-Utf8 $Registry ($reg | ConvertTo-Json -Depth 10)
    # PowerShell 5.1 的 JSON 排版难读，且会把非 ASCII 转成 \uXXXX；
    # 有 Python 时重新排版（保留中文、两格缩进）。依次尝试 python / py。
    $pyExe = $null
    foreach ($cand in @('python', 'py')) {
        if (Get-Command $cand -ErrorAction SilentlyContinue) { $pyExe = $cand; break }
    }
    if ($pyExe) {
        & $pyExe -I -c "import json,sys; p=sys.argv[1]; d=json.load(open(p,encoding='utf-8')); open(p,'w',encoding='utf-8',newline='\n').write(json.dumps(d,ensure_ascii=False,indent=2)+'\n')" $Registry
    }
}

function New-FromTemplate($tpl, $dest, $name) {
    if (Test-Path $dest) { Write-Host "  [跳过] 已存在 $dest"; return }
    $t = [IO.File]::ReadAllText((Join-Path $HubDir "templates\$tpl"), [Text.Encoding]::UTF8)
    Write-Utf8 $dest ($t.Replace('{{NAME}}', $name))
    Write-Host "  [+] $dest"
}

# 往 AGENTS.md 追加“安装 skill”一节；$domainDir 为 skill 实体所在的层目录（领域调用传领域目录，项目调用传项目目录）
function Add-InstallSection($agentsPath, $domainDir, [string]$note = '') {
    $text = [IO.File]::ReadAllText($agentsPath, [Text.Encoding]::UTF8)
    if ($text -match '## 安装 skill') { return }
    $t = [IO.File]::ReadAllText((Join-Path $HubDir 'templates\安装skill.md'), [Text.Encoding]::UTF8)
    $t = $t.Replace('{{NOTE}}', $note).Replace('{{SKILLDIR}}', (Join-Path $domainDir '.agents\skills')).Replace('{{VARIANTDIR}}', (Join-Path $domainDir '.agents\skills-claude')).Replace('{{LAYERDIR}}', $domainDir)
    # 放在“多 AI 协作纪律”之前（若有），否则追加到末尾
    $idx = $text.IndexOf('## 多 AI 协作纪律')
    if ($idx -ge 0) { $text = $text.Substring(0, $idx) + $t.TrimEnd() + "`n`n" + $text.Substring($idx) }
    else { $text = $text.TrimEnd() + "`n`n" + $t }
    Write-Utf8 $agentsPath $text
    Write-Host "  [√] $agentsPath 已写入安装 skill 一节"
}

# 屏蔽 $dir 以上所有层的 CLAUDE.md，使在该目录打开的 Claude Code 只读本目录规则
function Set-ClaudeMdExcludes($dir) {
    $ex = @()
    $rootNorm = $Root.TrimEnd('\')
    $p = Split-Path $dir -Parent
    # 用「等于根目录」或「位于根目录之下（根 + 分隔符开头）」判断，
    # 避免 StartsWith 把 C:\ws2 误判为 C:\ws 之下
    while ($p -and ($p.TrimEnd('\') -ieq $rootNorm -or $p.StartsWith($rootNorm + '\', [StringComparison]::OrdinalIgnoreCase))) {
        $f = Join-Path $p 'CLAUDE.md'
        $ex += $f
        $ex += $f.Replace('\', '/')
        $p = Split-Path $p -Parent
    }
    $settingsDir = Join-Path $dir '.claude'
    New-Item -ItemType Directory -Force $settingsDir | Out-Null
    $file = Join-Path $settingsDir 'settings.json'
    if (Test-Path $file) {
        $s = Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json
        $s | Add-Member -NotePropertyName claudeMdExcludes -NotePropertyValue $ex -Force
    } else {
        $s = [pscustomobject]@{ claudeMdExcludes = $ex }
    }
    Write-Utf8 $file ($s | ConvertTo-Json -Depth 10)
    Write-Host "  [√] $file 已屏蔽上层 CLAUDE.md"
}

function Initialize-Git($dir, [string[]]$ignore) {
    $gi = Join-Path $dir '.gitignore'
    $base = @('# 由 skill 同步脚本生成的联接，不入库（根层挂载的条目由 sync-skills.ps1 自动维护在文件末尾）', '.claude/skills', '', 'Thumbs.db', 'desktop.ini', '.DS_Store')
    if (-not (Test-Path $gi)) { Write-Utf8 $gi ((@($base) + @($ignore)) -join "`n") }
    if (-not (Test-Path (Join-Path $dir '.git'))) {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Warning "  [!] 未找到 git，跳过 git init：$dir（装好 Git for Windows 后手动 git init）"
            return
        }
        git -C $dir init -q
        Write-Host "  [√] git init $dir"
    }
}
