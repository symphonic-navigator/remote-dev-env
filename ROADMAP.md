# Roadmap

**End goal:** a personal, browser-based remote development workstation on a VPS.
Full VS Code in the browser, reachable from anywhere (laptop, tablet, bed),
with AI coding harnesses (Kimi Code, OpenCode, Codex, ...) running in its
terminal — plus the ability to run and preview the software being developed.

**Core architectural rule:** system level = image, user level = state.
Fast-moving tools (AI CLIs, npm globals) are installed as the `coder` user
into the persistent home (`~/.local`), so they survive image rebuilds and can
be updated without redeploying. The image itself only changes for OS/system
packages and is rebuilt via CI when needed.

---

## MVP 1 — Foundation (done)

- code-server (VS Code in the browser) via Docker Compose
- Password auth (Argon2 hash via Compose secret file, no escaping pitfalls)
- Persistent state: `workspace/`, `data/config`, `data/local` as host bind mounts
- Own Dockerfile as the foundation for future tooling
- Health check, `restart: unless-stopped`

## MVP 2 — Actually usable: toolchains + AI harnesses (done)

- Node.js 22 + pnpm in the image (system level)
- Kimi Code and OpenCode installed user-space in the persistent home
  (`NPM_CONFIG_PREFIX=~/.local`) — updatable via npm without any rebuild;
  Kimi Code's data redirected to the persistent tree via `KIMI_CODE_HOME`
- Finding: the base image already ships passwordless sudo for `coder`
  (still ephemeral across rebuilds, see README)
- Verified: both CLIs survive a `build --no-cache` rebuild

## MVP 3 — Reachable from anywhere: VPS deployment (done)

- `docker-compose.prod.yml`: Traefik labels for `chris.dev.tidesson.net`,
  TLS via Let's Encrypt, external network `traefik-proxy` — reuses the
  existing VPS Traefik setup; no mapped ports in prod
- Local port mapping moved to `docker-compose.override.yml` (auto-loaded
  locally, not on the VPS)
- GitHub Actions build & push to ghcr.io (pulled forward from MVP 5):
  chatsundere-style versioning — `latest` only moves on `v*.*.*` tags,
  pre-release tags from `version.txt`, cosign-signed images
- Watchtower auto-deploys releases on the VPS
- Finding: code-server's built-in `/proxy/<port>/` preview already works
  and is covered by the same login (tested locally)
- Multi-instance support added: `INSTANCE_NAME`/`DOMAIN` via `.env`
  (`.env.example`) let several people run isolated instances on one host
  (e.g. `brita.dev.tidesson.net` next to `chris.dev.tidesson.net`)
- Grok Build support: `~/.grok` (binary, login, config) persisted via
  `./data/grok` bind mount; install on demand with the official script
- Python toolchain in the image (user request): python3 + pip + venv +
  pipx via apt, uv via the Astral installer — system level, like Node.js
- Decided against fail2ban / extra rate limiting for the login page:
  code-server itself rate-limits password attempts to 2/minute + 12/hour,
  which is sufficient for personal instances

## MVP 4 — Run what you build: dev servers & ports

- code-server's built-in port proxy (`/proxy/<port>/`, `/absproxy/<port>/`)
  works — Vite needs `base: '/absproxy/<port>/'` in its config
- If that gets annoying: mapped port range (e.g. 3000–3010) for the
  `./start.sh` workflow (firewall it on the VPS — no auth on those ports)
- Possibly later: wildcard DNS (`*.dev.example.com` → port) via Traefik
- Docker CLI access (evaluate socket mount vs. rootless alternatives)

## MVP 5 — Operations

- ~~GitHub Actions: build & publish the image~~ (done, see MVP 3)
- Automated/nightly base-image updates (evaluate)
- Backup automation for `data/` and `workspace/`
- Additional harnesses on demand (e.g. Codex)

## Explicit non-goals (for now)

- Multi-user *within* one instance (shared container/auth) — several people
  are served by separate instances instead (see README, "Running several
  instances")
- Kubernetes / orchestration beyond Compose
- IDE alternatives / fleet management
