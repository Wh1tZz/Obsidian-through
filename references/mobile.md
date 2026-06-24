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

下载 Obsidian：

- iPhone/iPad：https://apps.apple.com/app/obsidian-connected-notes/id1557175442
- Android：https://play.google.com/store/apps/details?id=md.obsidian
- Obsidian 官方下载：https://obsidian.md/download

不得输出 Token 值，不得要求用户将 Token 发到聊天。Token 创建后只能完整显示一次，应保存到系统密码管理器。

## 2. 创建 GitHub 登录密钥

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

GitHub 无法找回已经关闭页面的 Token 明文。遗失后应创建新 Token，并在 <https://github.com/settings/personal-access-tokens> 撤销旧 Token。

## 3. iPhone 安装 Obsidian 和 Git 插件

### 安装 Obsidian

1. 打开 App Store 链接：<https://apps.apple.com/app/obsidian-connected-notes/id1557175442>。
2. 安装并打开 Obsidian。
3. 创建一个临时空 vault 用于安装插件。
4. 不要开启 `Store in iCloud`。Git 与 iCloud 同时写同一 vault 容易冲突。

### 安装 Obsidian Git

1. 打开插件链接：<https://obsidian.md/plugins?id=obsidian-git>。若系统允许，选择在 Obsidian 中打开。
2. 若链接无法直接跳转，在 Obsidian 打开 `Settings`。
3. 使用设置搜索查找 `Community plugins` 或“第三方插件”。
4. 关闭 `Restricted mode` 或选择允许第三方插件。
5. 选择 `Browse`，搜索插件名 `Git`。
6. 确认插件作者/项目为 Obsidian Git，再选择 `Install`。
7. 安装后选择 `Enable`。仅安装但未启用不会出现 Git 命令。
8. 回到设置，在 `Community plugins` 下找到 `Git` 并打开插件选项。

未来 Obsidian UI 即使改变，只要能在设置搜索中找到 `Community plugins`，并在插件市场搜索精确名称 `Git`，流程仍然适用。

## 4. iPhone 填写 Token、邮箱与作者

在 Git 插件设置中搜索或滚动到 `Authentication/Commit Author`：

1. `Username`：填写清单中的 GitHub 账号。
2. `Password/Token`：粘贴 Fine-grained Token，不是 GitHub 登录密码。
3. `Author name`：填写清单中的作者名；没有公开姓名时可使用 GitHub 登录名。
4. `Author email`：填写脚本生成的 noreply 邮箱，或在 <https://github.com/settings/emails> 查看 GitHub 已验证邮箱。
5. 不要把 Token 写进仓库 URL、笔记或截图。

若出现 `git author name/email not set`，说明第 3 或第 4 项未保存。重新填写并重启 Obsidian。

## 5. iPhone 克隆私有仓库

1. 打开 Obsidian 命令面板。可使用界面中的命令面板按钮；若位置改变，在应用搜索中查找 `Command palette`。
2. 搜索并运行稳定命令名：`Git: Clone existing remote repo`。
3. 粘贴清单中的 HTTPS `.git` 克隆地址，不要使用浏览器地址或 SSH 地址。
4. 按提示选择新的子文件夹，例如仓库名。Git 只能克隆到新的或空目录。
5. 如果提示目标中已有 `.obsidian`，优先克隆到新的子文件夹，不要覆盖未同步笔记。
6. 等待完成通知。克隆期间不要锁屏、切换应用或关闭 Obsidian。
7. 按提示重启 Obsidian。
8. 打开 vault 管理器，将克隆后的仓库文件夹作为 vault 打开。若插件已随 `.obsidian` 同步，确认它已启用；否则在新 vault 中再次安装并启用 Git。
9. 确认电脑端已有笔记出现在文件列表。

## 6. iPhone 设置自动同步

在 Git 插件设置中：

- `Auto commit-and-sync interval`：`1`；
- 开启 `Auto commit-and-sync after stopping file edits`；
- 关闭 `Split timers for automatic commit and sync`；
- 开启 `Pull on startup`；
- 可选：`Auto pull interval`：`1`；
- 保持 `Pull before push` 开启。

iOS 锁屏或切换应用后可能暂停 Obsidian，无法保证后台每分钟同步。离开应用前使用手动命令最可靠。

