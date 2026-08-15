---
name: release-container
description: Prepare, verify, or diagnose an automated SemVer release of the UGREEN NAS Codespace image. Use for release pull requests, version-bump questions, GitHub Release failures, Docker Hub publishing, missing tags, or multi-architecture manifest checks.
---

# Release Container

Read `AGENTS.md` and use protected pull requests. Confirm the squash PR title
selects the intended SemVer increment: breaking syntax is major, `feat:` is
minor, and all other Conventional Commit types are patch. The first release is
`v0.1.0`.

Before merge, require the `validate` check and ensure workflow secrets are never
printed. After merge, watch the Semantic release workflow, verify the GitHub
Release targets the merged commit, and inspect Docker Hub for `vX.Y.Z`,
`X.Y.Z`, `X.Y`, `X`, `latest`, and `sha-<short-sha>`. Confirm both
`linux/amd64` and `linux/arm64` and the provenance attestation.

If publishing fails, diagnose and rerun the existing version. Do not invent a
replacement tag or move an existing tag without explicit maintainer direction.
