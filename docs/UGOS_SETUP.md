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

1. Open **Docker** in UGOS Pro.
2. Open **Project**, select **Create**, and choose a project name such as
   `ugreen-nas-codespace`.
3. Copy the complete contents of
   [`examples/ugos/docker-compose.yml`](../examples/ugos/docker-compose.yml)
   into the Compose configuration editor.
4. Before deployment, edit these values in the configuration:

   - Replace `CHANGE-ME-TO-A-LONG-UNIQUE-PASSWORD` with a long, unique
     code-server password.
   - Replace the example `/volume1/.../workspace` source path with the absolute
     path prepared in step 2.
   - Change `user: "1000:1000"` if your workspace owner has another UID/GID.
   - Set `TZ` to an IANA time zone such as `Asia/Manila`.
   - Change host port `8443` if another application already uses it. Keep the
     container-side port `8080` unchanged.
   - For reproducible upgrades, replace `latest` with a published version such
     as `v0.1.1` after checking the Releases page.

5. Select **Deploy Now**. The first deployment downloads both the image and its
   platform-specific layers, so it can take a few minutes.

Anyone who can view the Project configuration can see its plain-text password.
Limit access to the UGOS administrator interface. Advanced users can use the
root [`docker-compose.yml`](../docker-compose.yml) with a protected `.env` file,
or set `HASHED_PASSWORD` as described in the main README.

## 4. Open the browser IDE

In Docker, wait until the `ugreen-codespace` container is running and healthy.
Then browse from the same network to:

```text
http://YOUR-NAS-LAN-IP:8443
```

Enter the password from the Project configuration. The editor opens
`/workspace`, which is the persistent NAS folder you mounted.

Open the integrated terminal and configure Git and the CLIs you use:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
gh auth login
gh auth setup-git
claude
codex
opencode
```

The GitHub, Claude Code, Codex, OpenCode, SSH, GPG, and VS Code data paths are
stored in Docker named volumes. They survive Project recreation, but deleting
the named volumes removes that retained configuration and may remove stored
credentials.

## 5. Update and back up

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

## 6. Configure access away from home

Do not forward port `8443` directly from the router to the internet. Keep
code-server password authentication enabled and use a separately managed
Tailscale connection or Cloudflare Tunnel with an identity policy. Follow the
[remote-access guidance in the README](../README.md#remote-access); neither
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

Open the container log in Docker. The image intentionally exits when both
`PASSWORD` and `HASHED_PASSWORD` are empty. Restore one authentication value and
redeploy.

### A CLI login disappeared

Confirm the named volumes were preserved when the Project was recreated.
Reauthenticate the affected CLI if its volume was deleted.

## Independence notice

UGREEN NAS Codespace is an independent community project. Its owners and
maintainers are not affiliated with, sponsored by, endorsed by, or paid by
UGREEN. Compatibility references do not imply official UGREEN support.
