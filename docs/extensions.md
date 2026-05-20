<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Extensions for bzlmod.

<a id="zig"></a>

## zig

<pre>
zig = use_extension("@rules_zig//zig:extensions.bzl", "zig")
zig.toolchain(<a href="#zig.toolchain-name">name</a>, <a href="#zig.toolchain-default">default</a>, <a href="#zig.toolchain-extra_exec_compatible_with">extra_exec_compatible_with</a>, <a href="#zig.toolchain-extra_target_compatible_with">extra_target_compatible_with</a>,
              <a href="#zig.toolchain-extra_target_settings">extra_target_settings</a>, <a href="#zig.toolchain-zig_version">zig_version</a>)
zig.extra_exec_compatible_with(<a href="#zig.extra_exec_compatible_with-constraints">constraints</a>)
zig.extra_target_compatible_with(<a href="#zig.extra_target_compatible_with-constraints">constraints</a>)
zig.extra_target_settings(<a href="#zig.extra_target_settings-settings">settings</a>)
zig.index(<a href="#zig.index-file">file</a>)
zig.mirrors(<a href="#zig.mirrors-urls">urls</a>)
</pre>

Installs a Zig toolchain.

Every module can define multiple toolchain versions. All these versions will be
registered as toolchains and you can select the toolchain using the
`@zig_toolchains//:version` build flag.

The latest version will be the default unless the root module explicitly
declares one as the default.


**TAG CLASSES**

<a id="zig.toolchain"></a>

### toolchain

Fetch and define toolchain targets for the given Zig SDK version.

Defaults to the latest known version.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.toolchain-name"></a>name |  A descriptive suffix for generated toolchain targets. Leave empty for the default wrapper names.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | optional |  `""`  |
| <a id="zig.toolchain-default"></a>default |  Make this the default Zig SDK version. Can only be used once, and only in the root module.   | Boolean | optional |  `False`  |
| <a id="zig.toolchain-extra_exec_compatible_with"></a>extra_exec_compatible_with |  Additional execution platform constraints for generated Zig SDK toolchain targets.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="zig.toolchain-extra_target_compatible_with"></a>extra_target_compatible_with |  Additional target platform constraints for generated Zig SDK toolchain targets.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="zig.toolchain-extra_target_settings"></a>extra_target_settings |  Additional target settings for generated Zig SDK toolchain targets.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="zig.toolchain-zig_version"></a>zig_version |  The Zig SDK version.   | String | required |  |

<a id="zig.extra_exec_compatible_with"></a>

### extra_exec_compatible_with

Add execution platform constraints to all generated Zig SDK toolchain targets.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.extra_exec_compatible_with-constraints"></a>constraints |  Additional execution platform constraints for generated Zig SDK toolchain targets.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |

<a id="zig.extra_target_compatible_with"></a>

### extra_target_compatible_with

Add target platform constraints to all generated Zig SDK toolchain targets.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.extra_target_compatible_with-constraints"></a>constraints |  Additional target platform constraints for generated Zig SDK toolchain targets.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |

<a id="zig.extra_target_settings"></a>

### extra_target_settings

Add target settings to all generated Zig SDK toolchain targets.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.extra_target_settings-settings"></a>settings |  Additional target settings for generated Zig SDK toolchain targets.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |

<a id="zig.index"></a>

### index

Extend the set of known Zig SDK versions based on a Zig version index.

The provided index must use a schema that is compatible with the [upstream index].

[upstream index]: https://ziglang.org/download/index.json

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.index-file"></a>file |  The Zig version index JSON file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |

<a id="zig.mirrors"></a>

### mirrors

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.mirrors-urls"></a>urls |  The mirrors base URLs.   | List of strings | required |  |


