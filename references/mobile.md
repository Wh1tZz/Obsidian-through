# 中文版

## 1. 必须先输出的用户专属信息

运行 `scripts/mobile-setup-info.ps1` 后，将结果整理成以下可复制清单。必须把占位符替换为真实值：

```text
GitHub 账号：<login>
提交作者名：<author name>
提交邮箱：<id+login@users.noreply.github.com>
私有仓库：https://github.com/<owner>/<repository>
克隆地址：https://github.com/<owner>/<repository>.git
创建 Token：https://github.com/settings/personal-access-tokens/new
检查邮箱：https://github.com/settings/emails
Obsidian Git 插件：https://obsidian.md/plugins?id=obsidian-git
```

这些值必须来自当前用户的 GitHub 登录状态、当前 vault 的远端仓库和 GitHub API。不要在 skill 中硬编码任何示例账号、固定邮箱、固定仓库名或作者名。若无法读取真实值，先停止并修复登录或仓库连接，不要让用户照抄别人的配置。

下载 Obsidian：

- iPhone/iPad：https://apps.apple.com/app/obsidian-connected-notes/id1557175442
- Android：https://play.google.com/store/apps/details?id=md.obsidian
- Obsidian 官方下载：https://obsidian.md/download

不得输出 Token 值，不得要求用户将 Token 发到聊天。Token 创建后只能完整显示一次，应保存到系统密码管理器。

## 2. 同步架构与核心逻辑

向用户解释这套同步不是 Obsidian 官方云同步，而是 Git 工作流：

```text
Windows Obsidian vault
        ↕
GitHub private repository
        ↕
iPhone / Android Obsidian vault
```

每台设备本地都有一份完整笔记库；GitHub 私有仓库是中转中心。Obsidian Git 插件在手机端负责三类动作：

```text
Pull
从 GitHub 下载别人或其他设备刚推送的最新笔记。

Commit
把本机新增、删除、修改记录成一个版本。

Push
把本机版本上传到 GitHub。
```

`Git: Commit-and-sync` 通常组合执行 `commit -> pull -> push`。编辑前仍建议先运行 `Git: Pull`，因为这样用户是在最新稿上继续写，而不是在旧稿上写完后再撞到冲突。停止编辑后的 1 分钟自动同步，触发的是 `Commit-and-sync`，不是单纯 Pull。

向用户说明四个注意点：

1. 增、删、改会产生可提交变更；搜索、阅读、打开页面不会提交。
2. 删除也是同步内容，手机删除后推送到 GitHub，电脑也会删除；误删要从 Git 历史恢复。
3. 多端不要同时编辑同一篇笔记；四端同步时只让 Windows 和一台主手机自动写入，其他设备默认手动同步。
4. `.obsidian/plugins/obsidian-git/data.json` 必须保持设备本地化，否则一台设备的 Git 设置会覆盖另一台。

## 3. 创建 GitHub 登录密钥 Key / Token

在手机浏览器完成：

1. 打开 GitHub Token 页面：<https://github.com/settings/personal-access-tokens/new>。
2. 如果出现登录页面，登录拥有私有仓库访问权的 GitHub 账号。
3. 页面标题通常包含 `New fine-grained personal access token`。若界面改版，从头像菜单进入 `Settings`，搜索 `Personal access tokens`，选择 `Fine-grained tokens`，再选择生成新 Token。
4. `Token name`：填写 `Obsidian iPhone` 或 `Obsidian Android`。
5. `Expiration`：选择有限期限；过期后重新创建。
6. `Resource owner`：选择私有仓库所属账号。
7. `Repository access`：选择 `Only select repositories`。
8. 在仓库选择器中只选择目标 Obsidian 私有仓库。
9. 展开 `Repository permissions`：
   - `Metadata`：`Read-only`；
   - `Contents`：`Read and write`；
   - `Commit statuses`：插件要求时选择 `Read and write`。
10. 检查没有授权其他仓库或多余权限。
11. 用户本人点击 `Generate token`。
12. 立即复制 Token 并保存到 iCloud 钥匙串、Apple 密码或 Android 密码管理器。

