# Release

Two artifacts are released independently: the **script** (`vibe-sandbox` plus
`vibe-sandbox.sig`) and the **image** (`nachtsieb/vibe-sandbox:latest`). A script
release needs no image build, and an image release needs no script release.

Everything below assumes you are in the repository root and that `openssl` is
3.0 or newer (`openssl version`). Older OpenSSL cannot sign Ed25519 with
`pkeyutl`.

## One-time: pin your release key

Do this once. The private key stays offline — never on a build host, never in
CI, never in the repository.

```bash
openssl genpkey -algorithm ed25519 -out vibe-sandbox-release.pem
chmod 600 vibe-sandbox-release.pem
```

Print the public key and paste it into `RELEASE_KEYS` in `vibe-sandbox`:

```bash
openssl pkey -in vibe-sandbox-release.pem -pubout -outform DER | tail -c 32 | openssl base64 -A
```

The result is 44 characters ending in `=`. It goes into the tuple:

```python
RELEASE_KEYS: tuple[str, ...] = (
    "xjWB5/MxxffYiw6uwTUj/7AW43GG+7jnsZ6nPzB1vec=",
)
```

`RELEASE_KEYS` is a tuple so several keys can be trusted at once during a
rotation. An empty tuple makes `upgrade` and `verify` fail closed — that is the
correct state for a build without a key, not a bug.

If you keep the private key in the repository directory, add it to
`.gitignore`:

```bash
echo 'vibe-sandbox-release.pem' >> .gitignore
```

## Script release

### 1. Bump the version

```bash
sed -i 's/^SCRIPT_VERSION = ".*"$/SCRIPT_VERSION = "2.1.0"/' vibe-sandbox
grep '^SCRIPT_VERSION' vibe-sandbox
```

On macOS use `sed -i ''` instead of `sed -i`.

Expected: `SCRIPT_VERSION = "2.1.0"`. Never lower the version — clients refuse
to downgrade.

### 2. Update the docs

`README.md`, if user-facing behavior, arguments, or commands changed.

### 3. Check the script

```bash
python3 -m py_compile vibe-sandbox
python3 -c "import ast; ast.parse(open('vibe-sandbox').read(), feature_version=(3, 10))"
./vibe-sandbox --version
./vibe-sandbox --help
./vibe-sandbox --verbose
```

Expected: `vibe-sandbox 2.1.0`, the help with the resolved `--config-dir`
default, and a `docker run` line that looks right. Then one real run against
your Docker daemon covering the flags you touched — at minimum the workspace
mount, `--volume` with `:ro`/`:rw`, and `--blacklist`.

If you touched the clipboard bridge, also copy an image on the host, run
`!vibe-paste` inside vibe, and confirm it prints an `@vibe-pasted-images/...`
path that attaches the image. Check that `--no-clipboard` removes the command.

### 4. Sign

Sign **after** the last edit: the signature covers the exact bytes.

```bash
VERSION=$(sed -n 's/^SCRIPT_VERSION = "\(.*\)"$/\1/p' vibe-sandbox)
openssl pkeyutl -sign -inkey vibe-sandbox-release.pem -rawin -in vibe-sandbox \
  | openssl base64 -A > /tmp/sig.b64
{ echo "# vibe-sandbox ${VERSION}"; cat /tmp/sig.b64; echo; } > vibe-sandbox.sig
rm -f /tmp/sig.b64
```

Expected: `vibe-sandbox.sig` with two lines — a comment and 88 base64
characters.

### 5. Verify locally

```bash
./vibe-sandbox verify
```

Expected:

```plain
/path/to/vibe-sandbox: signature valid (SHA256:d1726225ff0a671c...)
```

If it fails, the file changed after signing. Go back to step 4.

### 6. Commit and push

```bash
git add vibe-sandbox vibe-sandbox.sig README.md
git commit -m "release: vibe-sandbox 2.1.0"
git push origin main
```

Both files must land in the same commit. A `.sig` that does not match the
script makes every client's upgrade fail closed.

### 7. Verify what is actually served

The signature covers the bytes on disk, not the bytes Codeberg serves. Check
the served copy before announcing anything:

