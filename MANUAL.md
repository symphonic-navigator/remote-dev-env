# MANUAL.md

End-user manual for the remote development workstation. You don't need to
know anything about Docker or servers — this covers your day-to-day use.
(Operating and deploying the thing itself is documented in `README.md`.)

## What this is

A full development workstation that runs on a server and lives **in your
browser**: VS Code (code-server) with an integrated terminal, reachable from
any machine. Your operator gives you a URL and a password — that's all you
need to get in.

What's inside:

- VS Code in the browser, with your files, settings and extensions
- A Linux terminal with a comfy shell (fish, see below)
- Git + the GitHub CLI (`gh`), Node.js 22 + pnpm, Python 3 (pip, venv, pipx, uv),
  the .NET 10 SDK (`dotnet`)
- The popular AI coding CLIs (Kimi Code, OpenCode, Grok, Claude Code, Codex)

The important mental model: **the container is disposable, your state is
not.** Your operator can rebuild or replace the whole environment at any
time, and your code, settings, extensions, logins and installed tools all
survive. The only things that *don't* survive are system packages you
install yourself with `sudo apt install` — treat those as throwaway
experiments, and ask your operator to bake proven tools into the image.

Where things live:

- `/home/coder/workspace` — your projects (this is where the IDE opens)
- `~/.config` — settings (git, gh, fish, VS Code, ...)
- `~/.local` — tools you install with `npm install -g`
- `~/.grok`, `~/.claude`, `~/.codex` — AI CLI logins and sessions

Everything else under `/home/coder` (notably `~/.ssh`) is **temporary** and
reset when the container is recreated.

## Getting in

1. Open the URL your operator gave you.
2. Enter the password. Wrong password → rejected, correct → the IDE opens
   in your `workspace` folder.

There is no sign-up, no account — the password *is* the login.

## Git & GitHub

Git and the GitHub CLI (`gh`) are pre-installed. One-time setup, inside the
IDE terminal (`Terminal → New Terminal` or `` Ctrl+` ``):

```fish
gh auth login
```

- Choose **GitHub.com**, then **HTTPS** as the preferred protocol.
- When asked to authenticate Git with your GitHub credentials, say **Yes**.
- Authenticate via **Login with a web browser**: it shows a one-time code
  and a URL. Copy the code, open the URL in any browser (your laptop, your
  phone — anywhere), paste the code, approve. The terminal continues by
  itself.

Then tell git to use `gh` for credentials and set your identity (once, not
per repo):

```fish
gh auth setup-git
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

That's it. From now on, **clone via HTTPS** and everything just works —
clone, pull, push, no SSH keys, no password prompts:

```fish
gh repo clone user/repo                          # or:
git clone https://github.com/user/repo.git
cd repo
git pull
git push
```

Notes:

- Your gh token and git identity persist across rebuilds — you do this
  once per instance, ever.
- `gh` is also great beyond git: `gh pr create`, `gh pr list`,
  `gh issue list`, `gh run watch`, ...
- Avoid SSH remotes (`git@github.com:...`): `~/.ssh` is deliberately *not*
  persisted. If you cloned a repo with an SSH remote, switch it once:
  `git remote set-url origin https://github.com/user/repo.git`
  — or set a global rewrite once:
  `git config --global url."https://github.com/".insteadOf git@github.com:`

## Python

Python 3 is pre-installed, including `pip`, `venv`, `pipx` and `uv`.
System-wide `pip install` is deliberately blocked — that's normal. Instead:

```fish
# projects: one virtualenv per project
python3 -m venv .venv
source .venv/bin/activate.fish
pip install -r requirements.txt

# CLI tools (e.g. httpie, ruff): isolated, land in your persistent ~/.local
pipx install ruff

# uv does both, faster (uv venv / uv pip / uv tool install)
```

## AI coding CLIs

All of them run in the IDE terminal. Tools installed this way land in your
persistent home, so they survive rebuilds and you can update them yourself
anytime — no need to involve your operator.

### Kimi Code

```fish
npm install -g @moonshot-ai/kimi-code
kimi
```

First launch: `/login` (OAuth or API key).

### OpenCode

```fish
npm install -g opencode-ai
opencode
```

First launch: `opencode auth login`.

### Grok Build (xAI)

```fish
curl -fsSL https://x.ai/cli/install.sh | bash
grok
```

First launch: `grok login` (X account / SuperGrok) or API key. Its binary,
login and config live under `~/.grok`, which is persisted like everything
else.

### Claude Code

```fish
npm install -g @anthropic-ai/claude-code
claude
```

Logins and sessions in `~/.claude` persist. (Small caveat: Claude Code's
`~/.claude.json` state file is not persisted and resets on container
recreation — your credentials are what matter, and those persist.)

### Codex CLI

```fish
npm install -g @openai/codex
codex
```

### Updating

Anytime, no rebuild, no redeploy:

```fish
npm install -g @moonshot-ai/kimi-code@latest
npm install -g opencode-ai@latest
npm install -g @anthropic-ai/claude-code@latest
npm install -g @openai/codex@latest
```

## The terminal: fish with batteries included

Your login shell is **fish**, with a curated set of defaults. The short
tour:

| Command | What it does |
|---|---|
| `ls`, `l`, `la` | colorful listings via `eza` with icons (`l` = long, `la` = long + hidden) |
| `z <name>` | jump to directories you've visited before (zoxide — `z proj` takes you to `~/workspace/my-project`) |
| `clear` | clears the screen *including* scrollback |
| `v <file>` | edit in neovim |
| `pw-alpha [n]` | generate an alphanumeric password (default 43 chars) |
| `pw-hex [n]` | generate a hex password (default 32 chars) |
| `reload` | re-source your fish config after editing it |
| `wlc` / `wlp` | copy/paste through the browser terminal (OSC 52; paste needs clipboard-read permission, which browsers usually block) |

Also active, less visible:

- **starship** — the informative prompt (git branch, status, ...)
- **fzf** — fuzzy finding; press `Ctrl+R` for searchable history,
  `Ctrl+T` to fuzzy-insert a file path
- **direnv** — auto-loads per-project `.envrc` files when you `cd`

`git` is available with full tab completion, `EDITOR` is `nvim`.

### Making it yours

Your personal config is `~/.config/fish/config.fish` (persisted, like
everything in `~/.config`). The system defaults load *before* it, so you can
override or extend anything there — aliases, key bindings, prompt tweaks.
After editing, run `reload`.

Example — opt into vi key bindings:

```fish
echo 'set -g fish_key_bindings fish_vi_key_bindings' >> ~/.config/fish/config.fish
reload
```

## House rules (the short version)

- Put your projects in `~/workspace` — that's what's persisted for code.
- Install CLI tools with `npm install -g ...` (persistent), not
  `sudo apt install ...` (gone on the next rebuild).
- `sudo` works if you want to experiment — just know it's temporary.
- No SSH keys; GitHub goes over HTTPS + `gh`.
- If the environment gets rebuilt or restarted (updates deploy
  automatically on some setups), open IDE sessions and terminal processes
  are interrupted — your files, logins and settings are not.
