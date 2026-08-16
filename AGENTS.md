# AGENTS.md

Guidance for AI coding agents (Kimi Code, OpenCode, Codex, ...) working in this repository.

## What this project is

A personal, browser-based remote development workstation: code-server
(VS Code in the browser) in Docker Compose. Currently at **MVP 3**
(foundation + persistence + Node.js/pnpm + AI CLIs + VPS deployment behind
Traefik with CI-built images). See `README.md` for usage and `ROADMAP.md`
for the plan — do not build roadmap items ahead of schedule.

## Core architectural rule

**System level = image, user level = state.**

- OS packages, code-server, toolchains → `Dockerfile` (rebuilt rarely, via CI later)
- AI CLIs, npm globals, user tools → installed as the `coder` user into the
  persistent home (`~/.local`), never baked into the image
- Persistent state lives in host bind mounts:
  - `./workspace` → `/home/coder/workspace` (the user's projects)
  - `./data/config` → `/home/coder/.config`
  - `./data/local` → `/home/coder/.local`
  - `./data/grok` → `/home/coder/.grok` (Grok Build: binary, login, config)
  - `./data/claude` → `/home/coder/.claude` (Claude Code)
  - `./data/codex` → `/home/coder/.codex` (Codex CLI)
- The container must stay disposable: deleting/recreating it must never lose state.

## Compose file layout

- `docker-compose.yml` — base, no ports (safe everywhere)
- `docker-compose.override.yml` — local dev, maps `8080:8080`; auto-loaded
  by `docker compose` when no `-f` flags are given
- `docker-compose.prod.yml` — VPS: Traefik labels (TLS via `letsencrypt`,
  external network `traefik-proxy`), registry image, watchtower. Always
  used with explicit `-f` flags, which also suppresses the override file.
- Multi-instance: `INSTANCE_NAME` and `DOMAIN` come from `.env`
  (gitignored, see `.env.example`) and parameterize project/container name
  and Traefik router/service/host. Defaults = the original single instance,
  so `.env` is optional. Each person gets their own checkout + instance —
  never share one container between people.

## Commands

```bash
# local
docker compose up -d --build   # build & start
docker compose ps              # status incl. health check
docker compose logs -f         # logs
docker compose down            # stop (state persists)
docker compose build --no-cache && docker compose up -d   # clean rebuild

# VPS (never builds - pulls the CI-built image)
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# release (moves :latest, watchtower deploys it)
git tag vX.Y.Z && git push origin vX.Y.Z
```

## Conventions

- The container runs as unprivileged user `coder` (UID 1000). Keep it that way.
  The base image ships passwordless sudo for `coder` — fine for experiments,
  but `apt` installs are ephemeral; proven system packages go into the `Dockerfile`.
- Port `8080` is mapped only locally (override file). In prod, Traefik
  terminates TLS; the container maps no ports. No extra ports anywhere.
- Toolchains (currently Node.js 22 + pnpm via NodeSource/corepack, plus the
  GitHub CLI via its official apt repo) belong to the image.
- The login shell is fish. Generic, shareable shell goodies live in the
  repo's `fish/` directory and are baked into `/etc/fish/` (sourced before
  any user config) — keep them generic; personal config belongs to each
  user's own `~/.config/fish` (persisted via `./data/config`). Tools that
  the shared config references must be installed in the `Dockerfile`. AI CLIs and other fast-moving tools do NOT: they are installed
  at runtime with `npm install -g`, which lands in the persistent `~/.local`
  thanks to `NPM_CONFIG_PREFIX`. Same for `KIMI_CODE_HOME` and `COREPACK_HOME`
  (both redirected into `~/.local/share`). When adding a new user-space tool,
  make sure its data/config lands in `~/.config` or `~/.local` — anything
  else under `/home/coder` is ephemeral. Tools that hardcode their own home
  directory (like Grok Build's `~/.grok`) get their own `./data/*` bind mount
  instead.
- Authentication: Argon2 hash in `secrets/hashed_password`, mounted as a
  Compose secret; `entrypoint.sh` reads it and exports `HASHED_PASSWORD`.
  Do NOT pass the hash via Compose `environment:` — Compose interpolates `$`
  in env values and would mangle Argon2 hashes. File contents are literal.
- Never commit `secrets/` (except `*.example` files) or any credentials.
- `secrets/hashed_password.example` must stay in sync with the auth setup.
- Keep changes minimal and boring; this project values operability over cleverness.
- When modifying structure, conventions or commands, update `README.md`,
  `ROADMAP.md` and this file accordingly.

## Explicit non-goals for the current state

OAuth/SSO, Docker socket access, DinD, mapped dev-port ranges, wildcard DNS,
further toolchains (Python, Rust, ...), automated base-image updates,
backups, multi-user *within* one instance (multi-instance per person exists
and is the way).
These are planned — see `ROADMAP.md` — but must not be implemented early.