这里的 Token 就是用户在手机端说的 “key”。GitHub 无法找回已经关闭页面的 Token 明文。遗失后应创建新 Token，并在 <https://github.com/settings/personal-access-tokens> 撤销旧 Token。

## 4. iPhone 下载 Obsidian 和 Git 插件

### 安装 Obsidian

1. 打开 App Store 链接：<https://apps.apple.com/app/obsidian-connected-notes/id1557175442>。
2. 安装并打开 Obsidian。
3. 创建一个临时空 vault 用于安装插件。
4. 不要开启 `Store in iCloud`。Git 与 iCloud 同时写同一 vault 容易冲突。

### 下载并启用 Obsidian Git

1. 打开插件链接：<https://obsidian.md/plugins?id=obsidian-git>。若系统允许，选择在 Obsidian 中打开。
2. 若链接无法直接跳转，在 Obsidian 打开 `Settings`。
3. 使用设置搜索查找 `Community plugins` 或“第三方插件”。
4. 关闭 `Restricted mode` 或选择允许第三方插件。
5. 选择 `Browse`，搜索插件名 `Git`。
6. 确认插件作者/项目为 Obsidian Git，再选择 `Install`。
7. 安装后选择 `Enable`。仅安装但未启用不会出现 Git 命令。
8. 回到设置，在 `Community plugins` 下找到 `Git` 并打开插件选项。

未来 Obsidian UI 即使改变，只要能在设置搜索中找到 `Community plugins`，并在插件市场搜索精确名称 `Git`，流程仍然适用。

## 5. iPhone 填写克隆仓库所需的昵称和 Key

克隆私有仓库前，先在 Git 插件设置中找到认证区域。不同版本可能显示为 `Authentication`、`Remote`、`Username` 或 `Password/Token`。如果用户说“昵称和 key”，按下面解释：

```text
昵称 / Username = GitHub 登录名
Key / Password / Token = GitHub Fine-grained Token
```

1. `Username`：填写清单中的 GitHub 账号。
2. `Password/Token`：粘贴 Fine-grained Token，不是 GitHub 登录密码。
3. 不要把 Token 写进仓库 URL、笔记或截图。

若当前插件版本在克隆命令中弹出 Username/Password 输入框，也可以在弹窗中填写同样的 GitHub username 和 Token。不要使用 GitHub 登录密码。

## 6. iPhone 在 Obsidian 命令面板克隆私有仓库

1. 打开 Obsidian 命令面板。可使用界面中的命令面板按钮；若位置改变，在应用搜索中查找 `Command palette`。
2. 搜索并运行稳定命令名：`Git: Clone existing remote repo`。
3. 粘贴清单中的 HTTPS `.git` 克隆地址，不要使用浏览器地址或 SSH 地址。
4. 若提示 `Branch`，填写 `main`。
5. 若提示 `Vault Root` 或文件夹名，填写一个新的空文件夹名，例如仓库名。这个值表示手机 Obsidian 中克隆后的 vault 文件夹，不是 GitHub URL。
6. 若提示 `Specify depth of clone. Leave empty for full clone.`，优先留空；如果 UI 不允许留空，填写 `1`。不要把 URL、分支名或文件夹名填到 depth。
7. 如果出现 `Invalid depth. Aborting clone.`，说明 depth 填错了；重新执行克隆，并将 depth 留空或填 `1`。
8. Git 只能克隆到新的或空目录。如果提示目标中已有 `.obsidian`，优先克隆到新的子文件夹，不要覆盖未同步笔记。
9. 等待完成通知。克隆期间不要锁屏、切换应用或关闭 Obsidian。
10. 按提示重启 Obsidian。
11. 打开 vault 管理器，将克隆后的仓库文件夹作为 vault 打开。若插件已随 `.obsidian` 同步，确认它已启用；否则在新 vault 中再次安装并启用 Git。
12. 确认电脑端已有笔记出现在文件列表。不要继续在最初用于安装插件的临时空 vault 中写正式笔记。

## 7. iPhone 重启后按顺序设置 Git 插件开关

克隆完成并重启 Obsidian 后，先确认当前打开的是克隆后的 vault，再进入 `Settings -> Community plugins -> Git`。此时再填写提交作者信息和自动同步开关；不要让用户在临时空 vault 中填写这些最终设置。

