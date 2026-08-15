# Repository instructions for AI agents

## Project intent

Maintain a secure, single-user, browser-based development container for UGREEN
NAS devices. The published image must continue to support `linux/amd64` and
`linux/arm64`, require code-server authentication, and keep Cloudflare Tunnel
and Tailscale outside the application image.

## Sources of truth

- `Dockerfile` defines the image and installed tools.
- `docker-compose.yml` is the supported deployment configuration.
- `examples/ugos/docker-compose.yml` is the paste-ready UGOS example. Keep its
  image, port, mounts, security settings, and service behavior aligned with the
  root Compose file.
- `.env.example` documents supported deployment and build variables.
- `.github/workflows/ci.yml` is the required pull-request check.
- `.github/workflows/release.yml` owns automatic SemVer releases.
- `.github/workflows/publish.yml` owns multi-architecture Docker Hub tags.
- `README.md` and `docs/UGOS_SETUP.md` are end-user documentation.

## Change rules

1. Inspect `git status` and the relevant files before editing. Preserve
   unrelated user changes.
2. Never commit credentials, API keys, NAS addresses, private `.env` files, or
   generated authentication state.
3. Do not weaken hash-only code-server authentication or key-only SSH, mount the
   Docker socket in the default Compose file, install a tunnel in the image, or
   run the IDE as root. Plaintext `PASSWORD` must remain rejected.
4. Keep downloads architecture-neutral or explicitly support both published
   architectures. Pin versions or verify checksums when upstream supports it.
5. Keep the full and slim variants multi-architecture and their release tags in
   sync. Slim may defer optional tools into persistent `/home/coder/.local`.
6. Update `.env.example`, the root Compose file, the UGOS example, and user docs
   together when a deployment option changes. Workspace mounts must use an
   existing absolute host path and open `/workspace` explicitly.
7. Use Conventional Commit titles. Squash-merge titles determine SemVer:
   `feat:` is minor, `type!:` or `BREAKING CHANGE:` is major, everything else
   is patch.
8. Work through pull requests. Do not bypass protected `main`, required checks,
   or the no-force-push rule.

## Validation

Run the smallest applicable set and report anything not run:

```bash
IMAGE_NAME=local/ugreen-nas-codespace:test \
HASHED_PASSWORD='$$argon2id$$v=19$$m=65536,t=3,p=1$$test$$test' \
WORKSPACE_PATH=/absolute/existing/test/workspace \
docker compose -f docker-compose.yml -f compose/build.yml config --quiet

docker compose -f examples/ugos/docker-compose.yml config --quiet
shellcheck scripts/*.sh
bash -n scripts/*.sh
```

For image or runtime changes, build both `IMAGE_VARIANT=full` and
`IMAGE_VARIANT=slim` on the available architecture. Verify hashed login,
plaintext rejection, `/workspace` writes, dark defaults, key-only SSH, full
tools, and slim deferred-tool behavior. For workflow changes, validate the YAML
and inspect the resulting GitHub Actions run before merging.

Repository-specific workflows are also available as skills:

- `$validate-container` before opening or merging a container-related PR.
- `$release-container` when preparing or diagnosing a SemVer image release.

## Documentation style

Write for NAS owners who may be new to Docker. Prefer copyable commands, state
where they run, warn before destructive or privileged operations, and avoid
claiming that community software is officially supported by UGREEN. Preserve
the independence disclaimer and AGPL-3.0-only licensing language.
