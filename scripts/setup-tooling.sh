#!/usr/bin/env bash
set -euo pipefail

# setup-tooling.sh — install pinned tooling referenced in mise.toml
# Run from repo root: ./scripts/setup-tooling.sh
# This script performs user-level installs and may prompt for sudo when installing system packages.

# Pinned versions (keep in sync with mise.toml)
PIPX_VERSION="1.16.6"
NPM_VERSION="12.0.2"
ELIXIR_VERSION="1.20.3"
OTP_VERSION="29.0.5"

echo "Setting up tooling (pipx ${PIPX_VERSION}, npm ${NPM_VERSION}, elixir ${ELIXIR_VERSION}, otp ${OTP_VERSION})"

# Ensure ~/.local/bin is on PATH for pipx installs
export PATH="$HOME/.local/bin:$PATH"

# Install or pin pipx
if ! command -v pipx >/dev/null 2>&1; then
  echo "Installing pipx ${PIPX_VERSION}..."
  python3 -m pip install --user "pipx==${PIPX_VERSION}"
  python3 -m pipx ensurepath || true
  export PATH="$HOME/.local/bin:$PATH"
else
  echo "pipx already installed: $(pipx --version || true)"
fi

# Install gigalixir via pipx (example pipx package referenced in mise.toml comments)
if command -v pipx >/dev/null 2>&1; then
  echo "Installing gigalixir via pipx (idempotent)..."
  pipx install --force gigalixir || true
fi

# NPM and esbuild
if command -v npm >/dev/null 2>&1; then
  echo "Pinning npm to ${NPM_VERSION} and installing esbuild..."
  npm install -g "npm@${NPM_VERSION}" || true
  npm install -g esbuild || true
else
  echo "npm not found. Skipping npm/esbuild install — install Node.js (which includes npm) first."
fi

# Apt packages (inotify-tools)
if command -v apt-get >/dev/null 2>&1; then
  echo "Installing inotify-tools via apt (may ask for sudo)..."
  sudo apt-get update
  sudo apt-get install -y inotify-tools || true
else
  echo "apt-get not available; skipping inotify-tools."
fi

# asdf + Erlang/Elixir
if ! command -v asdf >/dev/null 2>&1; then
  echo "Installing asdf (user install)..."
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0 || true
  # shellcheck disable=SC1090
  . "$HOME/.asdf/asdf.sh" || true
else
  # shellcheck disable=SC1090
  . "$HOME/.asdf/asdf.sh" || true
fi

# Add plugins and install specific versions
if command -v asdf >/dev/null 2>&1; then
  asdf plugin-add erlang || true
  asdf plugin-add elixir || true

  echo "Installing Erlang/OTP ${OTP_VERSION} and Elixir ${ELIXIR_VERSION} via asdf (may take a while)..."
  asdf install erlang "${OTP_VERSION}" || true
  asdf install elixir "${ELIXIR_VERSION}" || true
  asdf global erlang "${OTP_VERSION}" elixir "${ELIXIR_VERSION}" || true
else
  echo "asdf not available; skipping Erlang/Elixir installs."
fi

echo "Setup finished. Verify versions:"
echo "  pipx: $(command -v pipx >/dev/null 2>&1 && pipx --version || echo 'not installed')"
echo "  npm: $(command -v npm >/dev/null 2>&1 && npm -v || echo 'not installed')"
echo "  esbuild: $(command -v esbuild >/dev/null 2>&1 && esbuild --version || echo 'not installed')"
echo "  inotifywait: $(command -v inotifywait >/dev/null 2>&1 && inotifywait --version || echo 'not installed')"
echo "  elixir: $(command -v elixir >/dev/null 2>&1 && elixir --version || echo 'not installed')"

echo "If any step failed, run the failing command manually or open an issue with the output."
