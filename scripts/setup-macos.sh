#!/usr/bin/env bash
set -euo pipefail

vault=""
repository=""
open_repository=0
dry_run=0

while (($#)); do
  case "$1" in
    --vault) vault="${2:-}"; shift 2 ;;
    --repo) repository="${2:-}"; shift 2 ;;
    --open) open_repository=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    *) printf 'Unknown macOS setup option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ "${OBSIDIAN_THROUGH_TEST_MODE:-}" == "1" ]]; then
  platform="${OBSIDIAN_THROUGH_TEST_PLATFORM:-$(uname -s)}"
else
  platform="$(uname -s)"
fi
if [[ "$platform" != "Darwin" && "$platform" != "darwin" ]]; then
  printf 'setup-macos.sh must run on macOS. Detected: %s\n' "$platform" >&2
  exit 1
fi

if ((dry_run)); then
  printf '{"platform":"darwin","workflow":"macos-obsidian-git","vault":"%s","repositoryUrl":"%s"}\n' "$vault" "$repository"
  exit 0
fi

install_tools() {
  if ! command -v git >/dev/null 2>&1; then
    xcode-select --install || true
    printf 'Finish the Apple Command Line Tools installation, then run npx obsidian-through again.\n'
    exit 2
  fi
  if ! command -v gh >/dev/null 2>&1; then
    if ! command -v brew >/dev/null 2>&1; then
      printf 'Installing Homebrew so GitHub CLI can be installed.\n'
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
    brew install gh
  fi
}

find_vault() {
  if [[ -n "$vault" ]]; then
    printf '%s\n' "$vault"
    return
  fi
  if [[ -d "$PWD/.obsidian" ]]; then
    printf '%s\n' "$PWD"
    return
  fi
  local config="$HOME/Library/Application Support/obsidian/obsidian.json"
  if [[ -f "$config" ]]; then
    local found
    found="$(node - "$config" <<'NODE'
const fs = require('node:fs');
const config = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
for (const item of Object.values(config.vaults || {})) {
  if (item && item.path && fs.existsSync(item.path + '/.obsidian')) {
    process.stdout.write(item.path);
    break;
  }
}
NODE
)"
    if [[ -n "$found" ]]; then
      printf '%s\n' "$found"
      return
    fi
  fi
  if [[ -d "$HOME/Documents/Obsidian Vault/.obsidian" ]]; then
    printf '%s\n' "$HOME/Documents/Obsidian Vault"
    return
  fi
  printf 'No Obsidian vault was found automatically. Rerun with --vault.\n' >&2
  exit 1
}

