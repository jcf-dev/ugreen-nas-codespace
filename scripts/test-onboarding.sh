#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
onboard_script="${script_dir}/onboard-project.sh"
test_root=$(mktemp -d)
trap 'rm -rf "${test_root}"' EXIT HUP INT TERM

workspace_dir="${test_root}/workspace"
state_dir="${test_root}/state"
fake_gh="${test_root}/gh"
gh_log="${test_root}/gh.log"

mkdir -p "${workspace_dir}"

UGREEN_WORKSPACE_DIR="${workspace_dir}" \
UGREEN_ONBOARDING_STATE_DIR="${state_dir}" \
  "${onboard_script}" blank
test "$(cat "${state_dir}/onboarding-complete")" = blank

UGREEN_ONBOARDING_STATE_DIR="${state_dir}" "${onboard_script}" reset
test ! -e "${state_dir}/onboarding-complete"

if UGREEN_WORKSPACE_DIR="${workspace_dir}" \
  UGREEN_ONBOARDING_STATE_DIR="${state_dir}" \
  "${onboard_script}" github 'not-a-repository'; then
  printf >&2 '%s\n' 'Invalid GitHub repository was accepted.'
  exit 1
fi

cat > "${fake_gh}" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >> "${UGREEN_TEST_GH_LOG}"
case "$1 $2" in
  'auth status')
    test "${UGREEN_TEST_GH_AUTHENTICATED:-false}" = true
    ;;
  'auth login'|'auth setup-git') exit 0 ;;
  'repo clone')
    mkdir -p "$4/.git"
    printf '# cloned in test\n' > "$4/README.md"
    ;;
  *) exit 1 ;;
esac
EOF
chmod 0755 "${fake_gh}"

printf '%s\n' existing > "${workspace_dir}/existing.txt"
if UGREEN_WORKSPACE_DIR="${workspace_dir}" \
  UGREEN_ONBOARDING_STATE_DIR="${state_dir}" \
  UGREEN_GH_BIN="${fake_gh}" \
  UGREEN_TEST_GH_LOG="${gh_log}" \
  "${onboard_script}" github owner/repository; then
  printf >&2 '%s\n' 'A GitHub clone into a non-empty workspace was accepted.'
  exit 1
fi
test ! -e "${gh_log}"

rm "${workspace_dir}/existing.txt"
UGREEN_WORKSPACE_DIR="${workspace_dir}" \
UGREEN_ONBOARDING_STATE_DIR="${state_dir}" \
UGREEN_GH_BIN="${fake_gh}" \
UGREEN_TEST_GH_LOG="${gh_log}" \
UGREEN_TEST_GH_AUTHENTICATED=false \
  "${onboard_script}" github https://github.com/owner/repository.git

test -d "${workspace_dir}/.git"
test "$(cat "${state_dir}/onboarding-complete")" = github
grep -Fx 'auth status --hostname github.com' "${gh_log}" >/dev/null
grep -Fx 'auth login --hostname github.com --git-protocol https --web --scopes repo,read:org' \
  "${gh_log}" >/dev/null
grep -Fx 'auth setup-git --hostname github.com' "${gh_log}" >/dev/null
grep -Fx "repo clone owner/repository ${workspace_dir}" "${gh_log}" >/dev/null

printf '%s\n' 'Onboarding helper tests passed.'
