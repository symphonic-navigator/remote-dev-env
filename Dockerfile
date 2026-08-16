# syntax=docker/dockerfile:1

# Base: official code-server image (VS Code in the browser).
# Later MVPs add development tooling here (system packages, toolchains, CLIs).
FROM codercom/code-server:latest

# curl is needed for the container health check (/healthz).
# fish is the default login shell of the coder user (its config lives in
# ~/.config/fish, which is persisted via the ./data/config bind mount).
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl fish \
    && rm -rf /var/lib/apt/lists/* \
    && chsh -s "$(command -v fish)" coder

# Node.js 22 LTS via NodeSource (>= 22.19 is required by the AI CLIs)
# + pnpm via corepack (bundled with Node).
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable

# GitHub CLI (official apt repo) - for working with PRs, issues and Actions
# from the IDE terminal.
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# CLI tools referenced by the user's shell config (fish functions/conf.d):
# eza (ls), starship (prompt), zoxide (cd), fzf, direnv, neovim (editor).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        eza fzf zoxide starship neovim direnv \
    && rm -rf /var/lib/apt/lists/*

# npm global installs land in the persistent home (~/.local is a bind mount),
# so user-installed tools (Kimi Code, OpenCode, ...) survive image rebuilds
# and can be updated with plain npm/pnpm - no redeploy needed.
ENV NPM_CONFIG_PREFIX=/home/coder/.local
ENV PATH=/home/coder/.local/bin:$PATH

# Kimi Code stores its data under ~/.kimi-code by default, which is NOT
# persisted - move it into the persistent ~/.local tree.
ENV KIMI_CODE_HOME=/home/coder/.local/share/kimi-code

# Keep the corepack (pnpm/yarn) download cache persistent as well.
ENV COREPACK_HOME=/home/coder/.local/share/corepack

# System-wide fish defaults (generic shell goodies: eza ls, starship,
# zoxide, fzf, password generators, ...). fish sources /etc/fish BEFORE the
# per-user config in ~/.config/fish, so users can override everything.
COPY fish/ /etc/fish/

# Build metadata (passed by the CI workflow; harmless defaults locally).
ARG VERSION=dev
ARG GIT_SHA=unknown
ARG BUILT_AT=unknown
RUN printf 'version=%s\ngit_sha=%s\nbuilt_at=%s\n' "$VERSION" "$GIT_SHA" "$BUILT_AT" \
    > /etc/remote-dev-env-version

# Entrypoint wrapper: loads the password hash from the Compose secret file.
COPY entrypoint.sh /usr/local/bin/rde-entrypoint.sh
RUN chmod 755 /usr/local/bin/rde-entrypoint.sh

# Run the IDE as the unprivileged coder user (uid 1000), like the base image.
USER coder

ENTRYPOINT ["/usr/local/bin/rde-entrypoint.sh"]
