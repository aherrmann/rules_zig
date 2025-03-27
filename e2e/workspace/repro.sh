#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE=/home/aj/.cache/bazel/_bazel_aj/ffffacc6b31c04d73393a64a0e6bdb65

zig_docs() {
  IDX="$1"
  VERSION="$2"
  KIND="$3"
  WD="repro-wd/$IDX-$VERSION-$KIND"
  case $KIND in
    binary) FLAGS=(build-exe);;
    library) FLAGS=(build-lib);;
    test) FLAGS=(test --test-no-exec);;
  esac
  mkdir -p "$WD"
  cp zig-docs/main.zig "$WD/main.zig"
  (
    cd "$WD"
    mkdir out.docs
    "$BASE/external/rules_zig++zig+zig_${VERSION}_x86_64-linux/zig" "${FLAGS[@]}" \
      -femit-docs="out.docs" \
      -fno-emit-bin \
      -fno-emit-implib \
      --zig-lib-dir "$BASE/external/rules_zig++zig+zig_${VERSION}_x86_64-linux/lib" \
      --cache-dir "/tmp/zig-cache" \
      --global-cache-dir "/tmp/zig-cache" \
      -Mtest="main.zig"
  )
  rm -rf $WD
}

rm -rf /tmp/zig-cache repro-wd
for i in `seq 50`; do
  for kind in binary library test; do
    zig_docs $i 0.14.0 $kind &
    zig_docs $i 0.13.0 $kind &
    zig_docs $i 0.12.1 $kind &
    zig_docs $i 0.12.0 $kind &
  done
done

wait
