# 中文版

## 认证失败

- GitHub 账号密码不能用于 HTTPS Git，请使用 Personal Access Token。
- Token 创建后无法再次查看；请创建替代 Token 并撤销丢失的 Token。
- Fine-grained Token 仅授权笔记仓库和最低必要权限。
- 禁止将 Token 放入 URL、提交文件、截图、日志或聊天。

## 手机显示 Request failed

先把它当作网络请求失败，而不是立刻重建仓库或强制推送：

1. 保持 Obsidian 在前台，用手机浏览器打开 `https://github.com` 和目标私有仓库。
2. 若浏览器也无法访问，切换 Wi-Fi/蜂窝网络；在 GitHub 受限或链路不稳定的网络中，开启用户已有且合规的 VPN 后重试。
3. 浏览器可访问但 Obsidian 仍失败时，检查远端必须为 HTTPS、Username 正确、Token 未过期，并具有目标仓库 `Contents: Read and write` 权限。
4. 完全关闭并重新打开 Obsidian，先运行 `Git: Pull`，成功后再运行 `Git: Commit-and-sync`。
5. 仍失败时保留完整错误和 Obsidian Git 控制台日志，但遮盖 Token；不要连续 Push、Force Push 或重新克隆到非空目录。

## 缺少作者名或邮箱

在 Obsidian Git 的 `Authentication/Commit Author` 中填写作者名和邮箱，优先使用 GitHub 邮箱设置中显示的 noreply 地址。

## iPhone 设置恢复原值

检查 `.obsidian/plugins/obsidian-git/data.json` 是否被跟踪。将其从索引移除并忽略，让每台设备保留独立时间与认证设置。iPhone 拉取该改动后，需要重新填写一次手机设置。

## 修改却出现新文件

检查提交状态：

- `A path.md`：新增路径。
- `M path.md`：已有笔记被修改。
- `R old.md new.md`：笔记被重命名。
- 删除加新增也可能表示重命名。

编辑前先拉取，从文件列表打开已有笔记并修改正文。点击不存在的内部链接、使用“新建笔记”或更改标题都会创建不同路径。

## Pull、Commit 和自动同步的关系

- `Git: Pull` 只把 GitHub 上的最新版本拉到本机，不会上传本机修改。
- `Git: Commit-and-sync` 才会提交本机修改、拉取远端更新并推送到 GitHub。
- `Auto commit-and-sync interval = 1` 表示停止编辑后约 1 分钟触发提交同步；用户想立即上传时，运行 `Git: Commit-and-sync`。
- 用户 Pull 后继续修改笔记，后续提交的是修改后的最新本地稿，不是 Pull 那一刻的旧稿。
- 编辑前先 Pull 的意义是拿到最新底稿，减少旧版本编辑导致的冲突或推送拒绝。

## 误删笔记恢复

先阻止扩大损失：要求用户暂停所有设备的 Push、Commit-and-sync 和强制同步。不要使用 `git reset --hard`、不要 force push、不要恢复整个 vault 覆盖当前内容。

在 Windows 或任意完整 Git 工作副本中先列出最近删除记录：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/restore-deleted-note.ps1 `
  -VaultPath "C:\path\to\vault" -ListDeleted
```

向用户显示删除文件路径、删除时间和提交信息，并让用户确认要恢复的具体文件。确认后只恢复那一篇：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/restore-deleted-note.ps1 `
  -VaultPath "C:\path\to\vault" `
  -NotePath "folder/deleted-note.md" `
  -Commit -Push
```

脚本会从删除提交的父提交中恢复文件，重新提交为 `Restore accidentally deleted note`，并在请求 `-Push` 时推送。恢复后让其他设备运行 `Git: Pull` 验证。若工作区不干净，先处理当前改动，不要覆盖用户笔记。

## 四端或多端同步策略

四端可以使用同一个私有仓库，但不要让所有设备都成为自动写入主力。推荐角色：

```text
GitHub = 中央仓库
Windows PC = 主同步端，事件监听自动提交，静默定时 Pull
主手机 = 移动写作端，可开启 1 分钟 Auto commit-and-sync
第二手机/第四端 = 查看或轻量编辑端，默认手动 Pull 与 Commit-and-sync
```

新增设备时逐台验收：先 Windows 与 GitHub，再主手机，再第二手机，再第四端。每台设备必须先 Pull、再编辑、再 Commit-and-sync。禁止多端同时编辑同一篇笔记；建议移动端新内容先写入 `手机收件箱/`，回到电脑后再整理。若第二手机也要频繁写作，不要同时开启多个手机的自动提交，优先使用手动命令。

## Windows 事件同步漏掉改动

- 确认计划任务存在。
- 确认 `Obsidian Git Event Sync ...` 为 `Running`，且 `verify-sync.ps1` 输出的 `watcherProcesses` 至少包含一个后台监听进程；若没有，确认 `Obsidian Git Sync Watchdog ...` 存在并会重新拉起它。
- 确认日志包含 `watcher started`。
- 使用 Skill 附带的事件队列监听器；阻塞式监听器可能在 Git 推送时漏掉事件。
- 忽略 `.git` 事件，避免循环触发。
- 仅在获得授权后运行 `verify-sync.ps1 -RunEventProbe`。