先填写提交作者信息。它写入 Git 历史，用来标记是谁提交了笔记，不等于 GitHub 登录密码：

```text
Author name for commit
<author name from generated checklist>

Author email for commit
<noreply or verified email from generated checklist>
```

如果用户看不到完全相同的字段名，搜索 `author`、`commit author`、`email`。若出现 `git author name/email not set`，说明这两个字段未保存，需要在克隆后的真实 vault 中重新填写并重启 Obsidian。

然后按常见手机 UI 顺序配置自动同步，不要让用户自己跳着找：

```text
Split timers for automatic commit and sync
关闭

Auto commit-and-sync interval (minutes)
1

Auto commit-and-sync after stopping file edits
开启
```

继续向下查找；如果当前插件版本显示这些选项，再这样设置：

```text
Pull on startup
开启

Pull before push
开启

Auto pull interval
1
```

若手机端没有 `Pull on startup` 或 `Pull before push`，不要卡住流程。改用命令面板替代：编辑前运行 `Git: Pull`，编辑后运行 `Git: Commit-and-sync`。不同版本可能把 `Pull before push` 合并进 `Commit-and-sync` 流程，不一定单独显示。

iOS 锁屏或切换应用后可能暂停 Obsidian，无法保证后台每分钟同步。离开应用前使用手动命令最可靠。

## 8. iPhone 日常调用 Git 命令

所有操作都在 Obsidian 命令面板中搜索，无需手机终端：

- `Git: Pull`：编辑前从 GitHub 拉取；
- `Git: Commit-and-sync`：提交本机修改、拉取并推送；
- `Git: Push`：仅推送已有提交；
- `Git: Open source control view`：查看 `A/M/D/R` 文件状态；
- `Git: View history`：查看提交历史。

推荐日常流程：

1. 打开 Obsidian。
2. 运行 `Git: Pull`。
3. 从文件列表打开已有笔记后编辑。
4. 保持应用前台等待自动同步，或运行 `Git: Commit-and-sync`。
5. 看到成功提示后再锁屏或切换应用。

解释给用户时必须区分：

```text
Pull = 从 GitHub 下载最新稿到手机，不会上传手机修改。
Commit-and-sync = 提交手机本地修改、拉取远端更新并推送到 GitHub。
```

如果用户先 Pull 后继续编辑，后续自动或手动 `Commit-and-sync` 提交的是编辑后的最新本地稿，不是 Pull 那一刻的旧稿。建议编辑前先 Pull，是为了避免用户在旧版本上继续写。

## 9. 云同步使用注意事项

1. 每次开始编辑前，先运行 `Git: Pull`。
2. 编辑完成后，保持 Obsidian 在前台等待 1 分钟，或直接运行 `Git: Commit-and-sync`。
3. 不要在多台设备同时编辑同一篇笔记。
4. 测试同步时使用专门测试文件，不要拿正式稿测试删除。
5. 手机端自动同步依赖前台运行；锁屏、切后台、省电限制、VPN 断开都可能导致同步失败。
6. 如果出现 `Request failed`，先检查手机浏览器能否打开 GitHub 和私有仓库，再检查 VPN、Token 权限和网络。
7. 如果误删笔记，立刻停止所有设备同步，使用 `troubleshooting.md` 的误删恢复流程。
8. 四端同步时，默认只让 Windows 和一台主手机自动提交；其他手机或备用端使用手动 Pull / Commit-and-sync。

## 10. Android 差异步骤

1. 从 Google Play 安装：<https://play.google.com/store/apps/details?id=md.obsidian>。
2. 创建本地空 vault，并授予 Obsidian 所需文件访问权限。
3. 按 iPhone 相同方式安装并启用 `Git` 插件。
4. 填写相同的 Username、Token、Author name 和 Author email。
5. 运行 `Git: Clone existing remote repo` 并粘贴 HTTPS `.git` 地址。
6. 按第 6 节处理 `Vault Root` 与 clone depth；`Vault Root` 填新的空文件夹名，depth 留空或填 `1`。
7. 按第 7 节顺序设置停止编辑后 1 分钟同步；若没有启动时 Pull 或 Push 前 Pull 选项，使用命令面板中的 `Git: Pull` 和 `Git: Commit-and-sync`。
8. 若系统限制后台活动，可在 Android 电池设置中允许 Obsidian 后台运行；不同厂商名称可能是“无限制”“不优化”或“允许后台活动”。

