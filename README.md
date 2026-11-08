# vibe-sandbox

Docker-based sandbox for Mistral AI's vibe coding agent for Python, Java, and Go developers.

## Install

Make sure you have Docker installed.

Download and install `vibe-sandbox`:
```plain
curl -sSL https://codeberg.org/nachtsieb/vibe-sandbox/raw/branch/main/vibe-sandbox -o ~/.local/bin/vibe-sandbox && chmod +x ~/.local/bin/vibe-sandbox
```

## Use

No further setup is required. Change into the directory you want to work in and run:

```plain
vibe-sandbox
```

The script pulls the latest image automatically and handles user, permissions, and state directory (`~/.vibe-sandbox`) on its own.

The current working directory is mounted into the container at `/workspace/<directory-name>`. If you run the script from `/home/user/my-project`, the project is available at `/workspace/my-project` inside the container.

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

Voice mode is enabled inside the container only through the `VIBE_VOICE_MODE_ENABLED=true` environment variable. The script never reads or modifies your vibe configuration (`~/.vibe-sandbox/config.toml`) — all vibe settings (transcribe model, language, API key in `~/.vibe-sandbox/.env`, etc.) stay entirely under your control.

Inside the vibe session, open `/voice` and press `Ctrl+T` to start/stop recording; the transcription is inserted into the prompt.

## Upgrade

The script can update itself to the latest version from codeberg.org:

```plain
vibe-sandbox upgrade
```

`update` works as an alias. The command downloads the current version from the repository, compares it with the installed one, and replaces the script in place if a different version is found. If the installed version is already current, nothing is changed.
