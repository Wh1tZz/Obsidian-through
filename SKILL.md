---
name: obsidian-through
description: Configure, repair, explain, and verify private Obsidian synchronization across Windows, macOS, GitHub, and mobile devices. 配置、修复、解释并验证 Windows、macOS、GitHub 与移动设备之间的 Obsidian 私有同步。Use for private vault repositories, Windows edit-event sync, macOS Obsidian Git sync, mobile setup, GitHub token/key guidance, Pull/Commit/Push workflow explanation, device-setting isolation, duplicate-note diagnosis, accidental deletion recovery, multi-device sync strategy, failed pushes, and end-to-end checks. 用于私有笔记仓库、Windows 编辑事件同步、macOS Obsidian Git 同步、移动端配置、GitHub Token/Key 指导、Pull/Commit/Push 工作流解释、设备设置隔离、重复笔记诊断、误删恢复、多端同步策略、推送失败和端到端检查。
---

# 中文版

## 目标

建立数据链路：`Windows/macOS Obsidian 笔记库 <-> GitHub 私有仓库 <-> 移动端 Obsidian 笔记库`。

将用户的私有 GitHub 笔记仓库作为数据中心。Skill 自身可以发布到公开仓库，但公开仓库只能包含通用脚本和文档，绝不能包含用户笔记、Token、账号凭据、本机路径或运行日志。

## 工作流

### 交互式配置协议

当用户说“帮我配置 Obsidian 和 GitHub”或同义请求时，必须按以下顺序执行：

先运行 `npx obsidian-through platform` 或读取运行时平台。`win32` 使用 `scripts/setup-windows.ps1` 和 Windows 事件监听器；`darwin` 使用 `scripts/setup-macos.sh`、原生 Git/GitHub CLI 与 Obsidian Git 自动同步。禁止在 macOS 运行 Windows 计划任务脚本，也禁止把 macOS 当作移动端。默认入口 `npx obsidian-through` 必须自动选择对应电脑端流程，安装缺失工具、打开 GitHub 网页登录、识别 Obsidian vault、创建或连接私有仓库、上传或安全合并笔记、配置平台对应的自动同步并验证。

面向用户输出时，PC 端和移动端都使用简短的“去哪里 → 点什么 → 填什么”步骤和可复制代码块。主流程不解释原理、不重复注意事项、不预先展开错误分支；只有实际报错时才读取故障排查并给对应处理。主流程中只把两个网址作为 Markdown 可点击链接输出：GitHub 登录页 `[https://github.com/login/device](https://github.com/login/device)`，GitHub Token 创建页 `[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)`。其他值必须来自脚本或 GitHub API，并放入 fenced code block。每个需要复制或在命令面板运行的值都必须使用独立代码块；`Git: Pull` 与 `Git: Commit-and-sync` 不得放在同一代码块。克隆阶段分别输出仓库 URL 和脚本生成的真实仓库名。真实仓库名可以是用户的任意仓库名，必须从当前远程动态取值，禁止固定写成 `obsidian-vault`。移动端必须克隆到以该真实仓库名命名的新子文件夹，不选择 `Vault Root`。不要向用户输出 `.obsidian` 选择、删除本地配置或 `Custom base path` 说明。GitHub Token 页面按当前界面顺序输出中英文标签。

