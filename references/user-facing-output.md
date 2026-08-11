# 中文版

## 输出规则

- 使用“去哪里 → 点什么 → 填什么”。
- 每步一句话，值放代码块。
- 所有 `<真实...>` 必须替换为脚本生成值。
- 主流程不解释原理，不预先输出故障处理。

## 1. 电脑端

运行：

```text
npx obsidian-through
```

程序自动安装所需环境并打开 GitHub 登录页：

[https://github.com/login/device](https://github.com/login/device)

登录完成后继续，输出：

```text
GitHub 账号：<真实账号>
Obsidian 路径：<真实 vault 绝对路径>
私有仓库：<真实 owner/repository>
仓库页面：<真实 repository URL>
克隆地址：<真实 HTTPS .git URL>
```

配置 Windows 监听器并验证后，让用户在 PC Obsidian 新建测试笔记：

```text
Obsidian-through-PC-test.md
```

GitHub 出现该笔记后进入移动端。

Windows 检测结果显示：

```text
系统：Windows
同步方式：Windows 隐藏事件监听器
停止编辑约 15 秒后推送；每 30 秒静默拉取
```

macOS 检测结果显示：

```text
系统：macOS
同步方式：Obsidian Git
Split timers for automatic commit and sync：关闭
Auto commit-and-sync interval (minutes)：0.5
Auto commit-and-sync after stopping file edits：开启
Pull on startup：开启
```

macOS 首次运行 `Git: Commit-and-sync` 后完全重启 Obsidian，再测试 30–60 秒自动同步。macOS 不填写移动端 Token，也不安装 Windows 监听器。

## 2. 移动端新建仓库

```text
打开 Obsidian
→ 仓库管理器 / Open vault manager
→ 新建仓库 / Create new vault
→ 仓库名称 / Vault name：Obsidian Mobile
→ 创建 / Create
```

## 3. 安装 Git 插件

```text
设置 / Settings
→ 第三方插件 / Community plugins
→ 浏览 / Browse
→ 搜索 Git
→ 安装 / Install
→ 启用 / Enable
```

## 4. 创建 Token

打开：

[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

按页面顺序填写：

```text
令牌名称 / Token name
Obsidian Mobile

描述 / Description
Obsidian 移动端同步 / Obsidian mobile sync（选填）

资源所有者 / Resource owner
<真实 GitHub 账号>

有效期 / Expiration
1 year

仓库访问 / Repository access
仅选定的仓库 / Only select repositories

选择仓库 / Select repositories
<真实私有仓库>

添加权限 / Add permissions
内容 / Contents：读写 / Read and write
提交状态 / Commit statuses：读写 / Read and write（页面有就添加）
元数据 / Metadata：只读 / Read-only

生成令牌 / Generate token
```

## 5. 填写克隆认证

```text
设置 / Settings
→ 第三方插件 / Community plugins
→ Git
```

找到 `Authentication/commit author`：

```text
Username on your git server
<真实 GitHub 账号>

Password/Personal access token
粘贴 Token
```

## 6. 克隆仓库

打开命令面板，运行：

```text
Git: Clone an existing remote repo
```

复制仓库地址：

```text
<真实 HTTPS .git 克隆地址>
```

克隆位置填写下面的真实仓库名。仓库名可以是任意名称，这里必须使用当前用户的实际仓库名，不选择 `Vault Root`：

```text
<真实仓库名>
```

出现 `Specify depth of clone` 时，输入：

```text
1
```

看到以下提示后重启 Obsidian：

```text
Cloned new repo.
Please restart Obsidian
```

只有看到以上提示才进入下一步；未看到时停止，不设置 `Automatic`，也不运行 `Git: Pull`。

## 7. 重启后设置

重启后进入：

```text
设置 / Settings
→ 第三方插件 / Community plugins
→ Git
```

先进入 `Automatic`：

```text
Split timers for automatic commit and sync：关闭
Auto commit-and-sync interval (minutes)：0.5
Auto commit-and-sync after stopping file edits：开启
Pull on startup：开启
```

再往下找到 `Authentication/commit author`：

```text
Username on your git server：<真实 GitHub 账号>
Password/Personal access token：粘贴 Token
Author name for commit：<真实作者名>
Author email for commit：<真实 noreply 邮箱>
```

## 8. 测试

打开命令面板，运行：

```text
Git: Pull
```

确认 PC 测试笔记出现，然后修改正文。

再次打开命令面板，运行：

```text
Git: Commit-and-sync
```

确认首次提交成功后，完全关闭并重新打开 Obsidian。再修改测试笔记，保持应用前台并停止编辑 30–60 秒，不再运行手动命令，检查 GitHub 是否自动更新，再检查 PC Obsidian。

## 9. 日常使用

编辑前打开命令面板，运行：

```text
Git: Pull
```

编辑笔记。离开应用前打开命令面板，运行：

```text
Git: Commit-and-sync
```

---

# English Version

## Output rules

- Use “where → click → enter”.
- Keep each step to one sentence and put values in code blocks.
- Replace every `<real ...>` value with script output.
- Do not explain concepts or troubleshooting in the main flow.

## 1. Desktop

Run:

```text
npx obsidian-through
```

The installer prepares the environment and opens:

[https://github.com/login/device](https://github.com/login/device)

After login, show:

```text
GitHub account: <real login>
Obsidian path: <real absolute vault path>
Private repository: <real owner/repository>
Repository page: <real repository URL>
Clone URL: <real HTTPS .git URL>
```

Install and verify the Windows watcher, then ask the user to create:

```text
Obsidian-through-PC-test.md
```

Continue to mobile after the note appears on GitHub.

On Windows, show:

```text
System: Windows
Sync: hidden Windows event watcher
Push about 15 seconds after edits stop; silent Pull every 30 seconds
```

On macOS, show:

```text
System: macOS
Sync: Obsidian Git
Split timers for automatic commit and sync: Off
Auto commit-and-sync interval (minutes): 0.5
Auto commit-and-sync after stopping file edits: On
Pull on startup: On
```

After the first manual `Git: Commit-and-sync` on macOS, restart Obsidian and verify automatic sync after 30–60 seconds. Do not request the mobile token or install the Windows watcher on macOS.

## 2. Create the mobile vault

```text
Open Obsidian
→ Open vault manager / 仓库管理器
→ Create new vault / 新建仓库
→ Vault name / 仓库名称: Obsidian Mobile
→ Create / 创建
```

## 3. Install Git

```text
Settings / 设置
→ Community plugins / 第三方插件
→ Browse / 浏览
→ Search Git
→ Install / 安装
→ Enable / 启用
```

## 4. Create a token

Open:

[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

Fill in page order:

```text
Token name / 令牌名称: Obsidian Mobile
Description / 描述: Obsidian mobile sync / Obsidian 移动端同步 (optional)
Resource owner / 资源所有者: <real GitHub login>
Expiration / 有效期: 1 year
Repository access / 仓库访问: Only select repositories / 仅选定的仓库
Select repositories / 选择仓库: <real private repository>
Contents / 内容: Read and write / 读写
Commit statuses / 提交状态: Read and write / 读写 (when available)
Metadata / 元数据: Read-only / 只读
Generate token / 生成令牌
```

## 5. Enter clone authentication

```text
Settings → Community plugins → Git
```

Under `Authentication/commit author`:

```text
Username on your git server: <real GitHub login>
Password/Personal access token: paste token
```

## 6. Clone

Run from Command Palette:

```text
Git: Clone an existing remote repo
```

Copy the repository URL:

```text
<real HTTPS .git clone URL>
```

For the clone location, enter the real repository name below. A repository may have any name; use the current user's actual repository name and do not select `Vault Root`:

```text
<real repository name>
```

At `Specify depth of clone`, enter:

```text
1
```

Restart after:

```text
Cloned new repo.
Please restart Obsidian
```

Continue only after this message appears. Otherwise stop: do not configure `Automatic` or run `Git: Pull`.

## 7. Configure after restart

After restarting, go to:

```text
Settings
→ Community plugins
→ Git
```

Open `Automatic` first:

```text
Split timers for automatic commit and sync: Off
Auto commit-and-sync interval (minutes): 0.5
Auto commit-and-sync after stopping file edits: On
Pull on startup: On
```

Then scroll to `Authentication/commit author`:

```text
Username on your git server: <real GitHub login>
Password/Personal access token: paste token
Author name for commit: <real author name>
Author email for commit: <real noreply email>
```

## 8. Test

Open Command Palette and run:

```text
Git: Pull
```

Confirm the PC test note appears, then edit its body.

Open Command Palette again and run:

```text
Git: Commit-and-sync
```

After the first sync succeeds, fully close and reopen Obsidian. Edit the test note again, keep the app active, stop editing for 30–60 seconds, and do not run another manual command. Check that GitHub updates automatically, then check PC Obsidian.

## 9. Daily use

Before editing, open Command Palette and run:

```text
Git: Pull
```

Edit notes. Before leaving the app, open Command Palette and run:

```text
Git: Commit-and-sync
```
