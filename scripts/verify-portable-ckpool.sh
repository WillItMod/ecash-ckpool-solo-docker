#!/bin/sh
# Configure and test the actual pinned upstream source before the pool build.
set -eu
source_dir="$(cd "$1" && pwd)"
vectors="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/bin"
real_cat="$(command -v cat)"
command -v yasm >/dev/null

# An AVX2 builder must not silently raise the resulting image's CPU floor.
cat > "$temporary/bin/cat" <<'EOF'
#!/bin/sh
if [ "$#" -eq 1 ] && [ "$1" = /proc/cpuinfo ]; then
  echo probed >> "$CPU_PROBE_LOG"
  echo 'flags : sse4_1 avx avx2 bmi2'
else
  exec "$REAL_CAT" "$@"
fi
EOF
chmod +x "$temporary/bin/cat"
export REAL_CAT="$real_cat"
export CPU_PROBE_LOG="$temporary/cpu-probes"
: > "$CPU_PROBE_LOG"
cd "$source_dir"

# AC_CHECK_PROG preserves this nonempty override even when yasm is installed.
if ! PATH="$temporary/bin:$PATH" YASM=no ./configure > portable-configure.log 2>&1; then
  "$real_cat" portable-configure.log >&2
  exit 1
fi
if grep -Eq '^#define USE_(AVX2|AVX1|SSE4) ' config.h; then
  echo 'configure selected nonportable SHA256 assembly' >&2
  exit 1
fi
if [ -s "$CPU_PROBE_LOG" ]; then
  echo 'configure inspected the builder CPU despite portable selection' >&2
  exit 1
fi
"${CC:-cc}" -O2 -I. -Isrc src/sha2.c "$vectors" -o "$temporary/sha256-vectors"
"$temporary/sha256-vectors"
nm "$temporary/sha256-vectors" > "$temporary/sha256-symbols"
if grep -Eq 'sha256_(rorx|avx|sse4)' "$temporary/sha256-symbols"; then
  echo 'vector binary links nonportable SHA256 assembly' >&2
  exit 1
fi
echo 'pinned upstream configure: portable C with yasm installed and AVX2 builder simulation passed'
