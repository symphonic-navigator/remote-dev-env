# remote-dev-env

Browser-based remote development workstation: VS Code (code-server) in Docker,
with persistent state. The container is disposable — your code, settings,
extensions and user-installed tools are not.

This is **MVP 2**: IDE in the browser + persistence + authentication +
Node.js/pnpm + AI coding CLIs (Kimi Code, OpenCode) in the IDE terminal.
See [ROADMAP.md](ROADMAP.md) for what comes next (VPS deployment with TLS,
dev-port handling, CI/CD, ...).

## Architecture

```
IMAGE (rebuild anytime)        STATE (survives rebuilds)
───────────────────────        ─────────────────────────
code-server                    ./workspace      → /home/coder/workspace
OS + system packages           ./data/config    → /home/coder/.config
Node.js 22 + pnpm              ./data/local     → /home/coder/.local
                               (npm -g tools, AI CLIs, their data)
```

npm/pnpm global installs are redirected to `~/.local` (`NPM_CONFIG_PREFIX`),
so anything installed with `npm install -g` inside the IDE terminal lands on
the persistent host directory — including updates. Kimi Code's data directory
is moved to `~/.local/share/kimi-code` (`KIMI_CODE_HOME`); OpenCode already
uses `~/.config` and `~/.local/share` on its own.

Because `data/` and `workspace/` are plain host directories, backup is
just `tar`, and inspection is just `ls`.

## Prerequisites

- Docker with the Compose plugin (`docker compose version`)
- Your host user should have UID 1000 (typical for the first user on Linux).
  The container runs as `coder` (UID 1000) and the bind-mounted directories
  must be writable by it.

## 1. Configure authentication

code-server uses password authentication with an Argon2 hash (no plaintext
passwords in this repo). Generate a hash for your password and write it to
`secrets/hashed_password` (choose one method):

```bash
# a) argon2 CLI (Debian/Ubuntu: apt install argon2, macOS: brew install argon2)
echo -n 'your-password' | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4 > secrets/hashed_password

# b) Python (pip install argon2-cffi)
python3 -c "from argon2 import PasswordHasher; print(PasswordHasher().hash('your-password'))" > secrets/hashed_password
```

The file must contain only the hash, on a single line. The `$` characters in
the hash do **not** need to be escaped — the hash is mounted into the
container as a file (a Compose secret), not passed through an environment
variable, so nothing is ever interpolated. `secrets/` is excluded from git.

## 2. Build and start

```bash
mkdir -p data/config data/local workspace
docker compose up -d --build
```

## 3. Log in

Open <http://localhost:8080> and enter your password.

- Correct password → the IDE opens (in `/home/coder/workspace`).
- Wrong password → rejected.

## 4. Use the AI CLIs

Inside the IDE terminal (`Terminal → New Terminal`):

```bash
kimi        # Kimi Code CLI — first launch: /login (OAuth or API key)
opencode    # OpenCode — first launch: opencode auth login
```

Update them anytime — no rebuild, no redeploy:

```bash
npm install -g @moonshot-ai/kimi-code@latest
npm install -g opencode-ai@latest
```

## 5. Operate

```bash
docker compose ps        # status incl. health check
docker compose logs -f   # follow logs
docker compose down      # stop (state persists)
docker compose up -d     # start again
```

## 6. Rebuild the image

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## 7. Verify persistence

1. In the IDE, create `/home/coder/workspace/test.txt` and change a setting
   (e.g. the color theme).
2. Run the rebuild from step 6.
3. Open <http://localhost:8080> again: the file and the setting are still
   there. (On the host they live in `workspace/test.txt` and `data/config/`.)

## Notes

- The container runs as the unprivileged `coder` user, which has passwordless
  `sudo` (shipped by the base image). Handy for experiments — but anything
  installed with `sudo apt install` is **ephemeral** and gone after the next
  image rebuild. Proven tools belong in the `Dockerfile`, fast-moving user
  tools belong in the persistent home (`npm install -g ...`).
- Only port `8080` is exposed. No TLS, no reverse proxy, no public exposure —
  do not expose this port to the internet as-is.
