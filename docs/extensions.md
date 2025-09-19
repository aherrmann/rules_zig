<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Extensions for bzlmod.

<a id="cc_common_link"></a>

## cc_common_link

<pre>
load("@rules_zig//zig:extensions.bzl", "cc_common_link")

cc_common_link(<a href="#cc_common_link-name">name</a>)
</pre>

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_common_link-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |


<a id="zig"></a>

## zig

<pre>
zig = use_extension("@rules_zig//zig:extensions.bzl", "zig")
zig.toolchain(<a href="#zig.toolchain-default">default</a>, <a href="#zig.toolchain-zig_version">zig_version</a>)
zig.index(<a href="#zig.index-file">file</a>)
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
| <a id="zig.toolchain-default"></a>default |  Make this the default Zig SDK version. Can only be used once, and only in the root module.   | Boolean | optional |  `False`  |
| <a id="zig.toolchain-zig_version"></a>zig_version |  The Zig SDK version.   | String | required |  |

<a id="zig.index"></a>

### index

Extend the set of known Zig SDK versions based on a Zig version index.

The provided index must use a schema that is compatible with the [upstream index].

[upstream index]: https://ziglang.org/download/index.json

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.index-file"></a>file |  The Zig version index JSON file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


