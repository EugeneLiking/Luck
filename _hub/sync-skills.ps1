<#
.SYNOPSIS
    按 _hub\skills-registry.json 重建 D:/codex/workbuddy work 下所有 skill 联接，并自动收编装错位置的 skill。可反复运行。
.DESCRIPTION
    每一层（根、各领域、各项目）：
      .agents\skills\          实体目录。项目专属 skill 直接装在项目层；共享 skill 装在根/领域层
      .agents\skills-claude\   上游给 Claude 单独出的变体（可选）
      .claude\skills\          全部由本脚本生成的联接，优先指向 Claude 变体
    挂载（实体在别层，以联接出现在本层 .agents\skills）：
      根层 skill 按 mountTo 挂进领域/项目（"*" = 全部领域，写领域名挂进该领域及其项目）
      领域层 skill 自动挂进所属各项目（领域 = 跨项目共享；项目 = 专属）
    各领域下的项目（registry.domains.<领域>.projects）作为独立层参与登记与校验；
    旧结构「项目 .agents\skills/.claude\skills 整目录联接到领域」会自动迁移为实体目录。
    自动收编（-CheckOnly 时只报告）：
      .claude\skills 下的实体目录 → 移入 .agents\skills（同名且内容不同则移入 .agents\skills-claude）
      .agents\skills 下未登记的 skill → 登记到所在层（来源从该层 skills-lock.json 查找）
    还会检查用户级 skill 目录，出现未确认的 skill 时提醒。
    只删除联接；实体目录只在“与已登记版本内容完全相同的重复副本”时删除。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File D:/codex/workbuddy work\_hub\sync-skills.ps1
    powershell -ExecutionPolicy Bypass -File D:/codex/workbuddy work\_hub\sync-skills.ps1 -CheckOnly
#>
param([switch]$CheckOnly)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$reg = Read-Registry
$problems = New-Object System.Collections.Generic.List[string]
$adopted  = New-Object System.Collections.Generic.List[string]
$regChanged = $false
$today = Get-Date -Format 'yyyy-MM-dd'

