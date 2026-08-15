# Contributing

Thanks for helping improve UGREEN NAS Codespace. Contributions to source,
documentation, compatibility, security, and reproducible builds are welcome.

Human and AI-assisted contributors should follow [AGENTS.md](AGENTS.md). Native
Codex and Claude Code repository skills are included for container validation
and release verification.

## Before opening a change

1. Search existing issues and pull requests.
2. For a large behavior or architecture change, open a proposal issue first.
3. Do not include credentials, private keys, NAS addresses, tunnel tokens, or
   personal `.env` files in reports, commits, images, or test output.

## Development setup

```bash
cp .env.example .env
```

Set `IMAGE_NAME=ugreen-nas-codespace:local`, choose a non-secret development
password, then run:

```bash
docker compose -f docker-compose.yml -f compose/build.yml config --quiet
docker compose -f docker-compose.yml -f compose/build.yml build
docker compose -f docker-compose.yml -f compose/build.yml up -d
make verify
```

Before submitting, verify at least the architecture you have available. State
whether you tested `linux/amd64`, `linux/arm64`, or only performed static checks.

## Pull requests

- Keep changes focused and explain the user-facing reason.
- Use a Conventional Commit title because squash-merged pull request titles
  determine the next SemVer release: `feat:` for minor, `fix:` for patch, and
  `type!:` or `BREAKING CHANGE:` for major.
- Update README and `.env.example` when adding an option.
- Prefer pinned download sources and verify signatures/checksums where upstream
  provides them.
- Preserve the password-required default and keep remote-access services outside
  the application image.
- Do not enable the Docker socket in the default Compose file.
- Use clear commit messages and add a changelog summary to the pull request.

By contributing, you agree that your contribution is licensed under
`AGPL-3.0-only`, as described in [LICENSE](LICENSE).
