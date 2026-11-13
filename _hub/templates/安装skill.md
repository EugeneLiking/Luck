## 安装 skill（本领域专属）

{{NOTE}}- **唯一正确位置**：`{{SKILLDIR}}\<skill名>\`。一级目录下直接是 `SKILL.md`，文件夹名与其中的 `name` 一致。上游另有 Claude 专用版时，放 `{{VARIANTDIR}}\<skill名>\`。
- **推荐命令**（在 `{{LAYERDIR}}` 下执行）：
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
  然后在 `{{LAYERDIR}}` 用 git 提交。
- 跨领域通用的 skill 不要装在这里，在 `HANDOFF.md` 提出，由 `D:/codex/workbuddy work` 总管理会话装到根层。详细流程见 skill `skill-manager`。