1. Windows 阅读 [references/desktop.md](references/desktop.md)，macOS 阅读 [references/macos.md](references/macos.md)。若用户要求模拟或复盘完整用户输出，同时阅读 [references/user-facing-output.md](references/user-facing-output.md) 中文版。
2. 直接运行默认入口 `npx obsidian-through`。CLI 必须自动识别 Windows 或 macOS 并调用对应脚本。
3. 不要把内部 JSON、Git 细节或无意义选择项直接堆给用户；只输出必要进度、真实 GitHub 账号、真实 vault 路径、真实私有仓库地址和测试步骤。
4. 登录成功后重新验证 GitHub 账号，不得要求用户在聊天中发送密码、验证码或 Token。
5. 定位笔记库，向用户明确显示将上传的本地路径、GitHub 账号、仓库名和 `PRIVATE` 可见性。
6. 获得上传授权后运行 `scripts/publish-vault.ps1 -ConfirmUpload`，初始化 Git、创建或连接私有仓库并完成首次推送。用户已有仓库时，优先接收完整 GitHub 仓库 URL，使用 `-RepositoryUrl` 和 `-OpenRepositoryPage`，不要反复要求用户拆分 owner、仓库名和 `.git` 地址。
7. 验证 GitHub 仓库为私有、本地与远端哈希一致。Windows 配置隐藏事件监听器；macOS 配置 Obsidian Git 的 `0.5` 分钟停止编辑后同步和启动 Pull。
8. 运行无侵入检查；获得测试文件上传授权后运行事件探针。
9. 请用户在当前电脑的 Obsidian 新建或编辑测试笔记，并确认 GitHub 页面出现改动。用户未确认前，不得声称桌面连接成功。
10. 电脑端确认成功后，直接进入统一的移动端流程，不询问或拆分手机、平板、iOS、iPadOS、Android 等设备类型。
11. 运行手机配置脚本时必须带 `-OpenTokenPage`，主动弹出 GitHub Fine-grained Token 创建页面；若脚本不可用，直接用系统浏览器打开 `https://github.com/settings/personal-access-tokens/new`。同时在聊天中输出 `[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)` 和 [references/mobile.md](references/mobile.md) 的统一移动端说明，并让用户在移动设备上完成首次 Pull/Push。
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

必须让 `.obsidian/plugins/obsidian-git/data.json` 保持设备本地化，否则电脑与移动端会互相覆盖同步时间和认证设置。若已被跟踪，保留本地文件并运行：

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
  -DebounceSeconds 15 `
  -PullIntervalSeconds 30
```

安装器会注册当前用户登录自启任务并立即启动。本地提交和推送只由文件事件触发；停止编辑约 15 秒后提交并推送。隐藏任务在工作区干净时每 30 秒静默拉取手机更新，不会调用 Obsidian 通知。若某次提交因断网或 GitHub 暂时不可达而未推送，网络恢复后会在周期检查中自动变基并补推，无需等待下一次编辑。不要默认低于 10 秒，过短会制造大量碎提交并增加多设备冲突概率。

安装器同时注册 `Obsidian Git Sync Watchdog ...` 守护任务。主任务和守护任务都通过 `wscript.exe` 与 `run-hidden.vbs` 隐藏启动 PowerShell，避免开机登录或周期检查时弹出 CLI 窗口。两个任务都允许电池供电、禁止因切换电池而停止，并在当前用户登录后启动。使用隐藏启动器后，主任务可能显示 `Running` 或 `Ready`；以 `verify-sync.ps1` 输出的 `watcherProcesses` 判断真实监听是否存活。守护任务每分钟只匹配以 `-File watch-vault.ps1` 启动的真实监听进程，不能把自身误判为监听器；若主监听因睡眠、电池、系统中断或异常退出而停止，会清理失效任务状态并自动重新启动。

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

安装或修复后运行恢复探针，主动终止一次监听进程并验证守护任务能够重新拉起：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 `
  -VaultPath "C:\笔记库路径" -RunWatcherRecoveryProbe
```

只有满足以下全部条件才能宣布成功：

- GitHub CLI 必须成功验证仓库为 `PRIVATE`；`unknown`、查询失败或任何非私有状态均不得通过。
- 监听任务和守护任务存在。
- `watcherProcesses` 至少包含一个后台监听进程；若监听进程被停止，守护任务能够重新拉起。
- 监听与守护任务均包含登录触发器，守护任务还包含每分钟触发器，且两个任务都不会因电池供电停止。
- 两个任务均通过 `wscript.exe` 隐藏启动并配置失败重启策略。
- 创建和删除事件无需手动 Git 命令即可提交并推送。
- 工作区干净。
- 本地与远端哈希一致。