## 7. iPhone 调用 Git 命令

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

## 8. Android 差异步骤

1. 从 Google Play 安装：<https://play.google.com/store/apps/details?id=md.obsidian>。
2. 创建本地空 vault，并授予 Obsidian 所需文件访问权限。
3. 按 iPhone 相同方式安装并启用 `Git` 插件。
4. 填写相同的 Username、Token、Author name 和 Author email。
5. 运行 `Git: Clone existing remote repo` 并粘贴 HTTPS `.git` 地址。
6. 设置停止编辑后 1 分钟同步和启动时 Pull。
7. 若系统限制后台活动，可在 Android 电池设置中允许 Obsidian 后台运行；不同厂商名称可能是“无限制”“不优化”或“允许后台活动”。

## 9. 手机端验收

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

## 2. Create the GitHub credential

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

GitHub cannot reveal a token after the page is closed. If lost, create a replacement and revoke the old token at <https://github.com/settings/personal-access-tokens>.

## 3. Install Obsidian and Git on iPhone

### Install Obsidian

1. Open <https://apps.apple.com/app/obsidian-connected-notes/id1557175442>.
2. Install and open Obsidian.
3. Create a temporary empty vault for installing the plugin.
4. Do not enable `Store in iCloud`; Git and iCloud must not write the same vault.

### Install Obsidian Git

1. Open <https://obsidian.md/plugins?id=obsidian-git> and choose to open it in Obsidian when offered.
2. If deep linking fails, open Obsidian `Settings`.
3. Use Settings search for `Community plugins`.
4. Disable `Restricted mode` or allow community plugins.
5. Select `Browse` and search for the exact plugin name `Git`.
6. Confirm it is the Obsidian Git plugin, then select `Install`.
7. Select `Enable`. Installation alone does not expose Git commands.
8. Return to Settings and open `Git` under Community plugins.

If a future Obsidian update moves buttons, use Settings search for `Community plugins` and plugin-market search for the exact name `Git`.

## 4. Enter token, email, and author on iPhone

Find `Authentication/Commit Author` in Git settings:

1. Username: the GitHub login from the checklist.
2. Password/Token: the fine-grained token, not the GitHub account password.
3. Author name: the checklist author name or GitHub login.
4. Author email: the generated noreply address or a verified email from <https://github.com/settings/emails>.
5. Never place the token in a repository URL, note, or screenshot.

If `git author name/email not set` appears, fields 3 or 4 were not saved. Enter them again and restart Obsidian.

## 5. Clone the private repository on iPhone

1. Open Obsidian Command Palette. If its button moves, search the app for `Command palette`.
2. Search for the stable command `Git: Clone existing remote repo`.
3. Paste the HTTPS `.git` clone URL from the checklist. Do not use the browser URL or SSH.
4. Choose a new subfolder such as the repository name. Git can clone only into a new or empty directory.
5. If `.obsidian` already exists, prefer a new subfolder and never overwrite unsynchronized notes.
6. Keep Obsidian active during clone; do not lock the screen or switch apps.
7. Restart Obsidian when requested.
8. Open the cloned repository folder as a vault. If Git was not carried into the new vault, install and enable it there again.
9. Confirm desktop notes appear in the file list.

## 6. Configure iPhone automatic sync

In Git settings:

- Auto commit-and-sync interval: `1`;
- enable `Auto commit-and-sync after stopping file edits`;
- disable `Split timers for automatic commit and sync`;
- enable `Pull on startup`;
- optionally set Auto pull interval to `1`;
- keep `Pull before push` enabled.

iOS may suspend Obsidian after screen lock or app switching. Background one-minute sync is not guaranteed; manual commands before leaving are the reliable fallback.

## 7. Run Git commands on iPhone

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

## 8. Android differences

1. Install from <https://play.google.com/store/apps/details?id=md.obsidian>.
2. Create an empty local vault and grant required file access.
3. Install and enable `Git` as described for iPhone.
4. Enter the same Username, Token, Author name, and Author email.
5. Run `Git: Clone existing remote repo` with the HTTPS `.git` URL.
6. Configure one-minute sync after stopping edits and Pull on startup.
7. If the vendor limits background activity, allow Obsidian unrestricted or non-optimized battery use where appropriate.

## 9. Mobile acceptance test

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
