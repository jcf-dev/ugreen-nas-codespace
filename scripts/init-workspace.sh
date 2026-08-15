#!/bin/sh
set -eu

settings_dir="${HOME}/.local/share/code-server/User"
settings_file="${settings_dir}/settings.json"

if [ ! -w "${NVM_DIR:-/usr/local/share/nvm}" ]; then
  sudo chown -R "$(id -u):$(id -g)" "${NVM_DIR:-/usr/local/share/nvm}"
fi

mkdir -p \
  "${HOME}/.claude" \
  "${HOME}/.codex" \
  "${HOME}/.config/gh" \
  "${HOME}/.config/opencode" \
  "${HOME}/.gnupg" \
  "${HOME}/.local/share/opencode" \
  "${HOME}/.ssh" \
  "${settings_dir}"

chmod 0700 "${HOME}/.gnupg" "${HOME}/.ssh"

if [ ! -e "${settings_file}" ]; then
  cp /opt/ugreen-codespace/settings.json "${settings_file}"
fi

if [ ! -w /workspace ]; then
  echo >&2 "WARNING: /workspace is not writable by UID $(id -u) and GID $(id -g)."
  echo >&2 "Update PUID/PGID or the NAS share ownership before editing files."
fi

echo "UGREEN NAS Codespace is starting (Node $(node --version), Python $(python3 --version 2>&1))."