### 5. 配置手机端

配置任何移动设备前阅读 [references/mobile.md](references/mobile.md) 的中文版。所有手机和平板使用同一套认证、克隆、插件设置和同步说明，不询问设备系统，也不拆分输出。若用户询问同步如何实现、为什么要 Pull、何时提交、移动端在哪里下载 Git 插件、如何获取和填写 Key/Token、命令面板输入什么、克隆后如何重启并设置插件开关，也必须阅读该文件并按其中顺序解释。

先运行以下跨平台命令生成用户专属配置，不要让用户手动猜测账号、邮箱或克隆地址：

```powershell
npx obsidian-through mobile-info --vault "<当前电脑的真实 vault 路径>" --open-token-page
```

向用户输出移动端配置前，通过跨平台 `scripts/mobile-setup-info.js` 自动弹出 GitHub Token 创建页面。消息本身只把 Token 创建页作为 Markdown 可点击链接输出；其他值使用代码块输出。不得输出或索取 Token 值。

所有可复制配置值都必须由 `scripts/mobile-setup-info.ps1` 或等价检查从当前用户的 GitHub 登录、私有仓库和 vault 远端生成。不得沿用历史对话中的账号、邮箱、仓库名、路径或示例值。

不要询问移动设备系统。手机和平板统一输出一套流程；只有在安装入口、文件权限或后台运行限制确实不同时，才在同一步骤中补充一句系统兼容提示，不另建第二套流程。

每完成一个阶段都要求用户确认：安装 Obsidian、启用 Git 插件、在 `Settings -> Community plugins -> Git -> Authentication/commit author` 填写 GitHub username 和 Fine-grained Token，然后克隆仓库。克隆前不要配置 `Automatic`。克隆位置必须填写当前远程的真实仓库名，它可以是任意名称，不选择 `Vault Root`。只有用户明确看到 `Cloned new repo.` 和 `Please restart Obsidian`，才能进入重启后设置；未看到就判定克隆失败，禁止设置 Automatic、运行 Pull 或选择 upstream。克隆成功并重启后，在 `Automatic` 按顺序设置：`Split timers for automatic commit and sync` 关闭、`Auto commit-and-sync interval (minutes)` 填写 `0.5`、`Auto commit-and-sync after stopping file edits` 开启、`Pull on startup` 开启。再填写 Username、Token、Author name、Author email并执行首次 Pull，然后执行首次 `Git: Commit-and-sync`。首次手动提交同步成功后，必须完全关闭并重新打开 Obsidian，让插件重新初始化自动同步计时器；随后在应用保持前台时修改测试笔记，停止编辑 30–60 秒，不运行手动命令，确认 GitHub 出现自动提交。出现克隆未完成、`No upstream branch is set`、选择 `origin` 后崩溃或启动退出循环时，立即读取 [references/troubleshooting.md](references/troubleshooting.md) 的对应移动端流程。

使用 HTTPS 和仅授权单个仓库的 Fine-grained Token。禁止要求用户在聊天中发送 Token。使用 Git 同步时，不要同时让同一笔记库使用 iCloud。

移动系统可能暂停后台应用。自动同步仅在 Obsidian 保持活动时可靠；编辑前执行 `Pull`、离开前执行 `Commit-and-sync` 是可靠的备用流程。

### 6. 验证三端同步

1. 确认 Windows 工作区干净且已推送。
2. 在移动端拉取。
3. 在移动端打开已有笔记，修改正文并同步。
4. 确认 GitHub 对原路径记录为 `M`，而不是另一个文件名的 `A`。
5. Windows 拉取并确认内容一致。
6. Windows 创建独立测试笔记，确认 GitHub 收到后在移动端拉取。
7. 删除测试文件并确认本地与远端哈希一致。

没有用户在实体移动设备上观察到成功的拉取和推送，不得声称移动端验证成功。

### macOS 电脑端规则

