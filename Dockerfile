# syntax=docker/dockerfile:1.7

ARG CODE_SERVER_VERSION=4.132.0
ARG UV_VERSION=0.12.5
ARG IMAGE_VARIANT=full
ARG GO_VERSION=1.26.6

# Security rebuild pins. The commits are immutable resolutions of the matching
# signed upstream release tags. Rebuilding avoids shipping release binaries
# compiled with vulnerable Go standard libraries.
ARG GH_VERSION=v2.97.0
ARG GH_COMMIT=55dbb4dc6b7edb10b48e3d7fc5bccd32318d1b55
ARG GIT_LFS_VERSION=v3.7.1
ARG GIT_LFS_COMMIT=b84b33847fe6458f36ef521534dc0eac953cb379
ARG DIRENV_VERSION=v2.37.1
ARG DIRENV_COMMIT=7590ee2442104060bb11eedebd7bd6daf3d88fcd
ARG DOCKER_CLI_VERSION=v29.7.2
ARG DOCKER_CLI_COMMIT=a7dcaa6fdb6ed04aacbfdc76357fdae01605609e
ARG BUILDX_VERSION=v0.36.1
ARG BUILDX_COMMIT=1d8dde89b8aba914e05e45366770736fea1fd690
ARG COMPOSE_VERSION=v5.4.0
ARG COMPOSE_COMMIT=ef61d7410a0c816a71705026e638ec256a591d69

FROM golang:${GO_VERSION}-bookworm AS core-go-tools

ARG GH_VERSION
ARG GH_COMMIT
ARG GIT_LFS_VERSION
ARG GIT_LFS_COMMIT
ARG DIRENV_VERSION
ARG DIRENV_COMMIT

RUN set -eux; \
    mkdir -p /out; \
    git init /src/gh; \
    git -C /src/gh remote add origin https://github.com/cli/cli.git; \
    git -C /src/gh fetch --depth 1 origin "${GH_COMMIT}"; \
    git -C /src/gh checkout --detach FETCH_HEAD; \
    cd /src/gh; \
    go get golang.org/x/mod@v0.40.0; \
    git add go.mod go.sum; \
    git -c user.name=builder -c user.email=builder@localhost \
      commit -m 'build: update security dependencies'; \
    git tag "${GH_VERSION}"; \
    make bin/gh; \
    install -m 0755 bin/gh /out/gh; \
    test "$(/out/gh --version | sed -n '1s/.*version \([^ ]*\).*/v\1/p')" = "${GH_VERSION}"; \
    git init /src/git-lfs; \
    git -C /src/git-lfs remote add origin https://github.com/git-lfs/git-lfs.git; \
    git -C /src/git-lfs fetch --depth 1 origin "${GIT_LFS_COMMIT}"; \
    git -C /src/git-lfs checkout --detach FETCH_HEAD; \
    cd /src/git-lfs; \
    go get \
      golang.org/x/crypto@v0.55.0 \
      golang.org/x/net@v0.58.0 \
      golang.org/x/sync@v0.22.0 \
      golang.org/x/sys@v0.47.0 \
      golang.org/x/text@v0.41.0; \
    CGO_ENABLED=0 go build -mod=mod -trimpath \
      -ldflags="-s -w -X github.com/git-lfs/git-lfs/v3/config.GitCommit=${GIT_LFS_VERSION}" \
      -o /out/git-lfs ./git-lfs.go; \
    /out/git-lfs version; \
    git init /src/direnv; \
    git -C /src/direnv remote add origin https://github.com/direnv/direnv.git; \
    git -C /src/direnv fetch --depth 1 origin "${DIRENV_COMMIT}"; \
    git -C /src/direnv checkout --detach FETCH_HEAD; \
    cd /src/direnv; \
    go get golang.org/x/mod@v0.40.0; \
    CGO_ENABLED=0 go build -trimpath \
      -ldflags="-s -w" \
      -o /out/direnv .; \
    test "$(/out/direnv version)" = "${DIRENV_VERSION#v}"

FROM golang:${GO_VERSION}-bookworm AS docker-cli-builder

ARG DOCKER_CLI_VERSION
ARG DOCKER_CLI_COMMIT

RUN set -eux; \
    git init /go/src/github.com/docker/cli; \
    git -C /go/src/github.com/docker/cli remote add origin https://github.com/docker/cli.git; \
    git -C /go/src/github.com/docker/cli fetch --depth 1 origin "${DOCKER_CLI_COMMIT}"; \
    git -C /go/src/github.com/docker/cli checkout --detach FETCH_HEAD; \
    cd /go/src/github.com/docker/cli; \
    DISABLE_WARN_OUTSIDE_CONTAINER=1 \
      VERSION="${DOCKER_CLI_VERSION#v}" \
      GITCOMMIT="${DOCKER_CLI_COMMIT}" \
      ./scripts/build/binary; \
    install -D -m 0755 build/docker /out/docker; \
    /out/docker --version

