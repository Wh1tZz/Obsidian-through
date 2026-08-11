# 中文版

## 0. 手机端用户输出格式

移动端主流程只输出“去哪里 → 点什么 → 填什么”，每一步保持简短。原理、注意事项和错误处理只在用户询问或实际报错时显示。只有 GitHub Token 创建页使用 Markdown 可点击链接；其他值来自 `scripts/mobile-setup-info.ps1` 并放入代码块。不得输出占位符。

开始手机端前，先输出真实动态清单：

```text
GitHub 账号
```

```text
<real login>
```

```text
电脑端 Obsidian vault
```

```text
<real absolute vault path>
```

```text
GitHub 私有仓库页面
```

```text
https://github.com/<real owner>/<real repository>
```

```text
手机端克隆地址
```

```text
https://github.com/<real owner>/<real repository>.git
```

```text
提交作者名
```

```text
<real author name>
```

```text
提交邮箱
```

```text
<real noreply or verified email>
```

然后逐步说明：

1. 在手机打开 Obsidian。
2. 进入 `设置`，搜索或打开 `Community plugins` / 第三方插件。
3. 安装并启用 `Git` / `Obsidian Git`。
4. 不要先克隆。进入 `Settings -> Community plugins -> Git`，找到截图中类似 `Authentication/commit author` 的区域。
5. 在 `Username on your git server. E.g. your username on GitHub` 输入框填写真实 GitHub 登录名：

```text
<real login>
```

6. 先自动弹出 GitHub Fine-grained Token 创建页面。执行手机配置时必须用脚本的 `-OpenTokenPage`，或等价地用系统浏览器打开这个可点击链接：

