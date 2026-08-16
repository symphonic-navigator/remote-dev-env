#!/bin/sh
# Wrapper around the base image's entrypoint.
#
# Reads the Argon2 password hash from a Compose secret file and exports it for
# code-server. A file (not an env var via Compose) is used on purpose: Compose
# interpolates '$' in environment values, which would mangle Argon2 hashes.
# The file content is used literally - no escaping needed, ever.
set -eu

SECRET_FILE=/run/secrets/hashed_password

if [ ! -s "$SECRET_FILE" ]; then
    echo "error: $SECRET_FILE is missing or empty." >&2
    echo "Create ./secrets/hashed_password first (see README.md, step 1)." >&2
    exit 1
fi

HASHED_PASSWORD="$(cat "$SECRET_FILE")"
export HASHED_PASSWORD

exec /usr/bin/entrypoint.sh --bind-addr 0.0.0.0:8080 /home/coder/workspace
