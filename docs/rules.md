<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules to build and run Zig code.

<a id="zig_binary"></a>

## zig_binary

<pre>
zig_binary(<a href="#zig_binary-name">name</a>, <a href="#zig_binary-copts">copts</a>, <a href="#zig_binary-csrcs">csrcs</a>, <a href="#zig_binary-data">data</a>, <a href="#zig_binary-deps">deps</a>, <a href="#zig_binary-extra_srcs">extra_srcs</a>, <a href="#zig_binary-linker_script">linker_script</a>, <a href="#zig_binary-main">main</a>, <a href="#zig_binary-srcs">srcs</a>)
</pre>

Builds a Zig binary.

The target can be built using `bazel build`, corresponding to `zig build-exe`,
and executed using `bazel run`, corresponding to `zig run`.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_binary")

zig_binary(
    name = "my-binary",
    main = "main.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":my-package",  # to support `@import("my-package")`.
    ],
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_binary-copts"></a>copts |  C compiler flags required to build the C sources of the target.   | List of strings | optional | <code>[]</code> |
| <a id="zig_binary-csrcs"></a>csrcs |  C source files required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_binary-data"></a>data |  Files required by the target during runtime.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_binary-deps"></a>deps |  Packages or libraries required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_binary-extra_srcs"></a>extra_srcs |  Other files required to build the target, e.g. files embedded using <code>@embedFile</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_binary-linker_script"></a>linker_script |  Custom linker script for the target.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="zig_binary-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_binary-srcs"></a>srcs |  Other Zig source files required to build the target, e.g. files imported using <code>@import</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="zig_configure"></a>

## zig_configure

<pre>
zig_configure(<a href="#zig_configure-name">name</a>, <a href="#zig_configure-actual">actual</a>, <a href="#zig_configure-mode">mode</a>, <a href="#zig_configure-target">target</a>, <a href="#zig_configure-threaded">threaded</a>)
</pre>

Transitions a target and its dependencies to a different configuration.

Settings like the build mode, e.g. `ReleaseSafe`, or the target platform,
can be set on the command-line on demand,
e.g. using `--@rules_zig//zig/settings:mode=release_safe`.

However, you may wish to always build a given target
in a particular configuration,
or you may wish to build a given target in multiple configurations
in a single build, e.g. to generate a multi-platform release bundle.

Use this rule to that end.

You can read more about Bazel configurations and transitions
[here][bazel-config].

[bazel-config]: https://bazel.build/extending/config

**EXAMPLE**

```bzl
load(
    "@rules_zig//zig:defs.bzl",
    "zig_binary",
    "zig_configure",
)

zig_library(
    name = "library",
    main = "library.zig",
    tags = ["manual"],  # optional, exclude from `bazel build //...`.
)

zig_configure(
    name = "library_debug",
    actual = ":library",
    mode = "debug",
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_configure-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_configure-actual"></a>actual |  The target to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_configure-mode"></a>mode |  The build mode setting, corresponds to the <code>-O</code> Zig compiler flag.   | String | optional | <code>""</code> |
| <a id="zig_configure-target"></a>target |  The target platform, expects a label to a Bazel target platform used to select a <code>zig_target_toolchain</code> instance.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="zig_configure-threaded"></a>threaded |  The threaded setting, corresponds to the <code>-fsingle-threaded</code> Zig compiler flag.   | String | optional | <code>""</code> |


<a id="zig_configure_binary"></a>

## zig_configure_binary

<pre>
zig_configure_binary(<a href="#zig_configure_binary-name">name</a>, <a href="#zig_configure_binary-actual">actual</a>, <a href="#zig_configure_binary-mode">mode</a>, <a href="#zig_configure_binary-target">target</a>, <a href="#zig_configure_binary-threaded">threaded</a>)
</pre>

Transitions a target and its dependencies to a different configuration.

Settings like the build mode, e.g. `ReleaseSafe`, or the target platform,
can be set on the command-line on demand,
e.g. using `--@rules_zig//zig/settings:mode=release_safe`.

However, you may wish to always build a given target
in a particular configuration,
or you may wish to build a given target in multiple configurations
in a single build, e.g. to generate a multi-platform release bundle.

Use this rule to that end.

You can read more about Bazel configurations and transitions
[here][bazel-config].

[bazel-config]: https://bazel.build/extending/config

**EXAMPLE**

```bzl
load(
    "@rules_zig//zig:defs.bzl",
    "zig_binary",
    "zig_configure_binary",
)

zig_binary(
    name = "binary",
    main = "main.zig",
    tags = ["manual"],  # optional, exclude from `bazel build //...`.
)

zig_configure_binary(
    name = "binary_debug",
    actual = ":binary",
    mode = "debug",
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_configure_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_configure_binary-actual"></a>actual |  The target to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_configure_binary-mode"></a>mode |  The build mode setting, corresponds to the <code>-O</code> Zig compiler flag.   | String | optional | <code>""</code> |
| <a id="zig_configure_binary-target"></a>target |  The target platform, expects a label to a Bazel target platform used to select a <code>zig_target_toolchain</code> instance.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="zig_configure_binary-threaded"></a>threaded |  The threaded setting, corresponds to the <code>-fsingle-threaded</code> Zig compiler flag.   | String | optional | <code>""</code> |


<a id="zig_configure_test"></a>

## zig_configure_test

<pre>
zig_configure_test(<a href="#zig_configure_test-name">name</a>, <a href="#zig_configure_test-actual">actual</a>, <a href="#zig_configure_test-mode">mode</a>, <a href="#zig_configure_test-target">target</a>, <a href="#zig_configure_test-threaded">threaded</a>)
</pre>

Transitions a target and its dependencies to a different configuration.

Settings like the build mode, e.g. `ReleaseSafe`, or the target platform,
can be set on the command-line on demand,
e.g. using `--@rules_zig//zig/settings:mode=release_safe`.

However, you may wish to always build a given target
in a particular configuration,
or you may wish to build a given target in multiple configurations
in a single build, e.g. to generate a multi-platform release bundle.

Use this rule to that end.

You can read more about Bazel configurations and transitions
[here][bazel-config].

[bazel-config]: https://bazel.build/extending/config

**EXAMPLE**

```bzl
load(
    "@rules_zig//zig:defs.bzl",
    "zig_test",
    "zig_configure_test",
)

zig_test(
    name = "test",
    main = "test.zig",
    tags = ["manual"],  # optional, exclude from `bazel build //...`.
)

