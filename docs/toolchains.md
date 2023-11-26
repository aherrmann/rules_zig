<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules to declare Zig toolchains.

<a id="zig_target_toolchain"></a>

## zig_target_toolchain

<pre>
zig_target_toolchain(<a href="#zig_target_toolchain-name">name</a>, <a href="#zig_target_toolchain-target">target</a>)
</pre>

Defines a Zig target configuration toolchain.

The Zig compiler toolchain, defined by the `zig_toolchain` rule,
has builtin cross-compilation support.
Meaning, most Zig toolchains can target any platform supported by Zig
independent of the execution platform.

Therefore, there is no need to couple the execution platform
with the target platform, at least not by default.

Use this rule to configure a Zig target platform
and declare the corresponding Bazel target platform constraints
using the builtin `toolchain` rule.

Use the target `@rules_zig//zig/target:resolved_toolchain`
to access the resolved toolchain for the current target platform.
You can build this target to obtain a JSON file
capturing the relevant Zig compiler flags.

See https://bazel.build/extending/toolchains#defining-toolchains.

**EXAMPLE**

```bzl
zig_target_toolchain(
    name = "x86_64-linux",
    target = "x86_64-linux",
)

toolchain(
    name = "x86_64-linux_toolchain",
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":x86_64-linux",
    toolchain_type = "@rules_zig//zig/target:toolchain_type",
)
```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_target_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_target_toolchain-target"></a>target |  The value of the -target flag.   | String | required |  |


<a id="zig_toolchain"></a>

## zig_toolchain

<pre>
zig_toolchain(<a href="#zig_toolchain-name">name</a>, <a href="#zig_toolchain-zig_exe">zig_exe</a>, <a href="#zig_toolchain-zig_exe_path">zig_exe_path</a>, <a href="#zig_toolchain-zig_lib">zig_lib</a>, <a href="#zig_toolchain-zig_lib_path">zig_lib_path</a>)
</pre>

Defines a Zig compiler toolchain.

The Zig compiler toolchain, defined by the `zig_toolchain` rule,
has builtin cross-compilation support.
Meaning, most Zig toolchains can target any platform supported by Zig
independent of the execution platform.

Therefore, there is no need to couple the execution platform
with the target platform, at least not by default.

This rule configures a Zig compiler toolchain
and the corresponding Bazel execution platform constraints
can be declared using the builtin `toolchain` rule.

You will rarely need to invoke this rule directly.
Instead, use `zig_register_toolchains`
provided by `@rules_zig//zig:repositories.bzl`.

Use the target `@rules_zig//zig:resolved_toolchain`
to access the resolved toolchain for the current execution platform.

See https://bazel.build/extending/toolchains#defining-toolchains.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_toolchain-zig_exe"></a>zig_exe |  A hermetically downloaded Zig executable for the target platform.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="zig_toolchain-zig_exe_path"></a>zig_exe_path |  Path to an existing Zig executable for the target platform.   | String | optional |  `""`  |
| <a id="zig_toolchain-zig_lib"></a>zig_lib |  Files of a hermetically downloaded Zig library for the target platform.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="zig_toolchain-zig_lib_path"></a>zig_lib_path |  Absolute path to an existing Zig library for the target platform or a the path to a hermetically downloaded Zig library relative to the Zig executable.   | String | optional |  `""`  |


