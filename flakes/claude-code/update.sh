#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BASE_URL="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

# Fetch latest version
VERSION=$(curl -sL "${BASE_URL}/latest")
echo "msg=\"latest version fetched\" version=${VERSION}"

# Get current version from flake.nix
CURRENT=$(grep 'version = "' flake.nix | sed 's/.*version = "\([^"]*\)".*/\1/')
echo "msg=\"current version\" version=${CURRENT}"

if [[ "${VERSION}" == "${CURRENT}" ]]; then
  echo "msg=\"already up to date\""
  echo "changes_detected=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

# Prefetch hashes for each platform
echo "msg=\"fetching hashes\""
HASH_X86=$(nix-prefetch-url "${BASE_URL}/${VERSION}/linux-x64/claude" 2>/dev/null)
HASH_ARM=$(nix-prefetch-url "${BASE_URL}/${VERSION}/linux-arm64/claude" 2>/dev/null)

echo "msg=\"hashes computed\" x86_64=${HASH_X86} aarch64=${HASH_ARM}"

# Update flake.nix
sed -i "s/version = \"[^\"]*\"/version = \"${VERSION}\"/" flake.nix
sed -i "s/\"x86_64-linux\" = \"[^\"]*\"/\"x86_64-linux\" = \"${HASH_X86}\"/" flake.nix
sed -i "s/\"aarch64-linux\" = \"[^\"]*\"/\"aarch64-linux\" = \"${HASH_ARM}\"/" flake.nix

# Update flake.lock
nix flake update

# Build to verify
echo "msg=\"building to verify\""
nix build .#claude-code
./result/bin/claude --version

echo "msg=\"update complete\" version=${VERSION}"
echo "changes_detected=true" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "new_version=${VERSION}" >> "${GITHUB_OUTPUT:-/dev/null}"
