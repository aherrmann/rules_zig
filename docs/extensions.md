<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Extensions for bzlmod.

<a id="zig"></a>

## zig

<pre>
zig = use_extension("@rules_zig//zig:extensions.bzl", "zig")
zig.toolchain(<a href="#zig.toolchain-zig_version">zig_version</a>)
</pre>

Installs a Zig toolchain.
Every module can define a toolchain version under the default name, "zig".
The latest of those versions will be selected (the rest discarded),
and will always be registered by rules_zig.

Additionally, the root module can define arbitrarily many more toolchain versions
under different names (the latest version will be picked for each name)
and can register them as it sees fit,
effectively overriding the default named toolchain
due to toolchain resolution precedence.


**TAG CLASSES**

<a id="zig.toolchain"></a>

### toolchain

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig.toolchain-zig_version"></a>zig_version |  Explicit version of Zig.   | String | required |  |


