---
name: obsidian-through
description: Configure, repair, explain, and verify private Obsidian synchronization across Windows, GitHub, iPhone, and Android. 配置、修复、解释并验证 Windows、GitHub、iPhone 与 Android 之间的 Obsidian 私有同步。Use for private vault repositories, Windows edit-event sync, mobile setup, GitHub token/key guidance, Pull/Commit/Push workflow explanation, device-setting isolation, duplicate-note diagnosis, accidental deletion recovery, multi-device sync strategy, failed pushes, and end-to-end checks. 用于私有笔记仓库、Windows 编辑事件同步、手机配置、GitHub Token/Key 指导、Pull/Commit/Push 工作流解释、设备设置隔离、重复笔记诊断、误删恢复、多端同步策略、推送失败和端到端检查。
---

# 中文版

## 目标

建立数据链路：`Windows Obsidian 笔记库 <-> GitHub 私有仓库 <-> iPhone Obsidian 笔记库`。

将用户的私有 GitHub 笔记仓库作为数据中心。Skill 自身可以发布到公开仓库，但公开仓库只能包含通用脚本和文档，绝不能包含用户笔记、Token、账号凭据、本机路径或运行日志。

## 工作流

### 交互式配置协议

当用户说“帮我配置 Obsidian 和 GitHub”或同义请求时，必须按以下顺序执行：

1. 阅读 [references/desktop.md](references/desktop.md) 中文版。
2. 运行 `scripts/ensure-git-tools.ps1` 检查 Git 和 GitHub CLI。缺失时先向用户确认安装，再使用 `-InstallIfMissing` 安装并复查版本。
3. 检查 `gh auth status`。未登录时运行 `scripts/github-web-login.ps1`，直接启动 GitHub 网页授权，并等待用户在浏览器完成登录。
4. 登录成功后重新验证 GitHub 账号，不得要求用户在聊天中发送密码、验证码或 Token。
5. 定位笔记库，向用户明确显示将上传的本地路径、GitHub 账号、仓库名和 `PRIVATE` 可见性。
6. 获得上传授权后运行 `scripts/publish-vault.ps1 -ConfirmUpload`，初始化 Git、创建或连接私有仓库并完成首次推送。用户已有仓库时，优先接收完整 GitHub 仓库 URL，使用 `-RepositoryUrl` 和 `-OpenRepositoryPage`，不要反复要求用户拆分 owner、仓库名和 `.git` 地址。
7. 验证 GitHub 仓库为私有、本地与远端哈希一致，运行 `scripts/configure-windows-obsidian-git.ps1` 关闭 Windows 插件自动任务和普通通知，再安装 Windows 事件同步。
8. 运行无侵入检查；获得测试文件上传授权后运行事件探针。
9. 请用户在 Windows Obsidian 新建或编辑测试笔记，并确认 GitHub 页面出现改动。用户未确认前，不得声称桌面连接成功。
10. Windows 确认成功后，询问手机类型。若用户已说明设备类型，直接进入对应流程。
11. 打开 GitHub Fine-grained Token 页面，显示 [references/mobile.md](references/mobile.md) 对应设备的完整说明，并让用户在手机上完成首次 Pull/Push。
12. 用户在实体手机验证成功后，才宣布三端同步完成。

### 1. 检查环境

1. 尽可能从 Obsidian 应用配置中定位当前打开的笔记库。
2. 区分笔记库目录与 Obsidian 软件安装目录。
3. 检查 `.git`、远端、分支、工作区状态、`.obsidian` 和 Git 插件状态。
4. 检查 Git、GitHub CLI 及登录状态。
5. 保留现有笔记和无关改动。没有先完成合并处理时，禁止覆盖非空笔记库。

### 2. 创建或连接私有仓库

1. 仅在笔记库尚未成为 Git 仓库时初始化 `main` 分支。
2. 创建 GitHub 私有仓库，或确认现有仓库为私有状态。
3. 在 `.gitignore` 中至少添加：

```gitignore
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache/
.obsidian/plugins/obsidian-git/data.json
.trash/
.DS_Store
Thumbs.db
desktop.ini
```

必须让 `.obsidian/plugins/obsidian-git/data.json` 保持设备本地化，否则电脑与 iPhone 会互相覆盖同步时间和认证设置。若已被跟踪，保留本地文件并运行：

```bash
git rm --cached .obsidian/plugins/obsidian-git/data.json
```

4. 提交并推送初始版本。
5. 确认本地 `HEAD` 与远端 `main` 哈希一致。

