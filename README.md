# UGREEN NAS Codespace

A self-hosted, single-user development environment for a UGREEN NAS. It gives
you VS Code in a browser through code-server, a persistent workspace, and a
practical CLI toolchain similar to the day-to-day experience of GitHub
Codespaces.

This project is designed for `linux/amd64` and `linux/arm64`. It does not install
Cloudflare Tunnel or Tailscale in the application image; both are documented as
external access options below.

## Choose an image

Two multi-architecture variants are published for `linux/amd64` and
`linux/arm64`:

| Tag | Best for | Contents |
| --- | --- | --- |
| `latest` or `vX.Y.Z` | A ready-to-use workstation | Core tools, AI CLIs, `uv`, Docker clients, build tools, and editor extensions |
| `slim` or `vX.Y.Z-slim` | Smaller downloads and storage use | Core tools; AI CLIs install into the persistent `.local` volume on first use |

Both variants include:

- Browser-based VS Code via code-server
- Guided first-run setup for a blank workspace or a GitHub repository
- Git, Git LFS, GitHub CLI, key-only SSH, GnuPG, and common terminal tools
- Python 3, `pip`, `pipx`, and virtual environments
- NVM with Node.js 24, npm, pnpm, Yarn, and TypeScript
- A dark editor theme and an explicit, writable `/workspace`
- Claude Code (`claude`), OpenAI Codex CLI (`codex`), and OpenCode CLI

The full image also bundles `uv`, Docker/Buildx/Compose **clients**, common
native build tools, all three AI CLIs, and Python/Ruff/ESLint/Prettier/YAML/TOML
editor extensions. The slim image omits those optional components. Its
`claude`, `codex`, or `opencode` command installs all three CLIs on first use;
the installation persists in `/home/coder/.local`.

The image intentionally does not include Docker Engine, Cloudflare Tunnel, or
Tailscale.

## Before you start

You need:

- A UGREEN NAS with Docker/Container Manager installed
- Docker Compose v2, either through the NAS interface or an SSH shell
- A writable NAS directory for source code
- At least 2 CPU cores and 4 GB RAM available; more is useful for large builds
- A strong code-server password from which to generate the required Argon2id
  hash, even when using a VPN or identity-aware proxy

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

1. Clone this repository into one NAS directory, or download
   `docker-compose.yml`, `.env.example`, and
   `scripts/generate-hashed-password.sh` while preserving that script path.
2. Copy the environment template and create an absolute workspace path:

   ```bash
   cp .env.example .env
   mkdir -p /volume1/docker/ugreen-nas-codespace/workspace
   chmod 600 .env
   ```

3. Generate the password hash locally. The password is read without echoing and
   is never written to `.env`:

   ```bash
   ./scripts/generate-hashed-password.sh
   ```

   Paste the complete `HASHED_PASSWORD=...` output over the empty line in
   `.env`. The doubled `$$` characters are required by Docker Compose.

4. Edit the remaining `.env` values:

   - Keep `IMAGE_NAME=joweenflores/ugreen-nas-codespace:latest`, or select a
     published semantic version for reproducible deployments. Use `:slim` for
     the smaller variant.
   - Set `PUID` and `PGID` to the owner of the NAS workspace. From SSH, use
     `id` to inspect your user and group IDs.
   - Set `WORKSPACE_PATH` to the existing absolute NAS path created above.
   - Set `SSH_AUTHORIZED_KEY` to one public key, or set `ENABLE_SSH=false`.
   - Change `TZ`, `WEB_PORT`, and `BIND_ADDRESS` if needed.

5. Pull and start:

   ```bash
   docker compose pull
   docker compose up -d
   docker compose ps
   ```

6. Open `http://NAS-LAN-IP:8443` and enter the original password used to
   generate the hash. The original password is not stored in Compose.

UGOS Pro users who prefer the Project editor should use the dedicated example
rather than pasting the environment-variable-based root file.

### Build from source

Clone the repository, set `IMAGE_NAME=ugreen-nas-codespace:local` in `.env`, and
use the build override. Set `IMAGE_VARIANT=slim` to build the smaller variant:

```bash
docker compose -f docker-compose.yml -f compose/build.yml build --pull
docker compose -f docker-compose.yml -f compose/build.yml up -d
```

The first build downloads the base image, language runtimes, CLI tools, and
editor extensions, so it can take several minutes. Security-sensitive Go CLIs
are rebuilt from pinned upstream release commits with the patched Go toolchain.
The final filesystem is flattened so removed or replaced base-image binaries
are not retained in image history or reported as active packages by scanners.

Pull requests build and scan both image variants with Docker Scout. CI rejects
fixable critical or high-severity findings before a change can merge, except
for a repository-reviewed OpenVEX assessment when the vulnerable code is not
in the image's execution path.

## First-run project setup

After the first browser login, the editor asks how to prepare `/workspace`.
The chooser uses native VS Code controls and codicons, so it automatically
matches the active code-server theme, keyboard navigation, and accessibility:

- **Blank project** uses the mounted workspace as a fresh project folder. It
  never deletes existing NAS files; if the folder is not empty, it asks before
  using the files already there.
- **Clone from GitHub** asks for `OWNER/REPOSITORY` or a `github.com` URL, opens
  a terminal for GitHub CLI browser authentication, configures Git's credential
  helper, and clones into the empty workspace. The clone is refused when the
  folder contains files.
- **GitLab** is shown as coming soon and does not configure or store anything.
- **Ask me later** shows the choices again on the next browser session.