FROM golang:${GO_VERSION}-bookworm AS buildx-builder

ARG BUILDX_VERSION
ARG BUILDX_COMMIT

RUN set -eux; \
    git init /src/buildx; \
    git -C /src/buildx remote add origin https://github.com/docker/buildx.git; \
    git -C /src/buildx fetch --depth 1 origin "${BUILDX_COMMIT}"; \
    git -C /src/buildx checkout --detach FETCH_HEAD; \
    cd /src/buildx; \
    go get golang.org/x/mod@v0.40.0; \
    CGO_ENABLED=0 go build -mod=mod -trimpath \
      -ldflags="-s -w -X github.com/docker/buildx/version.Version=${BUILDX_VERSION}" \
      -o /out/docker-buildx ./cmd/buildx; \
    /out/docker-buildx version

FROM golang:${GO_VERSION}-bookworm AS compose-builder

ARG COMPOSE_VERSION
ARG COMPOSE_COMMIT

RUN set -eux; \
    git init /src/compose; \
    git -C /src/compose remote add origin https://github.com/docker/compose.git; \
    git -C /src/compose fetch --depth 1 origin "${COMPOSE_COMMIT}"; \
    git -C /src/compose checkout --detach FETCH_HEAD; \
    cd /src/compose; \
    go get golang.org/x/mod@v0.40.0; \
    git add go.mod go.sum; \
    git -c user.name=builder -c user.email=builder@localhost \
      commit -m 'build: update security dependencies'; \
    git tag -f "${COMPOSE_VERSION}"; \
    CGO_ENABLED=0 go build -mod=mod -trimpath -tags e2e \
      -ldflags="-s -w -X github.com/docker/compose/v5/internal.Version=${COMPOSE_VERSION}" \
      -o /out/docker-compose ./cmd; \
    /out/docker-compose version

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv
FROM codercom/code-server:${CODE_SERVER_VERSION} AS base

ARG NVM_VERSION=v0.40.6
ARG NODE_VERSION=24
ARG CLAUDE_CODE_VERSION=latest
ARG CODEX_VERSION=latest
ARG OPENCODE_VERSION=latest
ARG PNPM_VERSION=latest
ARG YARN_VERSION=latest
ARG TYPESCRIPT_VERSION=6.0.3
ARG NPM_VERSION=12.0.2

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    ENTRYPOINTD=/home/coder/entrypoint.d \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    NVM_DIR=/usr/local/share/nvm \
    NVM_SYMLINK_CURRENT=true \
    PATH=/usr/local/share/nvm/current/bin:/home/coder/.local/bin:${PATH} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    UGREEN_CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION} \
    UGREEN_CODEX_VERSION=${CODEX_VERSION} \
    UGREEN_OPENCODE_VERSION=${OPENCODE_VERSION} \
    UV_NO_UPDATE=1