### 3. 配置 Windows 同步

用户要求编辑事件触发时，优先使用附带的 Windows 事件监听器。它会排队处理创建、修改、重命名和删除事件，等待编辑停止后自动提交、变基拉取并推送。

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-windows-event-sync.ps1 `
  -VaultPath "C:\笔记库路径" `
  -DebounceSeconds 60 `
  -PullIntervalSeconds 60
```

安装器会注册当前用户登录自启任务并立即启动。本地提交和推送只由文件事件触发；隐藏任务在工作区干净时每 60 秒静默拉取手机更新，不会调用 Obsidian 通知。

安装器同时注册 `Obsidian Git Sync Watchdog ...` 守护任务。主任务和守护任务都通过 `wscript.exe` 与 `run-hidden.vbs` 隐藏启动 PowerShell，避免开机登录或周期检查时弹出 CLI 窗口。使用隐藏启动器后，主任务可能显示 `Running` 或 `Ready`；以 `verify-sync.ps1` 输出的 `watcherProcesses` 判断真实监听是否存活。守护任务每分钟检查真实的 `watch-vault.ps1` 进程，若主监听因睡眠、电池、系统中断或异常退出而停止，会自动重新启动。

关闭 Windows Obsidian Git 插件的自动提交、周期自动拉取和普通通知，但开启 `Pull on startup`，确保每次打开 Obsidian 立即拉取一次。插件可保留用于历史记录和手动命令。

### 4. 验证 Windows 端到端流程

先执行无侵入检查：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 -VaultPath "C:\笔记库路径"
```

只有用户授权上传临时测试笔记后，才运行事件探针：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 `
  -VaultPath "C:\笔记库路径" -RunEventProbe
```

只有满足以下全部条件才能宣布成功：

- GitHub CLI 可验证时，仓库必须为私有。
- 监听任务和守护任务存在。
- `watcherProcesses` 至少包含一个后台监听进程；若监听进程被停止，守护任务能够重新拉起。
- 创建和删除事件无需手动 Git 命令即可提交并推送。
- 工作区干净。
- 本地与远端哈希一致。

### 5. 配置手机端

配置 iPhone 或 Android 前阅读 [references/mobile.md](references/mobile.md) 的中文版。若用户询问同步如何实现、为什么要 Pull、何时提交、手机端在哪里下载 Git 插件、如何获取和填写 Key/Token、命令面板输入什么、克隆后如何重启并设置插件开关，也必须阅读该文件并按其中顺序解释。

先运行以下脚本生成用户专属配置，不要让用户手动猜测账号、邮箱或克隆地址：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/mobile-setup-info.ps1 `
  -VaultPath "C:\笔记库路径" -OpenTokenPage
