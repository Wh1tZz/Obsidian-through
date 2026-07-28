# 中文版

## 0. PC 端自动安装和用户输出格式

PC 端默认是自动流程。用户要求配置 Obsidian 和 GitHub 后，直接运行 `scripts/setup-windows.ps1` 或 `npx obsidian-through`。不要先问用户是否安装 Git/GitHub CLI；缺失时通过 `ensure-git-tools.ps1 -InstallIfMissing` 自动安装。不要先询问仓库名；登录 GitHub 后默认使用当前账号下的 `obsidian-vault` 私有仓库，除非 vault 已经有 origin 或用户主动提供现有仓库 URL。

面向用户说话时，不要只说“复制这个地址”或“运行这个命令”。必须把 PC 端每个需要用户核对、复制、粘贴、打开或搜索的值放进单独的代码块，并说明用户应该在什么界面里使用它。

主流程里只有 GitHub 登录页使用 Markdown 可点击链接。仓库页面、clone URL、vault 路径、命令名等仍使用代码块，方便复制和核对。

所有代码块中的值必须来自当前运行结果：`setup-windows.ps1`、`publish-vault.ps1`、`verify-sync.ps1`、`gh api user`、`git remote get-url origin` 或等价检查。不要把示例占位符当成最终输出。

GitHub 登录阶段应这样输出：

```text
接下来我会打开 GitHub 官方授权页面。请只在浏览器里登录，不要把密码、验证码或 Token 发到聊天窗口。
```

