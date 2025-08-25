#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
VERSION=${TAG:1}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_zig-$VERSION"
ARCHIVE="$PREFIX.tar.gz"
git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE

cat << EOF
## Setup Instructions

Add the following to your \`MODULE.bazel\` file to install rules_zig:

\`\`\`starlark
bazel_dep(name = "rules_zig", version = "$VERSION")
\`\`\`

Optionally add the following to your \`MODULE.bazel\` file to install a specific Zig toolchain version:

\`\`\`starlark
zig = use_extension("//zig:extensions.bzl", "zig")
zig.toolchain(zig_version = "0.15.1")
\`\`\`

You can call \`zig.toolchain\` multiple times to install multiple Zig versions.

Note, rules_zig requires bzlmod, WORKSPACE mode is no longer supported.
EOF
