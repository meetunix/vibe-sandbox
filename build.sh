#!/usr/bin/env bash

# This script monitors a GitHub repository for new commits.
# If a new commit SHA is detected (or if no previous state file exists),
# it triggers a Docker build command. 
# The latest commit hash is exported as `VIBE_COMMIT_SHA` to act as a 
# cache-buster in the Dockerfile, ensuring the image rebuilds when mistral-vibe
# is upgraded

# Configuration
REPO="mistralai/mistral-vibe"
COMMIT_HASH_FILE=".mistral-vibe-sha"
BUILD_CMD="docker buildx bake -f docker-bake.hcl --push"
IDENTIFIER="mistral-vibe-watcher"

# Logging
log_info() {
    local msg
    msg="[INFO] $*"
    echo "$msg"
    echo "$msg" | systemd-cat -t "$IDENTIFIER" -p info
}

log_error() {
    local msg
    msg="[ERROR] $*"
    echo "$msg" >&2
    echo "$msg" | systemd-cat -t "$IDENTIFIER" -p err
}

# Main
log_info "Checking for changes in $REPO..."

LATEST=$(curl -sf "https://api.github.com/repos/$REPO/commits/main" | jq -r '.sha')

if [ -z "$LATEST" ]; then
    log_error "Failed to fetch latest commit hash (sha1) from GitHub API."
    exit 1
fi

if [ ! -f "$COMMIT_HASH_FILE" ]; then
    log_info "Sthe state file \"$COMMIT_HASH_FILE\" was not found. Initializing first build."
    PREVIOUS=""
else
    PREVIOUS=$(cat "$COMMIT_HASH_FILE")
fi

if [ "$LATEST" != "$PREVIOUS" ]; then
    log_info "Change detected: ${PREVIOUS:-none} -> $LATEST"

    log_info "Running build: $BUILD_CMD"
    export VIBE_COMMIT_SHA="$LATEST"

    if $BUILD_CMD; then
        echo "$LATEST" > "$COMMIT_HASH_FILE"
        log_info "Build succeeded. commit hash \"$LATEST\" written to \"$COMMIT_HASH_FILE\"."
    else
        log_error "Build failed! Commit hash not updated."
        exit 1
    fi
else
    log_info "No changes detected (commit hash: $LATEST)."
fi