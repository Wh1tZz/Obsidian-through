# 中文版

## 自动登录与桌面配置

### 1. 检查必需软件

先运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ensure-git-tools.ps1
```

脚本会输出 Git、GitHub CLI、版本和路径。若缺失，不得静默安装。先向用户说明将通过 Windows Package Manager 安装 `Git.Git` 和/或 `GitHub.cli`，获得确认后运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ensure-git-tools.ps1 -InstallIfMissing
```

安装结束后必须重新运行检查，确认两个工具均可执行。若 `winget` 不存在或安装失败，停止并提供官方安装方式，不要伪造成功状态。

### 2. 弹出 GitHub 登录界面

运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/github-web-login.ps1
```

脚本先检查现有登录。未登录时调用 `gh auth login --web`，默认浏览器会打开 GitHub 授权页面。用户在浏览器完成登录后，脚本再次检查账号并配置 Git 凭据。

不要代替用户输入 GitHub 密码，不要索取验证码，不要输出 GitHub CLI Token。

### 3. 定位 Obsidian 笔记库

优先读取 Obsidian 应用配置中的 vault 路径。确认目标目录包含笔记和 `.obsidian`，不要把 Obsidian 软件安装目录当作笔记库。

操作前向用户显示：

- 本地笔记库绝对路径；
- GitHub 登录账号；
- 计划创建或连接的仓库名；
- 仓库可见性必须为 `PRIVATE`；
- 首次推送会上传哪些文件。

### 4. 建立私有仓库

获得用户对明确本地路径和目标私有仓库的上传授权后运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish-vault.ps1 `
  -VaultPath "C:\笔记库路径" `
  -RepositoryName "obsidian-vault" `
  -ConfirmUpload
```

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
  -DebounceSeconds 60 `
  -PullIntervalSeconds 60
```

该任务监听创建、修改、重命名和删除。停止编辑 60 秒后自动提交、变基远端更新并推送。没有本地编辑时不会提交或推送；工作区干净时每 60 秒通过隐藏任务静默拉取手机更新。

安装脚本还会创建 `Obsidian Git Sync Watchdog ...` 计划任务。主同步任务和守护任务都通过 `wscript.exe` 调用 `run-hidden.vbs` 隐藏启动 PowerShell，避免开机登录或周期检查时弹出 CLI 窗口。使用隐藏启动器后，主同步任务可能显示 `Running` 或 `Ready`；以 `watcherProcesses` 判断真实监听是否存活。守护任务每分钟短暂运行一次，检查真实的 `watch-vault.ps1` 后台进程，若主监听因睡眠、断电、电池策略或异常退出而停止，守护任务会重新启动它。

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

检查结果应同时包含 `watcherTasks`、`watchdogTasks` 和 `watcherProcesses`。`watcherProcesses` 至少应有一个进程；守护任务可为 `Ready`。

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

## Automatic login and desktop configuration

### 1. Check required software

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ensure-git-tools.ps1
```

The script reports Git, GitHub CLI, versions, and paths. Never install silently. Explain that Windows Package Manager will install `Git.Git` and/or `GitHub.cli`, obtain approval, then run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ensure-git-tools.ps1 -InstallIfMissing
```

Run the check again after installation. If `winget` is unavailable or installation fails, stop and provide official installation guidance instead of claiming success.

### 2. Launch GitHub login

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/github-web-login.ps1
```

The script checks the current session first. If unauthenticated, `gh auth login --web` opens GitHub authorization in the default browser. After the user finishes, the script revalidates the account and configures Git credentials.

Never enter the user's GitHub password, request verification codes, or print the GitHub CLI token.

### 3. Locate the Obsidian vault

Prefer the vault path recorded by Obsidian. Confirm the directory contains notes and `.obsidian`; do not confuse it with the Obsidian installation directory.

Before acting, show:

- absolute local vault path;
- authenticated GitHub account;
- repository name;
- required `PRIVATE` visibility;
- files included in the first push.

### 4. Build the private repository

After the user authorizes uploading the exact local path to the named private repository, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish-vault.ps1 `
  -VaultPath "C:\path\to\vault" `
  -RepositoryName "obsidian-vault" `
  -ConfirmUpload
```

The script:

1. Verifies the authenticated GitHub account.
2. blocks files larger than 95 MB before push;
3. inspects existing Git state and remotes;
4. initializes branch `main` only when needed;
5. appends the required `.gitignore` entries;
6. removes Git plugin `data.json` from version control while preserving it locally;
7. configures a repository-local author with a GitHub noreply email;
8. creates a `PRIVATE` repository or safely connects the matching private repository;
9. refuses a different existing remote or unrelated history;
10. commits and performs the first push;
11. verifies visibility and matching hashes.

If the remote has unrelated history, stop and reconcile it. Never force-overwrite it.

### 5. Install event synchronization

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-windows-event-sync.ps1 `
  -VaultPath "C:\path\to\vault" `
  -DebounceSeconds 60 `
  -PullIntervalSeconds 60
```

The task listens for create, modify, rename, and delete events. Sixty quiet seconds trigger commit, rebase, and push. With no local edits, it does not commit or push; a hidden clean-worktree pull checks for phone updates every 60 seconds.

The installer also creates an `Obsidian Git Sync Watchdog ...` scheduled task. Both the main sync task and watchdog call `run-hidden.vbs` through `wscript.exe`, so they do not flash CLI windows at logon or during periodic checks. With the hidden launcher, the main sync task may appear as `Running` or `Ready`; use `watcherProcesses` to determine whether the real watcher is alive. The watchdog runs briefly every minute and checks the real `watch-vault.ps1` background process. If the watcher stops after sleep, power changes, battery policy, or an abnormal exit, the watchdog starts it again.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/configure-windows-obsidian-git.ps1 `
  -VaultPath "C:\path\to\vault"
```

It sets `Auto commit-and-sync interval = 0`, `Auto pull interval = 0`, Pull on startup on, sync-after-edit off, and Disable notifications on while preserving unrelated plugin options. Keep plugin `data.json` device-local and reload Obsidian afterward.

### 6. Automated verification

Noninvasive check:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-sync.ps1 -VaultPath "C:\path\to\vault"
```

The result should include `watcherTasks`, `watchdogTasks`, and `watcherProcesses`. `watcherProcesses` should contain at least one process, and the watchdog may be `Ready`.

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
