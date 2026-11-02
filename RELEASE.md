# Release

Checklist for releasing a new version of `vibe-sandbox`.

## Script release

1. Increase `SCRIPT_VERSION` in `vibe-sandbox` (format: `MAJOR.MINOR.PATCH`).
2. Update `README.md` if user-facing behavior, arguments, or commands changed.
3. Verify the script locally:
   - `bash -n vibe-sandbox` passes.
   - A test run against a local Docker daemon works (workdir mount, `--volume`, `:ro`/`:rw`).
   - `vibe-sandbox upgrade` reports `Already up to date` against the not-yet-pushed state.
4. Commit and push to `main` on codeberg.org. The upgrade command serves the script from the raw URL of the `main` branch, so the push *is* the release.
5. Verify the rollout: install the previous version, run `vibe-sandbox upgrade`, and confirm the output shows the new version (`Updated vibe-sandbox: vX.Y.Z -> vA.B.C`).

## Image release (only if Dockerfile, Dockerfile.base, or entrypoint changed)

6. Build and push the base image: `./build.sh base` (pushes `nachtsieb/vibe-sandbox-base:latest`).
7. Build and push the main image: `docker buildx bake -f docker-bake.hcl --push` (pushes `nachtsieb/vibe-sandbox:latest`). Normally this is handled automatically by the `mistral-vibe` PyPI watcher via `build.sh`; run it manually only when image files changed independently of a PyPI release.
8. Verify the image: run `vibe-sandbox` with `--pull always` (default) and confirm the container starts with the expected changes.

## Notes

- The script and the image are released independently: a script release does not require an image build and vice versa.
- The upgrade command compares versions by string equality. Never lower `SCRIPT_VERSION` on `main` — installed clients would "upgrade" to the older version.
- Both images are published as `:latest` only; there is no version pinning. A broken image affects all users immediately.
