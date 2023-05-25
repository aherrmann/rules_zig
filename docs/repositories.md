<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Declare rules_zig dependencies and toolchains.

These are needed for local development, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies


<a id="zig_repositories"></a>

## zig_repositories

<pre>
zig_repositories(<a href="#zig_repositories-name">name</a>, <a href="#zig_repositories-platform">platform</a>, <a href="#zig_repositories-repo_mapping">repo_mapping</a>, <a href="#zig_repositories-zig_version">zig_version</a>)
</pre>

Fetch and install a Zig toolchain.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_repositories-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_repositories-platform"></a>platform |  -   | String | required |  |
| <a id="zig_repositories-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="zig_repositories-zig_version"></a>zig_version |  -   | String | required |  |


<a id="rules_zig_dependencies"></a>

## rules_zig_dependencies

<pre>
rules_zig_dependencies()
</pre>

Register dependencies required by rules_zig.



<a id="zig_register_toolchains"></a>

## zig_register_toolchains

<pre>
zig_register_toolchains(<a href="#zig_register_toolchains-name">name</a>, <a href="#zig_register_toolchains-kwargs">kwargs</a>)
</pre>

Convenience macro for users which does typical setup.

- create a repository for each built-in platform like "zig_linux_amd64" -
  this repository is lazily fetched when zig is needed for that platform.
- TODO: create a convenience repository for the host platform like "zig_host"
- create a repository exposing toolchains for each platform like "zig_platforms"
- register a toolchain pointing at each platform

Users can avoid this macro and do these steps themselves, if they want more control.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="zig_register_toolchains-name"></a>name |  base name for all created repos, like "zig1_14"   |  none |
| <a id="zig_register_toolchains-kwargs"></a>kwargs |  passed to each zig_repositories call   |  none |


