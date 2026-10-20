#!/usr/bin/env bash
# Repackages a `flutter build linux --release` bundle as an x86_64 AppImage.
# Usage: tool/build_appimage.sh <bundle-dir> [version] [output-file]
set -euo pipefail

BUNDLE_DIR="${1:?usage: $0 <bundle-dir> [version] [output-file]}"
VERSION="${2:-dev}"
OUT="${3:-tonkatsu-box-${VERSION}-linux-x86_64.AppImage}"

# Must match APPLICATION_ID / BINARY_NAME in linux/CMakeLists.txt.
APP_ID="com.hacan359.tonkatsubox"
BINARY="tonkatsu_box"

# `continuous` is rebuilt in place upstream, so only a tagged release can be
# verified by hash. Override with APPIMAGETOOL=<path> to skip the download.
APPIMAGETOOL_VERSION="1.9.1"
APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_DIR="$(cd "$BUNDLE_DIR" && pwd)"
OUT="$(realpath -m "$OUT")"

if [ ! -x "$BUNDLE_DIR/$BINARY" ]; then
  echo "Error: '$BUNDLE_DIR/$BINARY' not found or not executable." >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
APPDIR="$WORK/AppDir"

# The binary's RPATH is $ORIGIN/lib, so the bundle has to stay in one piece.
mkdir -p "$APPDIR/usr/bin"
cp -a "$BUNDLE_DIR/." "$APPDIR/usr/bin/"
mkdir -p "$APPDIR/usr/bin/lib"

# The sqlite3 package ships libsqlite3 as a native asset into lib/; a bundle
# built without native assets would dlopen the host copy instead, so warn.
if ! ls "$APPDIR/usr/bin/lib"/libsqlite3.so* >/dev/null 2>&1; then
  echo "Warning: no libsqlite3 in the bundle; the AppImage will need it from the host." >&2
fi

cat > "$APPDIR/AppRun" <<EOF
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\$0")")"
export LD_LIBRARY_PATH="\$HERE/usr/bin/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
exec "\$HERE/usr/bin/$BINARY" "\$@"
EOF
chmod +x "$APPDIR/AppRun"

# StartupWMClass follows g_set_prgname(APPLICATION_ID) in the GTK runner.
cat > "$APPDIR/$APP_ID.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Tonkatsu Box
Comment=Collection manager for games, movies, TV shows, anime, books and more
Exec=$BINARY
Icon=$APP_ID
Categories=Utility;
Terminal=false
StartupWMClass=$APP_ID
X-AppImage-Version=${VERSION#v}
EOF

cp "$ROOT/assets/icon/icon.png" "$APPDIR/$APP_ID.png"
cp "$ROOT/assets/icon/icon.png" "$APPDIR/.DirIcon"

TOOL="${APPIMAGETOOL:-}"
if [ -z "$TOOL" ]; then
  TOOL="$WORK/appimagetool"
  curl -fsSL -o "$TOOL" \
    "https://github.com/AppImage/appimagetool/releases/download/${APPIMAGETOOL_VERSION}/appimagetool-x86_64.AppImage"
  echo "${APPIMAGETOOL_SHA256}  ${TOOL}" | sha256sum -c - >/dev/null
  chmod +x "$TOOL"
fi

# APPIMAGE_EXTRACT_AND_RUN lets the tool run without FUSE (CI, containers).
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" "$APPDIR" "$OUT"

echo "Built: $OUT"
