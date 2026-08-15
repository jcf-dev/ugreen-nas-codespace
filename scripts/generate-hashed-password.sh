#!/bin/sh
set -eu

minimum_length=16
mode="${1:-}"

read_interactive_password() {
  if [ ! -t 0 ]; then
    echo >&2 "ERROR: Interactive password generation requires a terminal."
    exit 1
  fi

  terminal_state="$(stty -g)"
  trap 'stty "${terminal_state}"' EXIT HUP INT TERM

  printf >&2 'Enter a new code-server password: '
  stty -echo
  IFS= read -r password
  stty "${terminal_state}"
  printf >&2 '\nConfirm the password: '
  stty -echo
  IFS= read -r confirmation
  stty "${terminal_state}"
  printf >&2 '\n'
  trap - EXIT HUP INT TERM

  if [ "${password}" != "${confirmation}" ]; then
    echo >&2 "ERROR: Passwords do not match."
    exit 1
  fi
}

case "${mode}" in
  "") read_interactive_password ;;
  --stdin)
    password="$(cat)"
    ;;
  *)
    echo >&2 "Usage: generate-hashed-password [--stdin]"
    exit 64
    ;;
esac

if [ "${#password}" -lt "${minimum_length}" ]; then
  echo >&2 "ERROR: Use at least ${minimum_length} characters."
  exit 1
fi

if command -v argon2 >/dev/null 2>&1; then
  salt="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
  encoded="$(printf '%s' "${password}" | argon2 "${salt}" -id -t 3 -m 16 -p 1 -e)"
elif command -v docker >/dev/null 2>&1; then
  hash_image="${IMAGE_NAME:-joweenflores/ugreen-nas-codespace:latest}"
  printf '%s' "${password}" | docker run --rm -i \
    --entrypoint /usr/local/bin/generate-hashed-password \
    "${hash_image}" --stdin
  password=
  exit 0
else
  echo >&2 "ERROR: Install argon2 or Docker to generate the hash."
  exit 1
fi

password=
compose_value="$(printf '%s' "${encoded}" | sed 's/\$/$$/g')"
printf 'HASHED_PASSWORD=%s\n' "${compose_value}"