For a private repository, follow the one-time code and URL shown in the setup
terminal. GitHub CLI uses its browser-based OAuth flow. If the repository
belongs to an organization that enforces SAML SSO, first establish an active
SSO session and authorize GitHub CLI for that organization; organization policy
may require an administrator to approve the OAuth app. See GitHub's
[OAuth authorization and SAML SSO guidance](https://docs.github.com/en/apps/oauth-apps/using-oauth-apps/authorizing-oauth-apps).

The completion marker is retained in `/home/coder/.config`. To choose again,
open the Command Palette and run **UGREEN Codespace: Reset First-Run Setup**.
You can also run **UGREEN Codespace: Run First-Run Setup** without resetting
the saved choice. The equivalent terminal commands are:

```bash
ugreen-onboard status
ugreen-onboard reset
```

After choosing a project, configure your Git identity in the integrated
terminal:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
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
- On the slim image, the first of these commands downloads all three AI CLIs
  into the persistent `.local` volume. Run `install-ai-tools --upgrade` later
  to refresh them.

Authentication state is retained in named volumes. GitHub CLI uses secure
credential storage when one is available, but may store its OAuth token in its
configuration file when the container has no credential store. Treat the
`.config` volume and UGOS administrator access as sensitive. No GitHub token is
accepted through Compose or baked into the image. Do not bake API keys, tokens,
SSH private keys, or `.env` files into a custom image. See the
[GitHub CLI authentication reference](https://cli.github.com/manual/gh_auth_login).

## Persistent data

| Path | Storage | Purpose |
| --- | --- | --- |
| `/workspace` | NAS bind mount | Repositories and project files |
| `/home/coder/.config` | Named volume | First-run state, GitHub CLI credentials, OpenCode, and app config |
| `/home/coder/.local` | Named volume | VS Code data/extensions and OpenCode data |
| `/home/coder/.claude` | Named volume | Claude Code state |
| `/home/coder/.codex` | Named volume | Codex state |
| `/home/coder/.ssh` | Named volume | SSH configuration and keys |
| `/home/coder/.gnupg` | Named volume | GPG configuration and keys |

Back up the workspace directory and named volumes before migrating the NAS.
`docker compose down` keeps them; `docker compose down --volumes` deletes the
named volumes and therefore removes retained tool configuration and credentials.

## Password authentication

Only `HASHED_PASSWORD` is accepted. The container rejects `PASSWORD` and exits
if the required Argon2i/Argon2id hash is absent or malformed. Generate a
Compose-safe Argon2id value with:

```bash
./scripts/generate-hashed-password.sh
```

The script uses a local `argon2` command when available, otherwise it uses a
one-off container. It never prints the original password. For automation only,
it also accepts a password on standard input with `--stdin`; avoid shell command
arguments because they may be recorded in history or process listings.

Protect `.env` with mode `0600`. A password hash is safer to store than its
plaintext source, but it is still authentication material and can be attacked
offline. Use a long, unique password. See code-server's
[official hashed-password guidance](https://coder.com/docs/code-server/FAQ#can-i-store-my-password-hashed).

## SSH from a terminal or desktop VS Code

The image includes a non-root SSH server on container port `2222`. It accepts
public keys only: SSH passwords, keyboard-interactive authentication, empty
passwords, and root login are disabled.

1. Create a dedicated key on your laptop if you do not already have one:

   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/ugreen_codespace -C ugreen-codespace
   cat ~/.ssh/ugreen_codespace.pub
   ```

2. Paste that single public-key line into `SSH_AUTHORIZED_KEY` in `.env`. Never
   copy the private key to the NAS or container. Redeploy with
   `docker compose up -d`.
3. Add a laptop-side `~/.ssh/config` entry:

   ```sshconfig
   Host ugreen-codespace
     HostName NAS-LAN-OR-TAILSCALE-IP
     User coder
     Port 2222
     IdentityFile ~/.ssh/ugreen_codespace
   ```

4. Connect with `ssh ugreen-codespace`, or install Microsoft's **Remote - SSH**
   extension in desktop VS Code and run **Remote-SSH: Connect to Host**.

The browser editor and SSH sessions both open the same `/workspace`. If you do
not need SSH, set `ENABLE_SSH=false`; when no authorized key is configured, the
SSH server does not start.

## Access away from home

Keep code-server hash authentication enabled. A tunnel or VPN protects network
access but does not replace the IDE password. Do not directly forward either
the web port or SSH port from your router to the public internet.

### Tailscale

Install Tailscale on the NAS host, on a supported UGREEN package, or as a
separately managed container. Do not add it to this development image.

- Simple private access: keep `BIND_ADDRESS=0.0.0.0` and browse to
  `http://NAS-TAILSCALE-IP:8443`. Use Tailscale ACLs to restrict the port.
- For terminal or Remote-SSH access, connect to the NAS Tailscale address on
  port `2222` and restrict that port with Tailscale ACLs.
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
code-server password. Tailscale is generally simpler for raw SSH; Cloudflare
SSH requires a separately configured Access TCP/SSH flow.

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

Each release builds `linux/amd64` and `linux/arm64`. The full image receives the
exact Git tag (`vX.Y.Z`), `latest`, `X.Y.Z`, major/minor, major-only, and
commit-SHA tags. The slim image receives `slim`, `vX.Y.Z-slim`, matching
major/minor tags with `-slim`, and a `-slim` SHA tag. Both variants include OCI
metadata and build provenance. Manually pushed `v*.*.*` tags and manual
workflow dispatches are also supported.

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
