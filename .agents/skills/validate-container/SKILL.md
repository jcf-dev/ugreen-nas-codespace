---
name: validate-container
description: Validate Dockerfile, Compose, shell, workflow, and runtime changes for the UGREEN NAS Codespace repository. Use before opening or merging a pull request that changes the image, deployment configuration, scripts, supported architectures, or GitHub Actions.
---

# Validate Container

Validate the changed surface proportionally. Do not claim checks that did not
run.

## Workflow

1. Read `AGENTS.md`, `git status`, and the relevant diff.
2. Classify the change as documentation, Compose, shell, Dockerfile/runtime, or
   GitHub Actions. Apply every matching check below.
3. Confirm no secrets, `.env` files, credentials, private endpoints, or tool
   authentication state are included.
4. Summarize passed checks, failures, and architecture coverage.

## Static checks

For Compose changes:

```bash
IMAGE_NAME=local/ugreen-nas-codespace:test \
HASHED_PASSWORD='$$argon2id$$v=19$$m=65536,t=3,p=1$$test$$test' \
WORKSPACE_PATH=/absolute/existing/test/workspace \
docker compose -f docker-compose.yml -f compose/build.yml config --quiet
docker compose -f examples/ugos/docker-compose.yml config --quiet
```

For shell changes:

```bash
shellcheck scripts/*.sh
bash -n scripts/*.sh
scripts/test-onboarding.sh
node --check extensions/ugreen-onboarding/extension.js
```

For workflow changes, parse every `.github/workflows/*.yml` file and run
`actionlint` when it is installed. Inspect expressions, permissions,
concurrency, secret handling, and reusable-workflow inputs manually.

## Image checks

For Dockerfile, version, extension, or startup changes, build the `full` and
`slim` variants on at least the local architecture. Generate a test-only hash
with `scripts/generate-hashed-password.sh --stdin`, then confirm:

- `PASSWORD` is rejected and a valid `HASHED_PASSWORD` starts code-server.
- `/workspace` is writable and code-server explicitly opens that directory.
- The default editor theme is dark and `/healthz` becomes healthy.
- The bundled onboarding extension is discoverable in both variants; blank
  setup preserves files, GitHub clone rejects non-empty workspaces, and the
  completion marker persists under `.config`.
- SSH starts only with a valid public key, accepts the matching key, and rejects
  password authentication.
- The full image contains the documented toolchain.
- The slim image contains core tools, omits bundled AI/Docker/build extras, and
  retains its deferred AI installer and wrappers.

If both `linux/amd64` and `linux/arm64` were not built, state which architecture
was omitted. Never infer cross-architecture success from a single local build.

## Invariants

- Only Argon2i/Argon2id `HASHED_PASSWORD` authentication is accepted;
  plaintext `PASSWORD` remains rejected.
- SSH remains non-root and public-key-only.
- The default container remains non-root.
- The Docker socket remains opt-in.
- Cloudflare Tunnel and Tailscale remain outside the image.
- Persistent paths and the UGOS example remain documented.
- Full and slim tags remain aligned across both published architectures.