```

向用户输出的手机配置消息必须包含可点击的 Obsidian 下载链接、Obsidian Git 插件链接、GitHub Token 创建链接、GitHub 邮箱设置链接、私有仓库页面、HTTPS `.git` 克隆地址、用户名、作者名和 noreply 邮箱。不得输出或索取 Token 值。

所有可复制配置值都必须由 `scripts/mobile-setup-info.ps1` 或等价检查从当前用户的 GitHub 登录、私有仓库和 vault 远端生成。不得沿用历史对话中的账号、邮箱、仓库名、路径或示例值。

若用户尚未说明手机系统，只询问一次 iPhone 或 Android；之后仅显示对应系统的完整步骤，不要同时堆叠无关步骤。

每完成一个阶段都要求用户确认：安装 Obsidian、启用 Git 插件、创建并填写 Token、克隆仓库、首次 Pull、首次 Commit-and-sync。界面文字变化时，让用户使用 Obsidian 设置搜索和命令面板搜索文档中的稳定英文命令名称。

使用 HTTPS 和仅授权单个仓库的 Fine-grained Token。禁止要求用户在聊天中发送 Token。使用 Git 同步时，不要同时让同一笔记库使用 iCloud。

iOS 无法保证后台运行。自动同步仅在 Obsidian 保持活动时可靠；编辑前执行 `Pull`、离开前执行 `Commit-and-sync` 是可靠的备用流程。

### 6. 验证三端同步

1. 确认 Windows 工作区干净且已推送。
2. 在 iPhone 上拉取。
3. 在 iPhone 打开已有笔记，修改正文并同步。
4. 确认 GitHub 对原路径记录为 `M`，而不是另一个文件名的 `A`。
5. Windows 拉取并确认内容一致。
6. Windows 创建独立测试笔记，确认 GitHub 收到后在 iPhone 拉取。
7. 删除测试文件并确认本地与远端哈希一致。

没有用户在实体 iPhone 上观察到成功的拉取和推送，不得声称 iPhone 端验证成功。

### 7. 故障排查

认证、网络或 VPN、重复笔记、冲突、监听失败、移动端限制、误删恢复和四端/多端同步策略请阅读 [references/troubleshooting.md](references/troubleshooting.md) 的中文版。

---

# English Version

## Goal

Build this data path: `Windows Obsidian vault <-> private GitHub repository <-> iPhone Obsidian vault`.

Treat the user's private GitHub vault repository as the source of truth. The skill itself may be published publicly, but its public repository must contain only generic scripts and documentation, never user notes, tokens, account credentials, machine-specific paths, or runtime logs.

## Workflow

### Interactive configuration protocol

When the user asks to configure Obsidian and GitHub, follow this exact order:

1. Read the English section in [references/desktop.md](references/desktop.md).
2. Run `scripts/ensure-git-tools.ps1` to check Git and GitHub CLI. If either is missing, obtain installation approval, run it with `-InstallIfMissing`, and recheck versions.
3. Check `gh auth status`. If unauthenticated, run `scripts/github-web-login.ps1` to launch GitHub web authorization and wait for the user to finish in the browser.
4. Revalidate the GitHub account. Never ask the user to send a password, verification code, or token in chat.
5. Locate the vault and show the exact local path, GitHub account, repository name, and `PRIVATE` visibility.
6. Before creating or connecting a repository, ask whether the user already created the private GitHub repository they want to import into Obsidian. If yes, request the complete repository URL and use that existing private repository; on a new device or empty target folder, clone it instead of creating a new repository. If no, create a new private repository only after the user confirms the repository name. When connecting an existing local vault, run `scripts/publish-vault.ps1 -ConfirmUpload` with `-RepositoryUrl` and `-OpenRepositoryPage`; do not repeatedly ask the user to split owner, repository name, and `.git` URL.
7. Verify private visibility and matching hashes, run `scripts/configure-windows-obsidian-git.ps1` to disable Windows plugin automatics and ordinary notices, then install Windows event synchronization.
8. Run the noninvasive check and run the event probe only after authorization to upload temporary test files.
9. Ask the user to create or edit a test note in Windows Obsidian and confirm that GitHub shows the change. Do not claim desktop success before confirmation.
10. After Windows confirmation, ask for the phone type unless it is already known.
11. Open the GitHub fine-grained token page, display the matching instructions from [references/mobile.md](references/mobile.md), and guide the first mobile Pull/Push.
12. Claim three-endpoint success only after the user verifies it on the physical phone.

### 1. Discover the environment

1. Locate the open Obsidian vault from Obsidian's application configuration when possible.
2. Distinguish the vault from the Obsidian installation directory.
3. Inspect `.git`, remotes, branch, worktree status, `.obsidian`, and Git plugin state.
4. Check Git and GitHub CLI availability and authentication.
5. Preserve existing notes and unrelated changes. Never clone over a nonempty vault without reconciling it first.

### 2. Create or connect the private repository

1. Ask the user whether a target private GitHub repository already exists. Do not guess.
2. If an existing private repository is provided, verify that the URL is reachable and private. On a new PC, phone, or empty local target folder, clone that repository and open the cloned folder as the Obsidian vault. Do not initialize a new repository and push over it.
3. If the user has local notes that must be connected to an existing repository, inspect both histories and reconcile them first; never force-push or overwrite unrelated remote history.
4. If no repository exists, ask for the repository name, then create a new private GitHub repository.
5. Initialize branch `main` only when creating a new repository from a local vault that is not already a repository.
6. Add at least these entries to `.gitignore`:

```gitignore
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache/
.obsidian/plugins/obsidian-git/data.json
.trash/
.DS_Store
Thumbs.db
desktop.ini
```

Keep `.obsidian/plugins/obsidian-git/data.json` device-local. Otherwise desktop timing settings overwrite iPhone settings and vice versa. If tracked, preserve the local file and run:

```bash
git rm --cached .obsidian/plugins/obsidian-git/data.json
```

7. Commit and push the baseline only after the correct repository path is confirmed.
8. Verify local `HEAD` equals remote `main`.

### 3. Configure Windows synchronization

Prefer the bundled Windows event watcher when the user requests edit-event synchronization. It queues create, modify, rename, and delete events, waits for a quiet period, commits, pulls with rebase, and pushes.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-windows-event-sync.ps1 `
  -VaultPath "C:\path\to\vault" `
  -DebounceSeconds 60 `
  -PullIntervalSeconds 60
