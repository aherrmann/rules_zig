#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE=/home/aj/.cache/bazel/_bazel_aj/ffffacc6b31c04d73393a64a0e6bdb65

zig_docs() {
  IDX="$1"
  VERSION="$2"
  KIND="$3"
  WD="repro-wd/$IDX-$VERSION-$KIND/_main"
  OUT="out"
  mkdir -p "$WD/$OUT"
  ln -sr "$SCRIPT_DIR/zig-docs/main.zig" "$WD/main.zig"
  mkdir -p "$WD/external"
  ln -s "$BASE/external/rules_zig++zig+zig_${VERSION}_x86_64-linux" "$WD/external/rules_zig++zig+zig_${VERSION}_x86_64-linux"
  (
    cd "$WD"
    case $KIND in
      binary) FLAGS=(build-exe);;
      library) FLAGS=(build-lib);;
      test) FLAGS=(test --test-no-exec);;
    esac
    "/home/aj/.cache/bazel/_bazel_aj/install/7e4ce7b0d69e79cb6bd84c7f9dfefe6b/process-wrapper" \
      "external/rules_zig++zig+zig_${VERSION}_x86_64-linux/zig" "${FLAGS[@]}" \
        -femit-docs="$OUT/main.docs" \
        -fno-emit-bin \
        -fno-emit-implib \
        --zig-lib-dir "external/rules_zig++zig+zig_${VERSION}_x86_64-linux/lib" \
        --cache-dir "/tmp/zig-cache" \
        --global-cache-dir "/tmp/zig-cache" \
        -Mtest="main.zig"
  )
  #rm -rf $WD
}

#rm -rf /tmp/zig-cache repro-wd
#zig_docs 0 0.14.0 binary

rm -rf /tmp/zig-cache repro-wd
for i in `seq 10`; do
  for kind in binary library test; do
    zig_docs $i 0.14.0 $kind &
    zig_docs $i 0.13.0 $kind &
    zig_docs $i 0.12.1 $kind &
    zig_docs $i 0.12.0 $kind &
  done
done

wait
