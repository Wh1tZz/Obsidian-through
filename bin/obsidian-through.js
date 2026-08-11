#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const path = require("node:path");

const root = path.resolve(__dirname, "..");

function detectedPlatform() {
  if (
    process.env.OBSIDIAN_THROUGH_TEST_MODE === "1" &&
    process.env.OBSIDIAN_THROUGH_TEST_PLATFORM
  ) {
    return process.env.OBSIDIAN_THROUGH_TEST_PLATFORM;
  }
  return process.platform;
}

function printUsage() {
  console.log(`Obsidian-through

Usage:
  npx obsidian-through
  npx obsidian-through setup [--vault <path>] [--repo <github-url-or-owner/name>] [--yes] [--open]
  npx obsidian-through help
  npx obsidian-through login [--proxy http://127.0.0.1:7890]
  npx obsidian-through publish --vault <path> --repo <github-url-or-owner/name> [--open]
  npx obsidian-through verify --vault <path> [--recovery-probe]
  npx obsidian-through mobile-info --vault <path> [--open-token-page]
  npx obsidian-through platform

Examples:
  npx obsidian-through
  npx obsidian-through setup --vault "<vault-path>" --repo owner/private-vault --open
  npx obsidian-through login
  npx obsidian-through publish --vault "<vault-path>" --repo https://github.com/owner/private-vault.git --open
  npx obsidian-through verify --vault "<vault-path>" --recovery-probe
`);
}

function valueAfter(args, name) {
  const index = args.indexOf(name);
  if (index === -1) return "";
  return args[index + 1] || "";
}

function hasFlag(args, name) {
  return args.includes(name);
}

function ps(script, scriptArgs) {
  const command = "powershell.exe";
  const fullScript = path.join(root, "scripts", script);
  const result = spawnSync(command, ["-ExecutionPolicy", "Bypass", "-File", fullScript, ...scriptArgs], {
    stdio: "inherit",
    windowsHide: false
  });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  process.exit(result.status ?? 0);
}

function sh(script, scriptArgs) {
  const fullScript = path.join(root, "scripts", script);
  const result = spawnSync("bash", [fullScript, ...scriptArgs], {
    stdio: "inherit"
  });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  process.exit(result.status ?? 0);
}

function nodeScript(script, scriptArgs) {
  const fullScript = path.join(root, "scripts", script);
  const result = spawnSync(process.execPath, [fullScript, ...scriptArgs], {
    stdio: "inherit"
  });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  process.exit(result.status ?? 0);
}

function platformWorkflow(platform) {
  if (platform === "win32") return "windows-event-watcher";
  if (platform === "darwin") return "macos-obsidian-git";
  return "unsupported";
}

function normalizeRepo(repo) {
  if (!repo) return "";
  if (/^https:\/\/github\.com\/[^/]+\/[^/]+\.git\/?$/.test(repo)) return repo.replace(/\/$/, "");
  if (/^https:\/\/github\.com\/[^/]+\/[^/]+\/?$/.test(repo)) return `${repo.replace(/\/$/, "")}.git`;
  if (/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo)) return `https://github.com/${repo}.git`;
  return repo;
}

const args = process.argv.slice(2);
let command = args[0] || "setup";
let rest = args.slice(1);
if (args[0] && args[0].startsWith("-") && args[0] !== "--help" && args[0] !== "-h") {
  command = "setup";
  rest = args;
}

if (command === "help" || command === "--help" || command === "-h") {
  printUsage();
  process.exit(0);
}

if (command === "platform") {
  const platform = detectedPlatform();
  console.log(JSON.stringify({ platform, workflow: platformWorkflow(platform) }, null, 2));
  process.exit(platformWorkflow(platform) === "unsupported" ? 1 : 0);
}

