# D:/codex/workbuddy work · 总管理层规则（AGENTS.md）

> Claude Code、Codex、Antigravity 共用的规则源。Claude Code 通过 `CLAUDE.md` 中的 `@AGENTS.md` 读取本文件。
> 本层是**总管理会话**：只做 skill 安装与登记、规则维护、新建领域/项目。不在这里做任何领域内的具体工作。

## 1. 目录约定

- `_hub\skills-registry.json`：全部 skill 登记表（唯一清单）；`_hub\sync-skills.ps1`：按登记表重建全部联接；`_hub\new-domain.ps1`、`_hub\new-project.ps1`：新建领域、项目；`_hub\templates\`：模板。
- `.agents\skills\`：根层 skill 实体；`.agents\skills-claude\`：其 Claude 专用版；`.claude\skills\`：脚本生成的联接，不手工放东西。
- 每类工作一个领域文件夹（如 `工作类型1\`），领域里每个独立作品/工程一个项目子文件夹（如 `工作类型1\项目1\`），各自独立 git。

## 2. Skill 分层

| 层 | 放什么 |
|---|---|
| 根 `.agents\skills` | 跨领域的基础类、优化类 skill；按登记表 `mountTo` 挂进需要它的领域 |
| 领域 `.agents\skills` | 只有该领域用得上的 skill |
| `.agents\skills-claude` | 上游专门给 Claude 改写的版本；生成 `.claude\skills` 时优先用它 |

- 实体只存在于 `.agents\skills`（及 `skills-claude`）。`.claude\skills` 全部是脚本生成的联接。
- 项目的 `.agents\skills`、`.claude\skills` 是整目录联接，指向所属领域。
- 不往用户级目录（`~/.claude/skills`、`~/.agents/skills`、`~/.codex/skills`、`~/.gemini/...`）装这里的 skill。

## 3. 安装 / 更新 skill

1. 判断层级：跨领域通用 → 根层；只服务一个领域 → 该领域。
2. 下载到目标层的 `.agents\skills\<name>\`（一级目录下直接有 `SKILL.md`，文件夹名与 `name` 一致）。上游另有 Claude 专用版时，放到同层 `.agents\skills-claude\<name>\`。
3. 在 `_hub\skills-registry.json` 登记（来源、`claudeVariant`、根层的 `mountTo`）。
4. 运行同步并确认“全部一致”：`powershell -ExecutionPolicy Bypass -File D:/codex/workbuddy work\_hub\sync-skills.ps1`（只检查加 `-CheckOnly`）。
5. 登记表变更在根目录 git 提交；领域 skill 在该领域 git 提交。

禁止使用 Codex 自带的 `skill-installer`。

## 4. 新建领域 / 项目

```powershell
powershell -ExecutionPolicy Bypass -File D:/codex/workbuddy work\_hub\new-domain.ps1 -Name "<领域名>"
powershell -ExecutionPolicy Bypass -File D:/codex/workbuddy work\_hub\new-project.ps1 -Domain "<领域名>" -Name "<项目名>"
```

## 5. 多 AI 协作总纲

1. **规则只写一处**：三家共用的写 `AGENTS.md`；Claude 专属写 `CLAUDE.md`；Antigravity 专属写 `.agents/rules/`。
2. **记忆不共享**：要让别的 AI 知道的结论，必须落盘到文件。
3. **认领再动手**：在项目的 `TASKS.md` 认领任务并写明要改的文件；别人认领的文件不改。
4. **离开必交接**：会话结束前在 `HANDOFF.md` 末尾追加交接记录。
5. **完成即提交**：每完成一项任务 `git commit`，消息以 `[claude]` / `[codex]` / `[agy]` 开头。
6. **不跨界**：在某领域/项目内工作时，不读取、不修改其他领域或项目的文件。

## 6. 安装、下载与归档位置

- 禁止将安装程序、安装缓存和大文件下载到 C 盘。
- 应用安装到 `D:`，安装时显式指定目录，装完核对实际位置。
- 需要归档的大文件存入 `D:/codex/workbuddy work_归档备份\` 下对应目录；重大变更前整体备份到 `D:/codex/workbuddy work_归档备份\<日期>_<说明>\`（robocopy 加 `/XJ` 跳过联接，联接清单另存 `junctions.txt`）。
- skill 和项目需要长期保留的内容，放在所属项目目录中。
