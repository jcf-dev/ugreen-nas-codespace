#!/bin/sh
set -eu

if [ -n "${PASSWORD:-}" ]; then
  echo >&2 "ERROR: Plaintext PASSWORD authentication is not supported."
  echo >&2 "Generate HASHED_PASSWORD with scripts/generate-hashed-password.sh."
  exit 1
fi

if [ -z "${HASHED_PASSWORD:-}" ]; then
  echo >&2 "ERROR: HASHED_PASSWORD is required."
  echo >&2 "Generate it with scripts/generate-hashed-password.sh."
  exit 1
fi

# Dollar signs are literal PHC separators, not shell expansions.
# shellcheck disable=SC2016
if ! printf '%s\n' "${HASHED_PASSWORD}" | grep -Eq \
  '^\$argon2(id|i)\$v=[0-9]+\$m=[0-9]+,t=[0-9]+,p=[0-9]+\$[A-Za-z0-9+/]+\$[A-Za-z0-9+/]+$'; then
  echo >&2 "ERROR: HASHED_PASSWORD must be a complete Argon2i or Argon2id encoded hash."
  exit 1
fi

exec /usr/bin/entrypoint.sh "$@"
