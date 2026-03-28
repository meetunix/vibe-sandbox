group "default" {
  targets = ["build", "push"]
}

variable "VIBE_COMMIT_SHA" {
  default = "unknown"
}

target "build" {
  dockerfile = "Dockerfile"
  tags = ["nachtsieb/vibe-sandbox:latest"]
  args = {
    CACHE_BUSTER = "${VIBE_COMMIT_SHA}"
  }
}

target "push" {
  inherits = ["build"]
  platforms = ["linux/amd64"]
}