```

The installer registers a per-user logon task and starts it immediately. Local commits and pushes occur only after file events; a hidden clean-worktree pull checks for phone updates every 60 seconds without using Obsidian notices.

The installer also registers an `Obsidian Git Sync Watchdog ...` task. Both the main task and watchdog launch PowerShell through `wscript.exe` and `run-hidden.vbs`, avoiding CLI windows at logon and during periodic checks. With the hidden launcher, the main task may appear as `Running` or `Ready`; use `watcherProcesses` from `verify-sync.ps1` to determine whether the real watcher is alive. The watchdog checks the real `watch-vault.ps1` process every minute and restarts it after sleep, battery transitions, system interruption, or abnormal exit.

Disable Obsidian Git automatic commit, periodic automatic pull, and ordinary notices on Windows, but enable `Pull on startup` so every Obsidian launch pulls once immediately. The plugin may remain installed for history and manual commands.

Configure only one desktop automation engine per Windows machine. If the bundled Windows event watcher is installed, run `scripts/configure-windows-obsidian-git.ps1` in its default `EventWatcher` mode and keep the plugin's 1-minute automatic commit/pull timers disabled. Enabling both the watcher and plugin timers can race for the Git index, create duplicate commits, show repeated notices, and increase conflict risk across two or more PCs. Use `-Mode PluginTimer` only when the Windows watcher is not installed or the user explicitly chooses Obsidian Git's built-in timers instead of the watcher.

### 4. Verify Windows end to end

Run a noninvasive check first:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 -VaultPath "C:\path\to\vault"
```

Run the event probe only after the user authorizes uploading a temporary test note:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 `
  -VaultPath "C:\path\to\vault" -RunEventProbe
```

Require every check before claiming success:

- Repository visibility is private when GitHub CLI can verify it.
- Watcher and watchdog tasks exist.
- `watcherProcesses` contains at least one background watcher process; if it is stopped, the watchdog can restart it.
- Create and delete events commit and push without manual Git commands.
- Worktree is clean.
- Local and remote hashes match.

### 5. Configure mobile

Read the English section in [references/mobile.md](references/mobile.md) before iPhone or Android setup. Also read it when the user asks how the sync architecture works, why Pull is needed, when commits happen, where to download the Git plugin on mobile, how to obtain and enter the key/token, which Command Palette command to run, and which plugin switches to enable or disable after clone and restart.

Generate personalized values before presenting instructions:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/mobile-setup-info.ps1 `
  -VaultPath "C:\path\to\vault" -OpenTokenPage
```

The mobile setup message must include clickable Obsidian download, Obsidian Git plugin, GitHub token, GitHub email settings, private repository, and repository clone links, plus username, author name, and noreply email. Never display or request the token value.

Every copyable configuration value must be generated by `scripts/mobile-setup-info.ps1` or an equivalent check from the current user's GitHub login, private repository, and vault remote. Never reuse accounts, emails, repository names, paths, or example values from prior conversations.

If the phone platform is unknown, ask once whether it is iPhone or Android, then show only the relevant complete path. Require confirmation after installing Obsidian, enabling Git, creating and entering the token, cloning, first Pull, and first Commit-and-sync. If labels move in a future UI, use Settings search and Command Palette searches for the stable English command names in the guide.

Use HTTPS with a fine-grained token restricted to one repository. Never request the token in chat. Do not use iCloud for the same vault when Git is the synchronization mechanism.

iOS cannot guarantee background execution. Automatic sync works while Obsidian remains active; `Pull` before editing and `Commit-and-sync` before leaving are the reliable fallback.

### 6. Validate all three endpoints

1. Ensure Windows is clean and pushed.
2. Pull on iPhone.
3. Open an existing note on iPhone, modify its body, and sync.
4. Confirm GitHub records `M`, not `A` for a second filename.
5. Pull on Windows and confirm the same content.
6. Create a distinct test note on Windows, confirm GitHub receives it, then pull it on iPhone.
7. Remove test artifacts and verify matching local and remote hashes.

Do not claim iPhone success without a user-observed test on the physical phone.

### 7. Troubleshooting

Read the English section in [references/troubleshooting.md](references/troubleshooting.md) for authentication, network or VPN failures, duplicate notes, conflicts, watcher failures, mobile limitations, accidental deletion recovery, and four-endpoint or multi-device sync strategy.