## Windows 主同步任务停止在 Ready

重新运行 `scripts/install-windows-event-sync.ps1`。安装器会取消电池停止限制，并注册每分钟运行一次的 watchdog。主同步任务应恢复为 `Running`；验证时同时检查 `watcherProcesses` 是否存在后台监听进程。watchdog 日志出现 `started target task` 表示它已经自动恢复过监听进程。

## Windows 周期性弹出 CLI 窗口

检查 `Obsidian Git Event Sync ...` 和 `Obsidian Git Sync Watchdog ...` 计划任务的 `Execute` 字段。新版安装器应让两个任务都使用 `wscript.exe`，避免开机登录和每分钟检查时弹窗。若任意一个仍显示 `powershell.exe`，重新运行 `scripts/install-windows-event-sync.ps1`。

## Windows 右上角持续出现 Pull 或 Push 弹窗

1. 检查 `.obsidian/plugins/obsidian-git/data.json` 是否被 Git 跟踪；若被跟踪，手机设置可能覆盖电脑设置。
2. 在 `.gitignore` 中忽略该文件，并使用 `git rm --cached` 停止跟踪但保留本地文件。
3. Windows 插件关闭自动提交、周期自动拉取和停止编辑后同步，开启禁用普通通知；`Pull on startup` 可以保持开启，只在启动时拉取一次。
4. 事件监听器可使用 `PullIntervalSeconds 60` 静默接收手机更新；它不会产生 Obsidian 弹窗。若仍弹窗，问题来自 Obsidian Git 插件设置。
5. 重新加载 Obsidian，静置超过 1 分钟，确认右上角无通知；日志中允许出现隐藏任务的 fetch/fast-forward。

## 本地有提交但 GitHub 未更新

比较本地与远端哈希，检查日志中的拉取或推送错误，确认 Git Credential Manager 能够无交互认证，并确认分支跟踪正确远端。

## 合并冲突

停止自动写入程序，保留两个版本，解决冲突 Markdown 文件，暂存并提交，然后按仓库策略拉取和推送。没有明确授权不得丢弃用户笔记。

## iOS 限制

移动端 Obsidian Git 使用 JavaScript Git 实现。大型仓库可能缓慢或崩溃，此模式不支持 SSH，且 iOS 可能暂停后台任务。优先使用 HTTPS、小型笔记库、前台同步，并在离开前手动运行 `Commit-and-sync`。

---

# English Version

## Authentication fails

- GitHub account passwords do not work for HTTPS Git; use a personal access token.
- A token cannot be revealed again after creation. Create a replacement and revoke the lost token.
- Restrict a fine-grained token to the vault repository and minimum permissions.
- Never place a token in URLs, committed files, screenshots, logs, or chat.

## Mobile shows Request failed

Treat this first as a network request failure. Do not immediately rebuild the repository or force-push:

1. Keep Obsidian in the foreground and open `https://github.com` plus the target private repository in the phone browser.
2. If the browser also fails, switch between Wi-Fi and cellular data. On a network where GitHub is restricted or unreliable, enable the user's existing compliant VPN and retry.
3. If the browser works but Obsidian still fails, confirm the remote uses HTTPS, the username is correct, the token is unexpired, and it grants `Contents: Read and write` for the target repository.
4. Fully close and reopen Obsidian. Run `Git: Pull` first, then `Git: Commit-and-sync` only after Pull succeeds.
5. If it still fails, preserve the complete error and Obsidian Git console log with the token redacted. Do not repeatedly push, force-push, or clone over a nonempty directory.

## Author name or email is missing

Set author name and email in Obsidian Git `Authentication/Commit Author`. Prefer the GitHub noreply address shown in GitHub email settings.

## iPhone setting reverts

Check whether `.obsidian/plugins/obsidian-git/data.json` is tracked. Remove it from the index and ignore it so each device keeps independent timing and authentication settings. After iPhone pulls the removal, enter mobile settings once again.

## New file instead of modification

Inspect commit status:

- `A path.md`: new path.
- `M path.md`: existing note modified.
- `R old.md new.md`: note renamed.
- Delete plus add may also represent a rename.

Pull before editing, open the existing note from the file list, and edit its body. Tapping a nonexistent internal link, using New Note, or changing the title creates a different path.

## Pull, commit, and automatic sync

- `Git: Pull` only downloads the newest version from GitHub to the local device. It does not upload local edits.
- `Git: Commit-and-sync` commits local edits, pulls remote changes, and pushes to GitHub.
- `Auto commit-and-sync interval = 1` means sync runs about one minute after editing stops. To upload immediately, run `Git: Commit-and-sync`.
- If the user pulls and then edits a note, the later sync uploads the edited local draft, not the draft as it existed at pull time.
- Pull before editing gives the user the newest base draft and reduces conflicts or push rejections from stale local copies.

