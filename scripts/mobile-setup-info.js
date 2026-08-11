const { spawn, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

function valueAfter(args, name) {
  const index = args.indexOf(name);
  return index === -1 ? "" : args[index + 1] || "";
}

function run(command, args) {
  const result = spawnSync(command, args, { encoding: "utf8" });
  if (result.error || result.status !== 0) {
    const detail = (result.stderr || result.error?.message || "").trim();
    throw new Error(`${command} ${args.join(" ")} failed${detail ? `: ${detail}` : ""}`);
  }
  return result.stdout.trim();
}

function openUrl(url) {
  if (process.platform === "win32") {
    spawn("cmd.exe", ["/d", "/s", "/c", "start", "", url], {
      detached: true,
      stdio: "ignore",
      windowsHide: true
    }).unref();
  } else if (process.platform === "darwin") {
    spawn("open", [url], { detached: true, stdio: "ignore" }).unref();
  }
}

function main() {
  const args = process.argv.slice(2);
  const vaultInput = valueAfter(args, "--vault");
  if (!vaultInput) throw new Error("mobile-info requires --vault.");
  const vault = path.resolve(vaultInput);
  if (!fs.existsSync(path.join(vault, ".git"))) {
    throw new Error(`The vault is not a Git repository: ${vault}`);
  }

  run("gh", ["auth", "status", "--hostname", "github.com"]);
  const account = JSON.parse(run("gh", ["api", "user"]));
  const remote = run("git", ["-C", vault, "remote", "get-url", "origin"]);
  const match = remote.match(/github\.com[/:]([^/]+)\/([^/]+?)(?:\.git)?$/);
  if (!match) throw new Error("Origin is not a GitHub repository.");
  const owner = match[1];
  const repositoryName = match[2];
  const repository = `${owner}/${repositoryName}`;
  const visibility = run("gh", ["repo", "view", repository, "--json", "visibility", "--jq", ".visibility"]);
  if (visibility !== "PRIVATE") throw new Error("The repository must be private before mobile setup.");

  const tokenCreationUrl = "https://github.com/settings/personal-access-tokens/new";
  if (args.includes("--open-token-page")) openUrl(tokenCreationUrl);

  console.log(JSON.stringify({
    githubLogin: account.login,
    authorName: account.name || account.login,
    authorEmail: `${account.id}+${account.login}@users.noreply.github.com`,
    repository,
    repositoryName,
    cloneDirectoryName: repositoryName,
    repositoryVisibility: visibility,
    repositoryUrl: `https://github.com/${repository}`,
    cloneUrl: `https://github.com/${repository}.git`,
    tokenCreationUrl
  }, null, 2));
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
