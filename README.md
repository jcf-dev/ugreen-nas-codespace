# UGREEN NAS Codespace

A self-hosted, single-user development environment for a UGREEN NAS. It gives
you VS Code in a browser through code-server, a persistent workspace, and a
practical CLI toolchain similar to the day-to-day experience of GitHub
Codespaces.

This project is designed for `linux/amd64` and `linux/arm64`. It does not install
Cloudflare Tunnel or Tailscale in the application image; both are documented as
external access options below.

## Included

- Browser-based VS Code via code-server
- Git, Git LFS, GitHub CLI, SSH, GnuPG, and common terminal tools
- Python 3, `pip`, `pipx`, virtual environments, and `uv`
- NVM with Node.js 24, npm, pnpm, Yarn, and TypeScript
- Claude Code (`claude`) installed from `@anthropic-ai/claude-code`
- OpenAI Codex CLI (`codex`) installed from `@openai/codex`
- OpenCode CLI (`opencode`) installed from `opencode-ai`
- Docker, Buildx, and Compose **clients** for optional access to the NAS daemon
- Python, Ruff, ESLint, Prettier, YAML, and TOML editor extensions

The image intentionally does not include Docker Engine, Cloudflare Tunnel, or
Tailscale.

## Before you start

You need:

- A UGREEN NAS with Docker/Container Manager installed
- Docker Compose v2, either through the NAS interface or an SSH shell
- A writable NAS directory for source code
- At least 2 CPU cores and 4 GB RAM available; more is useful for large builds
- A strong code-server password, even when using a VPN or identity-aware proxy

This is a trusted, single-user development container. The `coder` account has
passwordless `sudo` inside the container. Do not expose it directly to the
public internet.

## Deploy a published image on UGREEN NAS

For a point-and-click UGOS Pro deployment, follow the complete
**[UGOS Pro setup guide](docs/UGOS_SETUP.md)**. It uses the standalone,
paste-ready **[UGOS Docker Compose example](examples/ugos/docker-compose.yml)**
and covers storage paths, UID/GID permissions, first login, updates, backups,
remote access, and troubleshooting.

For an SSH or file-based Compose deployment:

1. Download `docker-compose.yml` and `.env.example` into one directory on the
   NAS.
2. Copy the environment template and create the workspace:

   ```bash
   cp .env.example .env
   mkdir -p workspace
   chmod 600 .env
   ```

3. Edit `.env`:

   - Keep `IMAGE_NAME=joweenflores/ugreen-nas-codespace:latest`, or select a
     published semantic version for reproducible deployments.
   - Replace `PASSWORD` with a long, unique password.
   - Set `PUID` and `PGID` to the owner of the NAS workspace. From SSH, use
     `id` to inspect your user and group IDs.
   - Set `WORKSPACE_PATH` to an absolute NAS path if you do not want the default
     `./workspace` directory.
   - Change `TZ`, `WEB_PORT`, and `BIND_ADDRESS` if needed.

4. Pull and start:

   ```bash
   docker compose pull
   docker compose up -d
   docker compose ps
   ```

5. Open `http://NAS-LAN-IP:8443` and enter the password from `.env`.

UGOS Pro users who prefer the Project editor should use the dedicated example
rather than pasting the environment-variable-based root file.

### Build from source

Clone the repository, set `IMAGE_NAME=ugreen-nas-codespace:local` in `.env`, and
use the build override:

```bash
docker compose -f docker-compose.yml -f compose/build.yml build --pull
docker compose -f docker-compose.yml -f compose/build.yml up -d
```

The first build downloads the base image, language runtimes, CLI tools, and
editor extensions, so it can take several minutes.

## First login

Open the integrated terminal in VS Code and configure the tools you use:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
gh auth login
gh auth setup-git
```

Then start each AI coding CLI once:

```bash
claude
codex
opencode
```

- Claude Code walks through its supported login flow.
- Codex offers its available sign-in methods on first run. See the
  [official Codex CLI guide](https://learn.chatgpt.com/docs/codex/cli).
- In OpenCode, use `/connect` to select and authenticate an LLM provider. See
  the [OpenCode setup guide](https://dev.opencode.ai/docs/).

Authentication state is retained in named volumes. Do not bake API keys,
tokens, SSH private keys, or `.env` files into a custom image.

## Persistent data

| Path | Storage | Purpose |
| --- | --- | --- |
| `/workspace` | NAS bind mount | Repositories and project files |
| `/home/coder/.config` | Named volume | GitHub CLI, OpenCode, and app config |
| `/home/coder/.local` | Named volume | VS Code data/extensions and OpenCode data |
| `/home/coder/.claude` | Named volume | Claude Code state |
| `/home/coder/.codex` | Named volume | Codex state |
| `/home/coder/.ssh` | Named volume | SSH configuration and keys |
| `/home/coder/.gnupg` | Named volume | GPG configuration and keys |

Back up the workspace directory and named volumes before migrating the NAS.
`docker compose down` keeps them; `docker compose down --volumes` deletes the
named volumes and therefore removes retained tool configuration and credentials.

## Password options

The container refuses to start unless `PASSWORD` or `HASHED_PASSWORD` is set.
The straightforward setup stores `PASSWORD` in `.env`, so protect that file with
mode `0600` and restrict who can read the Compose project.

code-server also accepts an Argon2 value in `HASHED_PASSWORD`. Follow the
[official hashed-password instructions](https://coder.com/docs/code-server/FAQ#can-i-store-my-password-hashed).
When placing an Argon2 hash in a Compose `.env` file, escape every `$` as `$$`.
The hashed value takes precedence over `PASSWORD`.

## Remote access

Keep code-server authentication enabled with either option. A tunnel or VPN
protects network access but does not replace the IDE password.

### Tailscale

Install Tailscale on the NAS host, on a supported UGREEN package, or as a
separately managed container. Do not add it to this development image.

- Simple private access: keep `BIND_ADDRESS=0.0.0.0` and browse to
  `http://NAS-TAILSCALE-IP:8443`. Use Tailscale ACLs to restrict the port.