## Recover an accidentally deleted note

First limit the damage: ask the user to pause Push, Commit-and-sync, and force synchronization on every device. Do not use `git reset --hard`, do not force push, and do not restore the whole vault over current content.

On Windows or any complete Git worktree, list recent deletions first:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/restore-deleted-note.ps1 `
  -VaultPath "C:\path\to\vault" -ListDeleted
```

Show the deleted paths, deletion times, and commit subjects to the user, then ask them to confirm exactly which file to restore. After confirmation, restore only that note:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/restore-deleted-note.ps1 `
  -VaultPath "C:\path\to\vault" `
  -NotePath "folder/deleted-note.md" `
  -Commit -Push
```

The script restores the file from the parent of the deletion commit, commits it as `Restore accidentally deleted note`, and pushes when `-Push` is requested. After recovery, ask other devices to run `Git: Pull`. If the worktree is dirty, resolve or preserve current changes first; never overwrite user notes.

## Four-endpoint or multi-device sync strategy

Four devices can share one private repository, but not every device should be an automatic writing endpoint. Recommended roles:

```text
GitHub = central repository
Windows PC = primary sync endpoint with event commits and silent periodic Pull
Main phone = mobile writing endpoint with one-minute Auto commit-and-sync
Second phone / fourth endpoint = reading or light-editing endpoint using manual Pull and Commit-and-sync by default
```

Validate devices one at a time: Windows with GitHub, then the main phone, then the second phone, then the fourth endpoint. Every device should Pull before editing and Commit-and-sync after editing. Do not edit the same note on multiple devices at the same time. Prefer a `Mobile Inbox/` or `手机收件箱/` folder for mobile captures, then organize notes on desktop. If a second phone also writes frequently, avoid enabling automatic commit on multiple phones; prefer manual commands.

## Windows event sync misses changes

- Confirm the scheduled task exists.
- Confirm `Obsidian Git Event Sync ...` is `Running`, and confirm `watcherProcesses` from `verify-sync.ps1` contains at least one background watcher process. If not, confirm the `Obsidian Git Sync Watchdog ...` task exists and restarts it.
- Confirm the log reports `watcher started`.
- Use the bundled event-queue watcher; blocking watchers can miss events during Git push.
- Ignore `.git` events to prevent loops.
- Run `verify-sync.ps1 -RunEventProbe` only after authorization.

## Windows main sync task is stuck in Ready

Run `scripts/install-windows-event-sync.ps1` again. The installer removes battery-stop restrictions and registers a watchdog that runs every minute. The main sync task should return to `Running`; during verification, also confirm `watcherProcesses` contains a background watcher process. `started target task` in the watchdog log means it has automatically recovered the watcher.

## Windows periodically flashes a CLI window

Inspect the `Execute` field for both `Obsidian Git Event Sync ...` and `Obsidian Git Sync Watchdog ...`. The current installer should run both tasks through `wscript.exe` to avoid visible windows at logon and during periodic checks. If either still shows `powershell.exe`, rerun `scripts/install-windows-event-sync.ps1`.

## Windows repeatedly shows Pull or Push notices

1. Check whether `.obsidian/plugins/obsidian-git/data.json` is tracked; mobile settings may be overwriting desktop settings.
2. Ignore it and use `git rm --cached` to stop tracking while preserving the local file.
3. Disable automatic commit, periodic automatic pull, and sync-after-edit in the Windows plugin; enable Disable notifications. `Pull on startup` may remain enabled because it runs once at launch.
4. The event watcher may use `PullIntervalSeconds 60` to receive phone updates silently; it does not create Obsidian notices. Continued popups come from Obsidian Git plugin settings.
5. Reload Obsidian and wait longer than one minute. Confirm no upper-right notice; hidden fetch/fast-forward entries in the watcher log are expected.

## Local commit exists but GitHub is unchanged

Compare local and remote hashes. Check logs for pull or push errors. Confirm Git Credential Manager can authenticate noninteractively and the branch tracks the intended remote.

## Filename too long on Windows

If the watcher log says `Filename too long` while adding a long clipping title, do not shorten or rename the note first. Enable Git long path support and retry:

```powershell
git config --global core.longpaths true
git -C "C:\path\to\vault" config core.longpaths true
git -C "C:\path\to\vault" add --all
```

The bundled publish and Windows event-sync scripts set `core.longpaths=true` automatically. This preserves long note filenames when GitHub and the filesystem can store them. This is different from Windows-forbidden characters such as `< > : " / \ | ? *`; those characters must still be avoided or renamed because Windows cannot create those paths.

## Merge conflict

Stop automatic writers. Preserve both versions, resolve conflicted Markdown files, stage, commit, pull with the repository's merge policy, and push. Never discard a user's note without explicit approval.

## iOS limitations

Mobile Obsidian Git uses a JavaScript Git implementation. Large repositories may be slow or crash, SSH is unsupported in this mode, and iOS may suspend background work. Prefer HTTPS, small vaults, foreground synchronization, and manual `Commit-and-sync` before leaving.
