FROM nachtsieb/vibe-sandbox-base:latest

ARG CACHE_BUSTER=unknown
RUN pipx install mistral-vibe && \
    chmod a+rx /home/vibe-user && \
    chmod -R a+rX /home/vibe-user/.local

ENTRYPOINT ["/home/vibe-user/.local/bin/vibe"]