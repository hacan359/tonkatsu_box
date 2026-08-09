# syntax=docker/dockerfile:1

# Both halves are built here, so an image needs nothing but this repo and a
# Docker daemon — no Flutter SDK on the machine doing the build.

# `stable` rather than a pin: cirruslabs publishes no tag for the SDK this repo
# is developed against, and an image older than pubspec's floor cannot build it.
FROM ghcr.io/cirruslabs/flutter:stable AS web
WORKDIR /src
# Manifests first: the dependency layer survives an edit to lib/.
COPY pubspec.yaml pubspec.lock ./
COPY packages ./packages
RUN flutter pub get
COPY . .
# --no-web-resources-cdn: CanvasKit is fetched from gstatic by default, which a
# LAN-only box cannot reach — the page would render blank. Serve the copy that
# is already in the bundle.
RUN flutter build web --release --no-web-resources-cdn

FROM dart:stable AS server
# The sqlite3 package builds its native library through a build hook, so the
# compile needs a C toolchain. Without one it links nothing and the binary dies
# at the first query with "undefined symbol: sqlite3_initialize".
RUN apt-get update \
    && apt-get install -y --no-install-recommends clang \
    && rm -rf /var/lib/apt/lists/*
COPY packages /src/packages
COPY server /src/server
WORKDIR /src/server
RUN dart pub get
# `dart compile exe` refuses a package with build hooks; `dart build cli` runs
# them and emits bin/ next to the lib/ holding the SQLite it just built.
RUN dart build cli

FROM debian:stable-slim AS runtime
# Only TLS roots: the bundle carries its own libsqlite3.so.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=server /src/server/build/cli/linux_x64/bundle /opt/tonkatsu
COPY --from=web /src/build/web /srv/web

ENV TONKATSU_DATA_DIR=/data \
    TONKATSU_WEB_ROOT=/srv/web \
    TONKATSU_ADDRESS=0.0.0.0 \
    TONKATSU_PORT=8080

VOLUME /data
EXPOSE 8080

ENTRYPOINT ["/opt/tonkatsu/bin/server"]
