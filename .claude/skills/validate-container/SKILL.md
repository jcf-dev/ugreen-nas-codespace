---
name: validate-container
description: Validate Dockerfile, Compose, shell, workflow, and runtime changes for the UGREEN NAS Codespace repository. Use before opening or merging a pull request that changes the image, deployment configuration, scripts, supported architectures, or GitHub Actions.
---

# Validate Container

Read `AGENTS.md`, inspect the relevant diff, and validate every changed surface.
Use the commands in the `Validation` section of `AGENTS.md`. For image or
startup changes, build the local architecture, start with a test-only password,
and run `make verify`.

Confirm these invariants:

- Password or hashed-password authentication remains mandatory.
- The default process remains non-root.
- The Docker socket remains opt-in.
- Cloudflare Tunnel and Tailscale remain outside the image.
- The root Compose file, UGOS example, environment template, and docs agree.
- Multi-architecture support is not broken.

Report each check actually run and any architecture not tested.
