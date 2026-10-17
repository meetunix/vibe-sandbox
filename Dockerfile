FROM nachtsieb/vibe-sandbox-base:latest

ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIPX_MAN_DIR=/usr/local/share/man

ARG CACHE_BUSTER=unknown
RUN echo "cache-buster: $CACHE_BUSTER" && \
    pipx install mistral-vibe && \
    chmod -R a+rX /opt/pipx

ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "vibe"]
