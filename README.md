# ecash-ckpool-solo Docker image

Small wrapper repo that builds `ckpool` from `WillItMod/ecash-ckpool-solo` and publishes a multi-arch image to GHCR.

The default source is `18b38ad`, currently the full upstream commit
`18b38ad886a4c7a323b5f9bdcf761704c669c223`. The wrapper selects portable C
SHA256 through upstream's `YASM=no` configure override. It does not modify
the eCash pool protocol or source. The build runs known SHA256 vectors and
rejects assembly defines, builder CPU probes and AVX/SSE SHA256 symbols.

Pull requests build and test on native Linux AMD64 and ARM64 runners without
publishing an image. This establishes build, hash and executable startup
checks; node/pool/share acceptance on the target host remains a separate test.

## Publish

This repo is designed to publish on git tag pushes.

- Plain hexadecimal tags retain their historical binding to the same upstream
  `ecash-ckpool-solo` source ref (for example `18b38ad`).
- Candidate image tags such as `18b38ad-portable-rc.<wrapper-commit>` use the
  default upstream ref, rather than trying to check out that image tag.
- Manual workflow dispatch accepts an image tag and a separate source ref.
  Supply the full upstream commit when preparing a reproducible candidate.
- Push the tag
- GitHub Actions builds and pushes:
  - `ghcr.io/willitmod/ecash-ckpool-solo:<tag>`

For a local candidate build, choose a new image tag independently:

```sh
docker buildx build --platform linux/amd64 \
  --build-arg SOURCE_REF=18b38ad886a4c7a323b5f9bdcf761704c669c223 \
  --tag ecash-ckpool-portable:local --load .
```

`SOURCE_REF` overrides the existing `VERSION` build argument. With neither
override, `VERSION=18b38ad` remains the default. The image records the actual
resolved upstream commit at `/usr/share/doc/ecash-ckpool-solo/source-commit`.
Existing published tags, including `18b38ad`, should not be overwritten by
portable candidates. Publish candidates under new tags after acceptance.

