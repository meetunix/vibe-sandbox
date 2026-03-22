# vibe-sandbox

Docker based sandbox for Mistral AI's vibe coding agent for python and Java developers.

## Install

Make sure you have Docker installed.


1. Create a `.vibe-sandbox` directory in your home directory with owner `1000`:
```plain
mkdir -p ~/.vibe-sandbox && sudo chown 1000 ~/.vibe-sandbox && sudo chmod 700 ~/.vibe-sandbox
```

After the first start, mistral vibe creates the needed configuration in this directory. You can sync this dir to other
workstation and use your sandbox seamlessly on this machines. Additionally, you can edit the sandbox configuration
outside of the sandbox.

2. Link `vibe-sandbox` in your path:
```plain
ln -s "$PWD/vibe-sandbox" ~/.local/bin/vibe-sandbox
```

## Use

**Start the sandbox in the directory you want to work**:

```plain
vibe-sandbox
```
