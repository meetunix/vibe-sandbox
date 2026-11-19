# vibe-sandbox

Docker-based sandbox for Mistral AI's vibe coding agent for Python, Java, and Go developers.

## Install

Make sure you have Docker and Python 3.10 or newer installed. The script uses the
Python standard library only, so there is nothing to `pip install`.

Download and install `vibe-sandbox`:
```plain
curl -sSL https://codeberg.org/nachtsieb/vibe-sandbox/raw/branch/main/vibe-sandbox -o ~/.local/bin/vibe-sandbox && chmod +x ~/.local/bin/vibe-sandbox
```

### Upgrading from the bash version (1.x)

`vibe-sandbox` 2.0.0 is a Python script. The 1.x bash updater validated the
downloaded file with `bash -n` and therefore refuses to install it — it exits
with `Error: downloaded file is not a valid bash script, aborting update.`
Nothing is broken by that; reinstall once with the `curl` command above. From
2.0.0 on, `vibe-sandbox upgrade` works again.

## Use

No further setup is required. Change into the directory you want to work in and run:

```plain
vibe-sandbox
```

The script pulls the latest image automatically and handles user, permissions, and state directory (`~/.vibe-sandbox`) on its own.

Run `vibe-sandbox` as a regular user. It refuses to run as root: the sandbox maps the invoking user into the container, and a root run would silently lose the state directory.

The workspace is mounted into the container at `/workspace/<directory-name>` and vibe starts inside it. If you run the script from `/home/user/my-project`, the project is available at `/workspace/my-project` inside the container.

## Options