# Shared core for both variants: browser IDE base, Python, Git/GitHub, Node,
# key-only SSH, and the password-hash generator.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      argon2 \
      ca-certificates \
      curl \
      git \
      gnupg \
      openssh-client \
      openssh-server \
      python3 \
      python3-pip \
      python3-venv \
      ripgrep \
      sudo \
      xz-utils \
      zsh; \
    rm -rf \
      /usr/lib/python3/dist-packages/click \
      /usr/lib/python3/dist-packages/click-*.dist-info \
      /usr/lib/python3/dist-packages/wheel \
      /usr/lib/python3/dist-packages/wheel-*.dist-info; \
    python3 -m pip install --break-system-packages --no-cache-dir \
      click==8.3.3 \
      pipx==1.16.7 \
      wheel==0.46.2; \
    install -m 0755 -d /run/sshd; \
    rm -f /usr/local/bin/fixuid /etc/fixuid/config.yml; \
    ln -s /bin/true /usr/local/bin/fixuid; \
    rm -rf /var/lib/apt/lists/*

COPY --from=core-go-tools /out/gh /out/git-lfs /usr/local/bin/

RUN ln -sf /usr/local/bin/git-lfs /usr/bin/git-lfs \
    && git lfs install --system

RUN install -d -o coder -g coder \
      /home/coder/.claude \
      /home/coder/.codex \
      /home/coder/.config \
      /home/coder/.local \
      /home/coder/.ssh \
      /home/coder/entrypoint.d \
      /usr/local/share/nvm \
      /workspace \
    && install -d /opt/ugreen-codespace /usr/local/libexec \
      /usr/share/licenses/ugreen-nas-codespace \
    && chown coder:coder /workspace

USER coder

# Cache mounts keep the Node archive and npm tarballs out of the final image and
# make subsequent full/slim builds share the expensive downloads.
RUN --mount=type=cache,target=/usr/local/share/nvm/.cache,uid=1000,gid=1000 \
    --mount=type=cache,target=/home/coder/.npm,uid=1000,gid=1000 \
    set -eux; \
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" \
      -o /tmp/install-nvm.sh; \
    PROFILE=/dev/null bash /tmp/install-nvm.sh; \
    rm /tmp/install-nvm.sh; \
    bash -c '. "${NVM_DIR}/nvm.sh"; \
      nvm install "${NODE_VERSION}"; \
      nvm alias default "${NODE_VERSION}"; \
      nvm use default; \
      ln -sfn "${NVM_DIR}/versions/node/$(nvm version default)" "${NVM_DIR}/current"; \
      npm install --global --no-audit --no-fund \
        "npm@${NPM_VERSION}" \
        "pnpm@${PNPM_VERSION}" \
        "typescript@${TYPESCRIPT_VERSION}" \
        "yarn@${YARN_VERSION}"'

# Patch the embedded VS Code/code-server dependency trees until the fixes are
# included by upstream. These packages are pure JavaScript and architecture
# neutral; exact versions keep the overlay reproducible.
USER root
RUN --mount=type=cache,target=/root/.npm \
    set -eux; \
    npm install --prefix /tmp/security-patches --package-lock=false \
      --no-audit --no-fund --ignore-scripts \
      brace-expansion@5.0.9 \
      ip-address@10.3.1 \
      js-yaml@4.3.1 \
      undici@7.29.0; \
    rm -rf \
      "${NVM_DIR}/current/lib/node_modules/npm/node_modules/brace-expansion" \
      "${NVM_DIR}/current/lib/node_modules/npm/node_modules/ip-address" \
      /usr/lib/code-server/lib/vscode/node_modules/ip-address \
      /usr/lib/code-server/lib/vscode/node_modules/undici \
      /usr/lib/code-server/node_modules/js-yaml; \
    cp -a /tmp/security-patches/node_modules/brace-expansion \
      "${NVM_DIR}/current/lib/node_modules/npm/node_modules/brace-expansion"; \
    cp -a /tmp/security-patches/node_modules/ip-address \
      "${NVM_DIR}/current/lib/node_modules/npm/node_modules/ip-address"; \
    cp -a /tmp/security-patches/node_modules/ip-address \
      /usr/lib/code-server/lib/vscode/node_modules/ip-address; \
    cp -a /tmp/security-patches/node_modules/undici \
      /usr/lib/code-server/lib/vscode/node_modules/undici; \
    cp -a /tmp/security-patches/node_modules/js-yaml \
      /usr/lib/code-server/node_modules/js-yaml; \
    rm -rf /tmp/security-patches

USER coder

# The full image retains every originally promised development tool.
FROM base AS full

USER root

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash-completion \
      build-essential \
      cmake \
      dnsutils \
      fd-find \
      file \
      iproute2 \
      iputils-ping \
      jq \
      less \
      lsof \
      make \
      man-db \
      nano \
      netcat-openbsd \
      pkg-config \
      python3-dev \
      rsync \
      shellcheck \
      sqlite3 \
      tmux \
      tree \
      unzip \
      vim \
      wget \
      zip; \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=core-go-tools /out/direnv /usr/local/bin/direnv
COPY --from=docker-cli-builder /out/docker /usr/local/bin/docker
COPY --from=buildx-builder /out/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx
COPY --from=compose-builder /out/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose

USER coder

RUN --mount=type=cache,target=/home/coder/.npm,uid=1000,gid=1000 \
    set -eux; \
    bash -c '. "${NVM_DIR}/nvm.sh"; \
      npm install --global --no-audit --no-fund \
        --allow-scripts=@anthropic-ai/claude-code,opencode-ai \
        "@anthropic-ai/claude-code@${UGREEN_CLAUDE_CODE_VERSION}" \
        "@openai/codex@${UGREEN_CODEX_VERSION}" \
        "opencode-ai@${UGREEN_OPENCODE_VERSION}"'

RUN --mount=type=cache,target=/home/coder/.cache,uid=1000,gid=1000 \
    set -eux; \
    code-server --install-extension charliermarsh.ruff; \
    code-server --install-extension dbaeumer.vscode-eslint; \
    code-server --install-extension esbenp.prettier-vscode; \
    code-server --install-extension ms-python.python; \
    code-server --install-extension redhat.vscode-yaml; \
    code-server --install-extension tamasfe.even-better-toml; \
    rm -f /home/coder/.config/code-server/config.yaml

ENV UGREEN_IMAGE_VARIANT=full

# Slim keeps the core environment. AI CLIs install into the persistent .local
# volume when first invoked; optional build/Docker tools and extensions are
# intentionally omitted.
FROM base AS slim
ENV UGREEN_IMAGE_VARIANT=slim

FROM ${IMAGE_VARIANT} AS selected

LABEL org.opencontainers.image.title="UGREEN NAS Codespace" \
      org.opencontainers.image.description="A self-hosted, browser-based development environment for UGREEN NAS devices" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.opencontainers.image.base.name="docker.io/codercom/code-server"

USER root

COPY --chown=coder:coder config/settings.json /opt/ugreen-codespace/settings.json
COPY --chown=coder:coder config/code-server.yaml /opt/ugreen-codespace/code-server.yaml
COPY extensions/ugreen-onboarding /usr/lib/code-server/lib/vscode/extensions/ugreen-codespace-onboarding
COPY config/sshd_config /opt/ugreen-codespace/sshd_config
COPY --chown=coder:coder config/bashrc /home/coder/.bashrc
COPY --chown=coder:coder config/profile /home/coder/.profile
COPY --chown=coder:coder config/profile /home/coder/.bash_profile
COPY --chown=coder:coder config/zshrc /home/coder/.zshrc
COPY --chown=coder:coder scripts/init-workspace.sh /home/coder/entrypoint.d/10-init-workspace.sh
COPY scripts/entrypoint.sh /usr/local/bin/ugreen-codespace-entrypoint
COPY scripts/generate-hashed-password.sh /usr/local/bin/generate-hashed-password
COPY scripts/install-ai-tools.sh /usr/local/bin/install-ai-tools
COPY scripts/onboard-project.sh /usr/local/bin/ugreen-onboard
COPY scripts/ai-tool-wrapper.sh /usr/local/libexec/ugreen-ai-tool-wrapper
COPY LICENSE /usr/share/licenses/ugreen-nas-codespace/LICENSE

RUN chmod 0755 \
      /home/coder/entrypoint.d/10-init-workspace.sh \
      /usr/local/bin/ugreen-codespace-entrypoint \
      /usr/local/bin/generate-hashed-password \
      /usr/local/bin/install-ai-tools \
      /usr/local/bin/ugreen-onboard \
      /usr/local/libexec/ugreen-ai-tool-wrapper \
    && chmod 0644 /opt/ugreen-codespace/sshd_config \
    && chmod 0700 /home/coder/.ssh \
    && ln -sf /usr/local/libexec/ugreen-ai-tool-wrapper /usr/local/bin/claude \
    && ln -sf /usr/local/libexec/ugreen-ai-tool-wrapper /usr/local/bin/codex \
    && ln -sf /usr/local/libexec/ugreen-ai-tool-wrapper /usr/local/bin/opencode \
    && chown -R coder:coder /home/coder /workspace

USER coder
WORKDIR /workspace

EXPOSE 8080 2222

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/healthz >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/ugreen-codespace-entrypoint"]
CMD ["--bind-addr", "0.0.0.0:8080", "/workspace"]

# Collapse the prepared filesystem into one final layer. Besides reducing layer
# overhead, this prevents scanners from reporting binaries that were removed or
# replaced above but remain present in inherited base-image history.
FROM scratch AS final

COPY --from=selected / /

ARG IMAGE_VARIANT
ARG CLAUDE_CODE_VERSION=latest
ARG CODEX_VERSION=latest
ARG OPENCODE_VERSION=latest

LABEL org.opencontainers.image.title="UGREEN NAS Codespace" \
      org.opencontainers.image.description="A self-hosted, browser-based development environment for UGREEN NAS devices" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.opencontainers.image.base.name="docker.io/codercom/code-server"

ENV DEBIAN_FRONTEND=noninteractive \
    ENTRYPOINTD=/home/coder/entrypoint.d \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    NVM_DIR=/usr/local/share/nvm \
    NVM_SYMLINK_CURRENT=true \
    PATH=/usr/local/share/nvm/current/bin:/home/coder/.local/bin:/usr/local/bin:/usr/bin:/bin \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    UGREEN_CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION} \
    UGREEN_CODEX_VERSION=${CODEX_VERSION} \
    UGREEN_IMAGE_VARIANT=${IMAGE_VARIANT} \
    UGREEN_OPENCODE_VERSION=${OPENCODE_VERSION} \
    UV_NO_UPDATE=1

USER coder
WORKDIR /workspace

EXPOSE 8080 2222

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/healthz >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/ugreen-codespace-entrypoint"]
CMD ["--bind-addr", "0.0.0.0:8080", "/workspace"]
