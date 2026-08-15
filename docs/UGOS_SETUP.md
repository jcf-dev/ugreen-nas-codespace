# Set up UGREEN NAS Codespace in UGOS Pro

This guide deploys the published image through the UGOS Pro Docker application.
It does not install Cloudflare Tunnel or Tailscale in the codespace container.

## 1. Check compatibility

Use a UGREEN NAS model that offers the Docker application in UGOS Pro. Docker
availability varies by model; check the App Center on the NAS or the current
model specifications before continuing. The NAS also needs at least 2 CPU cores
and 4 GB of available memory for a comfortable small-project setup.

Update UGOS Pro, install **Docker** from App Center, and open it once before
creating the project.

## 2. Prepare persistent storage

In UGOS File Manager, create a folder for the project and a `workspace`
subfolder. For example:

```text
docker/
└── ugreen-nas-codespace/
    └── workspace/
```

Find the absolute filesystem path for `workspace`. The paste-ready example uses
`/volume1/docker/ugreen-nas-codespace/workspace`, but storage-pool names and
paths differ. Replace it with the path shown by your NAS rather than assuming
the example is correct.

The container runs as UID and GID `1000` by default. If the workspace is owned
by another account, use an SSH terminal on the NAS to run:

```bash
id YOUR_NAS_USERNAME
```

Record the numeric `uid` and `gid`. You will put them in the Compose `user`
field as `UID:GID`. Do not enable SSH solely for this deployment if your UGOS
file-permission interface already gives you the correct ownership information.

## 3. Create the Docker Project

Before opening the Project editor, generate a Compose-safe password hash. If
you cloned this repository on a computer with Docker, run:

```bash
./scripts/generate-hashed-password.sh
```

Without a clone, run the generator from the published image:

```bash
docker run --rm -it \
  --entrypoint /usr/local/bin/generate-hashed-password \
  joweenflores/ugreen-nas-codespace:latest
```

The prompt hides your input and prints a line beginning with
`HASHED_PASSWORD=$$argon2id$$`. Save the original password in your password
manager. The project stores only its hash.

For optional terminal and desktop VS Code access, create a dedicated key on
your laptop and display its public half:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ugreen_codespace -C ugreen-codespace
cat ~/.ssh/ugreen_codespace.pub
```

Never copy the private key to the NAS or paste it into Compose.

1. Open **Docker** in UGOS Pro.
2. Open **Project**, select **Create**, and choose a project name such as
   `ugreen-nas-codespace`.
3. Copy the complete contents of
   [`examples/ugos/docker-compose.yml`](../examples/ugos/docker-compose.yml)
   into the Compose configuration editor.
4. Before deployment, edit these values in the configuration:

   - In the generator output, copy everything after `HASHED_PASSWORD=`. Replace
     the hash placeholder between the Compose quotation marks with that value,
     preserving every doubled `$$`.
   - Replace the SSH public-key placeholder with the complete `.pub` line. If
     you do not want SSH, set `ENABLE_SSH` to `"false"`; an empty key also keeps
     the SSH server stopped.
   - Replace the example `/volume1/.../workspace` source path with the absolute
     path prepared in step 2.
   - Change `user: "1000:1000"` if your workspace owner has another UID/GID.
   - Set `TZ` to an IANA time zone such as `Asia/Manila`.
   - Change host port `8443` if another application already uses it. Keep the
     container-side port `8080` unchanged.
   - Change host port `2222` if needed. Keep container port `2222` unchanged.
   - For reproducible upgrades, replace `latest` with a published version such
     as `v1.0.0` after checking the Releases page. Use `slim` or
     `vX.Y.Z-slim` when download and disk size matter more than bundled extras.

5. Select **Deploy Now**. The first deployment downloads both the image and its
   platform-specific layers, so it can take a few minutes.

The image does not accept plaintext password configuration. Still limit access
to the UGOS administrator interface because the stored hash is authentication
material. Advanced users can use the root
[`docker-compose.yml`](../docker-compose.yml) with a protected `.env` file.

## 4. Open the browser IDE

In Docker, wait until the `ugreen-codespace` container is running and healthy.
Then browse from the same network to:

```text
http://YOUR-NAS-LAN-IP:8443
```

Enter the original password used to generate the hash. The dark-themed editor
opens `/workspace`, which is the persistent NAS folder you mounted. Using the
absolute mount prevents the Project's own `docker-compose.yml` from being
opened as an accidental, read-only workspace on first launch.

The editor now asks how to prepare the project:

1. Choose **Blank project** for a fresh folder. This choice never deletes NAS
   files; if the workspace already contains files, the editor asks before using
   them as-is.
2. Choose **Clone from GitHub** to enter `OWNER/REPOSITORY` or a GitHub URL. The
   workspace must be empty. A terminal opens with a one-time code and browser
   URL for GitHub sign-in, then clones the repository.
3. **GitLab** is displayed as coming soon. Choose **Ask me later** if you are
   not ready.

For private repositories in an organization that enforces SAML SSO, sign in
through the organization and authorize the GitHub CLI OAuth app when GitHub
requests it. An organization administrator may need to approve the app. GitHub
documents this in
[Authorizing OAuth apps](https://docs.github.com/en/apps/oauth-apps/using-oauth-apps/authorizing-oauth-apps).

To see the project choices again, open the Command Palette and run **UGREEN
Codespace: Reset First-Run Setup**. The choice is stored in the `.config`
volume, not in the repository or workspace.

Open the integrated terminal and configure Git and the AI CLIs you use:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
claude
codex
opencode
```

