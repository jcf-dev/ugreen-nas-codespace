#!/bin/sh
set -eu

settings_dir="${HOME}/.local/share/code-server/User"
settings_file="${settings_dir}/settings.json"
code_server_config_dir="${HOME}/.config/code-server"
code_server_config="${code_server_config_dir}/config.yaml"
sshd_state_dir="${HOME}/.local/state/ugreen-codespace/sshd"
authorized_keys_file="${HOME}/.ssh/authorized_keys.environment"

if [ ! -w "${NVM_DIR:-/usr/local/share/nvm}" ]; then
  sudo chown -R "$(id -u):$(id -g)" "${NVM_DIR:-/usr/local/share/nvm}"
fi

mkdir -p \
  "${HOME}/.claude" \
  "${HOME}/.codex" \
  "${code_server_config_dir}" \
  "${HOME}/.config/gh" \
  "${HOME}/.config/opencode" \
  "${HOME}/.gnupg" \
  "${HOME}/.local/bin" \
  "${HOME}/.local/share/opencode" \
  "${sshd_state_dir}" \
  "${HOME}/.ssh" \
  "${settings_dir}"

chmod 0700 "${HOME}/.gnupg" "${HOME}/.ssh"

if [ ! -e "${settings_file}" ]; then
  cp /opt/ugreen-codespace/settings.json "${settings_file}"
fi

if [ ! -e "${code_server_config}" ]; then
  cp /opt/ugreen-codespace/code-server.yaml "${code_server_config}"
else
  # Remove code-server's legacy generated plaintext password while preserving
  # unrelated user configuration. HASHED_PASSWORD is supplied via environment.
  sed -i '/^[[:space:]]*password[[:space:]]*:/d' "${code_server_config}"
fi

if [ ! -w /workspace ]; then
  echo >&2 "WARNING: /workspace is not writable by UID $(id -u) and GID $(id -g)."
  echo >&2 "Update PUID/PGID or the NAS share ownership before editing files."
fi

ssh_authorized_key="${SSH_AUTHORIZED_KEY:-}"
key_without_line_breaks="$(printf '%s' "${ssh_authorized_key}" | tr -d '\r\n')"
if [ "${ssh_authorized_key}" != "${key_without_line_breaks}" ]; then
  echo >&2 "ERROR: SSH_AUTHORIZED_KEY must contain exactly one public-key line."
  exit 1
fi

case "${ssh_authorized_key}" in
  "")
    rm -f "${authorized_keys_file}"
    ;;
  ssh-ed25519\ *|ssh-rsa\ *|ecdsa-sha2-*\ *|sk-ssh-*\ *|sk-ecdsa-*\ *)
    printf '%s\n' "${ssh_authorized_key}" > "${authorized_keys_file}"
    ;;
  *)
    echo >&2 "ERROR: SSH_AUTHORIZED_KEY is not a supported OpenSSH public key."
    exit 1
    ;;
esac

if [ -e "${authorized_keys_file}" ]; then
  chmod 0600 "${authorized_keys_file}"
fi

if [ "${ENABLE_SSH:-true}" = "true" ]; then
  if [ ! -s "${authorized_keys_file}" ]; then
    echo >&2 "WARNING: SSH is enabled but no authorized key is configured; SSH will not start."
  else
    host_key="${sshd_state_dir}/ssh_host_ed25519_key"
    if [ ! -s "${host_key}" ]; then
      ssh-keygen -q -t ed25519 -N '' -f "${host_key}"
    fi
    chmod 0600 "${host_key}"
    chmod 0644 "${host_key}.pub"
    /usr/sbin/sshd -t -f /opt/ugreen-codespace/sshd_config
    /usr/sbin/sshd -f /opt/ugreen-codespace/sshd_config \
      -E "${sshd_state_dir}/sshd.log"
    echo "Key-only SSH is listening on container port 2222."
  fi
elif [ "${ENABLE_SSH}" != "false" ]; then
  echo >&2 "ERROR: ENABLE_SSH must be true or false."
  exit 1
fi

echo "UGREEN NAS Codespace (${UGREEN_IMAGE_VARIANT:-full}) is starting (Node $(node --version), Python $(python3 --version 2>&1))."
