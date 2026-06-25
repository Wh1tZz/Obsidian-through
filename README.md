# Obsidian-through

Obsidian-through is a reusable workflow skill for setting up private Obsidian synchronization through GitHub.

It helps connect a Windows Obsidian vault, a private GitHub repository, and Obsidian on iPhone or Android. It is not a new sync service or Obsidian plugin. The actual synchronization is handled by Git, GitHub, and Obsidian Git; this skill provides the setup, verification, repair, and recovery workflow.

---

## What It Solves

* Set up a private GitHub repository for an Obsidian vault
* Upload an existing Windows Obsidian vault safely
* Configure Windows event-based automatic sync
* Guide mobile Obsidian Git setup step by step
* Explain Pull, Commit, Push, and Commit-and-sync clearly
* Keep device-specific Obsidian Git settings local
* Diagnose failed Pull, Push, authentication, network, and conflict issues
* Recover accidentally deleted notes from Git history
* Provide safer guidance for three-device and four-device sync

---

## Sync Model

```text
Windows Obsidian vault
        ↕
Private GitHub repository
        ↕
iPhone / Android Obsidian vault
```

Each device keeps a local copy of the vault. GitHub acts as the private transfer hub.

---

## Installation

Install from a GitHub repository:

```bash
npx skills add <github-owner>/Obsidian-through -g
```

Replace `<github-owner>` with the repository owner that hosts this skill.

---

## Usage

Ask your skill-enabled AI tool to use `obsidian-through` for one of these tasks:

```text
Use obsidian-through to configure Obsidian sync across Windows, GitHub, and my phone.
```

```text
Use obsidian-through to inspect and repair my Obsidian Git sync.
```

```text
Use obsidian-through to recover an accidentally deleted Obsidian note.
```

The workflow reads the current user's GitHub login, vault path, repository remote, and repository visibility at runtime. It must not reuse another user's username, email, repository name, local path, token, or previous chat context.

---

## Notes

* Use a private GitHub repository for personal notes.
* Never paste GitHub tokens into chat, notes, screenshots, or repository URLs.
* Do not sync the same vault with both Git and iCloud.
* Pull before editing on mobile.
* Commit-and-sync after editing on mobile.
* Avoid editing the same note on multiple devices at the same time.
* Test synchronization with dedicated test notes, not important drafts.

---

# 中文版

Obsidian-through 是一个可复用的工作流 Skill，用于通过 GitHub 搭建 Obsidian 私有同步。

它可以帮助连接 Windows 端 Obsidian 笔记库、GitHub 私有仓库，以及 iPhone 或 Android 上的 Obsidian。它不是新的同步服务，也不是新的 Obsidian 插件。真正的同步由 Git、GitHub 和 Obsidian Git 完成；这个 Skill 负责提供配置、验证、修复和恢复流程。

---

## 解决什么问题

* 创建 Obsidian 私有 GitHub 仓库
* 安全上传 Windows 端已有笔记库
* 配置 Windows 事件触发自动同步
* 按步骤指导手机端 Obsidian Git 配置
* 清楚解释 Pull、Commit、Push、Commit-and-sync
* 让不同设备的 Obsidian Git 设置保持本地独立
* 排查 Pull、Push、认证、网络和冲突问题
* 从 Git 历史恢复误删笔记
* 为三端和四端同步提供更稳妥的使用策略

---

## 同步模型

```text
Windows Obsidian 笔记库
        ↕
GitHub 私有仓库
        ↕
iPhone / Android Obsidian 笔记库
```

每台设备都有一份本地笔记库。GitHub 作为私有中转仓库。

---

## 安装

从 GitHub 仓库安装：

```bash
npx skills add <github-owner>/Obsidian-through -g
```

将 `<github-owner>` 替换为托管此 Skill 的仓库所有者。

---

## 使用

在支持 Skill 的 AI 工具中调用 `obsidian-through`：

```text
使用 obsidian-through，帮我配置 Windows、GitHub 和手机端 Obsidian 同步。
```

```text
使用 obsidian-through，帮我检查并修复 Obsidian Git 同步。
```

```text
使用 obsidian-through，帮我恢复误删的 Obsidian 笔记。
```

这个工作流必须在运行时读取当前用户的 GitHub 登录、笔记库路径、远端仓库和仓库可见性。不得复用其他用户的用户名、邮箱、仓库名、本地路径、Token 或历史对话上下文。

---

## 注意事项

* 个人笔记应使用 GitHub 私有仓库。
* 不要把 GitHub Token 发到聊天、笔记、截图或仓库 URL 中。
* 不要同时用 Git 和 iCloud 同步同一个 vault。
* 手机端编辑前先 Pull。
* 手机端编辑后执行 Commit-and-sync。
* 尽量避免多台设备同时编辑同一篇笔记。
* 测试同步时使用专门测试笔记，不要拿重要草稿测试。