macOS 必须使用 [references/macos.md](references/macos.md)。使用原生 Git 和 GitHub CLI，不要求用户填写移动端 Token。自动同步由 Obsidian Git 插件负责，设置为：`Split timers` 关闭、`Auto commit-and-sync interval` 为 `0.5`、`Auto commit-and-sync after stopping file edits` 开启、`Pull on startup` 开启。不要安装 Windows Watchdog 或计划任务。首次手动 `Git: Commit-and-sync` 成功后重启 Obsidian，再验证自动提交。

### 7. 故障排查

认证、网络或 VPN、重复笔记、冲突、监听失败、移动端限制、误删恢复和四端/多端同步策略请阅读 [references/troubleshooting.md](references/troubleshooting.md) 的中文版。

---

# English Version

## Goal

Build this data path: `Windows/macOS Obsidian vault <-> private GitHub repository <-> mobile Obsidian vault`.

Treat the user's private GitHub vault repository as the source of truth. The skill itself may be published publicly, but its public repository must contain only generic scripts and documentation, never user notes, tokens, account credentials, machine-specific paths, or runtime logs.

## Workflow

### Interactive configuration protocol

When the user asks to configure Obsidian and GitHub, follow this exact order:

Detect the desktop platform before setup. Route `win32` to `scripts/setup-windows.ps1` and the Windows event watcher. Route `darwin` to `scripts/setup-macos.sh`, native Git/GitHub CLI, and Obsidian Git automation. Never run Windows scheduled-task scripts on macOS or treat macOS as mobile. The default `npx obsidian-through` entry must select the correct workflow automatically.

Use short “where → click → enter” steps and fenced copy blocks for PC and mobile user-facing output. Every copyable value or Command Palette command must use its own fenced code block. During clone, separately output the repository URL and the real repository name generated by the script. The real repository name may be any user-selected name; derive it dynamically from the current remote and never hardcode `obsidian-vault`. On mobile, clone into a new subfolder named after that real repository; do not select `Vault Root`. Do not show `.obsidian` choices, local-configuration deletion choices, or `Custom base path` instructions in the main user-facing flow. Present GitHub token fields in current UI order with Chinese / English label pairs. For simulations or full-output reviews, follow [references/user-facing-output.md](references/user-facing-output.md).

1. On Windows, read [references/desktop.md](references/desktop.md). On macOS, read [references/macos.md](references/macos.md). For a full simulation, also read [references/user-facing-output.md](references/user-facing-output.md).
2. Run `npx obsidian-through`; let the CLI select the platform-specific setup.
3. Do not dump internal JSON, Git details, or meaningless choices to the user. Show only necessary progress, the real GitHub account, real vault path, real private repository URL, and test steps.
4. Revalidate the GitHub account. Never ask the user to send a password, verification code, or token in chat.
5. Locate the vault and show the exact local path, GitHub account, repository name, and `PRIVATE` visibility.
6. Before creating or connecting a repository, ask whether the user already created the private GitHub repository they want to import into Obsidian. If no repository exists and the local vault has notes, create a new private repository and upload the local notes. If a repository exists and the local vault is empty or this is a new device, clone the existing repository. If a repository exists and the local vault also has notes, safely merge local and remote histories after creating a backup branch; never force-push or overwrite either side. Run `scripts/publish-vault.ps1 -ConfirmUpload` with `-RepositoryUrl` and `-OpenRepositoryPage`; do not repeatedly ask the user to split owner, repository name, and `.git` URL.
7. Verify private visibility and matching hashes. Install the hidden event watcher on Windows; configure Obsidian Git with a 0.5-minute post-edit sync and startup Pull on macOS.
8. Run the noninvasive check and run the event probe only after authorization to upload temporary test files.
9. Ask the user to create or edit a test note on the current desktop and confirm that GitHub shows the change. Do not claim desktop success before confirmation.
10. After desktop confirmation, continue directly to the shared mobile workflow without asking for the device type.
11. Run the mobile setup script with `-OpenTokenPage` so the GitHub fine-grained token page opens automatically. Print the concise mobile steps from [references/user-facing-output.md](references/user-facing-output.md) and guide the first mobile Pull/Push.
12. Claim three-endpoint success only after the user verifies it on the physical phone.

