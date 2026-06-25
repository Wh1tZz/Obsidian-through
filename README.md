# Obsidian-through

随时随地在手机端 Obsidian 中写下一篇笔记，它都可以同步到电脑端 Obsidian 和 GitHub 私有仓库中。

Obsidian-through 会帮助完成整套同步环境的搭建，包括创建或连接 GitHub 私有仓库、上传现有笔记、配置 Windows 自动同步，以及指导手机端 Obsidian Git 连接到 GitHub。

你不需要学习复杂的 Git 命令，也不需要在不同教程之间反复查找配置方法。安装后，只需要说明你想实现 Obsidian 多端同步，工具就会按照完整流程进行配置、检查和问题修复。

---

## 它能做什么？

* 检查并安装 Git、GitHub CLI 等必要工具
* 打开 GitHub 登录授权页面
* 创建或连接 GitHub 私有笔记仓库
* 将电脑端现有 Obsidian 笔记上传到 GitHub
* 配置 Windows 自动提交、拉取和上传
* 守护 Windows 后台同步任务，异常停止后自动恢复
* 指导 iPhone / Android 安装和配置 Obsidian Git
* 解释 Pull、Commit、Push、Commit-and-sync 的区别
* 检查并修复常见的 Pull、Push、认证、网络和冲突问题
* 从 Git 历史恢复误删笔记
* 验证手机、电脑和 GitHub 是否可以正常双向同步

---

## 同步方式

```text
手机端 Obsidian
       ↕
GitHub 私有仓库
       ↕
电脑端 Obsidian
```

手机上记录的笔记，可以通过 GitHub 同步到电脑。

电脑上修改的内容，也可以上传到 GitHub，并同步回手机。

---

## 安装方法

请先确保电脑已经安装 Node.js 18 或更高版本。

推荐使用：

```bash
npx obsidian-through
```

查看可用命令：

```bash
npx obsidian-through help
```

常用命令：

```bash
npx obsidian-through login
npx obsidian-through publish --vault "C:\path\to\vault" --repo https://github.com/owner/private-vault.git --open
npx obsidian-through verify --vault "C:\path\to\vault"
npx obsidian-through mobile-info --vault "C:\path\to\vault" --open-token-page
```

如果当前运行环境不支持 npm 包安装，也可以直接把此 GitHub 仓库链接交给支持读取 GitHub 仓库的 AI 工具，让它使用仓库中的 `SKILL.md`、`scripts/` 和 `references/`。

---

## GitHub 连接优化

配置时不要反复手动拆分 owner、仓库名和 `.git` 地址。

可以直接提供 GitHub 仓库网址：

```text
https://github.com/owner/private-vault
```

或：

```text
https://github.com/owner/private-vault.git
```

然后运行：

```bash
npx obsidian-through publish --vault "C:\path\to\vault" --repo https://github.com/owner/private-vault.git --open
```

`--open` 会打开目标 GitHub 仓库页面或新建仓库页面，方便确认当前连接的是正确的私有仓库。

如果 GitHub 登录失败，先运行：

```bash
npx obsidian-through login
```

网络需要代理时：

```bash
npx obsidian-through login --proxy http://127.0.0.1:7890
```

登录过程中不需要把 GitHub 密码、验证码或 Token 发到聊天窗口。

---

## 使用方法

配置电脑端同步：

```text
使用 obsidian-through，帮我配置电脑端 Obsidian、GitHub 私有仓库和手机端 Obsidian 同步。
```

检查已有同步：

```text
使用 obsidian-through，帮我检查并修复 Obsidian Git 同步问题。
```

恢复误删笔记：

```text
使用 obsidian-through，帮我恢复误删的 Obsidian 笔记。
```

---

## 注意事项

* 笔记默认应上传到 GitHub 私有仓库
* 上传前必须确认本地笔记库路径和目标仓库
* 不要将 GitHub Token 发送到聊天窗口、笔记、截图或仓库 URL
* 手机端可能无法长期在后台自动运行同步
* 建议手机开始编辑前执行 Pull
* 编辑完成后执行 Commit-and-sync
* 不建议同时使用 Git 和 iCloud 同步同一个笔记库
* 尽量避免多台设备同时修改同一篇笔记
* 测试删除时使用测试笔记，不要直接测试正式稿

---

## 说明

Obsidian-through 不是新的 Obsidian 同步插件。

它是一个帮助搭建、检查和修复 Obsidian Git 同步环境的工作流。

实际的笔记同步由 Obsidian Git、GitHub 和本地 Git 完成，Obsidian-through 负责帮助正确完成整套配置流程。

---

# English Version

Write a note in Obsidian on your phone, then sync it to Obsidian on your computer and to a private GitHub repository.

Obsidian-through helps set up the complete synchronization environment: creating or connecting a private GitHub repository, uploading existing notes, configuring Windows automatic sync, and guiding mobile Obsidian Git setup.

You do not need to learn complex Git commands or combine multiple tutorials. After installation, describe the Obsidian sync you want, and the workflow can guide setup, verification, and repair.

---

## What can it do?

* Check and install Git, GitHub CLI, and required tools
* Open the GitHub web login flow
* Create or connect a private GitHub note repository
* Upload an existing desktop Obsidian vault to GitHub
* Configure automatic commit, pull, and push on Windows
* Watch and recover the Windows background sync task
* Guide Obsidian Git setup on iPhone / Android
* Explain Pull, Commit, Push, and Commit-and-sync
* Diagnose Pull, Push, authentication, network, and conflict issues
* Recover accidentally deleted notes from Git history
* Verify two-way sync across phone, computer, and GitHub

---

## Sync model

```text
Mobile Obsidian
       ↕
Private GitHub repository
       ↕
Desktop Obsidian
```

---

## Installation

Make sure Node.js 18 or newer is installed.

Recommended:

```bash
npx obsidian-through
```

Show commands:

```bash
npx obsidian-through help
```

Common commands:

```bash
npx obsidian-through login
npx obsidian-through publish --vault "C:\path\to\vault" --repo https://github.com/owner/private-vault.git --open
npx obsidian-through verify --vault "C:\path\to\vault"
npx obsidian-through mobile-info --vault "C:\path\to\vault" --open-token-page
```

If npm package installation is not available in the current environment, provide this GitHub repository link to any AI tool that can read repositories and ask it to use `SKILL.md`, `scripts/`, and `references/`.

---

## GitHub connection

Do not repeatedly split owner, repository name, and `.git` URL by hand.

Use the repository URL directly:

```text
https://github.com/owner/private-vault
```

or:

```text
https://github.com/owner/private-vault.git
```

Then run:

```bash
npx obsidian-through publish --vault "C:\path\to\vault" --repo https://github.com/owner/private-vault.git --open
```

`--open` opens the target GitHub repository page or new repository page so the user can confirm the correct private repository.

If GitHub login fails, run:

```bash
npx obsidian-through login
```

If the network needs a proxy:

```bash
npx obsidian-through login --proxy http://127.0.0.1:7890
```

Never send GitHub passwords, verification codes, or tokens through chat.

---

## Notes

* Use a private GitHub repository for notes
* Confirm the local vault path and target repository before upload
* Never paste GitHub tokens into chat, notes, screenshots, or repository URLs
* Mobile automatic sync may not run continuously in the background
* Pull before editing on mobile
* Commit-and-sync after editing on mobile
* Do not use Git and iCloud to sync the same vault
* Avoid editing the same note on multiple devices at the same time
* Test deletion with test notes, not important drafts