[https://github.com/login/device](https://github.com/login/device)

如果 GitHub CLI 显示一次性 code，只让用户把 PowerShell 窗口里的 code 填到 GitHub 网页中；不要让用户把 code 发给聊天窗口。

GitHub 登录完成后，应输出真实账号：

```text
GitHub 登录账号
```

```text
<real login from gh api user>
```

确认 PC vault 时，应输出真实路径，并说明这是 Obsidian 笔记库，不是 Obsidian 软件安装目录：

```text
电脑端 Obsidian vault 路径
```

```text
<real absolute vault path>
```

确认仓库时，应输出真实仓库地址和可见性：

```text
GitHub 私有仓库
```

```text
https://github.com/<real owner>/<real repository>
```

```text
Git remote clone URL
```

```text
https://github.com/<real owner>/<real repository>.git
```

上传前必须自然语言说明：确认后会把上述 vault 连接到上述 private repository；如果本地和远程都有内容，会安全合并并保留冲突，不会 force push。

PC 配置完成后，给用户的测试步骤必须具体到操作位置：

1. 打开 Windows 端 Obsidian。
2. 在左侧文件列表新建一篇测试笔记。
3. 文件名建议给出可复制值：

```text
Windows 同步测试
```

4. 正文建议给出可复制值：

```text
这是一条 Windows 到 GitHub 的同步测试。
```

5. 停止编辑并等待 15 到 30 秒。
6. 打开实际 GitHub 仓库页面刷新：

```text
https://github.com/<real owner>/<real repository>
```

7. 让用户确认是否看到了刚刚的测试笔记。只有用户确认后，才宣布 PC 端成功，并继续手机端配置。

## 自动登录与桌面配置

### 1. 检查并自动安装必需软件

先运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ensure-git-tools.ps1 -InstallIfMissing
```

脚本会检查 Git 和 GitHub CLI。若缺失，直接通过 Windows Package Manager 安装 `Git.Git` 和/或 `GitHub.cli`，然后复查版本。不要把完整工具路径和内部 JSON 堆给用户，只需要说明：

```text
正在检查并安装同步所需环境。
```

安装完成后输出：

```text
Git 和 GitHub CLI 已准备完成。
```

若 `winget` 不存在或安装失败，停止并提示用户手动安装官方 Git 和 GitHub CLI；不要伪造成成功状态。

仍可单独运行底层脚本：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ensure-git-tools.ps1 -InstallIfMissing
```

### 2. 弹出 GitHub 登录界面

运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/github-web-login.ps1
```

脚本先检查现有登录。未登录时调用 `gh auth login --web`，默认浏览器会打开 GitHub 授权页面。用户在浏览器完成登录后，脚本再次检查账号并配置 Git 凭据。

不要代替用户输入 GitHub 密码，不要索取验证码，不要输出 GitHub CLI Token。

如果网络需要本机代理，允许用户传入代理地址：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/github-web-login.ps1 `
  -Proxy "http://127.0.0.1:7890"
```

登录脚本会直接打开 GitHub device 授权页面。若 GitHub CLI 显示一次性 code，让用户把 PowerShell 窗口里的 code 填到浏览器页面；不要要求用户把 code、密码或 Token 发到聊天中。

### 3. 定位 Obsidian 笔记库

优先读取 Obsidian 应用配置中的 vault 路径。确认目标目录包含笔记和 `.obsidian`，不要把 Obsidian 软件安装目录当作笔记库。

操作前向用户显示：

- 本地笔记库绝对路径；
- GitHub 登录账号；
- 计划创建或连接的仓库名；
- 仓库可见性必须为 `PRIVATE`；
- 首次推送会上传哪些文件。

### 4. 建立私有仓库

默认不询问仓库名。登录 GitHub 后，若 vault 已经有 GitHub origin，就沿用该 origin；否则创建或连接当前 GitHub 账号下的默认私有仓库：

```text
https://github.com/<real login>/obsidian-vault.git
```

如果用户主动提供现有仓库 URL，才使用用户提供的 URL。执行时运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish-vault.ps1 `
  -VaultPath "C:\笔记库路径" `
  -RepositoryUrl "https://github.com/<owner>/<repository>.git" `
  -OpenRepositoryPage `
  -ConfirmUpload
```

优先让用户直接提供完整 GitHub 仓库 URL，而不是反复拆分 owner 和仓库名。脚本会从 URL 中解析 owner 和 repository，并打开 GitHub 仓库页或新建仓库页，供用户确认连接的是正确的私有仓库。若用户没有现成仓库，也可改用 `-RepositoryName "<repository-name>"` 创建当前 GitHub 账号下的私有仓库。

脚本会：

1. 检查 GitHub 登录账号。
2. 扫描超过 95 MB 的文件并在推送前阻止风险文件。
3. 检查现有 Git 状态和远端。
4. 若尚未初始化，使用 `main` 分支初始化。
5. 补充 Skill 要求的 `.gitignore`。
6. 将 Git 插件 `data.json` 从版本控制移除但保留本地文件。
7. 设置仓库级提交作者，优先使用 GitHub noreply 邮箱。
8. 创建 `PRIVATE` GitHub 仓库或安全连接同名私有仓库。
9. 拒绝覆盖不同的现有远端或无关历史。
10. 首次提交并推送。
11. 验证 GitHub 可见性、本地哈希和远端哈希。

若远端仓库已有不相关历史，停止并处理合并，禁止强制覆盖。

### 5. 安装事件同步

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-windows-event-sync.ps1 `
  -VaultPath "C:\笔记库路径" `
  -DebounceSeconds 15 `
  -PullIntervalSeconds 30
```

该任务监听创建、修改、重命名和删除。停止编辑 15 秒后自动提交、变基远端更新并推送。没有本地编辑时不会提交或推送；工作区干净时每 30 秒通过隐藏任务静默拉取手机更新。不要默认低于 10 秒，过短会制造大量碎提交并增加多设备冲突概率。

安装脚本还会创建 `Obsidian Git Sync Watchdog ...` 计划任务。主同步任务和守护任务都通过 `wscript.exe` 调用 `run-hidden.vbs` 隐藏启动 PowerShell，避免开机登录或周期检查时弹出 CLI 窗口。两个任务都在当前用户登录后启动，允许电池供电，并且不会因切换到电池而停止。使用隐藏启动器后，主同步任务可能显示 `Running` 或 `Ready`；以 `watcherProcesses` 判断真实监听是否存活。守护任务每分钟短暂运行一次，只识别以 `-File watch-vault.ps1` 启动的真实后台进程，不会把自己的命令行误判成监听器。若主监听因睡眠、断电、电池策略或异常退出而停止，守护任务会清理失效状态并重新启动它。

运行以下脚本自动设置 Windows Obsidian Git：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/configure-windows-obsidian-git.ps1 `
  -VaultPath "C:\笔记库路径"
```

它会设置 `Auto commit-and-sync interval = 0`、`Auto pull interval = 0`、开启 `Pull on startup`、关闭停止编辑后自动同步，并开启 `Disable notifications`。其他插件选项会保留。插件配置 `data.json` 必须保持设备本地化。运行后重新加载 Obsidian。

### 6. 自动验证

无侵入检查：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 -VaultPath "C:\笔记库路径"
```

检查结果应同时包含 `watcherTasks`、`watchdogTasks` 和 `watcherProcesses`。`watcherProcesses` 至少应有一个进程；守护任务可为 `Ready`。`visibilityVerified`、登录触发器、每分钟守护触发器、电池策略、隐藏启动方式和失败重启策略必须全部通过；GitHub 查询失败或返回 `unknown` 时不得宣布成功。

安装或修复监听器后运行恢复探针：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 `
  -VaultPath "C:\笔记库路径" -RunWatcherRecoveryProbe
```

该探针会终止一次真实监听进程，立即调用守护任务，并确认出现不同 PID 的替代监听进程。它不会创建、修改或推送笔记。

用户授权临时测试文件后：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 `
  -VaultPath "C:\笔记库路径" -RunEventProbe -RunRemotePullProbe
```

`RunRemotePullProbe` 会从临时 clone 向 GitHub 推送一个测试文件，等待 Windows 后台任务自动拉取到本地，然后从本地仓库提交删除测试文件并推回 GitHub。这样验证 GitHub -> PC 的自动拉取，同时避免远端删除与 Obsidian 本地配置自动提交相撞。

### 7. 请求用户测试

自动验证通过后，请用户执行：

1. 在 Windows Obsidian 新建 `Windows同步测试`。
2. 输入一行可识别内容并停止编辑 15 至 30 秒。
3. 打开 GitHub 私有仓库，确认同名 Markdown 文件和内容存在。
4. 回复“Windows 端成功”或提供错误截图。

用户确认后再显示手机设置。

---

# English Version

## 0. Automatic PC Installation and User-Facing Output Format

PC setup is automatic by default. When the user asks to configure Obsidian and GitHub, run `scripts/setup-windows.ps1` or `npx obsidian-through` directly. Do not ask whether to install Git/GitHub CLI first; if missing, install them through `ensure-git-tools.ps1 -InstallIfMissing`. Do not ask for a repository name first; after GitHub login, default to the authenticated account's `obsidian-vault` private repository unless the vault already has an origin or the user explicitly provides an existing repository URL.

When speaking to the user, do not only say "copy this URL" or "run this command." Every PC-side value the user must verify, copy, paste, open, or search must appear in its own fenced code block, with natural-language instructions explaining where to use it.

In the main workflow, only the GitHub login page should be rendered as a Markdown clickable link. Repository pages, clone URLs, vault paths, and command names should remain in code blocks for copying and verification.

Every value in a copy block must come from the current run: `setup-windows.ps1`, `publish-vault.ps1`, `verify-sync.ps1`, `gh api user`, `git remote get-url origin`, or an equivalent check. Do not present example placeholders as final instructions.

For GitHub login, output:

```text
I will open the official GitHub authorization page. Sign in only in the browser. Do not send your password, verification code, or token in chat.
```

[https://github.com/login/device](https://github.com/login/device)

If GitHub CLI shows a one-time code, tell the user to enter the code from the PowerShell window into the GitHub webpage. Do not ask them to send the code in chat.

After login, show the real account:

```text
GitHub login
```

```text
<real login from gh api user>
```

When confirming the PC vault, show the real path and explain that it is the Obsidian vault, not the Obsidian application install folder:

```text
Desktop Obsidian vault path
```

```text
<real absolute vault path>
```

When confirming the repository, show the real repository URL and visibility:

```text
GitHub private repository
```

```text
https://github.com/<real owner>/<real repository>
```

```text
Git remote clone URL
```

```text
https://github.com/<real owner>/<real repository>.git
```

Before upload, explain that confirmation connects the shown vault to the shown private repository. If both local and remote sides contain content, the workflow will merge safely, preserve conflicts, and never force-push.

After PC setup, the Windows Obsidian test must include exact UI actions:

1. Open Windows Obsidian.
2. Create a test note from the left file list.
3. Provide a copyable filename:

```text
Windows Sync Test
```

4. Provide copyable body text:

```text
This is a Windows to GitHub sync test.
```

5. Stop editing and wait 15 to 30 seconds.
6. Open and refresh the actual GitHub repository page:

```text
https://github.com/<real owner>/<real repository>
```

7. Ask the user to confirm whether the test note appears. Only after user confirmation may you claim PC success and move to mobile setup.

## Automatic login and desktop configuration

### 1. Check and automatically install required software

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ensure-git-tools.ps1 -InstallIfMissing
```

The script checks Git and GitHub CLI. If either is missing, install `Git.Git` and/or `GitHub.cli` directly through Windows Package Manager, then recheck versions. Do not dump full tool paths or internal JSON to the user. Say only:

```text
Checking and installing the sync environment.
```

After installation, say:

```text
Git and GitHub CLI are ready.
```

If `winget` is unavailable or installation fails, stop and ask the user to install official Git and GitHub CLI manually. Do not claim success.

The low-level command is:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ensure-git-tools.ps1 -InstallIfMissing
```

### 2. Launch GitHub login

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/github-web-login.ps1
```

The script checks the current session first. If unauthenticated, `gh auth login --web` opens GitHub authorization in the default browser. After the user finishes, the script revalidates the account and configures Git credentials.

Never enter the user's GitHub password, request verification codes, or print the GitHub CLI token.

If the network needs a local proxy, let the user pass it explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/github-web-login.ps1 `
  -Proxy "http://127.0.0.1:7890"
```

The login script opens the GitHub device authorization page directly. If GitHub CLI shows a one-time code, ask the user to enter the code from the PowerShell window into the browser page. Do not ask the user to send the code, password, or token in chat.

### 3. Locate the Obsidian vault

Prefer the vault path recorded by Obsidian. Confirm the directory contains notes and `.obsidian`; do not confuse it with the Obsidian installation directory.

Before acting, show:

- absolute local vault path;
- authenticated GitHub account;
- repository name;
- required `PRIVATE` visibility;
- files included in the first push.

### 4. Build the private repository

Do not ask for the repository name by default. After GitHub login, if the vault already has a GitHub origin, reuse that origin. Otherwise create or connect the default private repository under the authenticated GitHub account:

```text
https://github.com/<real login>/obsidian-vault.git
```

Use a user-provided repository URL only when the user explicitly provides one.

After the user authorizes uploading the exact local path to the confirmed private repository, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish-vault.ps1 `
  -VaultPath "C:\path\to\vault" `
  -RepositoryUrl "https://github.com/<owner>/<repository>.git" `
  -OpenRepositoryPage `
  -ConfirmUpload
```

Prefer a complete GitHub repository URL instead of asking the user to split owner and repository names repeatedly. The script parses owner and repository from the URL and opens the GitHub repository page or new repository page so the user can confirm the intended private repository. If the user does not already have a repository, use `-RepositoryName "<repository-name>"` to create one under the authenticated GitHub account.

When connecting local notes to an existing repository, the script creates a `backup-before-remote-merge-...` branch before merging. If the histories diverge and Git can merge cleanly, it commits the merge and continues to push. If conflicts occur, the script stops and reports the backup branch; resolve conflicts manually, commit, and push. Force push remains disabled.

The script:

1. Verifies the authenticated GitHub account.
2. blocks files larger than 95 MB before push;
3. inspects existing Git state and remotes;
4. initializes branch `main` only when needed;
5. appends the required `.gitignore` entries;
6. removes Git plugin `data.json` from version control while preserving it locally;
7. configures a repository-local author with a GitHub noreply email;
8. creates a `PRIVATE` repository or safely connects the matching private repository;
9. refuses a different existing remote;
10. safely merges matching existing remote history when needed;
11. commits and performs the first push;
12. verifies visibility and matching hashes.

If the remote has unrelated history and Git cannot merge it cleanly, stop and reconcile conflicts. Never force-overwrite it.

### 5. Install event synchronization

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-windows-event-sync.ps1 `
  -VaultPath "C:\path\to\vault" `
  -DebounceSeconds 15 `
  -PullIntervalSeconds 30
```

The task listens for create, modify, rename, and delete events. Fifteen quiet seconds trigger commit, rebase, and push. With no local edits, it does not commit or push; a hidden clean-worktree pull checks for phone updates every 30 seconds.

The installer enables Git long path support with `core.longpaths=true` for both the current vault and the user's global Git config. This lets long clipped note titles be committed without shortening the filename.

Recommended speed settings:

- Normal responsive desktop sync: `-DebounceSeconds 15 -PullIntervalSeconds 30`
- Conservative sync for very large vaults or slow networks: `-DebounceSeconds 60 -PullIntervalSeconds 60`
- Aggressive sync only by explicit user request: `-DebounceSeconds 10 -PullIntervalSeconds 20`

Avoid debounce values below 10 seconds by default. They create many tiny commits while the user is still editing and increase the chance of conflicts when several devices are active.

The installer also creates an `Obsidian Git Sync Watchdog ...` scheduled task. Both the main sync task and watchdog call `run-hidden.vbs` through `wscript.exe`, so they do not flash CLI windows at logon or during periodic checks. Both tasks start at user logon, run on battery power, and are not stopped by a battery transition. With the hidden launcher, the main sync task may appear as `Running` or `Ready`; use `watcherProcesses` to determine whether the real watcher is alive. Every minute, the watchdog matches only a process launched with `-File watch-vault.ps1`, so its own command line cannot create a false positive. If the watcher stops after sleep, power changes, battery policy, or an abnormal exit, the watchdog clears stale state and starts it again.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/configure-windows-obsidian-git.ps1 `
  -VaultPath "C:\path\to\vault"
```

Default desktop mode is `EventWatcher`. In this mode, the Windows watcher owns automatic sync and the Obsidian Git plugin is kept for startup pull, history, and manual commands. The script sets:

- `Split timers for automatic commit and sync` off
- `Auto commit-and-sync interval (minutes)` to `0`
- `Auto commit-and-sync after stopping file edits` off
- `Pull on startup` on
- `Auto pull interval` to `0`
- ordinary notifications off, while keeping error notices on

Do not also enable the plugin's 1-minute automatic commit/pull while the Windows watcher is installed. Two automatic sync engines can race for the Git index, create duplicate commits, surface repeated notices, or increase rename/delete conflicts across multiple PCs.

Use plugin timer mode only when the Windows watcher is not installed or the user explicitly wants Obsidian Git itself to own desktop automation:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/configure-windows-obsidian-git.ps1 `
  -VaultPath "C:\path\to\vault" `
  -Mode PluginTimer
```

Plugin timer mode sets `Auto commit-and-sync interval (minutes) = 1`, `Auto commit-and-sync after stopping file edits` on, `Split timers for automatic commit and sync` off, `Pull on startup` on, and `Auto pull interval = 1`.

Keep plugin `data.json` device-local and reload Obsidian after either mode.

### 6. Automated verification

Noninvasive check:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 -VaultPath "C:\path\to\vault"
```

The result should include `watcherTasks`, `watchdogTasks`, and `watcherProcesses`. `watcherProcesses` should contain at least one process, and the watchdog may be `Ready`. `visibilityVerified`, logon triggers, the one-minute watchdog trigger, battery policy, hidden launch actions, and restart-on-failure policies must all pass. A failed GitHub query or `unknown` visibility must fail verification.

After installing or repairing the watcher, run the recovery probe:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 `
  -VaultPath "C:\path\to\vault" -RunWatcherRecoveryProbe
```

The probe terminates one real watcher process, starts the watchdog immediately, and confirms that a replacement watcher appears with a different PID. It does not create, modify, or push notes.

After authorization for temporary test files:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 `
  -VaultPath "C:\path\to\vault" -RunEventProbe -RunRemotePullProbe
```

`RunRemotePullProbe` pushes a test file to GitHub from a temporary clone, waits for the Windows background task to pull it locally, then removes the test file from the local vault and pushes that cleanup. This verifies GitHub -> PC automatic pull while avoiding a remote deletion racing against Obsidian's local configuration writes.

### 7. Ask the user to test

After automated verification, ask the user to:

1. Create `Windows Sync Test` in Windows Obsidian.
2. Enter recognizable content and stop editing for 15 to 30 seconds.
3. Open the private GitHub repository and confirm the matching Markdown file and content.
4. Reply that Windows succeeded or provide an error screenshot.

Show mobile setup only after confirmation.
