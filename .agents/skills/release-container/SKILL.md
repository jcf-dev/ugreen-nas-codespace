---
name: release-container
description: Prepare, verify, or diagnose an automated SemVer release of the UGREEN NAS Codespace image. Use for release pull requests, version-bump questions, GitHub Release failures, Docker Hub publishing, missing tags, or multi-architecture manifest checks.
---

# Release Container

Use the protected pull-request workflow. Never create or move a release tag by
hand unless the maintainer explicitly requests recovery from an automation
failure.

## Determine the version

Read the latest `vX.Y.Z` tag and every commit since it. The merge commit subject
comes from the squash-merged pull-request title.

- `type(scope)!:` or a `BREAKING CHANGE:` footer increments major.
- `feat:` or `feat(scope):` increments minor.
- Any other conventional type increments patch.
- With no prior release, start at `v0.1.0`.

Ensure the pull-request title expresses the intended increment before merge.

## Pre-merge checks

1. Confirm the branch is based on current `main` and the required `validate`
   check passes.
2. Review `.github/workflows/release.yml` and `publish.yml` if either changed.
3. Confirm Docker Hub secrets are referenced only through GitHub Actions and
   are not printed.
4. Confirm tag generation includes `vX.Y.Z`, `X.Y.Z`, `X.Y`, `X`, `latest`, and
   `sha-<short-sha>`.

## Post-merge verification

1. Watch the Semantic release workflow through completion.
2. Confirm the GitHub Release targets the merged `main` commit.
3. Inspect the Docker Hub manifest for the exact Git tag and `latest`.
4. Confirm the manifest contains both `linux/amd64` and `linux/arm64` images.
5. Confirm build provenance attestation completed.

If publishing fails, diagnose the run before rerunning it. Prefer GitHub's
rerun mechanism or the workflow dispatch with the existing version; do not
create a second SemVer tag for the same commit.
