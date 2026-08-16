# syntax=docker/dockerfile:1

# Base: official code-server image (VS Code in the browser).
# Later MVPs add development tooling here (system packages, toolchains, CLIs).
FROM codercom/code-server:latest

# curl is needed for the container health check (/healthz).
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS via NodeSource (>= 22.19 is required by the AI CLIs)
# + pnpm via corepack (bundled with Node).
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable

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
