ARG VERSION=18b38ad

# Build stage
FROM debian:trixie-slim AS builder

ARG VERSION

WORKDIR /build

RUN apt-get update
RUN apt-get install --yes git build-essential yasm autoconf automake libtool libzmq3-dev pkgconf ca-certificates

# Clone and checkout a specific ref
RUN git clone https://github.com/WillItMod/ecash-ckpool-solo.git .
RUN git checkout $VERSION

# Hack to disable cpu based optimisations for more portable builds
# (matches the approach used by getumbrel/docker-ckpool-solo)
RUN sed -i "s/host_cpu = 'x86_64'/host_cpu = 'x86_64-disabled'/" configure.ac
RUN sed -i "s/host_cpu = 'aarch64'/host_cpu = 'aarch64-disabled'/" configure.ac

RUN ./autogen.sh
RUN ./configure
RUN make -j$(nproc)

# Final image
FROM debian:trixie-slim

RUN apt-get update
RUN apt-get install --yes libzmq3-dev ca-certificates

COPY --from=builder /build/src/ckpool /bin/ckpool

EXPOSE 3333

ENTRYPOINT ["ckpool"]