normalize_repository() {
  local value="$1" login="$2"
  if [[ -z "$value" ]]; then
    printf 'https://github.com/%s/obsidian-vault.git\n' "$login"
  elif [[ "$value" =~ ^https://github\.com/[^/]+/[^/]+\.git/?$ ]]; then
    printf '%s\n' "${value%/}"
  elif [[ "$value" =~ ^https://github\.com/[^/]+/[^/]+/?$ ]]; then
    printf '%s.git\n' "${value%/}"
  elif [[ "$value" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    printf 'https://github.com/%s.git\n' "$value"
  else
    printf 'Repository must be a GitHub HTTPS URL or owner/name.\n' >&2
    exit 2
  fi
}

append_ignore() {
  local entry="$1" file="$2"
  grep -Fqx "$entry" "$file" 2>/dev/null || printf '%s\n' "$entry" >> "$file"
}

configure_plugin() {
  local data="$vault/.obsidian/plugins/obsidian-git/data.json"
  mkdir -p "$(dirname "$data")"
  node - "$data" <<'NODE'
const fs = require('node:fs');
const file = process.argv[2];
let settings = {};
if (fs.existsSync(file)) {
  const raw = fs.readFileSync(file, 'utf8').trim();
  if (raw) settings = JSON.parse(raw);
}
Object.assign(settings, {
  autoSaveInterval: 0.5,
  autoPushInterval: 0,
  autoPullInterval: 0,
  autoPullOnBoot: true,
  autoBackupAfterFileChange: true,
  differentIntervalCommitAndPush: false,
  disablePopups: false,
  showErrorNotices: true
});
fs.writeFileSync(file, JSON.stringify(settings, null, 2) + '\n');
NODE
}

printf 'Obsidian-through detected macOS.\n'
install_tools

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  printf 'Opening GitHub web login. Complete authentication in the browser.\n'
  gh auth login --hostname github.com --git-protocol https --web
fi
gh auth setup-git

login="$(gh api user --jq .login)"
account_id="$(gh api user --jq .id)"
vault="$(find_vault)"
vault="$(cd "$vault" && pwd -P)"
[[ -d "$vault/.obsidian" ]] || { printf 'Not an Obsidian vault: %s\n' "$vault" >&2; exit 1; }

if [[ -z "$repository" && -d "$vault/.git" ]]; then
  repository="$(git -C "$vault" remote get-url origin 2>/dev/null || true)"
fi
repository="$(normalize_repository "$repository" "$login")"
repo_path="${repository#https://github.com/}"
repo_path="${repo_path%.git}"
repo_web="https://github.com/$repo_path"

if gh repo view "$repo_path" --json visibility --jq .visibility >/dev/null 2>&1; then
  visibility="$(gh repo view "$repo_path" --json visibility --jq .visibility)"
  [[ "$visibility" == "PRIVATE" ]] || { printf 'Existing repository is not private: %s\n' "$repo_path" >&2; exit 1; }
else
  gh repo create "$repo_path" --private
fi

if [[ ! -d "$vault/.git" ]]; then
  git -C "$vault" init -b main
fi
ignore="$vault/.gitignore"
touch "$ignore"
for entry in \
  '.obsidian/workspace.json' \
  '.obsidian/workspace-mobile.json' \
  '.obsidian/cache/' \
  '.obsidian/plugins/obsidian-git/data.json' \
  '.trash/' '.DS_Store' 'Thumbs.db' 'desktop.ini'; do
  append_ignore "$entry" "$ignore"
done
git -C "$vault" rm --cached --ignore-unmatch '.obsidian/plugins/obsidian-git/data.json' >/dev/null 2>&1 || true

git -C "$vault" config user.name >/dev/null 2>&1 || git -C "$vault" config user.name "$login"
git -C "$vault" config user.email >/dev/null 2>&1 || git -C "$vault" config user.email "${account_id}+${login}@users.noreply.github.com"

if git -C "$vault" remote get-url origin >/dev/null 2>&1; then
  current_origin="$(git -C "$vault" remote get-url origin)"
  [[ "${current_origin%/}" == "${repository%/}" ]] || { printf 'Existing origin points elsewhere: %s\n' "$current_origin" >&2; exit 1; }
else
  git -C "$vault" remote add origin "$repository"
fi

git -C "$vault" add --all
if ! git -C "$vault" diff --cached --quiet; then
  git -C "$vault" commit -m 'Initialize Obsidian vault sync'
fi

if git -C "$vault" fetch origin main >/dev/null 2>&1; then
  backup="backup-before-remote-merge-$(date +%Y%m%d-%H%M%S)"
  git -C "$vault" branch "$backup"
  if git -C "$vault" merge-base --is-ancestor origin/main HEAD; then
    :
  elif git -C "$vault" merge-base --is-ancestor HEAD origin/main; then
    git -C "$vault" pull --rebase origin main
  else
    git -C "$vault" merge --no-edit --allow-unrelated-histories origin/main || {
      printf 'Merge conflicts were preserved. Resolve them before pushing. Backup branch: %s\n' "$backup" >&2
      exit 1
    }
  fi
fi

git -C "$vault" push --set-upstream origin main
configure_plugin

local_hash="$(git -C "$vault" rev-parse HEAD)"
remote_hash="$(git -C "$vault" ls-remote origin refs/heads/main | awk '{print $1}')"
visibility="$(gh repo view "$repo_path" --json visibility --jq .visibility)"
[[ "$visibility" == "PRIVATE" && "$local_hash" == "$remote_hash" ]] || { printf 'macOS verification failed.\n' >&2; exit 1; }

((open_repository)) && open "$repo_web"
printf '\nmacOS sync setup is complete.\n'
printf 'GitHub account: %s\n' "$login"
printf 'Obsidian vault: %s\n' "$vault"
printf 'Private repository: %s\n' "$repo_path"
printf 'Repository page: %s\n' "$repo_web"
printf 'Automation: Obsidian Git, 0.5-minute sync after edits, Pull on startup enabled.\n'
printf 'Restart Obsidian, then create or edit one test note and keep the app open for 30-60 seconds.\n'