The GitHub, Claude Code, Codex, OpenCode, SSH, GPG, and VS Code data paths are
stored in Docker named volumes. They survive Project recreation, but deleting
the named volumes removes that retained configuration and may remove stored
credentials.

GitHub CLI uses secure credential storage when available and otherwise may
store its OAuth token in its configuration file. Protect the `.config` volume
and UGOS administrator account as credential-bearing resources. The deployment
does not put a GitHub token in Compose.

On the slim image, the first `claude`, `codex`, or `opencode` command installs
all three tools into the persistent `.local` volume. This one-time download can
take a few minutes. Run `install-ai-tools --upgrade` to update them later.

## 5. Connect with SSH or desktop VS Code

After setting `SSH_AUTHORIZED_KEY`, connect from the laptop that owns the
matching private key:

```bash
ssh -i ~/.ssh/ugreen_codespace -p 2222 coder@YOUR-NAS-LAN-IP
```

For a convenient saved target, add this to the laptop's `~/.ssh/config`:

```sshconfig
Host ugreen-codespace
  HostName YOUR-NAS-LAN-OR-TAILSCALE-IP
  User coder
  Port 2222
  IdentityFile ~/.ssh/ugreen_codespace
```

Then run `ssh ugreen-codespace`. In desktop VS Code, install **Remote - SSH**,
run **Remote-SSH: Connect to Host**, choose `ugreen-codespace`, and open
`/workspace`. Password-based SSH and root login are disabled.

## 6. Update and back up

Back up the NAS `workspace` folder and the project volumes before major changes.
Do not delete volumes unless you intend to erase retained editor and CLI state.

To follow current releases, pull the newer image in UGOS Docker and recreate the
Project with the same volumes. If you manage the project from an SSH shell, run
these commands in its directory:

```bash
docker compose pull
docker compose up -d
```

Pin the image to `vX.Y.Z` when you prefer controlled upgrades. Change the tag
only after reviewing the corresponding GitHub Release.

## 7. Configure access away from home

Do not forward ports `8443` or `2222` directly from the router to the internet.
Keep code-server authentication enabled and use a separately managed Tailscale
connection or Cloudflare Tunnel with an identity policy. Follow the
[away-from-home guidance in the README](../README.md#access-away-from-home); neither
service belongs in this application image or Compose example.

## Troubleshooting

### The Project does not deploy

- Confirm the NAS model supports Docker and enough storage is available.
- Check that the Compose editor contains spaces rather than tab characters.
- Make sure the selected host port is unused.
- Confirm the workspace source is an absolute path that exists on the NAS.

### The editor opens but cannot save files

The UID/GID in `user` does not own the mounted workspace, or the UGOS shared
folder permissions deny writes. Match `user: "UID:GID"` to the folder owner and
grant that account read/write access in UGOS.

### The container repeatedly restarts

Open the container log in Docker. The image intentionally exits when
`HASHED_PASSWORD` is empty, malformed, or still a placeholder, and it rejects
the `PASSWORD` variable. Generate a valid hash and redeploy.

### SSH does not start

Confirm `ENABLE_SSH` is `"true"`, `SSH_AUTHORIZED_KEY` contains one complete
supported public-key line, and host port `2222` is free. Inspect the container
log for a rejected key. Never use a private key as this value.

### A CLI login disappeared

Confirm the named volumes were preserved when the Project was recreated.
Reauthenticate the affected CLI if its volume was deleted.

### The first-run project prompt did not appear

Open the Command Palette and run **UGREEN Codespace: Run First-Run Setup**. To
discard only the saved setup choice and prompt again, run **UGREEN Codespace:
Reset First-Run Setup**. Neither command deletes workspace files.

### A GitHub private repository will not clone

Confirm your GitHub account can see the repository. If its organization
enforces SAML SSO, establish an active SSO session and authorize the GitHub CLI
OAuth app for that organization. Some organizations require administrator
approval. Move or back up any files already in `/workspace`; onboarding refuses
to clone over a non-empty folder.

## Independence notice

UGREEN NAS Codespace is an independent community project. Its owners and
maintainers are not affiliated with, sponsored by, endorsed by, or paid by
UGREEN. Compatibility references do not imply official UGREEN support.
