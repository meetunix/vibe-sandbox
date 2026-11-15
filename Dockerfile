FROM nachtsieb/vibe-sandbox-base:latest

ARG CACHE_BUSTER=unknown
RUN --mount=type=cache,target=/root/.cache/uv \
    export UV_CACHE_DIR=/root/.cache/uv && \
    echo "cache-buster: $CACHE_BUSTER" && \
    uv tool install --python /usr/bin/python3 mistral-vibe && \
    chmod -R a+rX /opt/uv

ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "vibe"]
