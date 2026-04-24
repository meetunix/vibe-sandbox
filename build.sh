#!/usr/bin/env bash

# This script monitors a GitHub repository for new commits.
# If a new commit SHA is detected (or if no previous state file exists),
# it triggers a Docker build command. 
# The latest commit hash is exported as `VIBE_COMMIT_SHA` to act as a 
# cache-buster in the Dockerfile, ensuring the image rebuilds when mistral-vibe
# is upgraded

# Get the directory where this build.sh build.sh script is located
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Configuration
REPO="mistralai/mistral-vibe"
COMMIT_HASH_FILE=".mistral-vibe-sha"
IDENTIFIER="mistral-vibe-watcher"

# Parse command line arguments
BUILD_BASE=false
if [ "$1" = "base" ]; then
    BUILD_BASE=true
    BUILD_CMD="docker buildx bake -f docker-bake.hcl --push base"
else
    BUILD_CMD="docker buildx bake -f docker-bake.hcl --push"
fi

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

pull_repo() {
    log_info "Pulling current repository..."
    if ! git pull; then
        log_error "Failed to pull the current repository."
        exit 1
    fi
}

# Main
cd "$REPO_DIR" || { log_error "Unable to cd to $REPO_DIR"; exit 1; }

if [ "$BUILD_BASE" = true ]; then
    log_info "Building base image..."
    log_info "Running build: $BUILD_CMD"
    if $BUILD_CMD; then
        log_info "Base image build succeeded."
    else
        log_error "Base image build failed!"
        exit 1
    fi
else
    log_info "Checking for changes in $REPO..."

    LATEST=$(curl -sf "https://api.github.com/repos/$REPO/commits/main" | jq -r '.sha')

    if [ -z "$LATEST" ]; then
        log_error "Failed to fetch latest commit hash (sha1) from GitHub API."
        exit 1
    fi

    if [ ! -f "$COMMIT_HASH_FILE" ]; then
        log_info "Sthe state file \"$COMMIT_HASH_FILE\" was not found. Initializing first build."
        PREVIOUS=""
        pull_repo
    else
        PREVIOUS=$(cat "$COMMIT_HASH_FILE")
    fi

    if [ "$LATEST" != "$PREVIOUS" ]; then
        log_info "Change detected: ${PREVIOUS:-none} -> $LATEST"
        pull_repo

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
fi