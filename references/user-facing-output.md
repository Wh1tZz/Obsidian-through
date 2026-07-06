# 中文版

## 0. 端到端用户输出模板

当用户要求配置、演示或模拟 Obsidian-through 的完整流程时，按本模板输出。所有 `<真实...>` 值必须由脚本、GitHub API、Git remote 或 Obsidian vault 检查动态替换，不能把占位符作为最终用户可复制内容。

主流程中只把两个网址作为 Markdown 可点击链接输出：

- GitHub 登录页：[https://github.com/login/device](https://github.com/login/device)
- GitHub Token 创建页：[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

仓库页面、clone URL、vault 路径、命令名、插件字段名等使用代码块输出，方便复制和核对。

## 1. PC 端开始

```text
我先帮你配置 PC 端 Obsidian 和 GitHub 私有仓库同步。这个过程会自动检查 Git、GitHub CLI、GitHub 登录状态，并把你的本地 Obsidian vault 连接到 GitHub 私有仓库。
```

正在检查环境：

```text
Git：<已安装 / 已自动安装 / 需要人工处理>
GitHub CLI：<已安装 / 已自动安装 / 需要人工处理>
GitHub 登录状态：<已登录 / 需要登录>
```

接下来我会打开 GitHub 官方授权页面。请只在浏览器里登录，不要把密码、验证码或 Token 发到聊天窗口。

[https://github.com/login/device](https://github.com/login/device)

登录完成后继续检测账号：

```text
GitHub 登录账号
<真实 GitHub username>
```

正在查找 Obsidian 笔记库：

```text
电脑端 Obsidian vault 路径
<真实本地 vault 绝对路径>
```

准备连接的 GitHub 私有仓库：

```text
GitHub 私有仓库
https://github.com/<真实 username>/<真实仓库名>
```

```text
Git remote clone URL
https://github.com/<真实 username>/<真实仓库名>.git
```

如果用户还没有私有仓库，创建新的私有仓库并上传本地笔记。如果用户已经有私有仓库，连接现有仓库并安全合并本地笔记和远端内容，不强制覆盖。

## 2. PC 端同步方式说明

```text
PC 端不需要手动填写 Token。它通过 GitHub CLI / Git Credential Manager 完成网页登录授权。
```

PC 端同步主要由 Windows 隐藏事件监听器完成，不靠 Obsidian Git 插件反复弹窗推送：

```text
监听范围：Obsidian vault 文件夹
触发事件：新增、修改、删除、重命名
等待时间：停止编辑约 15 秒
执行动作：git add -> git commit -> git pull --rebase -> git push
后台拉取：工作区干净时每 30 秒静默拉取 GitHub 更新
守护任务：监听器异常退出后自动重启
```

关闭 Windows Obsidian Git 插件里容易造成弹窗和冲突的自动提交、周期自动拉取和普通通知。同步主要交给 Windows 监听器完成。

PC 端配置完成后要求用户测试：

```text
测试文件名
Windows 同步测试
```

```text
测试正文
这是一条 Windows 到 GitHub 的同步测试。
```

让用户在 PC 端 Obsidian 新建这篇测试笔记，停止编辑并等待 15 到 30 秒，然后刷新 GitHub 仓库页面，确认测试笔记是否出现：

```text
GitHub 私有仓库
https://github.com/<真实 username>/<真实仓库名>
```

只有用户确认 GitHub 上出现测试笔记后，才继续手机端配置。

## 3. 手机端配置

```text
接下来配置手机端 Obsidian。请先在手机上安装 Obsidian，然后在 Obsidian 中安装并启用 Git / Obsidian Git 插件。
```

如果插件链接不能跳转，就在 Obsidian 里打开：

```text
设置 -> 第三方插件 -> 浏览
```

搜索：

```text
Git
```

安装并启用。

## 4. 创建手机 Token

自动打开 GitHub Token 创建页面。如果没有弹出，请用户手动打开：

[https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

在 GitHub 页面里这样设置：

```text
Token name：Obsidian Mobile
Expiration：建议 1 年
Resource owner：<真实 GitHub username>
Repository access：Only select repositories
选择仓库：<真实 Obsidian 私有仓库>
添加权限：Contents / 内容，Read and write / 读写
Metadata / 元数据：Read-only / 只读
```

然后点击：

```text
Generate token
```

生成后立刻复制保存。Token 只显示一次，不要让用户发到聊天，不要让用户截图。

## 5. 填写手机 Git 插件认证

回到手机 Obsidian：

```text
设置 -> 第三方插件 -> Git
```

找到：

```text
Authentication/commit author
```

先填写：

```text
Username on your git server. E.g. your username on GitHub
<真实 GitHub username>
```

然后填写：

```text
Password/Personal access token
粘贴刚生成的 Token
```

说明：这里的 Password 不是 GitHub 登录密码，是 GitHub Token。这两个必须先填，再克隆私有仓库。

## 6. 手机端克隆仓库

打开 Obsidian 命令面板，搜索并执行：

```text
Git: Clone existing remote repo
```

仓库地址填写：

```text
https://github.com/<真实 username>/<真实仓库名>.git
```

如果询问：

```text
Branch
main
```

如果询问：

```text
Vault Root
<建议填写仓库名或新的空文件夹名>
```

如果询问：

```text
Specify depth of clone
留空；不能留空就填 1
```

如果出现：

```text
Invalid depth. Aborting clone.
```

说明 depth 填错了，重新克隆，depth 留空或填 1。

克隆完成后，完全关闭并重新打开 Obsidian，然后打开刚刚克隆出来的 vault。

## 7. 手机端提交设置

进入克隆后的 vault：

```text
设置 -> 第三方插件 -> Git
```

填写：

```text
Author name for commit
<真实 GitHub username>
```

```text
Author email for commit
<真实 GitHub noreply 邮箱>
```

自动同步建议：

```text
Split timers for automatic commit and sync：关闭
Auto commit-and-sync interval (minutes)：1
Auto commit-and-sync after stopping file edits：开启
Pull on startup：如果有就开启
Pull before push：如果有就开启
Auto pull interval：如果有就填 1
```

如果手机端没有 `Pull on startup` 或 `Pull before push`，不用卡住，日常用命令面板操作即可。

## 8. 最终测试

手机端先执行：

```text
Git: Pull
```

说明：这一步是从 GitHub 下载最新内容到手机，不会上传手机修改。

然后打开一篇已有测试笔记，修改正文，再执行：

```text
Git: Commit-and-sync
```

说明：这一步才会把手机修改上传到 GitHub。

刷新 GitHub 仓库，确认手机修改出现：

```text
GitHub 私有仓库
https://github.com/<真实 username>/<真实仓库名>
```

最后回到 PC 端，等待 Windows 监听器静默拉取，或者重启 Obsidian 触发拉取。PC、GitHub、手机三边内容一致，才说明三端同步完成。

## 9. 日常使用

```text
PC 端：直接写，Windows 监听器自动同步
手机端：写之前 Git: Pull
手机端：写完后 Git: Commit-and-sync
GitHub：作为中转中心和版本历史
```

---

# English Version

Use the same sequence for English-speaking users. Replace every `<real ...>` placeholder with values from scripts, GitHub API, Git remote, or Obsidian vault checks.

Only these two URLs should be Markdown clickable links in the main flow:

- GitHub login page: [https://github.com/login/device](https://github.com/login/device)
- GitHub token creation page: [https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

Keep repository pages, clone URLs, vault paths, command names, and plugin field names in fenced copy blocks.

Daily summary:

```text
PC: write normally; the Windows watcher syncs automatically.
Phone: run Git: Pull before writing.
Phone: run Git: Commit-and-sync after writing.
GitHub: acts as the transfer hub and version history.
```
