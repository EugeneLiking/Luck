# 职业规划与技能提升 · AI 协作规则（AGENTS.md）

> Claude Code、Codex、Antigravity 共用的规则源。Claude Code 通过 `CLAUDE.md` 中的 `@AGENTS.md` 读取。

## 1. 本目录是什么

面向未来职业规划的**技能增强**领域。

**用途**：明确职业方向，识别能力差距，系统补齐专业技能，把「想做什么」变成可执行的提升计划。

**产出物**：
- 职业方向分析与目标岗位画像
- 技能差距清单与学习路线图
- 学习笔记、练习成果、阶段性复盘

**目录约定**：
- 每个独立的学习方向或作品单独建项目（`_hub\new-project.ps1`）
- 跨项目通用的材料放本目录根下
- 尚未拆出具体项目，先在本层积累；项目成形后用 `new-project.ps1` 独立出去

## 2. 可用 skill

skill 由 `D:/codex/workbuddy work` 总管理会话统一安装，位于 `.agents/skills/`（Codex、Antigravity）与 `.claude/skills/`（Claude Code）。

## 安装 skill（本领域专属）

- **唯一正确位置**：`D:\codex\workbuddy work\职业规划与技能提升\.agents\skills\<skill名>\`。一级目录下直接是 `SKILL.md`，文件夹名与其中的 `name` 一致。上游另有 Claude 专用版时，放 `D:\codex\workbuddy work\职业规划与技能提升\.agents\skills-claude\<skill名>\`。
- **推荐命令**（在 `D:\codex\workbuddy work\职业规划与技能提升` 下执行）：
  ```powershell
  npx --yes skills add <owner/repo> --skill <skill名> --agent codex --copy --yes
  ```
- **禁止**：
  - Codex 自带的 `skill-installer`：它装到 `~/.codex/skills`，所有会话都会加载；
  - 装进任何用户级目录（`~/.claude/skills`、`~/.agents/skills`、`~/.gemini/...`）；
  - 直接往 `.claude/skills` 放文件（那里只放同步脚本生成的联接）。
- **装完必须同步**：自动登记、生成 Claude Code 用的联接、收编装错位置的 skill。
  ```powershell
  powershell -ExecutionPolicy Bypass -File D:/codex/workbuddy work\_hub\sync-skills.ps1
  ```
  然后在 `D:\codex\workbuddy work\职业规划与技能提升` 用 git 提交。
- 跨领域通用的 skill 不要装在这里，在 `HANDOFF.md` 提出，由 `D:/codex/workbuddy work` 总管理会话装到根层。详细流程见 skill `skill-manager`。

## 多 AI 协作纪律（Claude Code · Codex · Antigravity）

本目录可能同时由多个 AI 工作。三家的记忆互不相通，一切以文件为准。

1. **开工先读**：本文件 → `HANDOFF.md` 最后 3 条 → `TASKS.md`。
2. **认领再动手**：在 `TASKS.md` 认领任务，写明负责 AI（`claude` / `codex` / `agy`）和要改的文件。别人认领中的文件不改；确需改动，在 `HANDOFF.md` 留言协商。
3. **离开必交接**：会话结束前在 `HANDOFF.md` 末尾追加一条（时间、AI、完成内容、改动文件、下一步、未决问题）。
4. **完成即提交**：每完成一项任务 `git commit`，消息以 `[claude]` / `[codex]` / `[agy]` 开头。不改写、不强推别人的提交。
5. **结论落盘**：讨论敲定的规则、设定、决定写进对应文件，不只留在对话或某个 AI 的记忆里。
6. **装 skill 按规定位置**：只服务本领域的，按本文件“安装 skill”一节装到本领域并运行同步脚本；跨领域通用的，在 `HANDOFF.md` 提出，由 `D:/codex/workbuddy work` 总管理会话装到根层。
7. **不跨界**：不读取、不修改本目录以外的其他领域或项目。