```bash
curl -fsSL https://codeberg.org/nachtsieb/vibe-sandbox/raw/branch/main/vibe-sandbox -o /tmp/vs-check
curl -fsSL https://codeberg.org/nachtsieb/vibe-sandbox/raw/branch/main/vibe-sandbox.sig -o /tmp/vs-check.sig
./vibe-sandbox verify /tmp/vs-check
```

Expected: `signature valid`. If this fails while step 5 passed, the served
bytes differ from the committed ones — look for line-ending conversion or a
proxy in front of the raw URL.

### 8. Verify the rollout

Install the previous version somewhere and upgrade it:

```bash
vibe-sandbox upgrade
```

Expected:

```plain
Checking for updates (installed: v2.0.0)...
Updated vibe-sandbox: v2.0.0 -> v2.1.0 (signed by SHA256:d1726225ff0a671c...)
```

## Image release

Only when `Dockerfile`, `Dockerfile.base`, or `entrypoint.sh` changed.

1. Build and push the base image: `./build.sh base` (pushes `nachtsieb/vibe-sandbox-base:latest`).
2. Build and push the main image: `docker buildx bake -f docker-bake.hcl --push` (pushes `nachtsieb/vibe-sandbox:latest`).
3. Check it: run `vibe-sandbox` with `--pull always` (the default) and confirm the container starts with the expected changes.

Step 2 normally runs automatically from the `mistral-vibe` PyPI watcher via
`build.sh`; run it by hand only when image files changed independently of a
PyPI release.

## Key rotation

Clients only trust the keys compiled into the version they run, so a key cannot
be swapped in one step.

1. Generate the new key pair.
2. Add the new public key to `RELEASE_KEYS` next to the old one, and release
   that version signed with the **old** key.
3. Wait until clients have picked that release up.
4. Sign subsequent releases with the new key.
5. Remove the old key from `RELEASE_KEYS` in a later release.

If a private key is compromised, remove it from `RELEASE_KEYS` and release
signed with the remaining key. Clients that have not upgraded yet still trust
the compromised key; that window cannot be closed retroactively, which is why
the private key belongs offline.

## Troubleshooting

| Message | Cause |
|---|---|
| `no release key is pinned in this script` | `RELEASE_KEYS` is empty |
| `signature file ... does not exist` | `vibe-sandbox.sig` missing or misnamed |
| `release signature does not match any pinned key` | edited after signing, wrong key, or stale `.sig` |
| `signature file contains no signature` | `.sig` is empty or has only comments |
| `malformed signature file: expected 64 bytes` | truncated or re-wrapped base64 |
| `Already up to date (vX.Y.Z)` | version not bumped |
| `Installed vX is newer than vY; not downgrading` | version lowered |
| `could not download ...` | network problem, or the raw URL moved |

## Notes

- The upgrade command compares versions numerically (`MAJOR.MINOR.PATCH`) and refuses to downgrade. Never lower `SCRIPT_VERSION` on `main` — installed clients would report `Installed vX is newer than vY; not downgrading.` and stay put.
- Both images are published as `:latest` only; there is no version pinning. A broken image affects all users immediately.
- The script requires Python 3.10 or newer and uses the standard library only. Do not add third-party imports — Ed25519 verification is implemented in the script itself (RFC 8032, verification only) precisely to avoid a dependency. No Python version ships Ed25519 in the standard library, so bumping the minimum version would not remove that code.
- The signature covers the script, not the image. Signing the image would need a separate mechanism (cosign or similar).
- The clipboard bridge lives entirely in the script; it needs no image change. It requires `wl-clipboard` or `xclip` on the host and stays off when neither is present.

## 1.x → 2.0.0 migration

`vibe-sandbox` 2.0.0 replaced the bash implementation with a Python script. The
1.x updater validated the downloaded file with `bash -n` and therefore cannot
install it: it exits with `Error: downloaded file is not a valid bash script,
aborting update.` without touching the installed script.

This break is accepted. Users on 1.x reinstall once with the `curl` command from
the README; from 2.0.0 on, `vibe-sandbox upgrade` works again. Do not try to
restore compatibility by keeping a bash shim at the raw URL — the file served
there is the Python script.
