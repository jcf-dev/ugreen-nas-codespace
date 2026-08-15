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
PASSWORD=test-only-not-for-deployment \
docker compose -f docker-compose.yml -f compose/build.yml config --quiet
docker compose -f examples/ugos/docker-compose.yml config --quiet
```

For shell changes:

```bash
shellcheck scripts/*.sh
bash -n scripts/*.sh
```

For workflow changes, parse every `.github/workflows/*.yml` file and run
`actionlint` when it is installed. Inspect expressions, permissions,
concurrency, secret handling, and reusable-workflow inputs manually.

## Image checks

For Dockerfile, version, extension, or startup changes, build at least the local
architecture. Start the container with a test-only password and run
`make verify`. Confirm `/workspace` is writable for the configured UID/GID and
the health check reaches `/healthz`.

If both `linux/amd64` and `linux/arm64` were not built, state which architecture
was omitted. Never infer cross-architecture success from a single local build.

## Invariants

- Password or hashed-password authentication remains mandatory.
- The default container remains non-root.
- The Docker socket remains opt-in.
- Cloudflare Tunnel and Tailscale remain outside the image.
- Persistent paths and the UGOS example remain documented.