| Option | Description |
| --- | --- |
| `-w`, `--workspace TEXT` | Workspace directory (defaults to current directory) |
| `--no-pull` | Don't pull the latest image before running |
| `-m`, `--memory TEXT` | Memory limit, `8` being 8G (default: `4G`) |
| `-c`, `--cpus TEXT` | CPU limit (default: `2.0`) |
| `--model TEXT` | Name of the model to use |
| `-v`, `--volume TEXT` | Additional path to mount (see [Volumes](#volumes)) |
| `--ssh-key TEXT` | SSH key from `~/.ssh` to mount read-only (see [SSH keys](#ssh-keys)) |
| `-r`, `--resume` | Resume the most recent session |
| `-b`, `--blacklist TEXT` | Directory to hide inside the container (see [Blacklist](#blacklist)) |
| `-k`, `--kubernetes`, `--kube` | Mount `~/.kube/config` read-only |
| `-D`, `--docker-arg TEXT` | Extra argument for `docker run` (see [Docker arguments](#docker-arguments)) |
| `-e`, `--env TEXT` | Extra environment variable for the container (see [Environment](#environment)) |
| `--verbose` | Print the full docker command before running it |
| `--config-dir TEXT` | Vibe configuration directory for this session (default: `~/.vibe-sandbox`) |
| `--gpus` | Shorthand for `--docker-arg=--gpus=all` |
| `--voice` | Pass host audio devices into the container and enable voice mode |
| `--no-clipboard` | Don't expose the host clipboard to the container |
| `--version` | Print the script version |
| `--help` | Print the help |

Arguments the script does not recognise are passed to vibe inside the container,
e.g. `vibe-sandbox --agent ask`. Use `--` to stop option parsing.

## Workspace

`--workspace` (or `-w`) selects the directory to mount as the project:

```plain
vibe-sandbox --workspace ~/src/my-project
```

It defaults to the current directory. The directory must exist and must not be
`/`, `/proc`, `/sys` or `/dev`. It is mounted read-write at
`/workspace/<directory-name>`, and vibe is started at `/workspace` with
`--workdir`, so the project sits one level below the working directory and
`vibe-pasted-images/` can live beside it instead of inside the repository.
Pointing it at your home directory prints a warning, because the container can
then read and write everything in it.

Because the working directory is always `/workspace`, vibe's folder-scoped
session picker no longer separates projects: `--resume` continues the most
recent session in the sandbox, whichever project it was started in.

## Volumes

To mount additional host directories into the container, use `--volume` (or the short form `-v`). The directory is mounted at `/workspace/<directory-name>`:

```plain
vibe-sandbox --volume /host/path/to/project_hell
```

This mounts `/host/path/to/project_hell` at `/workspace/project_hell` inside the container.

Optionally, an access mode can be appended:

- `:ro` — read-only (default)
- `:rw` — read/write

```plain
vibe-sandbox --volume /host/path/to/project_hell:rw
```

Custom container mountpoints are not permitted. Specifying a target path (e.g. `--volume /host/path:/opt/path:ro`) is rejected with an error. The host path must exist — the script does not create missing directories.

The following paths are refused outright:

- `/`, `/proc`, `/sys`, `/dev` and anything below them
- the Docker socket (`/var/run/docker.sock`, `/run/docker.sock`)
- anything that is not a regular file or a directory (sockets, devices, FIFOs)
- the configuration directory, and anything inside it
- a path whose name collides with the workspace or another volume, since both
  would land on the same container path

Mounting your home directory or a credential directory (`~/.ssh`, `~/.gnupg`,
`~/.aws`, `~/.kube`, `~/.docker`, `~/.config`, `~/.vibe`, `~/.vibe-sandbox`)
prints a warning. Prefer `--ssh-key` and `--kubernetes` for those.

## Blacklist

`--blacklist` (or `-b`) hides a directory inside the container by mounting an
empty read-only tmpfs over it. The path is relative to the workspace root and
can be given multiple times:

```plain
vibe-sandbox --blacklist .git --blacklist node_modules --blacklist .env.d
```

Only directories can be hidden. The path must exist, must stay inside the
workspace after resolving symlinks, must not be the workspace root itself, and
must not be a symlink — name the target directory instead, so the tmpfs lands
where you expect.

## SSH keys

`--ssh-key` mounts a key from `~/.ssh` read-only into the container, together
with its `.pub` file, `~/.ssh/config` and `~/.ssh/known_hosts` (each only if it
exists):

```plain
vibe-sandbox --ssh-key id_ed25519
```

Several keys can be given comma-separated or by repeating the flag:

```plain
vibe-sandbox --ssh-key id_ed25519,id_work_rsa
```

The name must be a plain file name inside `~/.ssh`; path separators and `..`
are rejected. The key is mounted at `/home/vibe-user/.ssh/<name>`.

Note that a private key mounted into the container is readable by everything
running in it, including the agent. Only mount keys you are willing to expose
to the sandbox.

## Kubernetes

`--kubernetes` (also `--kube`, `-k`) mounts `~/.kube/config` read-only at
`/home/vibe-user/.kube/config`:

```plain
vibe-sandbox --kubernetes
```

The file must exist. The container can then use every cluster credential in
that kubeconfig, so the same caveat as for SSH keys applies.

## Environment

`--env` (or `-e`) passes an environment variable into the container. Either give
a value explicitly, or name the variable alone to forward this shell's current
value:

```plain
vibe-sandbox --env MISTRAL_API_KEY --env GIT_AUTHOR_NAME="Ada Lovelace"
```

A name that is not set in the current shell is skipped with a warning. Names
must match `[A-Za-z_][A-Za-z0-9_]*`.

## Model and resume

`--model` selects the model for the session. It is passed as the
`VIBE_ACTIVE_MODEL` environment variable, because vibe's own `--model` flag only
applies to headless (`-p`) runs:

```plain
vibe-sandbox --model mistral-medium-3.5
```

`--resume` (or `-r`) continues the most recent session in the sandbox. It maps
to `vibe --continue`; use vibe's `/resume` inside the session to pick a
different one. Since vibe always runs in `/workspace`, the session is not
scoped to the project you started from.

A resumed session keeps the model it was started with, so `--model` has no
effect together with `--resume`. Start a new session to switch models.

## Configuration directory

`--config-dir` points the session at a different vibe configuration directory.
It is mounted read-write as `~/.vibe` inside the container, which is where vibe
keeps `config.toml`, `.env`, skills, agents, and session logs:

```plain
vibe-sandbox --config-dir ~/.vibe-work
```

The default is `~/.vibe-sandbox`, and `--help` prints the resolved path. A
missing directory is created with mode `0700`. An existing directory that is
readable by other users triggers a warning, because it holds API keys. `/`,
`/proc`, `/sys` and `/dev` are refused, and so is your home directory or
anything above it — that would hand the container your whole home read-write.

## Resource limits

The container is limited to 2 CPUs and 4 GB of memory by default. Both can be changed per run:

```plain
vibe-sandbox --cpus 4 --memory 8g
```

`--cpus` (also `--cpu`) takes a positive number of CPUs; fractions are allowed (`1.5`). `--memory` (also `--mem`) takes a size with an optional unit suffix (`b`, `k`, `m`, `g`, also `kb`/`kib` and so on); fractions are allowed (`1.5g`), and a value without a suffix is interpreted as bytes. Both values are passed straight to `docker run --cpus` and `--memory`.

## NVIDIA GPUs

To pass the host's NVIDIA GPUs into the container, run:

```plain
vibe-sandbox --gpus
```

This is a shorthand for `--docker-arg=--gpus=all`, so all host GPUs are visible inside the sandbox. The host needs Docker with the NVIDIA Container Toolkit installed; without it, Docker aborts the run with `could not select device driver "" with capabilities: [[gpu]]`.

## Docker arguments

`--docker-arg` (or `-D`) appends a raw argument to `docker run`. The value is
shell-split and placed after all built-in flags, so it overrides them:

```plain
vibe-sandbox --docker-arg=--gpus=all --docker-arg=--shm-size=2g
```

The flag can be repeated. `-D --gpus=all` works as well as
`--docker-arg=--gpus=all`. The value must start with a `-`, so it cannot
accidentally replace the image name.

This is an escape hatch: flags such as `--privileged`, `--pid=host`,
`--cap-add`, `--device`, `--mount`, `-v`, `--entrypoint` or `--security-opt`
dismantle the isolation the sandbox provides. The script prints a warning
naming the flags it recognised, but it does not block them.

## Voice mode

To use vibe's voice mode (speak instead of type), run:

```plain
vibe-sandbox --voice
```

With `--voice`, the script passes the host audio hardware into the container whenever it finds it:

- `/dev/snd` (ALSA devices) via `--device /dev/snd`, plus the host's `audio` group via `--group-add`
- the PipeWire socket (`$XDG_RUNTIME_DIR/pipewire-0` or `/run/user/<uid>/pipewire-0`)
- the PulseAudio socket (`$XDG_RUNTIME_DIR/pulse` or `/run/user/<uid>/pulse`) with `PULSE_SERVER` set accordingly

`XDG_RUNTIME_DIR` is set inside the container to match the mounted sockets. If no audio device or socket is found on the host, a warning is printed and the container starts anyway.

Voice mode is enabled inside the container only through the `VIBE_VOICE_MODE_ENABLED=true` environment variable. The script never reads or modifies your vibe configuration — all vibe settings (transcribe model, language, API key in the configuration directory's `.env`, etc.) stay entirely under your control.

Inside the vibe session, open `/voice` and press `Ctrl+T` to start/stop recording; the transcription is inserted into the prompt.

## Pasting images

vibe's own Ctrl+V image paste is compiled out on Linux: `paste_image::is_supported()`
is `cfg!(target_os = "macos")`, so neither the key binding nor `/paste-image`
exists in the container — on any host, because the container always runs Linux.
`vibe-paste` works around that without handing the container your display server.

Copy an image on the host, then run this inside vibe:

```plain
!vibe-paste
```

It writes the image into `/workspace/vibe-pasted-images/` — beside the project,
never inside it — and prints an `@` mention:

```plain
@vibe-pasted-images/clipboard-20251119T204500.png
```

Type `@` and let the file autocomplete, or paste the printed path. vibe turns
the mention into an image attachment.

The command talks to a small bridge that `vibe-sandbox` runs on the host. The
container never reaches the display server; it asks the bridge for one image
over a per-session unix socket. The bridge:

- serves only `image/*` reads, never text or arbitrary clipboard content
- answers only while this session's terminal has seen input in the last 30
  seconds, so an abandoned sandbox cannot help itself
- caps a request at 256 bytes and an image at 10 MiB
- lives in a `0700` directory with a `0600` socket, mounted read-only

The host needs `wl-clipboard` (Wayland) or `xclip` (X11). Without either the
bridge stays off and `vibe-paste` is unavailable; everything else works as
usual. `--no-clipboard` turns it off explicitly.

## Verbose

`--verbose` prints the exact `docker run` command, shell-quoted, to stderr before
executing it:

```plain
vibe-sandbox --verbose --gpus
```

## Upgrade

The script can update itself to the latest version from codeberg.org:

```plain
vibe-sandbox upgrade
```

`update` works as an alias. The command downloads the current version from the
repository over HTTPS, compares it with the installed one, and replaces the
script in place if a newer version is found. If the installed version is already
current, nothing is changed; if the downloaded version is older, the script
refuses to downgrade.

Every release is signed with an Ed25519 key, and the script carries the
maintainer's public key. The signature is checked **before** anything is parsed
out of the download, so a compromised mirror, a hijacked DNS answer, or a
tampered file cannot install code:

- the download is capped at 1 MiB, must come over HTTPS, and a redirect to a
  non-HTTPS URL is refused
- the detached signature from `<script-url>.sig` must verify against one of the
  pinned keys; otherwise the upgrade aborts and the installed script is left
  untouched
- only then is the version read, compared, and the payload checked to be a
  Python script that compiles
- the new script is written to a temporary file next to the installed one and
  moved into place atomically, keeping the original file mode

The success message names the fingerprint of the key that signed the release:

```plain
Updated vibe-sandbox: v2.0.0 -> v2.1.0 (signed by SHA256:d1726225ff0a671c...)
```

If no key is pinned in the script, `upgrade` refuses to run. That is deliberate:
a build without a pinned key must not be able to install code.

### Verifying a local file

`verify` checks a script against the `.sig` file next to it, using the same
pinned keys:

```plain
vibe-sandbox verify
vibe-sandbox verify ./vibe-sandbox
```

Without an argument it verifies the installed script. This is what the release
checklist uses before pushing.

### Signature format

The `.sig` file is plain text. Lines starting with `#` are comments; the first
other line is the base64-encoded 64-byte Ed25519 signature over the exact bytes
of the script:

```plain
# vibe-sandbox 2.1.0
JUnNX56TFtya3/U9whRE9dd9VrRtHS8a7DgZGY2reZnJjDGO+LEHUYK5QktY...
```

The format is deliberately tool-agnostic: any Ed25519 implementation that can
produce a raw detached signature works. See `RELEASE.md` for the signing
commands.

## Security notes

The sandbox is a convenience wrapper, not a security boundary against a
determined attacker. What the script does:

- runs the container with `--security-opt no-new-privileges=true`
- maps the invoking UID/GID into the container instead of running as root
- refuses to run as root on the host
- validates every host path before it reaches `docker run`, and rejects the
  Docker socket, `/proc`, `/sys`, `/dev`, and non-file/non-directory paths
- never builds a shell command line: `docker` is executed directly with an
  argument vector, so no user input is ever interpreted by a shell
- mounts the configuration directory with mode `0700` and warns when it is
  readable by other users
- verifies an Ed25519 signature over every self-update before parsing it, with
  the public key pinned in the script
- reaches the host clipboard only through a per-session unix socket that serves
  `image/*` reads and only while the session's terminal has recent input

What it does not do: the container still shares the host kernel, the workspace
is mounted read-write, and `--docker-arg` can remove every restriction above.
Treat the sandbox as a guard against accidents, not as a jail.

The update signature protects the script, not the image. `nachtsieb/vibe-sandbox:latest`
is pulled from the registry and is only as trustworthy as that registry and the
account that publishes it.
