# Obsidian-through

让 AI Agent 帮你配置和维护：

`Windows Obsidian <-> GitHub 私有仓库 <-> iPhone / Android Obsidian`

[中文](#中文) | [English](#english)

## 中文

### 解决的痛点

- Obsidian Git 三端配置步骤多，Token、邮箱、仓库权限容易填错。
- Windows 与手机端设置互相覆盖，导致重复弹窗、无法自动同步或反复登录。
- 手机出现 `Request failed`、Push 被拒绝、冲突或重复笔记时难以定位原因。
- iOS 后台任务不可靠，设置了定时同步也可能没有执行。

### 解决方式

Obsidian-through 是一个遵循开放 [Agent Skills](https://agentskills.io) 格式的 Skill。它指导兼容的 AI Agent：

- 检查并安装 Git 与 GitHub CLI；
- 创建或连接 GitHub 私有仓库；
- 配置 Windows 编辑事件触发同步和启动拉取；
- 配置 iPhone / Android 的 Obsidian Git、Token 和作者信息；
- 隔离各设备设置，避免认证与同步参数互相覆盖；
- 排查网络/VPN、认证、冲突、重复文件和推送失败；
- 完成 Windows、GitHub 与手机之间的端到端验证。

### 优点

- **跨 Agent**：使用标准 `SKILL.md`，不绑定单一模型或产品。
- **安全**：默认使用私有仓库和单仓库 Fine-grained Token，不在日志或聊天中保存 Token。
- **自动化**：附带 Windows 配置、事件同步和验证脚本。
- **可验证**：只有实际完成三端 Pull/Push 测试后才判定成功。
- **中英双语**：核心流程和参考文档均提供中文与英文版本。

### 安装

需要先安装 [Node.js](https://nodejs.org/) 18 或更高版本，然后运行：

```bash
npx skills add Wh1tZz/Obsidian-through -g
```

安装器会列出可用的 AI Agent，并让你选择安装目标。也可以查看而不安装：

```bash
npx skills add Wh1tZz/Obsidian-through --list
```

### 使用

安装后，对你的 AI Agent 说：

```text
使用 obsidian-through，帮我配置 Windows、GitHub 私有仓库和 iPhone Obsidian 三端同步。
```

Agent 会按步骤检查环境、请求必要确认、运行脚本并指导手机端配置。不要把 GitHub Token 发送到聊天、截图、笔记或仓库中。

### 注意

- 不要让 Git 和 iCloud 同时同步同一个 vault。
- iOS 无法保证后台常驻；离开 Obsidian 前手动执行 `Git: Commit-and-sync` 最可靠。
- 手机端同步时需要保持 Obsidian 在前台，并确保网络能够访问 GitHub。
- 当前自动化脚本主要面向 Windows；手机端由 Obsidian Git 插件完成同步。

## English

### Problems solved

- Three-endpoint Obsidian Git setup is easy to misconfigure, especially tokens, author email, and repository permissions.
- Desktop and mobile settings can overwrite each other, causing repeated notices, failed automation, or repeated authentication.
- Mobile errors such as `Request failed`, rejected pushes, conflicts, and duplicate notes are difficult to diagnose.
- iOS background execution is unreliable even when interval synchronization is enabled.

### How it works

Obsidian-through follows the open [Agent Skills](https://agentskills.io) format. It guides any compatible AI agent to:

- check and install Git and GitHub CLI;
- create or connect a private GitHub repository;
- configure Windows edit-event synchronization and startup pull;
- configure Obsidian Git, credentials, and author identity on iPhone or Android;
- isolate per-device settings;
- diagnose network/VPN, authentication, conflict, duplicate-file, and push failures;
- verify the complete Windows, GitHub, and mobile synchronization path.

### Benefits

- **Cross-agent**: standard `SKILL.md` format with no dependency on one model or product.
- **Secure defaults**: private repositories and repository-scoped fine-grained tokens.
- **Automated**: bundled Windows setup, event-sync, and verification scripts.
- **Verifiable**: success requires real Pull and Push tests across all endpoints.
- **Bilingual**: complete Chinese and English workflows and references.

### Install

Install [Node.js](https://nodejs.org/) 18 or newer, then run:

```bash
npx skills add Wh1tZz/Obsidian-through -g
```

The installer detects supported AI agents and lets you choose the installation target. To inspect available skills first:

```bash
npx skills add Wh1tZz/Obsidian-through --list
```

### Use

Ask your AI agent:

```text
Use obsidian-through to configure Obsidian sync across Windows, a private GitHub repository, and my iPhone.
```

The agent will inspect the environment, request required confirmations, run the bundled scripts, and guide mobile setup. Never send a GitHub token through chat, screenshots, notes, or repositories.

### Notes

- Do not synchronize the same vault with both Git and iCloud.
- iOS cannot guarantee background execution; manually run `Git: Commit-and-sync` before leaving Obsidian.
- Keep Obsidian active and ensure the phone network can reach GitHub during synchronization.
- Desktop automation currently targets Windows; mobile synchronization uses the Obsidian Git plugin.

## License

[MIT](LICENSE)
