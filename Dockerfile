ARG VERSION=18b38ad
ARG SOURCE_REF

# Build stage
FROM debian:trixie-slim AS builder

ARG VERSION
ARG SOURCE_REF

WORKDIR /build

RUN apt-get update
RUN apt-get install --yes git build-essential yasm autoconf automake libtool libzmq3-dev pkgconf ca-certificates

# Clone and checkout a specific ref
RUN git clone https://github.com/WillItMod/ecash-ckpool-solo.git .
RUN source_ref="${SOURCE_REF:-$VERSION}" \
  && source_commit="$(git rev-parse --verify --end-of-options "${source_ref}^{commit}")" \
  && git checkout --detach "$source_commit" \
  && git rev-parse HEAD > /build/SOURCE_COMMIT

COPY tests/ckpool_sha256_vectors.c scripts/verify-portable-ckpool.sh /build/tests/

# Upstream dispatches SHA256 assembly at compile time. Its documented YASM
# configure override selects portable C without changing the pinned source.
RUN ./autogen.sh \
  && /bin/sh /build/tests/verify-portable-ckpool.sh /build /build/tests/ckpool_sha256_vectors.c \
  && make -j"$(nproc)" \
  && nm src/ckpool > /build/ckpool.symbols \
  && ! grep -E 'sha256_(rorx|avx|sse4)' /build/ckpool.symbols

# Final image
FROM debian:trixie-slim

RUN apt-get update
RUN apt-get install --yes libzmq3-dev ca-certificates

COPY --from=builder /build/src/ckpool /bin/ckpool
COPY --from=builder /build/SOURCE_COMMIT /usr/share/doc/ecash-ckpool-solo/source-commit

EXPOSE 3333

ENTRYPOINT ["ckpool"]

