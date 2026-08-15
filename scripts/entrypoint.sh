#!/bin/sh
set -eu

if [ -z "${PASSWORD:-}" ] && [ -z "${HASHED_PASSWORD:-}" ]; then
  echo >&2 "ERROR: Set PASSWORD or HASHED_PASSWORD before starting the container."
  echo >&2 "Copy .env.example to .env and replace the placeholder value."
  exit 1
fi

exec /usr/bin/entrypoint.sh "$@"
