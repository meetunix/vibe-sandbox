FROM nachtsieb/vibe-sandbox-base:latest

ARG CACHE_BUSTER=unknown
RUN pipx install mistral-vibe


ENTRYPOINT ["/home/vibe-user/.local/bin/vibe"]