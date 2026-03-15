By default, `rules_zig` targets a "lowest common denominator" glibc version to ensure broad compatibility. You can find the discussion behind this choice in [this PR](https://github.com/aherrmann/rules_zig/pull/299) and see the implementation [here](https://github.com/aherrmann/rules_zig/blob/main/zig/target/BUILD.bazel#L56).

This example project demonstrates how to manually configure and use a specific glibc version with `rules_zig`.


```bash
# navigate to the workspace directory:
cd e2e/workspace

# run with the default glibc version
# "main-unconfigured" uses the default glibc version
# note that the runtime glibc version depends on the execution environment
bazel run toolchain-glibc-version:main-unconfigured

# run with a custom glibc version
# "main-2.25" uses a custom toolchain using glibc 2.25
bazel run toolchain-glibc-version:main-2.25

# verify the fallback behaviour
# this shows the "unconfigured" zig_test still uses the fallback version
bazel test toolchain-glibc-version:fallback_glibc.2.17
```
