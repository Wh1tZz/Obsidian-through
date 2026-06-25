#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const path = require("node:path");

const root = path.resolve(__dirname, "..");

function printUsage() {
  console.log(`Obsidian-through

Usage:
  npx obsidian-through help
  npx obsidian-through login [--proxy http://127.0.0.1:7890]
  npx obsidian-through publish --vault <path> --repo <github-url-or-owner/name> [--open]
  npx obsidian-through verify --vault <path>
  npx obsidian-through mobile-info --vault <path> [--open-token-page]

Examples:
  npx obsidian-through login
  npx obsidian-through publish --vault "<vault-path>" --repo https://github.com/owner/private-vault.git --open
  npx obsidian-through verify --vault "<vault-path>"
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
  const command = process.platform === "win32" ? "powershell.exe" : "pwsh";
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

function normalizeRepo(repo) {
  if (!repo) return "";
  if (/^https:\/\/github\.com\/[^/]+\/[^/]+\/?$/.test(repo)) return repo;
  if (/^https:\/\/github\.com\/[^/]+\/[^/]+\.git\/?$/.test(repo)) return repo;
  if (/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo)) return `https://github.com/${repo}.git`;
  return repo;
}

const args = process.argv.slice(2);
const command = args[0] || "help";
const rest = args.slice(1);

if (command === "help" || command === "--help" || command === "-h") {
  printUsage();
  process.exit(0);
}

if (command === "login") {
  const proxy = valueAfter(rest, "--proxy");
  const psArgs = [];
  if (proxy) psArgs.push("-Proxy", proxy);
  ps("github-web-login.ps1", psArgs);
}

if (command === "publish") {
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
  const vault = valueAfter(rest, "--vault");
  if (!vault) {
    console.error("verify requires --vault.");
    printUsage();
    process.exit(2);
  }
  ps("verify-sync.ps1", ["-VaultPath", vault]);
}

if (command === "mobile-info") {
  const vault = valueAfter(rest, "--vault");
  if (!vault) {
    console.error("mobile-info requires --vault.");
    printUsage();
    process.exit(2);
  }
  const psArgs = ["-VaultPath", vault];
  if (hasFlag(rest, "--open-token-page")) psArgs.push("-OpenTokenPage");
  ps("mobile-setup-info.ps1", psArgs);
}

console.error(`Unknown command: ${command}`);
printUsage();
process.exit(2);
