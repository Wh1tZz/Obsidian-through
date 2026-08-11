# 中文版

## macOS 电脑端

1. 运行 `npx obsidian-through`。CLI 检测到 `darwin` 后调用 `scripts/setup-macos.sh`。
2. 脚本检查 Git、GitHub CLI 和 Obsidian vault。缺少 Git 时打开 Apple Command Line Tools 安装；缺少 GitHub CLI 时通过 Homebrew 安装。
3. GitHub 未登录时运行网页授权。不要要求用户在聊天中发送密码、验证码或 Token。
4. 自动读取 `~/Library/Application Support/obsidian/obsidian.json` 定位 vault；定位失败时才要求 `--vault`。
5. 创建或连接 GitHub 私有仓库，安全合并本地与远端，禁止强推。
6. 配置 Obsidian Git：

```text
Split timers for automatic commit and sync：关闭
Auto commit-and-sync interval (minutes)：0.5
Auto commit-and-sync after stopping file edits：开启
Pull on startup：开启
```

7. 完全关闭并重新打开 Obsidian，运行一次 `Git: Commit-and-sync`。再次重启后修改测试笔记，保持应用打开 30–60 秒，确认 GitHub 自动更新。
8. macOS 不安装 Windows 事件监听器、Watchdog 或计划任务，也不填写移动端 Personal Access Token。

---

# English Version

## macOS desktop

1. Run `npx obsidian-through`. On `darwin`, the CLI invokes `scripts/setup-macos.sh`.
2. The script checks Git, GitHub CLI, and the Obsidian vault. Missing Git opens Apple Command Line Tools; missing GitHub CLI is installed through Homebrew.
3. Authenticate GitHub in the browser. Never request passwords, codes, or tokens in chat.
4. Detect the vault from `~/Library/Application Support/obsidian/obsidian.json`; request `--vault` only if detection fails.
5. Create or connect the private repository and safely merge local and remote history. Never force-push.
6. Configure Obsidian Git with split timers off, interval `0.5`, sync-after-edit on, and startup Pull on.
7. Restart Obsidian, run one manual `Git: Commit-and-sync`, restart again, edit a test note, keep the app open for 30–60 seconds, and verify the automatic GitHub update.
8. Do not install Windows scheduled tasks or request the mobile personal access token on macOS.
