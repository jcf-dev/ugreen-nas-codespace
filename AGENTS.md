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
3. Do not weaken the password-required entrypoint, mount the Docker socket in
   the default Compose file, install a tunnel in the image, or run the IDE as
   root.
4. Keep downloads architecture-neutral or explicitly support both published
   architectures. Pin versions or verify checksums when upstream supports it.
5. Update `.env.example`, the root Compose file, the UGOS example, and user docs
   together when a deployment option changes.
6. Use Conventional Commit titles. Squash-merge titles determine SemVer:
   `feat:` is minor, `type!:` or `BREAKING CHANGE:` is major, everything else
   is patch.
7. Work through pull requests. Do not bypass protected `main`, required checks,
   or the no-force-push rule.

## Validation

Run the smallest applicable set and report anything not run:

```bash
IMAGE_NAME=local/ugreen-nas-codespace:test \
PASSWORD=test-only-not-for-deployment \
docker compose -f docker-compose.yml -f compose/build.yml config --quiet

docker compose -f examples/ugos/docker-compose.yml config --quiet
shellcheck scripts/*.sh
bash -n scripts/*.sh
```

For image or runtime changes, build the available architecture and run
`make verify`. For workflow changes, validate the YAML and inspect the resulting
GitHub Actions run before merging.

Repository-specific workflows are also available as skills:

- `$validate-container` before opening or merging a container-related PR.
- `$release-container` when preparing or diagnosing a SemVer image release.

## Documentation style

Write for NAS owners who may be new to Docker. Prefer copyable commands, state
where they run, warn before destructive or privileged operations, and avoid
claiming that community software is officially supported by UGREEN. Preserve
the independence disclaimer and AGPL-3.0-only licensing language.
