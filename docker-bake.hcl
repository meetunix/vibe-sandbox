group "default" {
  targets = ["build", "push"]
}

variable "VIBE_COMMIT_SHA" {
  default = "unknown"
}

target "base" {
  dockerfile = "Dockerfile.base"
  tags = ["nachtsieb/vibe-sandbox-base:latest"]
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

target "push-base" {
  inherits = ["base"]
  platforms = ["linux/amd64"]
}