### 1. Discover the environment

1. Locate the open Obsidian vault from Obsidian's application configuration when possible.
2. Distinguish the vault from the Obsidian installation directory.
3. Inspect `.git`, remotes, branch, worktree status, `.obsidian`, and Git plugin state.
4. Check Git and GitHub CLI availability and authentication.
5. Preserve existing notes and unrelated changes. Never clone over a nonempty vault without reconciling it first.

### 2. Create or connect the private repository

1. Ask the user whether a target private GitHub repository already exists. Do not guess.
2. If no repository exists and the local vault has notes, ask for the repository name, create a new private GitHub repository, commit the local notes, and push them.
3. If no repository exists and the local target is empty, ask for the repository name, create a new private GitHub repository, then use it as the sync destination.
4. If an existing private repository is provided and this is a new PC, phone, or empty local target folder, clone that repository and open the cloned folder as the Obsidian vault.
5. If an existing private repository is provided and the local vault also has notes, inspect both histories, create a local backup branch, fetch the remote, and merge the remote with the local notes. If conflicts appear, stop and preserve all conflict markers for resolution. Never force-push or overwrite unrelated remote history.
6. Initialize branch `main` only when creating a new repository from a local vault that is not already a repository.
7. Add at least these entries to `.gitignore`:

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

Keep `.obsidian/plugins/obsidian-git/data.json` device-local. Otherwise desktop and mobile timing or authentication settings overwrite each other. If tracked, preserve the local file and run:

```bash
git rm --cached .obsidian/plugins/obsidian-git/data.json
```

8. Commit and push the baseline or merge result only after the correct repository path is confirmed.
9. Verify local `HEAD` equals remote `main`.

### 3. Configure Windows synchronization

Prefer the bundled Windows event watcher when the user requests edit-event synchronization. It queues create, modify, rename, and delete events, waits for a quiet period, commits, pulls with rebase, and pushes.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-windows-event-sync.ps1 `
  -VaultPath "C:\path\to\vault" `
  -DebounceSeconds 15 `
  -PullIntervalSeconds 30
```

The installer registers a per-user logon task and starts it immediately. Local commits and pushes occur only after file events and a short quiet period; a hidden clean-worktree pull checks for phone updates every 30 seconds without using Obsidian notices. If a commit remains unpushed because the network or GitHub was unavailable, the periodic check rebases and retries the push after connectivity returns without waiting for another edit. Use 15 seconds for responsive desktop sync; avoid values below 10 seconds unless the user explicitly accepts many small commits and higher conflict risk.

The installer also registers an `Obsidian Git Sync Watchdog ...` task. Both the main task and watchdog launch PowerShell through `wscript.exe` and `run-hidden.vbs`, avoiding CLI windows at logon and during periodic checks. Both tasks are allowed on battery power, are not stopped by a battery transition, and start at user logon. With the hidden launcher, the main task may appear as `Running` or `Ready`; use `watcherProcesses` from `verify-sync.ps1` to determine whether the real watcher is alive. Every minute, the watchdog matches only a process launched with `-File watch-vault.ps1`, so it cannot mistake its own command line for the watcher. If the watcher stops after sleep, a power transition, system interruption, or abnormal exit, the watchdog clears stale task state and restarts it.

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

After installation or repair, run the recovery probe. It terminates the watcher once and verifies that the watchdog starts a replacement:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 `
  -VaultPath "C:\path\to\vault" -RunWatcherRecoveryProbe
```

Require every check before claiming success:

