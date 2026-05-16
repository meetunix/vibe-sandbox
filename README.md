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
