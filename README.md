# vibe-sandbox

Docker-based sandbox for Mistral AI's vibe coding agent for Python, Java, and Go developers.

## Install

Make sure you have Docker installed.


1. Create a `.vibe-sandbox` directory in your home directory with owner `1000`:
```plain
mkdir -p ~/.vibe-sandbox && sudo chown 1000 ~/.vibe-sandbox && sudo chmod 700 ~/.vibe-sandbox
```

After the first start, Mistral Vibe creates the needed configuration in this directory. You can sync this directory to other
workstations and use your sandbox seamlessly on these machines. Additionally, you can edit the sandbox configuration
outside of the sandbox.

2. Link `vibe-sandbox` in your path:
```plain
ln -s "$PWD/vibe-sandbox" ~/.local/bin/vibe-sandbox
```

## Use

**Start the sandbox in the directory where you want to work**:

```plain
vibe-sandbox
```
