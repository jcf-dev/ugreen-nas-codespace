# syntax=docker/dockerfile:1.7

ARG CODE_SERVER_VERSION=4.132.0
ARG UV_VERSION=0.12.5
ARG IMAGE_VARIANT=full

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv
FROM codercom/code-server:${CODE_SERVER_VERSION} AS base

ARG NVM_VERSION=v0.40.6
ARG NODE_VERSION=24
ARG CLAUDE_CODE_VERSION=latest
ARG CODEX_VERSION=latest
ARG OPENCODE_VERSION=latest
ARG PNPM_VERSION=latest
ARG YARN_VERSION=latest
ARG TYPESCRIPT_VERSION=latest

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
      git-lfs \
      gnupg \
      openssh-client \
      openssh-server \
      pipx \
      python3 \
      python3-pip \
      python3-venv \
      ripgrep \
      sudo \
      xz-utils \
      zsh; \
    install -m 0755 -d /etc/apt/keyrings /etc/apt/sources.list.d /run/sshd; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/github-cli-archive-keyring.gpg; \
    chmod a+r /etc/apt/keyrings/github-cli-archive-keyring.gpg; \
    printf '%s\n' \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/github-cli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends gh; \
    git lfs install --system; \
    rm -rf /var/lib/apt/lists/*

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
        "pnpm@${PNPM_VERSION}" \
        "typescript@${TYPESCRIPT_VERSION}" \
        "yarn@${YARN_VERSION}"'

# The full image retains every originally promised development tool.
FROM base AS full

USER root

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash-completion \
      build-essential \
      cmake \
      direnv \
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
    curl -fsSL https://download.docker.com/linux/debian/gpg \
      -o /etc/apt/keyrings/docker.asc; \
    chmod a+r /etc/apt/keyrings/docker.asc; \
    . /etc/os-release; \
    printf '%s\n' \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" \
      > /etc/apt/sources.list.d/docker.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      docker-buildx-plugin \
      docker-ce-cli \
      docker-compose-plugin; \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/

USER coder

RUN --mount=type=cache,target=/home/coder/.npm,uid=1000,gid=1000 \
    set -eux; \
    bash -c '. "${NVM_DIR}/nvm.sh"; \
      npm install --global --no-audit --no-fund \
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
