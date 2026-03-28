FROM debian:13-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
COPY --from=ghcr.io/astral-sh/ruff:latest /ruff /bin/
COPY --from=ghcr.io/astral-sh/ty:latest /ty /bin/

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production

RUN groupadd -g 1000 vibe && \
    useradd -m -u 1000 -g vibe vibe-user && \
    mkdir -p /workspace && chown -R vibe-user: /workspace && \
    mkdir -p /home/vibe-user/.vibe && chown -R vibe-user: /home/vibe-user/.vibe

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    vim \
    nano \
    jq \
    curl \
    wget \
    git \
    pipx \
    git-lfs \
    net-tools \
    bind9-dnsutils \
    nmap \
    ca-certificates \
    python3 \
    python-is-python3 \
    python3-pip \
    python3-venv \
    openjdk-21-jdk \
    gradle \
    maven  \
    golang-go `# required for pre-commit hooks like gitleaks (language: golang)`

RUN mkdir -p /workspace && chown -R vibe-user: /workspace && \
    mkdir -p /home/vibe-user/.vibe && chown -R vibe-user: /home/vibe-user/.vibe

USER vibe-user
WORKDIR /workspace

ENV PATH="/home/vibe-user/.local/bin:$PATH"
ENV HOME="/home/vibe-user/"
ENV VIBE_HOME="/home/vibe-user/.vibe"

RUN cat >> ~/.bashrc << 'EOF'
export PATH="/home/vibe-user/.local/bin:$PATH"
export VIBE_HOME="$HOME/.vibe"
export PS1="vibe-sandbox:\w$ "
echo "vibe available at: $(which vibe 2>/dev/null || echo NOT FOUND)"
EOF

RUN --mount=type=cache,target=/home/vibe-user/.cache/pipx,uid=1000,gid=1000 \
    pipx install prek pre-commit mistral-vibe

ENTRYPOINT ["/home/vibe-user/.local/bin/vibe"]