function Test-Junction($p) {
    $i = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
    if (-not $i) { return $false }
    if (-not ($i.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $false }
    # 关键：OneDrive「文件随取」等云同步会把普通目录也标成 ReparsePoint，但没有链接目标；
    # 真正的 junction / 目录符号链接一定带 Target。只看 ReparsePoint 位会在 OneDrive 目录下
    # 把所有目录误判为联接，导致 .claude\skills 无法生成。
    $t = $i.Target
    return [bool]($t -and (@($t) | Where-Object { $_ }).Count -gt 0)
}
function Get-LinkTarget($p) {
    $i = Get-Item -LiteralPath $p -Force
    $t = $i.Target
    if ($t -is [array]) { $t = $t[0] }
    if (-not $t) { return $null }
    # 统一为绝对路径字符串，去掉可能的 \\?\ 前缀与结尾分隔符，便于跨形式比较
    $t = [string]$t
    if ($t.StartsWith('\\?\')) { $t = $t.Substring(4) }
    return $t.TrimEnd('\')
}
function Remove-Junction($p) {
    # 安全闸：只允许删除真正的联接。若误把 OneDrive 占位目录当联接删除，会连实体内容一起丢掉。
    if (-not (Test-Junction $p)) {
        $problems.Add("拒绝删除：不是联接（可能是实体目录或云占位目录）: $p")
        return
    }
    # [System.IO.Directory]::Delete 只删联接本身，不碰目标内容；
    # 不用 cmd /c rmdir，避免 cmd 解析在含空格/中文/特殊字符路径上的转义风险，
    # 也避免在禁用 cmd.exe 的受限环境中无法运行。
    [System.IO.Directory]::Delete($p)
}
function Set-Junction($link, $target) {
    if (Test-Path -LiteralPath $link) {
        if (Test-Junction $link) {
            if ((Get-LinkTarget $link) -eq $target) { return }
            if ($CheckOnly) { $problems.Add("联接指向错误: $link"); return }
            Remove-Junction $link
        } else {
            $problems.Add("应为联接但是实体目录，已跳过: $link")
            return
        }
    } elseif ($CheckOnly) { $problems.Add("缺少联接: $link -> $target"); return }
    New-Item -ItemType Directory -Force (Split-Path $link -Parent) | Out-Null
    # 用 New-Item -ItemType Junction 代替 cmd /c mklink /J（PS 5.0+ 原生支持，无需管理员权限）
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "  + $link -> $target"
}
function Resolve-Final($p) {
    if (Test-Junction $p) { return (Get-LinkTarget $p) } else { return $p }
}
function Get-DirHash($p) {
    $base = (Resolve-Path -LiteralPath $p).Path
    $lines = Get-ChildItem -LiteralPath $p -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
        $_.FullName.Substring($base.Length) + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
    return ($lines -join "`n")
}
function Get-SkillName($dir) {
    $f = Join-Path $dir 'SKILL.md'
    if (-not (Test-Path -LiteralPath $f)) { return $null }
    $m = Select-String -LiteralPath $f -Pattern '^name:\s*["'']?([^"''\s]+)' -Encoding UTF8 | Select-Object -First 1
    if ($m) { return $m.Matches[0].Groups[1].Value } else { return '' }
}
function Get-LockSource($dir, $name) {
    $lock = Join-Path $dir 'skills-lock.json'
    if (-not (Test-Path $lock)) { return $null }
    $l = Get-Content $lock -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($l.skills -and $l.skills.$name) { return $l.skills.$name.source }
    return $null
}
function Add-RegistryEntry($layer, $name, $source, $note) {
    if (-not $reg.skills.$layer) {
        $reg.skills | Add-Member -NotePropertyName $layer -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $entry = [pscustomobject]@{ source = $source; note = $note }
    if ($layer -eq 'root') { $entry | Add-Member -NotePropertyName mountTo -NotePropertyValue @() }
    $reg.skills.$layer | Add-Member -NotePropertyName $name -NotePropertyValue $entry -Force
    $script:regChanged = $true
}

$rootAgents   = Join-Path $Root '.agents\skills'
$rootVariants = Join-Path $Root '.agents\skills-claude'
# 过滤空名：domains 为空对象时 Properties.Name 为 $null，
# 不过滤会产生一个空名幽灵层（会把根目录重复处理一遍）
$domainNames  = @($reg.domains.PSObject.Properties.Name | Where-Object { $_ })

# 层 = 根 + 各领域 + 各项目（键名 "领域/项目"）。项目层拥有自己的实体 skill，
# 所属领域的共享 skill 会自动挂进项目。
$layers = @('root')
foreach ($d in $domainNames) {
    $layers += $d
    foreach ($proj in @($reg.domains.$d.projects)) { if ($proj) { $layers += "$d/$proj" } }
}
foreach ($layer in $layers) {
    $isProject   = $layer.Contains('/')
    $parentLayer = if ($isProject) { $layer.Split('/')[0] } else { $null }
    $dir      = if ($layer -eq 'root') { $Root } else { Join-Path $Root ($layer.Replace('/', '\')) }
    $agents   = Join-Path $dir '.agents\skills'
    $variants = Join-Path $dir '.agents\skills-claude'
    $claude   = Join-Path $dir '.claude\skills'
    $parentAgents = if ($isProject) { Join-Path (Join-Path $Root $parentLayer) '.agents\skills' } else { $null }
    Write-Host "== [$layer] $dir" -ForegroundColor Cyan
    # 旧结构迁移：整目录联接一律移除后重建为实体目录（Remove-Junction 只删联接本身）
    foreach ($lp in @($agents, $claude)) {
        if (Test-Junction $lp) {
            if ($CheckOnly) { $problems.Add("[$layer] $lp 是旧的整目录联接，待迁移为实体目录") }
            else { Remove-Junction $lp; Write-Host "  - 移除旧整目录联接: $lp" }
        }
    }
    if (-not (Test-Path $agents)) { New-Item -ItemType Directory -Force $agents | Out-Null }

    # 0. 本层要挂载的根层 skill
    $mounted = @()
    $mountedOk = @()
    if ($layer -ne 'root' -and $reg.skills.root) {
        foreach ($p in $reg.skills.root.PSObject.Properties) {
            $mt = @($p.Value.mountTo)
            if ($mt -contains '*' -or $mt -contains $layer -or ($parentLayer -and $mt -contains $parentLayer)) { $mounted += $p.Name }
        }
    }

    # 1. 收编：.claude\skills 下的实体目录
    if ((Test-Path $claude) -and -not (Test-Junction $claude)) {
        foreach ($e in @(Get-ChildItem -LiteralPath $claude -Force -Directory | Where-Object { -not (Test-Junction $_.FullName) })) {
            $n = $e.Name
            if ($null -eq (Get-SkillName $e.FullName)) { $problems.Add("[$layer] .claude\skills\$n 不是有效 skill（一级目录下没有 SKILL.md），未处理"); continue }
            if ($mounted -contains $n) { $problems.Add("[$layer] .claude\skills\$n 与根层挂载的同名 skill 冲突，未处理"); continue }
            $a = Join-Path $agents $n
            $v = Join-Path $variants $n
            if ($CheckOnly) { $problems.Add("[$layer] 待收编：.claude\skills\$n（实体目录）"); continue }
            if (-not (Test-Path -LiteralPath $a)) {
                Move-Item -LiteralPath $e.FullName -Destination $a
                $adopted.Add("[$layer] $n：.claude\skills → .agents\skills")
            } elseif ((Get-DirHash $a) -eq (Get-DirHash $e.FullName)) {
                Remove-Item -LiteralPath $e.FullName -Recurse -Force
                $adopted.Add("[$layer] $n：.claude\skills 下是重复副本，已删除")
            } elseif (-not (Test-Path -LiteralPath $v)) {
                New-Item -ItemType Directory -Force $variants | Out-Null
                Move-Item -LiteralPath $e.FullName -Destination $v
                $adopted.Add("[$layer] $n：内容与 .agents 版不同，作为 Claude 专用版移入 .agents\skills-claude")
            } else {
                $problems.Add("[$layer] .claude\skills\$n 与 .agents\skills、.agents\skills-claude 中的同名 skill 都冲突，未处理")
            }
        }
    }

    # 2. 挂载进本层：根层 skill（按 mountTo）+ 所属领域共享 skill（项目层自动）
    if ($layer -ne 'root') {
        $mountMap = @{}
        foreach ($n in $mounted) { $mountMap[$n] = Join-Path $rootAgents $n }
        if ($isProject -and (Test-Path -LiteralPath $parentAgents)) {
            foreach ($e in @(Get-ChildItem -LiteralPath $parentAgents -Force -Directory | Where-Object { -not (Test-Junction $_.FullName) })) {
                if (-not $mountMap.ContainsKey($e.Name)) { $mountMap[$e.Name] = $e.FullName }
            }
        }
        foreach ($n in $mountMap.Keys) {
            $a = Join-Path $agents $n
            if ((Test-Path -LiteralPath $a) -and -not (Test-Junction $a)) { $problems.Add("[$layer] 本层有与挂载 skill 同名的实体：$n，未挂载"); continue }
            Set-Junction $a $mountMap[$n]
            $mountedOk += $n
        }
        # 撤掉不再挂载的联接（目标在根层或所属领域 .agents\skills 下的）
        Get-ChildItem -LiteralPath $agents -Force -Directory | Where-Object { Test-Junction $_.FullName } | ForEach-Object {
            $t = Get-LinkTarget $_.FullName
            $isMount = $t -and ($t.StartsWith($rootAgents) -or ($parentAgents -and $t.StartsWith($parentAgents)))
            if ($isMount -and (-not $mountMap.ContainsKey($_.Name) -or $mountMap[$_.Name] -ne $t)) {
                if ($CheckOnly) { $problems.Add("多余的挂载联接: $($_.FullName)") }
                else { Remove-Junction $_.FullName; Write-Host "  - $($_.FullName)" }
            }
        }
        # 挂载联接写进本层 .gitignore 的自动维护区（区名沿用「根层挂载」以兼容旧文件）
        if (-not $CheckOnly) {
            $gi = Join-Path $dir '.gitignore'
            $begin = '# >>> sync-skills 根层挂载（自动生成，勿手改）'
            $end   = '# <<< sync-skills'
            $orig = if (Test-Path $gi) { [IO.File]::ReadAllText($gi, [Text.Encoding]::UTF8) } else { '' }
            $old = [regex]::Replace($orig, "(?s)\r?\n?$([regex]::Escape($begin)).*?$([regex]::Escape($end))\r?\n?", "`n")
            $block = @($begin) + @($mountedOk | ForEach-Object { ".agents/skills/$_" }) + @($end)
            $new = $old.TrimEnd() + "`n`n" + ($block -join "`n") + "`n"
            if ($new -ne $orig) { Write-Utf8 $gi $new }
        }
    }

    # 3. 收编：.agents\skills 下未登记的实体 skill；并核对登记表
    $onDisk = @(Get-ChildItem -LiteralPath $agents -Force -Directory | Where-Object { -not (Test-Junction $_.FullName) } | ForEach-Object Name)
    $declared = $reg.skills.$layer
    $names = if ($declared) { @($declared.PSObject.Properties.Name) } else { @() }
    foreach ($n in $onDisk) {
        $sd = Join-Path $agents $n
        $skillName = Get-SkillName $sd
        if ($null -eq $skillName) { $problems.Add("[$layer] .agents\skills\$n 一级目录下没有 SKILL.md（可能装成了仓库结构，需手工整理）"); continue }
        if ($skillName -and $skillName -ne $n) { $problems.Add("[$layer] .agents\skills\$n 的 SKILL.md name 为 '$skillName'，与文件夹名不一致") }
        if ($names -notcontains $n) {
            if ($CheckOnly) { $problems.Add("[$layer] 待登记：$n"); continue }
            $src = Get-LockSource $dir $n
            if (-not $src) { $src = 'unknown' }
            Add-RegistryEntry $layer $n $src "自动收编 $today，请补充来源/用途"
            $adopted.Add("[$layer] $n：已登记（来源 $src）")
        }
    }
    $declared = $reg.skills.$layer
    $names = if ($declared) { @($declared.PSObject.Properties.Name) } else { @() }
    foreach ($n in $names) { if ($onDisk -notcontains $n) { $problems.Add("[$layer] 已登记但磁盘上没有: $n") } }

    # Claude 变体与登记一致
    foreach ($n in $onDisk) {
        $hasVariant = Test-Path -LiteralPath (Join-Path $variants $n)
        $isVariant = $declared -and $declared.$n -and $declared.$n.claudeVariant
        if ($hasVariant -and -not $isVariant) {
            if ($CheckOnly) { $problems.Add("[$layer] 有 Claude 变体但未登记 claudeVariant: $n") }
            else { $declared.$n | Add-Member -NotePropertyName claudeVariant -NotePropertyValue $true -Force; $regChanged = $true }
        }
        if ($isVariant -and -not $hasVariant) { $problems.Add("[$layer] 登记为有 Claude 变体但找不到: $n") }
    }
    if (Test-Path $variants) {
        foreach ($e in Get-ChildItem -LiteralPath $variants -Force -Directory) {
            if ($onDisk -notcontains $e.Name) { $problems.Add("[$layer] .agents\skills-claude\$($e.Name) 没有对应的 .agents\skills 版本") }
        }
    }

    # 4. 生成 .claude\skills（只含联接）
    if (Test-Junction $claude) {
        $problems.Add("[$layer] .claude\skills 是整目录联接，应为实体目录，已跳过")
    } else {
        if (-not (Test-Path $claude)) { New-Item -ItemType Directory -Force $claude | Out-Null }
        $want = @{}
        foreach ($e in Get-ChildItem -LiteralPath $agents -Force -Directory) {
            $n = $e.Name
            $target = Resolve-Final $e.FullName
            # 变体优先级：本层变体 > 实体所在层的 Claude 变体
            $ownVar = Join-Path $variants $n
            $srcLayerDir = Split-Path (Split-Path $target -Parent) -Parent
            $srcVar = Join-Path (Join-Path $srcLayerDir '.agents\skills-claude') $n
            if (Test-Path -LiteralPath $ownVar) { $want[$n] = $ownVar }
            elseif ((Test-Path -LiteralPath $srcVar) -and ($srcVar -ne $ownVar)) { $want[$n] = $srcVar }
            else { $want[$n] = $target }
        }
        foreach ($e in Get-ChildItem -LiteralPath $claude -Force -Directory) {
            if (-not (Test-Junction $e.FullName)) { continue }   # 实体目录已在第 1 步处理或报告
            if (-not $want.ContainsKey($e.Name)) {
                if ($CheckOnly) { $problems.Add("[$layer] .claude\skills 多余联接: $($e.Name)") }
                else { Remove-Junction $e.FullName; Write-Host "  - $($e.FullName)" }
            }
        }
        foreach ($n in $want.Keys) { Set-Junction (Join-Path $claude $n) $want[$n] }
    }

    $count = @(Get-ChildItem -LiteralPath $agents -Force -Directory).Count
    Write-Host "  skill 数: $count（其中挂载 $($mountedOk.Count)）"
}

# 6. 用户级目录：这些位置的 skill 会进入所有会话，不受分层控制
$ack = @($reg.userLevelAcknowledged)
$userDirs = @(
    "$env:USERPROFILE\.claude\skills",
    "$env:USERPROFILE\.agents\skills",
    "$env:USERPROFILE\.codex\skills",
    "$env:USERPROFILE\.gemini\antigravity\skills",
    "$env:USERPROFILE\.gemini\config\skills"
)
foreach ($u in $userDirs) {
    if (-not (Test-Path $u)) { continue }
    foreach ($e in Get-ChildItem -LiteralPath $u -Force -Directory | Where-Object { $_.Name -ne '.system' }) {
        $key = $e.FullName.Replace($env:USERPROFILE, '~').Replace('\', '/')
        if ($ack -notcontains $key) { $problems.Add("用户级目录有未确认的 skill：$key（所有会话都会加载；如属误装，移入对应层的 .agents\skills 后重跑本脚本；如确需全局，加入登记表 userLevelAcknowledged）") }
    }
}

if ($regChanged) { Save-Registry $reg; Write-Host "登记表已更新。" }

Write-Host ""
if ($adopted.Count -gt 0) {
    Write-Host "已收编 $($adopted.Count) 项（记得在对应目录 git 提交）：" -ForegroundColor Green
    $adopted | ForEach-Object { Write-Host "  * $_" -ForegroundColor Green }
}
if ($problems.Count -eq 0) { Write-Host "全部一致。" -ForegroundColor Green }
else {
    Write-Host "发现 $($problems.Count) 个问题：" -ForegroundColor Yellow
    $problems | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Yellow }
    exit 1
}