## 11. 手机端验收

### GitHub 到手机

1. Windows 创建唯一命名测试笔记并等待推送。
2. 手机运行 `Git: Pull`。
3. 确认文件名和内容完全一致。

### 手机到 GitHub

1. 从文件列表打开同一测试笔记。
2. 只修改正文，不点击新建笔记，不改变标题。
3. 运行 `Git: Commit-and-sync`。
4. 打开清单中的私有仓库链接，确认提交出现。
5. Git 状态应为修改 `M`。若出现新增 `A`，说明手机创建了另一个文件路径。

### GitHub 回到 Windows

等待 Windows 自动拉取，或在工作区干净时手动 Pull，确认手机修改出现在电脑。

任一步失败时停止继续操作，保留错误提示并参考 `troubleshooting.md`，不要反复点击 Push 或强制覆盖。

---

# English Version

## 1. Personalized information that must be shown first

Run `scripts/mobile-setup-info.ps1` and replace every placeholder in this checklist with real values:

```text
GitHub account: <login>
Commit author: <author name>
Commit email: <id+login@users.noreply.github.com>
Private repository: https://github.com/<owner>/<repository>
Clone URL: https://github.com/<owner>/<repository>.git
Create token: https://github.com/settings/personal-access-tokens/new
Check email: https://github.com/settings/emails
Obsidian Git plugin: https://obsidian.md/plugins?id=obsidian-git
```

Download Obsidian:

- iPhone/iPad: https://apps.apple.com/app/obsidian-connected-notes/id1557175442
- Android: https://play.google.com/store/apps/details?id=md.obsidian
- Official download: https://obsidian.md/download

Never display the token value or ask the user to send it in chat. A token is shown in full only once and should be saved in the system password manager.

These values must come from the current user's GitHub login state, the current vault remote, and the GitHub API. Do not hard-code any example account, fixed email, fixed repository name, or author name in the skill. If real values cannot be read, stop and repair GitHub login or repository connection instead of letting the user copy another person's configuration.

## 2. Sync architecture and core logic

Explain that this is not Obsidian's official cloud sync. It is a Git workflow:

```text
Windows Obsidian vault
        ↕
GitHub private repository
        ↕
iPhone / Android Obsidian vault
```

Each device keeps a full local copy of the vault, and the GitHub private repository is the transfer hub. The Obsidian Git plugin on mobile performs three actions:

```text
Pull
Download the newest notes from GitHub.

Commit
Record local additions, deletions, and edits as a version.

Push
Upload the local version to GitHub.
```

`Git: Commit-and-sync` usually performs `commit -> pull -> push`. Still recommend `Git: Pull` before editing so the user starts from the newest draft instead of editing a stale copy and hitting conflicts later. One-minute automatic sync after editing triggers `Commit-and-sync`, not just Pull.

Explain four rules:

1. Create, delete, and edit operations produce changes; search, reading, and opening pages do not.
2. Deletion is also synchronized. If a phone deletes a note and pushes it, the desktop will delete it too; accidental deletion is recovered from Git history.
3. Do not edit the same note on multiple devices at the same time. With four devices, only Windows and one main phone should auto-write by default; other devices should use manual sync.
4. `.obsidian/plugins/obsidian-git/data.json` must remain device-local, or one device's Git settings will overwrite another's.

## 3. Create the GitHub credential key / token

Complete these steps in the phone browser:

1. Open <https://github.com/settings/personal-access-tokens/new>.
2. Sign in to the GitHub account that can access the private repository.
3. The page normally says `New fine-grained personal access token`. If the UI changes, open profile `Settings`, search for `Personal access tokens`, choose `Fine-grained tokens`, and generate a new token.
4. Use `Obsidian iPhone` or `Obsidian Android` as Token name.
5. Prefer a finite expiration date.
6. Select the repository owner as Resource owner.
7. Choose `Only select repositories`.
8. Select only the target Obsidian repository.
9. Under `Repository permissions`, set:
   - Metadata: `Read-only`;
   - Contents: `Read and write`;
   - Commit statuses: `Read and write` when required.
