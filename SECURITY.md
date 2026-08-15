# Security Policy

## Supported versions

Security fixes are applied to the latest image tag and the current default
branch. Rebuild and redeploy promptly after a security release; old container
images are not supported indefinitely.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting feature for this repository. If it
is not enabled, contact the maintainers privately using the contact information
on their GitHub profiles. Do not disclose an unpatched vulnerability in a public
issue, discussion, pull request, image log, or Docker Hub comment.

Include affected versions, architecture, configuration, reproduction steps,
impact, and any suggested mitigation. Remove tokens, passwords, private keys,
hostnames, and personal data from the report.

Maintainers should acknowledge a report within seven days and provide a status
update within fourteen days. Timelines for remediation and coordinated
disclosure depend on severity and upstream dependencies.

## Deployment security

- Keep hash-only code-server authentication enabled; never configure
  `PASSWORD`.
- Keep SSH public-key-only and disable it when unused.
- Use Tailscale or Cloudflare Tunnel with an access policy for remote access.
- Do not directly forward the IDE or SSH port from the public internet.
- Treat Docker socket access as root access to the NAS.
- Use unique credentials and back up persistent volumes securely.
- Never bake secrets into the image or commit `.env`.
