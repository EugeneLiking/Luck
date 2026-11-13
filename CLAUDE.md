# D:/codex/workbuddy work · 总管理会话（Claude Code 入口）

@AGENTS.md

## Claude Code 补充

- 各领域、项目的 `.claude/settings.json` 用 `claudeMdExcludes` 屏蔽了本文件和上层 CLAUDE.md，避免总管理规则混入领域会话；新建领域/项目时保持这一设置（`new-domain.ps1` 会自动写入）。
- 本会话里 `.claude\skills` 中能看到的只有根层 skill；领域 skill 不在本会话加载，属正常。