10. Verify no extra repositories or permissions are granted.
11. The user personally selects `Generate token`.
12. Copy it immediately and save it in Apple Passwords, iCloud Keychain, or the Android password manager.

This token is the "key" users may refer to on mobile. GitHub cannot reveal a token after the page is closed. If lost, create a replacement and revoke the old token at <https://github.com/settings/personal-access-tokens>.

## 4. Download Obsidian and the Git plugin on iPhone

### Install Obsidian

1. Open <https://apps.apple.com/app/obsidian-connected-notes/id1557175442>.
2. Install and open Obsidian.
3. Create a temporary empty vault for installing the plugin.
4. Do not enable `Store in iCloud`; Git and iCloud must not write the same vault.

### Download and enable Obsidian Git

1. Open <https://obsidian.md/plugins?id=obsidian-git> and choose to open it in Obsidian when offered.
2. If deep linking fails, open Obsidian `Settings`.
3. Use Settings search for `Community plugins`.
4. Disable `Restricted mode` or allow community plugins.
5. Select `Browse` and search for the exact plugin name `Git`.
6. Confirm it is the Obsidian Git plugin, then select `Install`.
7. Select `Enable`. Installation alone does not expose Git commands.
8. Return to Settings and open `Git` under Community plugins.

If a future Obsidian update moves buttons, use Settings search for `Community plugins` and plugin-market search for the exact name `Git`.

## 5. Enter the nickname and key required for clone on iPhone

Before cloning a private repository, find the authentication area in Git settings. Depending on version, it may appear as `Authentication`, `Remote`, `Username`, or `Password/Token`. If the user says "nickname and key", map the terms like this:

```text
Nickname / Username = GitHub login
Key / Password / Token = GitHub fine-grained token
```

1. Username: the GitHub login from the checklist.
2. Password/Token: the fine-grained token, not the GitHub account password.
3. Never place the token in a repository URL, note, or screenshot.

If this plugin version prompts for Username/Password inside the clone command, enter the same GitHub username and token in that prompt. Do not use the GitHub account password.

## 6. Clone the private repository from Obsidian Command Palette

1. Open Obsidian Command Palette. If its button moves, search the app for `Command palette`.
2. Search for the stable command `Git: Clone existing remote repo`.
3. Paste the HTTPS `.git` clone URL from the checklist. Do not use the browser URL or SSH.
4. If prompted for `Branch`, enter `main`.
5. If prompted for `Vault Root` or folder name, enter a new empty folder name such as the repository name. This is the cloned vault folder on the phone, not the GitHub URL.
6. If prompted with `Specify depth of clone. Leave empty for full clone.`, prefer leaving it empty. If the UI does not allow an empty value, enter `1`. Do not enter a URL, branch, or folder name as depth.
7. If `Invalid depth. Aborting clone.` appears, the depth value was wrong. Restart clone and leave depth empty or enter `1`.
8. Git can clone only into a new or empty directory. If `.obsidian` already exists, prefer a new subfolder and never overwrite unsynchronized notes.
9. Keep Obsidian active during clone; do not lock the screen or switch apps.
10. Restart Obsidian when requested.
11. Open the cloned repository folder as a vault. If Git was not carried into the new vault, install and enable it there again.
12. Confirm desktop notes appear in the file list. Do not keep writing real notes in the temporary empty vault used only for plugin setup.

## 7. Configure Git plugin switches after restart

After clone and Obsidian restart, confirm the cloned vault is open, then go to `Settings -> Community plugins -> Git`. Enter commit author information and automatic sync switches at this point; do not make the user enter final settings in the temporary empty vault.

First enter commit author information. It is written into Git history to mark who made note commits; it is not the GitHub password:

```text
Author name for commit
<author name from generated checklist>

Author email for commit
<noreply or verified email from generated checklist>
```

If the exact field names are not visible, search for `author`, `commit author`, or `email`. If `git author name/email not set` appears, these fields were not saved; enter them again in the cloned real vault and restart Obsidian.