if (command === "setup") {
  if (hasFlag(rest, "--help") || hasFlag(rest, "-h")) {
    printUsage();
    process.exit(0);
  }
  const vault = valueAfter(rest, "--vault");
  const repo = normalizeRepo(valueAfter(rest, "--repo"));
  const proxy = valueAfter(rest, "--proxy");
  const debounce = valueAfter(rest, "--debounce-seconds");
  const pullInterval = valueAfter(rest, "--pull-interval-seconds");
  const platform = detectedPlatform();
  const workflow = platformWorkflow(platform);
  if (hasFlag(rest, "--dry-run")) {
    console.log(JSON.stringify({ platform, workflow, vault, repositoryUrl: repo }, null, 2));
    process.exit(workflow === "unsupported" ? 1 : 0);
  }
  if (platform === "win32") {
    const psArgs = [];
    if (vault) psArgs.push("-VaultPath", vault);
    if (repo) psArgs.push("-RepositoryUrl", repo);
    if (proxy) psArgs.push("-Proxy", proxy);
    if (debounce) psArgs.push("-DebounceSeconds", debounce);
    if (pullInterval) psArgs.push("-PullIntervalSeconds", pullInterval);
    if (hasFlag(rest, "--install-if-missing")) psArgs.push("-InstallIfMissing");
    if (hasFlag(rest, "--open")) psArgs.push("-OpenRepositoryPage");
    if (hasFlag(rest, "--yes") || hasFlag(rest, "-y")) psArgs.push("-Yes");
    ps("setup-windows.ps1", psArgs);
  }
  if (platform === "darwin") {
    const shArgs = [];
    if (vault) shArgs.push("--vault", vault);
    if (repo) shArgs.push("--repo", repo);
    if (hasFlag(rest, "--open")) shArgs.push("--open");
    sh("setup-macos.sh", shArgs);
  }
  console.error(`Unsupported operating system: ${platform}. Windows and macOS are supported.`);
  process.exit(1);
}

if (command === "login") {
  if (detectedPlatform() !== "win32") {
    console.error("On macOS, run the setup command; it performs GitHub web login automatically.");
    process.exit(2);
  }
  const proxy = valueAfter(rest, "--proxy");
  const psArgs = [];
  if (proxy) psArgs.push("-Proxy", proxy);
  ps("github-web-login.ps1", psArgs);
}

if (command === "publish") {
  if (detectedPlatform() !== "win32") {
    console.error("On macOS, run the setup command to connect or publish the vault safely.");
    process.exit(2);
  }
  const vault = valueAfter(rest, "--vault");
  const repo = normalizeRepo(valueAfter(rest, "--repo"));
  if (!vault || !repo) {
    console.error("publish requires --vault and --repo.");
    printUsage();
    process.exit(2);
  }
  const psArgs = ["-VaultPath", vault, "-RepositoryUrl", repo, "-ConfirmUpload"];
  if (hasFlag(rest, "--open")) psArgs.push("-OpenRepositoryPage");
  ps("publish-vault.ps1", psArgs);
}

if (command === "verify") {
  if (detectedPlatform() !== "win32") {
    console.error("The standalone verify command currently checks the Windows watcher. macOS verification runs inside setup.");
    process.exit(2);
  }
  const vault = valueAfter(rest, "--vault");
  if (!vault) {
    console.error("verify requires --vault.");
    printUsage();
    process.exit(2);
  }
  const psArgs = ["-VaultPath", vault];
  if (hasFlag(rest, "--recovery-probe")) psArgs.push("-RunWatcherRecoveryProbe");
  ps("verify-sync.ps1", psArgs);
}

if (command === "mobile-info") {
  const vault = valueAfter(rest, "--vault");
  if (!vault) {
    console.error("mobile-info requires --vault.");
    printUsage();
    process.exit(2);
  }
  const nodeArgs = ["--vault", vault];
  if (hasFlag(rest, "--open-token-page")) nodeArgs.push("--open-token-page");
  nodeScript("mobile-setup-info.js", nodeArgs);
}

console.error(`Unknown command: ${command}`);
printUsage();
process.exit(2);
