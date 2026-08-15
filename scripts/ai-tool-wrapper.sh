#!/bin/sh
set -eu

tool_name="${0##*/}"

case "${tool_name}" in
  claude|codex|opencode) ;;
  *)
    echo >&2 "ERROR: Unsupported AI tool wrapper name: ${tool_name}"
    exit 64
    ;;
esac

system_tool="${NVM_DIR:-/usr/local/share/nvm}/current/bin/${tool_name}"
persistent_tool="${HOME}/.local/bin/${tool_name}"

if [ -x "${system_tool}" ]; then
  exec "${system_tool}" "$@"
fi

if [ ! -x "${persistent_tool}" ]; then
  echo >&2 "${tool_name} is not bundled in the slim image. Installing all AI CLIs into persistent storage..."
  /usr/local/bin/install-ai-tools
fi

exec "${persistent_tool}" "$@"
