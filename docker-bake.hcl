group "default" {
  targets = ["build", "push"]
}

target "build" {
  dockerfile = "Dockerfile"
  tags = ["nachtsieb/vibe-sandbox:latest"]
}

target "push" {
  inherits = ["build"]
  platforms = ["linux/amd64"]
}