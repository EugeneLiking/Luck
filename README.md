# Luck 技能仓库

这是 Luck 使用的技能总库，从本地工作区 `D:\codex\workbuddy work` 发布到 [EugeneLiking/Luck](https://github.com/EugeneLiking/Luck)。

## 结构

- `_hub/`：技能登记表与同步脚本（`skills-registry.json`、`sync-skills.ps1`）
- `硕士毕业/`：毕业论文、统计学学习相关技能与规则
- `职业规划与技能提升/`：职业规划领域（项目尚未拆分）
- `AGENTS.md`：各 AI 共用的技能分层、安装与协作约定

## 约定摘要

- 技能实体只放在各层的 `.agents/skills/`，`.claude/skills` 只由 `_hub/sync-skills.ps1` 生成联接。
- 不要安装到用户级目录（`~/.claude/skills`、`~/.agents/skills`、`~/.codex/skills` 等）。
- 安装或更新后必须运行同步脚本，并确认“全部一致”。
- 具体项目文件在 `C:\Users\L1141\OneDrive\MIMO\MIMO desk top\projects`，不把技能仓库搬进 projects。
