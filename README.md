# ecash-ckpool-solo Docker image

Small wrapper repo that builds `ckpool` from `WillItMod/ecash-ckpool-solo` and publishes a multi-arch image to GHCR.

## Publish

This repo is designed to publish on git tag pushes.

- Create a tag that matches the upstream `ecash-ckpool-solo` git ref (typically the short SHA, e.g. `18b38ad`)
- Push the tag
- GitHub Actions builds and pushes:
  - `ghcr.io/willitmod/ecash-ckpool-solo:<tag>`

