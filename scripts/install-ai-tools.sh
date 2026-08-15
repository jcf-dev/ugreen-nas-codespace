#!/bin/sh
set -eu

force=false
case "${1:-}" in
  "") ;;
  --force|--upgrade) force=true ;;
  *)
    echo >&2 "Usage: install-ai-tools [--force|--upgrade]"
    exit 64
    ;;
esac

prefix="${HOME}/.local"
state_dir="${prefix}/state/ugreen-codespace"
lock_dir="${state_dir}/ai-tools.lock"
marker="${state_dir}/ai-tools.versions"

claude_spec="@anthropic-ai/claude-code@${UGREEN_CLAUDE_CODE_VERSION:-latest}"
codex_spec="@openai/codex@${UGREEN_CODEX_VERSION:-latest}"
opencode_spec="opencode-ai@${UGREEN_OPENCODE_VERSION:-latest}"

if [ "${force}" = false ] \
  && [ -x "${prefix}/bin/claude" ] \
  && [ -x "${prefix}/bin/codex" ] \
  && [ -x "${prefix}/bin/opencode" ]; then
  echo "AI CLIs are already installed in ${prefix}."
  exit 0
fi

mkdir -p "${state_dir}"

if ! mkdir "${lock_dir}" 2>/dev/null; then
  if [ -r "${lock_dir}/pid" ] \
    && kill -0 "$(sed -n '1p' "${lock_dir}/pid")" 2>/dev/null; then
    echo >&2 "ERROR: Another AI CLI installation is already running."
    exit 1
  fi
  rm -rf "${lock_dir}"
  mkdir "${lock_dir}"
fi

printf '%s\n' "$$" > "${lock_dir}/pid"
cleanup() {
  rm -rf "${lock_dir}"
}
trap cleanup EXIT HUP INT TERM

echo "Installing Claude Code, Codex, and OpenCode into ${prefix}..."
npm install --global --prefix "${prefix}" --no-audit --no-fund \
  --allow-scripts=@anthropic-ai/claude-code,opencode-ai \
  "${claude_spec}" \
  "${codex_spec}" \
  "${opencode_spec}"

printf '%s\n' \
  "${claude_spec}" \
  "${codex_spec}" \
  "${opencode_spec}" \
  > "${marker}"

echo "AI CLIs installed. Run install-ai-tools --upgrade to refresh them later."
