#!/usr/bin/env bash
# Release helper: bump version.txt, tag vX.Y.Z, push.
#
# Usage: ./update-version.sh <version>   (e.g. 0.2.0 or v0.2.0)
#
# Flow:
#   1. abort if the working tree is dirty (anything unadded/uncommitted)
#   2. fetch all tags from origin
#   3. validate the version and abort if tag v<version> already exists
#   4. write the version into version.txt, commit it, tag, push
#
# The tag push triggers the CI release build (see .github/workflows/docker.yml):
# :latest only moves on v*.*.* tags, and watchtower deploys it on the VPS.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

# --- 1. arguments & clean tree ----------------------------------------------
[ $# -eq 1 ] || die "usage: $0 <version> (e.g. 0.2.0)"

VERSION="${1#v}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
    || die "'$1' is not a valid version - expected X.Y.Z (e.g. 0.2.0)"

TAG="v$VERSION"

if [ -n "$(git status --porcelain)" ]; then
    echo "error: working tree is not clean - commit or stash everything first:" >&2
    git status --short >&2
    exit 1
fi

# --- 2. sync tags with remote ------------------------------------------------
git fetch --tags origin

# --- 3. collision check ------------------------------------------------------
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    die "tag $TAG already exists - pick a higher version"
fi

# --- 4. bump, commit, tag, push ----------------------------------------------
echo "$VERSION" > version.txt
git add version.txt
git commit -m "$TAG"
git tag "$TAG"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
git push origin "$BRANCH"
git push origin "$TAG"

echo "released $TAG - CI builds the image, watchtower deploys it."
