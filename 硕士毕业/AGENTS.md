# 硕士毕业 · AI 协作规则（AGENTS.md）

> Claude Code、Codex、Antigravity 共用的规则源。Claude Code 通过 `CLAUDE.md` 中的 `@AGENTS.md` 读取。

## 1. 本目录是什么

**用途**：承载硕士毕业阶段当前必须应对的两项工作，分两个项目推进：毕业论文、统计学学习。本领域负责统筹毕业相关事务的进度与产出，不在这里做与毕业无关的探索。

**产出物**：
- 毕业论文相关：选题与提纲、文献综述、数据与方法、正文各章节、修改稿与定稿、答辩材料；
- 统计学学习相关：知识点梳理与笔记、例题与练习、与论文方法部分的衔接记录；
- 共通：进度记录、待办与风险清单、阶段复盘。

**目录约定**：
- 两个项目各有独立目录：`毕业论文\`、`统计学学习\`，互不混放材料；
- 本领域根目录只放跨项目的材料与说明（如毕业整体时间表、通用规范）；
- 论文成稿与大文件按 `毕业论文\` 项目内的约定存放；统计学习资料按主题归入 `统计学学习\`。

## 2. 可用 skill

skill 由 `D:/codex/workbuddy work` 总管理会话统一安装，位于 `.agents/skills/`（Codex、Antigravity）与 `.claude/skills/`（Claude Code）。

## 安装 skill（本领域专属）

- **唯一正确位置**：`D:\codex\workbuddy work\硕士毕业\.agents\skills\<skill名>\`。一级目录下直接是 `SKILL.md`，文件夹名与其中的 `name` 一致。上游另有 Claude 专用版时，放 `D:\codex\workbuddy work\硕士毕业\.agents\skills-claude\<skill名>\`。
- **推荐命令**（在 `D:\codex\workbuddy work\硕士毕业` 下执行）：
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
  然后在 `D:\codex\workbuddy work\硕士毕业` 用 git 提交。
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

## PDF 阅读约定（自动，无需用户要求）

- 凡需阅读 PDF 内容，**先用共享 skill `pdf-to-markdown` 自动转成 Markdown** 再读，不等用户开口。
- md 中凡 📊 图表页标记，**必须用图像查看工具打开对应整页 PNG**，把图的含义（趋势/显著性/坐标轴/结论）与该页文字上下文一起理解，**不得只读文字跳过图表**。
- 只要局部内容（某页文本/表格/插图/目录）用 `pdf-extract`；扫描件用 `handwriting-ocr`。
