# Obsidian-through

随时随地在 iPhone 的 Obsidian 中写下一篇笔记，它都可以同步到 PC 端的 Obsidian 和 GitHub 私有仓库中。

Obsidian-through Skill 会帮你完成整个同步环境的搭建，包括创建 GitHub 私有仓库、上传现有笔记、配置电脑自动同步，以及指导你将 iPhone 上的 Obsidian 连接到 GitHub。

你不需要学习复杂的 Git 命令，也不需要在不同教程之间反复查找配置方法。安装这个 Skill 后，只需要告诉你的 Agent 你想实现 Obsidian 多端同步，它就会按照完整流程帮助你进行配置、检查和问题修复。

---

## 它能做什么？

* 创建 GitHub 私有笔记仓库
* 将 PC 端现有的 Obsidian 笔记上传到 GitHub
* 配置 Windows 自动提交、拉取和上传
* 指导 iPhone 安装和配置 Obsidian Git
* 让手机、电脑和 GitHub 保持同步
* 检查并修复常见的 Pull、Push 和认证问题
* 验证笔记是否可以正常双向同步

---

## 同步方式

```text
iPhone Obsidian
       ↕
GitHub 私有仓库
       ↕
PC 端 Obsidian
```

在 iPhone 上记录的笔记，可以通过 GitHub 同步到电脑。

在电脑上修改的内容，也可以上传到 GitHub，并同步回 iPhone。

---

## 安装方法

请先确保电脑已经安装 Node.js 18 或更高版本。

在终端中运行：

```bash
npx skills add Wh1tZz/Obsidian-through -g
```

安装完成后，在支持 Agent Skills 的 Agent 中使用。

---

## 使用方法

安装完成后，直接告诉你的 Agent：

```text
使用 obsidian-through，帮我配置 PC、GitHub 私有仓库和 iPhone Obsidian 三端同步。
```

Agent 会按照以下流程帮助你完成配置：

```text
检查电脑环境
→ 登录 GitHub
→ 创建私有仓库
→ 上传现有笔记
→ 配置 PC 自动同步
→ 指导 iPhone 连接 GitHub
→ 测试双向同步
```

已经配置过但无法正常同步时，也可以告诉你的 Agent：

```text
使用 obsidian-through，帮我检查并修复 Obsidian 同步问题。
```

---

## 注意事项

* 笔记默认上传到 GitHub 私有仓库
* 上传前请确认本地笔记库路径和仓库名称
* 不要将 GitHub Token 发送到聊天窗口
* iPhone 可能无法长期在后台自动运行同步
* 建议在手机开始编辑前执行一次 Pull
* 编辑完成后执行 Commit-and-sync
* 不建议同时使用 Git 和 iCloud 同步同一个笔记库
* 尽量避免在手机和电脑上同时修改同一篇笔记

---

## 说明

Obsidian-through 不是新的 Obsidian 同步插件。

它是一个帮助 Agent 搭建、检查和修复 Obsidian Git 同步环境的 Skill。

实际的笔记同步由 Obsidian Git 和 GitHub 完成，Obsidian-through 负责帮助你的 Agent 正确完成整套配置流程。

---

# English Version

Write a note in Obsidian on your iPhone wherever you are, then sync it to Obsidian on your PC and to a private GitHub repository.

The Obsidian-through Skill helps set up the complete synchronization environment. It can create a private GitHub repository, upload your existing notes, configure automatic synchronization on your computer, and guide you through connecting Obsidian on your iPhone to GitHub.

You do not need to learn complicated Git commands or piece together instructions from multiple tutorials. After installing this Skill, simply tell your Agent that you want multi-device Obsidian synchronization. It will guide you through setup, verification, and troubleshooting using a complete workflow.

---

## What can it do?

* Create a private GitHub repository for your notes
* Upload an existing Obsidian vault from your PC to GitHub
* Configure automatic commit, pull, and push on Windows
* Guide the installation and configuration of Obsidian Git on iPhone
* Keep your phone, computer, and GitHub repository synchronized
* Diagnose and fix common Pull, Push, and authentication problems
* Verify that notes synchronize correctly in both directions

---

## Synchronization flow

```text
iPhone Obsidian
       ↕
Private GitHub repository
       ↕
PC Obsidian
```

Notes written on your iPhone can be synchronized to your computer through GitHub.

Changes made on your computer can also be pushed to GitHub and synchronized back to your iPhone.

---

## Installation

Make sure Node.js 18 or newer is installed on your computer.

Run this command in a terminal:

```bash
npx skills add Wh1tZz/Obsidian-through -g
```

After installation, use the Skill with any Agent that supports Agent Skills.

---

## Usage

After installation, tell your Agent:

```text
Use obsidian-through to configure synchronization across my PC, a private GitHub repository, and Obsidian on my iPhone.
```

The Agent will guide you through this workflow:

```text
Check the computer environment
→ Sign in to GitHub
→ Create a private repository
→ Upload existing notes
→ Configure automatic PC synchronization
→ Connect the iPhone to GitHub
→ Test two-way synchronization
```

If synchronization has already been configured but is not working, tell your Agent:

```text
Use obsidian-through to inspect and repair my Obsidian synchronization.
```

---

## Important notes

* Notes are uploaded to a private GitHub repository by default
* Confirm the local vault path and repository name before uploading
* Never send your GitHub Token through a chat window
* iPhone may not keep synchronization running continuously in the background
* Run Pull before you start editing on your phone
* Run Commit-and-sync after you finish editing
* Do not use Git and iCloud to synchronize the same vault
* Avoid editing the same note on your phone and computer at the same time

---

## About

Obsidian-through is not a new Obsidian synchronization plugin.

It is a Skill that helps an Agent set up, inspect, and repair an Obsidian Git synchronization environment.

The actual note synchronization is handled by Obsidian Git and GitHub. Obsidian-through helps your Agent configure the complete workflow correctly.
