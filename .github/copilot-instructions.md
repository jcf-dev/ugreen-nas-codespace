# GitHub Copilot repository instructions

Follow `AGENTS.md` as the repository source of truth. Preserve authentication,
non-root execution, multi-architecture support, external tunnel separation,
protected-branch delivery, and AGPL-3.0-only licensing. Keep the root Compose
file, UGOS example, environment template, and end-user documentation in sync.
Use Conventional Commit pull-request titles because the squash title controls
the automatic SemVer release.

First-run setup must remain non-destructive. Blank setup preserves existing
files, GitHub setup clones only into an empty `/workspace`, OAuth tokens never
travel through Compose or command arguments, and GitLab remains marked as
unsupported until implemented. Keep the onboarding extension and helper tests
in sync.
