# syntax=docker/dockerfile:1.7

ARG CODE_SERVER_VERSION=4.130.0
ARG UV_VERSION=0.11.32

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv
FROM codercom/code-server:${CODE_SERVER_VERSION}

ARG NVM_VERSION=v0.40.6
ARG NODE_VERSION=24
ARG CLAUDE_CODE_VERSION=latest
ARG CODEX_VERSION=latest
ARG OPENCODE_VERSION=latest
ARG PNPM_VERSION=latest
ARG YARN_VERSION=latest
ARG TYPESCRIPT_VERSION=latest

LABEL org.opencontainers.image.title="UGREEN NAS Codespace" \
      org.opencontainers.image.description="A self-hosted, browser-based development environment for UGREEN NAS devices" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.opencontainers.image.base.name="docker.io/codercom/code-server"

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    ENTRYPOINTD=/home/coder/entrypoint.d \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    NVM_DIR=/usr/local/share/nvm \
    NVM_SYMLINK_CURRENT=true \
    PATH=/usr/local/share/nvm/current/bin:/home/coder/.local/bin:${PATH} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    UV_NO_UPDATE=1

# General development tools plus the official GitHub CLI and Docker CLI
# repositories. Docker Engine is intentionally not installed in this image.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash-completion \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      direnv \
      dnsutils \
      fd-find \
      file \
      git \
      git-lfs \
      gnupg \
      iproute2 \
      iputils-ping \
      jq \
      less \
      locales \
      lsof \
      make \
      man-db \
      nano \
      netcat-openbsd \
      openssh-client \
      pipx \
      pkg-config \
      procps \
      python3 \
      python3-dev \
      python3-pip \
      python3-venv \
      ripgrep \
      rsync \
      shellcheck \
      sqlite3 \
      sudo \
      tmux \
      tree \
      unzip \
      vim \
      wget \
      xz-utils \
      zip \
      zsh; \
    install -m 0755 -d /etc/apt/keyrings /etc/apt/sources.list.d; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    printf '%s\n' \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list; \
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
      docker-compose-plugin \
      gh; \
    git lfs install --system; \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/

RUN install -d -o coder -g coder \
      /home/coder/.claude \
      /home/coder/.codex \
      /home/coder/.config \
      /home/coder/.local \
      /home/coder/.ssh \
      /home/coder/entrypoint.d \
      /usr/local/share/nvm \
      /workspace \
    && install -d /opt/ugreen-codespace /usr/share/licenses/ugreen-nas-codespace \
    && chown coder:coder /workspace

USER coder

# NVM is installed system-wide but remains owned by the non-root coder user, so
# `nvm install` continues to work from the integrated terminal.
RUN set -eux; \
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" \
      -o /tmp/install-nvm.sh; \
    PROFILE=/dev/null bash /tmp/install-nvm.sh; \
    rm /tmp/install-nvm.sh; \
    bash -c '. "${NVM_DIR}/nvm.sh"; \
      nvm install "${NODE_VERSION}"; \
      nvm alias default "${NODE_VERSION}"; \
      nvm use default; \
      ln -sfn "${NVM_DIR}/versions/node/$(nvm version default)" "${NVM_DIR}/current"; \
      npm install --global \
        "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
        "@openai/codex@${CODEX_VERSION}" \
        "opencode-ai@${OPENCODE_VERSION}" \
        "pnpm@${PNPM_VERSION}" \
        "typescript@${TYPESCRIPT_VERSION}" \
        "yarn@${YARN_VERSION}"; \
      npm cache clean --force'

# A compact starter set. More extensions can be installed normally from the
# code-server Extensions panel and are retained in the persistent local volume.
RUN set -eux; \
    code-server --install-extension charliermarsh.ruff; \
    code-server --install-extension dbaeumer.vscode-eslint; \
    code-server --install-extension esbenp.prettier-vscode; \
    code-server --install-extension ms-python.python; \
    code-server --install-extension redhat.vscode-yaml; \
    code-server --install-extension tamasfe.even-better-toml

USER root

COPY --chown=coder:coder config/settings.json /opt/ugreen-codespace/settings.json
COPY --chown=coder:coder config/bashrc /home/coder/.bashrc
COPY --chown=coder:coder config/profile /home/coder/.profile
COPY --chown=coder:coder config/profile /home/coder/.bash_profile
COPY --chown=coder:coder config/zshrc /home/coder/.zshrc
COPY --chown=coder:coder scripts/init-workspace.sh /home/coder/entrypoint.d/10-init-workspace.sh
COPY scripts/entrypoint.sh /usr/local/bin/ugreen-codespace-entrypoint
COPY LICENSE /usr/share/licenses/ugreen-nas-codespace/LICENSE

RUN chmod 0755 /home/coder/entrypoint.d/10-init-workspace.sh \
    && chmod 0755 /usr/local/bin/ugreen-codespace-entrypoint \
    && chmod 0700 /home/coder/.ssh \
    && chown -R coder:coder /home/coder /workspace

USER coder
WORKDIR /workspace

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/healthz >/dev/null || exit 1

# The wrapper enforces authentication, then delegates to the upstream image's
# fixuid-aware entrypoint. The final dot opens /workspace in the editor.
ENTRYPOINT ["/usr/local/bin/ugreen-codespace-entrypoint"]
CMD ["--bind-addr", "0.0.0.0:8080", "."]
