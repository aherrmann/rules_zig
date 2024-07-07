<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Declare rules_zig dependencies and toolchains.

These are needed for local development, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies

<a id="rules_zig_dependencies"></a>

## rules_zig_dependencies

<pre>
load("@rules_zig//zig:repositories.bzl", "rules_zig_dependencies")

rules_zig_dependencies()
</pre>

Register dependencies required by rules_zig.



<a id="zig_register_toolchains"></a>

## zig_register_toolchains

<pre>
load("@rules_zig//zig:repositories.bzl", "zig_register_toolchains")

zig_register_toolchains(*, <a href="#zig_register_toolchains-name">name</a>, <a href="#zig_register_toolchains-zig_versions">zig_versions</a>, <a href="#zig_register_toolchains-zig_version">zig_version</a>, <a href="#zig_register_toolchains-register">register</a>, <a href="#zig_register_toolchains-kwargs">**kwargs</a>)
</pre>

Convenience macro for users which does typical setup.

- create a repository for each version and built-in platform like
  "zig_0.10.1_linux_amd64" - this repository is lazily fetched when zig is
  needed for that version and platform.
- TODO: create a convenience repository for the host platform like "zig_host"
- create a repository exposing toolchains for each platform like "zig_platforms"
- register a toolchain pointing at each platform

Users can avoid this macro and do these steps themselves, if they want more control.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="zig_register_toolchains-name"></a>name |  base name for all created repos, like "zig".   |  none |
| <a id="zig_register_toolchains-zig_versions"></a>zig_versions |  The list of Zig SDK versions to fetch, toolchains are registered in the given order.   |  `None` |
| <a id="zig_register_toolchains-zig_version"></a>zig_version |  A single Zig SDK version to fetch. Do not use together with zig_versions.   |  `None` |
| <a id="zig_register_toolchains-register"></a>register |  whether to call through to native.register_toolchains. Should be True for WORKSPACE users, but False when used under bzlmod extension.   |  `True` |
| <a id="zig_register_toolchains-kwargs"></a>kwargs |  passed to each zig_repository call   |  none |


<a id="zig_repositories"></a>

## zig_repositories

<pre>
load("@rules_zig//zig:repositories.bzl", "zig_repositories")

zig_repositories(<a href="#zig_repositories-kwargs">**kwargs</a>)
</pre>

Fetch and install a Zig toolchain.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="zig_repositories-kwargs"></a>kwargs |  forwarded to `zig_repository`.   |  none |

**DEPRECATED**

Use `zig_repository` instead.


<a id="zig_repository"></a>

## zig_repository

<pre>
load("@rules_zig//zig:repositories.bzl", "zig_repository")

zig_repository(*, <a href="#zig_repository-name">name</a>, <a href="#zig_repository-zig_version">zig_version</a>, <a href="#zig_repository-platform">platform</a>, <a href="#zig_repository-kwargs">**kwargs</a>)
</pre>

Fetch and install a Zig toolchain.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="zig_repository-name"></a>name |  string, A unique name for the repository.   |  none |
| <a id="zig_repository-zig_version"></a>zig_version |  string, The Zig SDK version number.   |  none |
| <a id="zig_repository-platform"></a>platform |  string, The platform that the Zig SDK can execute on, e.g. `x86_64-linux` or `aarch64-macos`.   |  none |
| <a id="zig_repository-kwargs"></a>kwargs |  Passed to the underlying repository rule.   |  none |