Then configure automatic sync in the common mobile UI order; do not make the user hunt for scattered settings:

```text
Split timers for automatic commit and sync
Off

Auto commit-and-sync interval (minutes)
1

Auto commit-and-sync after stopping file edits
On
```

Continue scrolling. If this plugin version shows these options, set them as follows:

```text
Pull on startup
On

Pull before push
On

Auto pull interval
1
```

If the phone does not show `Pull on startup` or `Pull before push`, do not block setup. Use Command Palette instead: run `Git: Pull` before editing and `Git: Commit-and-sync` after editing. Some versions fold `Pull before push` into `Commit-and-sync` and do not expose it separately.

iOS may suspend Obsidian after screen lock or app switching. Background one-minute sync is not guaranteed; manual commands before leaving are the reliable fallback.

## 8. Daily Git commands on iPhone

Search these exact commands in Obsidian Command Palette; no mobile terminal is required:

- `Git: Pull`: pull from GitHub before editing;
- `Git: Commit-and-sync`: commit local changes, pull, and push;
- `Git: Push`: push existing commits only;
- `Git: Open source control view`: inspect `A/M/D/R` status;
- `Git: View history`: inspect commit history.

Recommended routine:

1. Open Obsidian.
2. Run `Git: Pull`.
3. Open an existing note from the file list and edit it.
4. Keep the app active for automatic sync or run `Git: Commit-and-sync`.
5. Wait for success before locking the phone or switching apps.

Explain the difference clearly:

```text
Pull = download the newest draft from GitHub to the phone; it does not upload phone edits.
Commit-and-sync = commit phone edits, pull remote changes, and push to GitHub.
```

If the user pulls and then edits, the later automatic or manual `Commit-and-sync` uploads the edited local draft, not the draft as it existed at pull time. Pull before editing is recommended so the user starts from the newest base.

## 9. Cloud sync operating rules

1. Run `Git: Pull` before editing.
2. After editing, keep Obsidian in the foreground for one minute or run `Git: Commit-and-sync` immediately.
3. Do not edit the same note on multiple devices at the same time.
4. Use dedicated test notes for sync tests; do not test deletion on real drafts.
5. Mobile automatic sync depends on foreground execution. Screen lock, background suspension, battery limits, and VPN/network changes can stop sync.
6. If `Request failed` appears, first check whether the phone browser can open GitHub and the private repository, then check VPN, token permissions, and network.
7. If a note is accidentally deleted, stop syncing on every device and use the accidental deletion recovery flow in `troubleshooting.md`.
8. With four devices, let only Windows and one main phone auto-commit by default. Other phones or backup endpoints should use manual Pull / Commit-and-sync.

## 10. Android differences

1. Install from <https://play.google.com/store/apps/details?id=md.obsidian>.
2. Create an empty local vault and grant required file access.
3. Install and enable `Git` as described for iPhone.
4. Enter the same Username, Token, Author name, and Author email.
5. Run `Git: Clone existing remote repo` with the HTTPS `.git` URL.
6. Follow section 6 for `Vault Root` and clone depth. Enter a new empty folder name for `Vault Root`; leave depth empty or enter `1`.
7. Follow section 7 for one-minute sync after stopping edits. If startup pull or pull-before-push options are missing, use `Git: Pull` and `Git: Commit-and-sync` from Command Palette.
8. If the vendor limits background activity, allow Obsidian unrestricted or non-optimized battery use where appropriate.

## 11. Mobile acceptance test

### GitHub to phone

1. Create a uniquely named test note on Windows and wait for push.
2. Run `Git: Pull` on the phone.
3. Confirm identical filename and content.

### Phone to GitHub

1. Open the same test note from the file list.
2. Modify only its body; do not create a new note or rename it.
3. Run `Git: Commit-and-sync`.
4. Open the private repository link and confirm the commit.
5. Git status should be modified `M`. Added `A` means the phone created another path.

### GitHub back to Windows

Wait for the Windows clean-worktree pull or pull manually, then confirm the mobile content appears.

If any step fails, stop, preserve the error, and use `troubleshooting.md`. Do not repeatedly push or force-overwrite history.