[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

7. 指导用户在弹出的 GitHub 页面创建 Fine-grained Token，复制后回到 Obsidian，把 Token 粘贴到 `Password/Personal access token` 输入框。这里不要输出 Token 值，不要要求用户把 Token 发到聊天里，不要把 Token 写进笔记或截图。
8. 明确告诉用户：这两个认证字段必须在克隆私有仓库前填写，否则插件可能没有权限访问 GitHub 私有仓库。
9. 回到 Obsidian 主界面，打开命令面板；如果找不到，搜索 `Command palette`。
10. 在命令面板搜索并点击：

```text
Git: Clone an existing remote repo
```

11. 当它要求填写仓库地址时，粘贴真实 clone URL：

```text
https://github.com/<real owner>/<real repository>.git
```

12. 当插件询问克隆目录时，填写脚本从当前远程生成的真实仓库名。仓库可以叫任意名称，不得固定输出 `obsidian-vault`：

```text
<real repository name>
```

选择或创建这个同名子文件夹，不要选择 `Vault Root`。

13. 克隆成功后，完全关闭并重新打开 Obsidian。
14. 进入 `设置 / Settings → 第三方插件 / Community plugins → Git → Automatic`，按顺序设置：关闭 `Split timers for automatic commit and sync`，把 `Auto commit-and-sync interval (minutes)` 填写为 `0.5`，开启 `Auto commit-and-sync after stopping file edits`，开启 `Pull on startup`。
15. 再往下找到 `Authentication/commit author`，重新填写 Username、Token、Author name 和 Author email。
16. 回到主界面，进入命令面板，搜索并执行：

```text
Git: Pull
```

17. 手机端新建测试笔记后，搜索并执行：

```text
Git: Commit-and-sync
```

18. 首次 `Git: Commit-and-sync` 成功后，完全关闭并重新打开 Obsidian。再修改测试笔记，保持应用前台并停止编辑 30–60 秒，不运行手动命令，确认 GitHub 自动出现新提交。

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

下载 Obsidian 时，直接在移动设备的应用商店搜索 `Obsidian - Connected Notes`。不同移动系统使用同一套后续配置流程，不询问设备类型，也不分别输出说明。

不得输出 Token 值，不得要求用户将 Token 发到聊天。Token 创建后只能完整显示一次，应保存到系统密码管理器。

## 2. 同步架构与核心逻辑

向用户解释这套同步不是 Obsidian 官方云同步，而是 Git 工作流：

```text
Windows Obsidian vault
        ↕
GitHub private repository
        ↕
移动端 Obsidian vault
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

`Git: Commit-and-sync` 通常组合执行 `commit -> pull -> push`。编辑前仍建议先运行 `Git: Pull`，因为这样用户是在最新稿上继续写，而不是在旧稿上写完后再撞到冲突。停止编辑后的 0.5 分钟自动同步，触发的是 `Commit-and-sync`，不是单纯 Pull。

向用户说明四个注意点：

1. 增、删、改会产生可提交变更；搜索、阅读、打开页面不会提交。
2. 删除也是同步内容，手机删除后推送到 GitHub，电脑也会删除；误删要从 Git 历史恢复。
3. 多端不要同时编辑同一篇笔记；四端同步时只让 Windows 和一台主手机自动写入，其他设备默认手动同步。
4. `.obsidian/plugins/obsidian-git/data.json` 必须保持设备本地化，否则一台设备的 Git 设置会覆盖另一台。

## 3. 创建 GitHub 登录密钥 Key / Token

在移动设备浏览器完成。字段必须中英文对照，并严格按照页面从上往下的顺序指导：

1. 先自动弹出 GitHub Token 页面；若没有弹出，手动打开：<https://github.com/settings/personal-access-tokens/new>。
2. 如果出现登录页面，登录拥有私有仓库访问权的 GitHub 账号。
3. 页面标题通常是 `新建精细化个人访问令牌 / New fine-grained personal access token`。
4. `令牌名称 / Token name`：填写 `Obsidian Mobile`。
5. `描述 / Description`：选填，可填写 `Obsidian 移动端同步 / Obsidian mobile sync`，也可以留空。
6. `资源所有者 / Resource owner`：选择私有仓库所属的真实 GitHub 账号。
7. `有效期 / Expiration`：选择有限期限；过期后重新创建 Token。
8. `仓库访问 / Repository access`：选择 `仅选定的仓库 / Only select repositories`。
9. 点击 `选择仓库 / Select repositories`，只勾选目标 Obsidian 私有仓库。
10. 向下找到 `权限 / Permissions`，保持在 `仓库 / Repository permissions` 标签页。
11. 点击 `添加权限 / Add permissions`，在同一个权限选择框里依次添加：
    - `内容 / Contents`：设置为 `读写 / Read and write`；
    - `提交状态 / Commit statuses`：页面能找到该权限时添加，并设置为 `读写 / Read and write`。
12. `元数据 / Metadata` 保持 `只读 / Read-only`。它通常由 GitHub 自动加入，不需要重复添加。
13. 检查没有授权其他仓库或多余权限。
14. 点击 `生成令牌 / Generate token`。
15. 立即复制 Token 并保存到设备的系统密码管理器。

这里的 Token 就是用户在手机端说的 “key”。GitHub 无法找回已经关闭页面的 Token 明文。遗失后应创建新 Token，并在 <https://github.com/settings/personal-access-tokens> 撤销旧 Token。

## 4. 移动端下载 Obsidian 和 Git 插件

### 安装 Obsidian

1. 在移动设备的应用商店搜索并安装 `Obsidian - Connected Notes`。
2. 打开 Obsidian，进入 `仓库管理器 / Open vault manager`。
3. 点击 `新建仓库 / Create new vault`。
4. 在 `仓库名称 / Vault name` 填写 `Obsidian Mobile`，然后点击 `创建 / Create`。

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

## 5. 移动端填写克隆所需的昵称和 Key

克隆私有仓库前，进入 `Settings -> Community plugins -> Git`，找到 `Authentication/commit author`。如果用户说“昵称和 key”，按下面填写：

```text
Username on your git server. E.g. your username on GitHub = GitHub 登录名
Password/Personal access token = GitHub Fine-grained Token
```

1. 先填写 `Username on your git server. E.g. your username on GitHub`，值必须是清单中的真实 GitHub 账号。
2. 再填写 `Password/Personal access token`，值是用户自己创建的 Fine-grained Token，不是 GitHub 登录密码。
3. 这两项必须在 `Git: Clone an existing remote repo` 前完成。
4. 不要把 Token 写进仓库 URL、笔记或截图，也不要要求用户把 Token 发到聊天里。

若当前插件版本在克隆命令中弹出 Username/Password 输入框，也可以在弹窗中填写同样的 GitHub username 和 Token。不要使用 GitHub 登录密码。

## 6. 移动端在 Obsidian 命令面板克隆私有仓库

1. 打开 Obsidian 命令面板。可使用界面中的命令面板按钮；若位置改变，在应用搜索中查找 `Command palette`。
2. 搜索并运行稳定命令名：`Git: Clone an existing remote repo`。
3. 粘贴清单中的 HTTPS `.git` 克隆地址，不要使用浏览器地址或 SSH 地址。
4. 若提示克隆位置，填写 `mobile-setup-info.ps1` 输出的 `cloneDirectoryName`。这是当前远程的真实仓库名，可以是任意名称；选择或创建该同名子文件夹，不要选择 `Vault Root`，不要固定填写 `obsidian-vault`。
5. 出现 `Specify depth of clone. Leave empty for full clone.` 时，输入 `1` 并按手机键盘 `Enter / 回车`。浅克隆保留当前完整文件，只省略旧提交历史，可降低移动端克隆时的内存峰值。
6. 保持 Obsidian 在前台，直到看到 `Cloned new repo.` 和 `Please restart Obsidian`。未看到成功提示就视为克隆失败，停止流程，不设置 Automatic，也不运行 Pull。
7. 完全关闭并重新打开 Obsidian，确认 Git 仍然启用。
8. 重新填写 Username、Token、Author name 和 Author email，确认电脑端已有笔记出现在文件列表。

## 7. 移动端重启后按顺序设置 Git 插件开关

克隆完成并重启 Obsidian 后，进入：

```text
设置 / Settings
→ 第三方插件 / Community plugins
→ Git
```

先进入 `Automatic`，按顺序设置：

```text
Split timers for automatic commit and sync
关闭

Auto commit-and-sync interval (minutes)
0.5

Auto commit-and-sync after stopping file edits
开启

Pull on startup
开启
```

再往下找到 `Authentication/commit author`，按顺序填写：

```text
Username on your git server
<real login from generated checklist>

Password/Personal access token
粘贴用户刚创建的 Token

Author name for commit
<author name from generated checklist>

Author email for commit
<noreply or verified email from generated checklist>
```

如果用户看不到完全相同的字段名，搜索 `author`、`commit author`、`email`。若出现 `git author name/email not set`，说明这两个字段未保存，需要在克隆后的真实 vault 中重新填写并重启 Obsidian。

移动系统可能在锁屏、切换应用、省电或后台受限时暂停 Obsidian，无法保证后台每分钟同步。离开应用前使用手动命令最可靠。

## 8. 移动端日常调用 Git 命令

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
2. 编辑完成后，保持 Obsidian 在前台等待约 30 秒，或直接运行 `Git: Commit-and-sync`。
3. 不要在多台设备同时编辑同一篇笔记。
4. 测试同步时使用专门测试文件，不要拿正式稿测试删除。
5. 手机端自动同步依赖前台运行；锁屏、切后台、省电限制、VPN 断开都可能导致同步失败。
6. 如果出现 `Request failed`，先检查手机浏览器能否打开 GitHub 和私有仓库，再检查 VPN、Token 权限和网络。
7. 如果误删笔记，立刻停止所有设备同步，使用 `troubleshooting.md` 的误删恢复流程。
8. 四端同步时，默认只让 Windows 和一台主手机自动提交；其他手机或备用端使用手动 Pull / Commit-and-sync。

## 10. 移动端验收

### GitHub 到手机

1. Windows 创建唯一命名测试笔记并等待推送。
2. 手机运行 `Git: Pull`。
3. 确认文件名和内容完全一致。

### 手机到 GitHub

1. 从文件列表打开同一测试笔记。
2. 只修改正文，不点击新建笔记，不改变标题。
3. 运行 `Git: Commit-and-sync`。
4. 打开清单中的私有仓库链接，确认首次手动提交出现。
5. 完全关闭并重新打开 Obsidian，再次修改同一篇测试笔记的正文。
6. 保持 Obsidian 在前台，停止编辑 30–60 秒，不运行 `Git: Commit-and-sync`，确认 GitHub 自动出现第二次提交。
7. Git 状态应为修改 `M`。若出现新增 `A`，说明手机创建了另一个文件路径。

### GitHub 回到 Windows

等待 Windows 自动拉取，或在工作区干净时手动 Pull，确认手机修改出现在电脑。

任一步失败时停止继续操作，保留错误提示并参考 `troubleshooting.md`，不要反复点击 Push 或强制覆盖。

---

# English Version

## 0. Mobile User-Facing Output Format

The mobile main flow must contain only short “where → click → enter” steps. Explain concepts, cautions, or repairs only when asked or after the matching error occurs. Only the GitHub token page is a clickable link; all other values come from `scripts/mobile-setup-info.ps1` and appear in copy blocks. Never output placeholders.

Before mobile setup, show the real dynamic checklist:

```text
GitHub account
```

```text
<real login>
```

```text
Desktop Obsidian vault
```

```text
<real absolute vault path>
```

```text
GitHub private repository page
```

```text
https://github.com/<real owner>/<real repository>
```

```text
Mobile clone URL
```

```text
https://github.com/<real owner>/<real repository>.git
```

```text
Commit author name
```

```text
<real author name>
```

```text
Commit email
```

```text
<real noreply or verified email>
```

Then guide the user step by step:

1. Open Obsidian on the phone.
2. Open `Settings`, then search for or open `Community plugins`.
3. Install and enable `Git` / `Obsidian Git`.
4. Do not clone yet. Open `Settings -> Community plugins -> Git` and find the area similar to `Authentication/commit author`.
5. In `Username on your git server. E.g. your username on GitHub`, enter the real GitHub login:

```text
<real login>
```

6. First open the GitHub fine-grained token creation page automatically. During mobile setup, run the script with `-OpenTokenPage` or equivalently open this clickable link in the system browser:

[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

7. Guide the user to create the fine-grained token in the opened GitHub page, copy it, return to Obsidian, and paste it into `Password/Personal access token`. Do not display the token value, never ask the user to send it in chat, and never write it into notes or screenshots.
8. Tell the user clearly that these two authentication fields must be filled before cloning a private repository, otherwise the plugin may not have permission to access GitHub.
9. Return to the Obsidian main screen and open Command Palette. If the user cannot find it, search for `Command palette`.
10. Search and run:

```text
Git: Clone an existing remote repo
```

11. When asked for the repository URL, paste the real clone URL:

```text
https://github.com/<real owner>/<real repository>.git
```

12. When prompted for the clone directory, enter the real repository name generated from the current remote. The repository may have any name; never hardcode `obsidian-vault`:

```text
<real repository name>
```

Select or create that repository-named subfolder. Do not select `Vault Root`.

13. After a successful clone, fully close and reopen Obsidian.
14. After reopening, configure `Automatic` in this order: turn off `Split timers for automatic commit and sync`, set `Auto commit-and-sync interval (minutes)` to `0.5`, turn on `Auto commit-and-sync after stopping file edits`, and turn on `Pull on startup`.
15. Search Command Palette and run:

```text
Git: Pull
```

16. After creating a mobile test note, search and run:

```text
Git: Commit-and-sync
```

17. After the first `Git: Commit-and-sync` succeeds, fully close and reopen Obsidian. Edit the test note again, keep the app active, stop editing for 30–60 seconds, and verify GitHub receives an automatic commit without running another manual command.

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

To download Obsidian, search the device's app store for `Obsidian - Connected Notes`. All mobile operating systems use the same setup workflow; do not ask for the platform or output separate guides.

Never display the token value or ask the user to send it in chat. A token is shown in full only once and should be saved in the system password manager.

These values must come from the current user's GitHub login state, the current vault remote, and the GitHub API. Do not hard-code any example account, fixed email, fixed repository name, or author name in the skill. If real values cannot be read, stop and repair GitHub login or repository connection instead of letting the user copy another person's configuration.

## 2. Sync architecture and core logic

Explain that this is not Obsidian's official cloud sync. It is a Git workflow:

```text
Windows Obsidian vault
        ↕
GitHub private repository
        ↕
Mobile Obsidian vault
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

Complete these steps in the mobile browser. Keep every label bilingual and follow the page from top to bottom:

1. Open the GitHub token page automatically first. If it does not open, manually open <https://github.com/settings/personal-access-tokens/new>.
2. Sign in to the GitHub account that can access the private repository.
3. The page normally says `新建精细化个人访问令牌 / New fine-grained personal access token`.
4. `令牌名称 / Token name`: enter `Obsidian Mobile`.
5. `描述 / Description`: optional; enter `Obsidian 移动端同步 / Obsidian mobile sync` or leave it blank.
6. `资源所有者 / Resource owner`: select the real GitHub account that owns the private repository.
7. `有效期 / Expiration`: choose a finite expiration; create a replacement when it expires.
8. `仓库访问 / Repository access`: choose `仅选定的仓库 / Only select repositories`.
9. Open `选择仓库 / Select repositories` and select only the target Obsidian private repository.
10. Scroll to `权限 / Permissions` and remain on the `仓库 / Repository permissions` tab.
11. Select `添加权限 / Add permissions` and add both permissions from the same permission picker:
    - `内容 / Contents`: set to `读写 / Read and write`;
    - `提交状态 / Commit statuses`: add it when available and set it to `读写 / Read and write`.
12. Keep `元数据 / Metadata` at `只读 / Read-only`. GitHub normally adds it automatically.
13. Verify no extra repositories or permissions are granted.
14. Select `生成令牌 / Generate token`.
15. Copy it immediately and save it in the device's system password manager.

This token is the "key" users may refer to on mobile. GitHub cannot reveal a token after the page is closed. If lost, create a replacement and revoke the old token at <https://github.com/settings/personal-access-tokens>.

## 4. Download Obsidian and the Git plugin on mobile

### Install Obsidian

1. Search the device's app store for `Obsidian - Connected Notes` and install it.
2. Open Obsidian and select `仓库管理器 / Open vault manager`.
3. Select `新建仓库 / Create new vault`.
4. Enter `Obsidian Mobile` under `仓库名称 / Vault name`, then select `创建 / Create`.

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

## 5. Enter the nickname and key required for cloning

Before cloning, open `Settings -> Community plugins -> Git` and find `Authentication/commit author`. If the user says "nickname and key", map the terms like this:

```text
Username on your git server. E.g. your username on GitHub = GitHub login
Password/Personal access token = GitHub fine-grained token
```

1. Fill `Username on your git server. E.g. your username on GitHub` first, using the real GitHub login from the checklist.
2. Fill `Password/Personal access token` next, using the user's fine-grained token, not the GitHub account password.
3. These two fields must be completed before `Git: Clone an existing remote repo`.
4. Never place the token in a repository URL, note, or screenshot, and never ask the user to send the token in chat.

If this plugin version prompts for Username/Password inside the clone command, enter the same GitHub username and token in that prompt. Do not use the GitHub account password.

## 6. Clone the private repository from Obsidian Command Palette

1. Open Obsidian Command Palette. If its button moves, search the app for `Command palette`.
2. Search for the stable command `Git: Clone an existing remote repo`.
3. Paste the HTTPS `.git` clone URL from the checklist. Do not use the browser URL or SSH.
4. If prompted for the clone location, enter `cloneDirectoryName` from `mobile-setup-info.ps1`. This is the current remote's real repository name and may be any name. Select or create that repository-named subfolder; do not select `Vault Root` and never hardcode `obsidian-vault`.
5. At `Specify depth of clone. Leave empty for full clone.`, enter `1` and press the mobile keyboard `Enter / Return`. A shallow clone keeps the complete current files and omits only older commit history, reducing peak mobile memory use during clone.
6. Keep Obsidian active until `Cloned new repo.` and `Please restart Obsidian` appear. If the success message never appears, treat the clone as failed: stop, do not configure Automatic, and do not run Pull.
7. Fully close and reopen Obsidian and confirm Git remains enabled.
8. Enter Username, Token, Author name, and Author email again, then confirm desktop notes appear in the file list.

## 7. Configure Git plugin switches after restart

After clone and restart, go to:

```text
Settings
→ Community plugins
→ Git
```

Open `Automatic` first:

```text
Split timers for automatic commit and sync
Off

Auto commit-and-sync interval (minutes)
0.5

Auto commit-and-sync after stopping file edits
On

Pull on startup
On
```

Then scroll to `Authentication/commit author` and enter:

```text
Username on your git server
<real login from generated checklist>

Password/Personal access token
paste the token created by the user

Author name for commit
<real author name from generated checklist>

Author email for commit
<real noreply or verified email from generated checklist>
```

If the exact field names are not visible, search for `author`, `commit author`, or `email`. If `git author name/email not set` appears, these fields were not saved; enter them again in the cloned real vault and restart Obsidian.

Mobile operating systems may suspend Obsidian after screen lock, app switching, battery saving, or background restrictions. Background 0.5-minute sync is not guaranteed; manual commands before leaving are the reliable fallback.

## 8. Daily Git commands on mobile

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
2. After editing, keep Obsidian in the foreground for about 30 seconds or run `Git: Commit-and-sync` immediately.
3. Do not edit the same note on multiple devices at the same time.
4. Use dedicated test notes for sync tests; do not test deletion on real drafts.
5. Mobile automatic sync depends on foreground execution. Screen lock, background suspension, battery limits, and VPN/network changes can stop sync.
6. If `Request failed` appears, first check whether the phone browser can open GitHub and the private repository, then check VPN, token permissions, and network.
7. If a note is accidentally deleted, stop syncing on every device and use the accidental deletion recovery flow in `troubleshooting.md`.
8. With four devices, let only Windows and one main phone auto-commit by default. Other phones or backup endpoints should use manual Pull / Commit-and-sync.

## 10. Mobile acceptance test

### GitHub to phone

1. Create a uniquely named test note on Windows and wait for push.
2. Run `Git: Pull` on the phone.
3. Confirm identical filename and content.

### Phone to GitHub

1. Open the same test note from the file list.
2. Modify only its body; do not create a new note or rename it.
3. Run `Git: Commit-and-sync`.
4. Open the private repository link and confirm the first manual commit.
5. Fully close and reopen Obsidian, then edit the same test note body again.
6. Keep Obsidian active, stop editing for 30–60 seconds, do not run `Git: Commit-and-sync`, and confirm GitHub receives a second automatic commit.
7. Git status should be modified `M`. Added `A` means the phone created another path.

### GitHub back to Windows

Wait for the Windows clean-worktree pull or pull manually, then confirm the mobile content appears.

If any step fails, stop, preserve the error, and use `troubleshooting.md`. Do not repeatedly push or force-overwrite history.