- Host-side HTTPS: set `BIND_ADDRESS=127.0.0.1`, then configure Tailscale Serve
  on the NAS to proxy `localhost:8443`. Follow the current
  [Tailscale Serve documentation](https://tailscale.com/docs/reference/tailscale-cli/serve).

### Cloudflare Tunnel

Install and run `cloudflared` separately on the NAS or another trusted device on
the same LAN. Create a published application route whose service URL is
`http://NAS-LAN-IP:8443` (or `http://localhost:8443` when `cloudflared` runs on
the NAS). See the [Cloudflare Tunnel setup guide](https://developers.cloudflare.com/tunnel/setup/).

Place a Cloudflare Access application and identity policy in front of the
hostname. Do not create a public DNS route without an access policy and the
code-server password.

## Optional Docker daemon access

Docker CLI, Buildx, and Compose are installed, but the NAS Docker socket is not
mounted by default. To enable it:

```bash
stat -c '%g' /var/run/docker.sock
```

Put that number in `DOCKER_GID` in `.env`, then start with the override:

```bash
docker compose -f docker-compose.yml -f compose/docker-socket.yml up -d
```

If building locally as well, include both overrides:

```bash
docker compose \
  -f docker-compose.yml \
  -f compose/build.yml \
  -f compose/docker-socket.yml \
  up -d --build
```

**Security warning:** access to `/var/run/docker.sock` is effectively root-level
control of the NAS. Enable it only for a trusted user, keep the IDE private, and
never mount the socket into an internet-exposed or shared instance.

For bind mounts launched from inside the codespace, Docker resolves host paths,
not container-only paths. Use NAS paths that exist identically on the host when
a child container needs to mount project files.

## Updates and customization

Update a published deployment:

```bash
docker compose pull
docker compose up -d
docker image prune
```

`docker image prune` removes only unused image layers; it does not remove the
workspace or named volumes.

For more OS packages, editor extensions, or globally installed npm tools, fork
the repository and update the Dockerfile. Runtime changes outside the mounted
paths are intentionally ephemeral and disappear when the container is replaced.

Build arguments let maintainers change the code-server, uv, NVM, Node, Claude
Code, Codex, and OpenCode versions. Pin the npm arguments to exact versions for
reproducible releases. The defaults use the upstream `latest` channel for the
three AI CLIs so newly built images receive current releases.

## Publish to Docker Hub

Protected merges to `main` automatically create a SemVer tag and GitHub Release,
then invoke the multi-architecture Docker Hub publishing workflow. Versions
start at `v0.1.0` and are derived from the squash-merge commit:

- `type(scope)!:` or a `BREAKING CHANGE:` footer increments the major version.
- `feat:` increments the minor version.
- Other changes increment the patch version.

To enable publishing:

1. Create the public Docker Hub repository
   `joweenflores/ugreen-nas-codespace`.
2. In the GitHub repository, add Actions secrets:
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN` (use a Docker Hub access token, not your password)
3. Merge a pull request into `main`. Direct pushes and force pushes are blocked.

Each release builds `linux/amd64` and `linux/arm64`, publishes the exact Git tag
(`vX.Y.Z`), `latest`, `X.Y.Z`, major/minor, major-only, and commit-SHA tags,
adds OCI metadata, and creates a build provenance attestation. Manually pushed
`v*.*.*` tags and manual workflow dispatches are also supported.

## How this differs from GitHub Codespaces

This project provides the most useful personal workflow pieces, but it is not a
drop-in implementation of GitHub Codespaces. It is one long-running container,
not an isolated VM-per-workspace control plane. It has no organization policy,
automatic suspend/billing, disposable workspace orchestration, or multi-user
isolation. Run one instance per trusted user if several people need access.

code-server uses the Open VSX extension registry. A few Microsoft Marketplace
extensions may be unavailable or licensed only for Microsoft's products.

## Project policy

- [Contributing](CONTRIBUTING.md)
- [UGOS Pro deployment guide](docs/UGOS_SETUP.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)
- [Support](SUPPORT.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

## License

Copyright © 2026 Joween Flores and contributors.

Licensed under the GNU Affero General Public License version 3 only
(`AGPL-3.0-only`). See [LICENSE](LICENSE).

Bundled and downloaded tools remain under their respective upstream licenses;
the AGPL does not relicense those separate works. UGREEN, GitHub, VS Code,
Cloudflare, Tailscale, Anthropic, OpenAI, and OpenCode are trademarks of their
respective owners.

## Legal disclaimer

This is an independent community project. The project and its repository
owners and maintainers are not affiliated with, employed by, sponsored by, or
endorsed by UGREEN, and have not been paid or otherwise compensated by UGREEN
for developing, maintaining, or promoting this project. Use of the UGREEN name
describes intended hardware compatibility only and does not imply an official
relationship, certification, or endorsement. Contributors participate in their
individual capacities unless they explicitly state otherwise.
