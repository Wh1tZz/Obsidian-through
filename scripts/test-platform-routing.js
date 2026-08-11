const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const cli = path.join(root, "bin", "obsidian-through.js");

function run(platform, args) {
  const result = spawnSync(process.execPath, [cli, ...args], {
    cwd: root,
    encoding: "utf8",
    env: {
      ...process.env,
      OBSIDIAN_THROUGH_TEST_MODE: "1",
      OBSIDIAN_THROUGH_TEST_PLATFORM: platform
    }
  });
  assert.equal(result.status, 0, result.stderr || result.stdout);
  return JSON.parse(result.stdout);
}

const windows = run("win32", [
  "setup",
  "--dry-run",
  "--vault",
  "D:\\Virtual Environments\\Windows Vault",
  "--repo",
  "ExampleUser/windows-vault"
]);
assert.deepEqual(windows, {
  platform: "win32",
  workflow: "windows-event-watcher",
  vault: "D:\\Virtual Environments\\Windows Vault",
  repositoryUrl: "https://github.com/ExampleUser/windows-vault.git"
});

const macos = run("darwin", [
  "setup",
  "--dry-run",
  "--vault",
  "/Users/example/Obsidian Vault",
  "--repo",
  "ExampleUser/macos-vault"
]);
assert.deepEqual(macos, {
  platform: "darwin",
  workflow: "macos-obsidian-git",
  vault: "/Users/example/Obsidian Vault",
  repositoryUrl: "https://github.com/ExampleUser/macos-vault.git"
});

assert.equal(run("win32", ["platform"]).workflow, "windows-event-watcher");
assert.equal(run("darwin", ["platform"]).workflow, "macos-obsidian-git");

console.log("Platform routing tests passed for Windows and macOS.");