zig_configure_test(
    name = "test_debug",
    actual = ":test",
    mode = "debug",
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_configure_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_configure_test-actual"></a>actual |  The target to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_configure_test-mode"></a>mode |  The build mode setting, corresponds to the <code>-O</code> Zig compiler flag.   | String | optional | <code>""</code> |
| <a id="zig_configure_test-target"></a>target |  The target platform, expects a label to a Bazel target platform used to select a <code>zig_target_toolchain</code> instance.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="zig_configure_test-threaded"></a>threaded |  The threaded setting, corresponds to the <code>-fsingle-threaded</code> Zig compiler flag.   | String | optional | <code>""</code> |


<a id="zig_library"></a>

## zig_library

<pre>
zig_library(<a href="#zig_library-name">name</a>, <a href="#zig_library-copts">copts</a>, <a href="#zig_library-csrcs">csrcs</a>, <a href="#zig_library-data">data</a>, <a href="#zig_library-deps">deps</a>, <a href="#zig_library-extra_srcs">extra_srcs</a>, <a href="#zig_library-linker_script">linker_script</a>, <a href="#zig_library-main">main</a>, <a href="#zig_library-srcs">srcs</a>)
</pre>

Builds a Zig library.

The target can be built using `bazel build`, corresponding to `zig build-lib`.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_library")

zig_library(
    name = "my-library",
    main = "main.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":my-package",  # to support `@import("my-package")`.
    ],
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_library-copts"></a>copts |  C compiler flags required to build the C sources of the target.   | List of strings | optional | <code>[]</code> |
| <a id="zig_library-csrcs"></a>csrcs |  C source files required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_library-data"></a>data |  Files required by the target during runtime.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_library-deps"></a>deps |  Packages or libraries required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_library-extra_srcs"></a>extra_srcs |  Other files required to build the target, e.g. files embedded using <code>@embedFile</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_library-linker_script"></a>linker_script |  Custom linker script for the target.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="zig_library-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_library-srcs"></a>srcs |  Other Zig source files required to build the target, e.g. files imported using <code>@import</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="zig_package"></a>

## zig_package

<pre>
zig_package(<a href="#zig_package-name">name</a>, <a href="#zig_package-deps">deps</a>, <a href="#zig_package-extra_srcs">extra_srcs</a>, <a href="#zig_package-main">main</a>, <a href="#zig_package-srcs">srcs</a>)
</pre>

Defines a Zig package.

A Zig package is a collection of Zig sources with a main source file
that defines the package's entry point.

This rule does not perform compilation by itself.
Instead, packages are compiled at the use-site.
Zig performs whole program compilation.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_package")

zig_package(
    name = "my-package",
    main = "main.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":other-package",  # to support `@import("other-package")`.
    ],
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_package-deps"></a>deps |  Other packages required when building the package.<br><br>Note, the Zig compiler requires that every package dependency is specified with its own package dependencies on the command-line, recursively. Meaning the entire Zig package dependency tree will be represented on the command-line without deduplication of shared nodes. Keep this in mind when you defined the granularity of your Zig packages.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_package-extra_srcs"></a>extra_srcs |  Other files required when building the package, e.g. files embedded using <code>@embedFile</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_package-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_package-srcs"></a>srcs |  Other Zig source files required when building the package, e.g. files imported using <code>@import</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="zig_test"></a>

## zig_test

<pre>
zig_test(<a href="#zig_test-name">name</a>, <a href="#zig_test-copts">copts</a>, <a href="#zig_test-csrcs">csrcs</a>, <a href="#zig_test-data">data</a>, <a href="#zig_test-deps">deps</a>, <a href="#zig_test-extra_srcs">extra_srcs</a>, <a href="#zig_test-linker_script">linker_script</a>, <a href="#zig_test-main">main</a>, <a href="#zig_test-srcs">srcs</a>)
</pre>

Builds a Zig test.

The target can be executed using `bazel test`, corresponding to `zig test`.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_test")

zig_test(
    name = "my-test",
    main = "test.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":my-package",  # to support `@import("my-package")`.
    ],
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_test-copts"></a>copts |  C compiler flags required to build the C sources of the target.   | List of strings | optional | <code>[]</code> |
| <a id="zig_test-csrcs"></a>csrcs |  C source files required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_test-data"></a>data |  Files required by the target during runtime.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_test-deps"></a>deps |  Packages or libraries required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_test-extra_srcs"></a>extra_srcs |  Other files required to build the target, e.g. files embedded using <code>@embedFile</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_test-linker_script"></a>linker_script |  Custom linker script for the target.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="zig_test-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_test-srcs"></a>srcs |  Other Zig source files required to build the target, e.g. files imported using <code>@import</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