- GitHub CLI must verify repository visibility as `PRIVATE`; `unknown`, query failure, or any non-private result must fail.
- Watcher and watchdog tasks exist.
- `watcherProcesses` contains at least one background watcher process; if it is stopped, the watchdog can restart it.
- Watcher and watchdog tasks have logon triggers, the watchdog has a one-minute timer, and neither task stops on battery power.
- Both tasks launch through `wscript.exe` and have restart-on-failure policies.
- Create and delete events commit and push without manual Git commands.
- Worktree is clean.
- Local and remote hashes match.

### 5. Configure mobile

Read the English section in [references/mobile.md](references/mobile.md) before configuring any mobile device. Phones and tablets use one shared authentication, clone, plugin-settings, and sync guide. Do not ask for the operating system or split the output by platform. Also read it when the user asks how the sync architecture works, why Pull is needed, when commits happen, where to download the Git plugin on mobile, how to obtain and enter the key/token, which Command Palette command to run, and which plugin switches to enable or disable after clone and restart.

Generate personalized values before presenting instructions on Windows or macOS:

```text
npx obsidian-through mobile-info --vault "<real desktop vault path>" --open-token-page
```

Before sending the mobile setup message, use cross-platform `scripts/mobile-setup-info.js` to open the GitHub token creation page and generate the private repository URL, clone URL, username, author name, and noreply email. Never display or request the token value.

Every copyable configuration value must be generated by `scripts/mobile-setup-info.ps1` or an equivalent check from the current user's GitHub login, private repository, and vault remote. Never reuse accounts, emails, repository names, paths, or example values from prior conversations.

Do not ask which mobile operating system the user has. Give phones and tablets one shared workflow. After enabling Git, enter the GitHub username and fine-grained token before cloning. Do not configure `Automatic` before cloning. For the clone location, enter the current remote's real repository name, which may be any name, and never select `Vault Root`. Continue only after the user explicitly sees `Cloned new repo.` and `Please restart Obsidian`; otherwise treat clone as failed and do not configure Automatic, run Pull, or select an upstream. After a successful clone and restart, set `Split timers for automatic commit and sync` off, interval `0.5`, sync after edits on, and `Pull on startup` on. Enter Username, Token, Author name, and Author email, perform the first Pull, then run the first `Git: Commit-and-sync`. After that first manual sync succeeds, fully close and reopen Obsidian so the plugin reinitializes its automatic-sync timer. Test automatic sync by editing a note, leaving the app active for 30–60 seconds, and verifying GitHub updates without another manual command. For incomplete clone, missing upstream, crash after selecting `origin`, or startup exit loops, load the matching mobile repair in [references/troubleshooting.md](references/troubleshooting.md).

Use HTTPS with a fine-grained token restricted to one repository. Never request the token in chat. Do not use iCloud for the same vault when Git is the synchronization mechanism.

Mobile operating systems cannot guarantee background execution. Automatic sync works while Obsidian remains active; `Pull` before editing and `Commit-and-sync` before leaving are the reliable fallback.

### 6. Validate all three endpoints

1. Ensure Windows is clean and pushed.
2. Pull on the mobile device.
3. Open an existing note on the mobile device, modify its body, and sync.
4. Confirm GitHub records `M`, not `A` for a second filename.
5. Pull on Windows and confirm the same content.
6. Create a distinct test note on Windows, confirm GitHub receives it, then pull it on the mobile device.
7. Remove test artifacts and verify matching local and remote hashes.

Do not claim mobile success without a user-observed test on the physical mobile device.

### macOS desktop rules

Use [references/macos.md](references/macos.md). Authenticate native Git through GitHub CLI; do not request the mobile token. Let Obsidian Git own automation with split timers off, interval `0.5`, sync-after-edit on, and startup Pull on. Never install the Windows watcher or watchdog on macOS. After the first manual `Git: Commit-and-sync`, restart Obsidian and verify automatic sync.

### 7. Troubleshooting

Read the English section in [references/troubleshooting.md](references/troubleshooting.md) for authentication, network or VPN failures, duplicate notes, conflicts, watcher failures, mobile limitations, accidental deletion recovery, and four-endpoint or multi-device sync strategy.
