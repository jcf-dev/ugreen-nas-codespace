#!/bin/sh
set -eu

workspace_dir="${UGREEN_WORKSPACE_DIR:-/workspace}"
state_dir="${UGREEN_ONBOARDING_STATE_DIR:-${HOME}/.config/ugreen-codespace}"
completion_marker="${state_dir}/onboarding-complete"
gh_bin="${UGREEN_GH_BIN:-gh}"

usage() {
  cat <<'EOF'
Usage: ugreen-onboard blank
       ugreen-onboard github OWNER/REPOSITORY
       ugreen-onboard status
       ugreen-onboard reset
EOF
}

fail() {
  printf >&2 'ERROR: %s\n' "$*"
  exit 1
}

mark_complete() {
  mode="$1"
  umask 077
  mkdir -p "${state_dir}"
  marker_tmp="${completion_marker}.tmp.$$"
  trap 'rm -f "${marker_tmp}"' EXIT HUP INT TERM
  printf '%s\n' "${mode}" > "${marker_tmp}"
  mv "${marker_tmp}" "${completion_marker}"
  trap - EXIT HUP INT TERM
}

prepare_workspace() {
  mkdir -p "${workspace_dir}"
  [ -d "${workspace_dir}" ] || fail "${workspace_dir} is not a directory."
  if [ ! -r "${workspace_dir}" ] || [ ! -w "${workspace_dir}" ]; then
    fail "${workspace_dir} is not readable and writable. Fix its NAS ownership or Compose UID/GID."
  fi
}

normalise_github_repository() {
  repository="$1"
  case "${repository}" in
    https://github.com/*)
      repository=${repository#https://github.com/}
      ;;
    http://github.com/*)
      repository=${repository#http://github.com/}
      ;;
    git@github.com:*)
      repository=${repository#git@github.com:}
      ;;
    github.com/*)
      repository=${repository#github.com/}
      ;;
  esac
  repository=${repository%/}
  repository=${repository%.git}

  case "${repository}" in
    */*) ;;
    *) fail "Use OWNER/REPOSITORY or a github.com repository URL." ;;
  esac

  owner=${repository%%/*}
  name=${repository#*/}
  case "${owner}" in
    ''|*[!A-Za-z0-9_.-]*) fail "The GitHub owner is invalid." ;;
  esac
  case "${name}" in
    ''|*/*|*[!A-Za-z0-9_.-]*) fail "The GitHub repository name is invalid." ;;
  esac

  printf '%s/%s\n' "${owner}" "${name}"
}

command_name="${1:-}"
case "${command_name}" in
  blank)
    [ "$#" -eq 1 ] || fail "blank does not accept arguments."
    prepare_workspace
    mark_complete blank
    printf 'Workspace ready at %s. Existing files were not changed.\n' "${workspace_dir}"
    ;;
  github)
    [ "$#" -eq 2 ] || fail "github requires one OWNER/REPOSITORY value."
    prepare_workspace
    repository_slug=$(normalise_github_repository "$2")
    first_entry=$(find "${workspace_dir}" -mindepth 1 -maxdepth 1 -print -quit)
    [ -z "${first_entry}" ] || \
      fail "${workspace_dir} is not empty. Move or back up its files before cloning."

    if ! "${gh_bin}" auth status --hostname github.com >/dev/null 2>&1; then
      cat <<'EOF'
GitHub authentication is required. GitHub CLI will show a one-time code and
browser URL. Open that URL on a trusted device and complete the browser sign-in.
EOF
      "${gh_bin}" auth login \
        --hostname github.com \
        --git-protocol https \
        --web \
        --scopes repo,read:org
    fi

    "${gh_bin}" auth setup-git --hostname github.com
    owner=${repository_slug%%/*}
    printf '%s\n' \
      "If ${owner} enforces SAML SSO, authorize GitHub CLI at:" \
      "https://github.com/orgs/${owner}/sso"
    "${gh_bin}" repo clone "${repository_slug}" "${workspace_dir}"
    mark_complete github
    printf 'GitHub project cloned into %s. Return to the editor to begin.\n' "${workspace_dir}"
    ;;
  status)
    [ "$#" -eq 1 ] || fail "status does not accept arguments."
    if [ -f "${completion_marker}" ]; then
      printf 'complete: %s\n' "$(sed -n '1p' "${completion_marker}")"
    else
      printf '%s\n' 'pending'
    fi
    ;;
  reset)
    [ "$#" -eq 1 ] || fail "reset does not accept arguments."
    rm -f "${completion_marker}"
    printf '%s\n' 'First-run project setup reset. Reopen the editor or run the setup command.'
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
