<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Extensions for bzlmod.

<a id="zig"></a>

## zig

<pre>
zig = use_extension("@rules_zig//zig:extensions.bzl", "zig")
zig.toolchain(<a href="#zig.toolchain-default">default</a>, <a href="#zig.toolchain-zig_version">zig_version</a>)
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

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.toolchain-default"></a>default |  Make this the default Zig SDK version. Can only be used once, and only in the root module.   | Boolean | optional |  `False`  |
| <a id="zig.toolchain-zig_version"></a>zig_version |  The Zig SDK version.   | String | required |  |


