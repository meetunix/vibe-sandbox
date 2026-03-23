FROM debian:13-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
COPY --from=ghcr.io/astral-sh/ruff:latest /ruff /bin/
COPY --from=ghcr.io/astral-sh/ty:latest /ty /bin/

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production

RUN groupadd -g 1000 vibe && \
    useradd -m -u 1000 -g vibe vibe-user

RUN apt-get update && apt-get install -y \
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
    golang-go `# required for pre-commit hooks like gitleaks (language: golang)` \
    && apt autoclean -y \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /workspace && chown -R vibe-user: /workspace && \
    mkdir -p /home/vibe-user/.vibe && chown -R vibe-user: /home/vibe-user/.vibe

USER vibe-user
WORKDIR /workspace

ENV PATH="/home/vibe-user/.local/bin:$PATH"
ENV HOME="/home/vibe-user/"
ENV VIBE_HOME="/home/vibe-user/.vibe"

RUN pipx install prek pre-commit mistral-vibe

RUN echo 'export PATH="/home/vibe-user/.local/bin:$PATH"' >> ~/.bashrc \
    && echo 'export PS1="vibe-sandbox:\w$ "' >> ~/.bashrc \
    && echo 'echo "vibe available at: $(which vibe 2>/dev/null || echo NOT FOUND)"' >> ~/.bashrc

ENTRYPOINT ["/home/vibe-user/.local/bin/vibe"]