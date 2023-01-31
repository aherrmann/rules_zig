<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API re-exports

<a id="zig_binary"></a>

## zig_binary

<pre>
zig_binary(<a href="#zig_binary-name">name</a>, <a href="#zig_binary-deps">deps</a>, <a href="#zig_binary-main">main</a>, <a href="#zig_binary-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_binary-deps"></a>deps |  Packages or libraries required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_binary-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_binary-srcs"></a>srcs |  Other source files required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="zig_package"></a>

## zig_package

<pre>
zig_package(<a href="#zig_package-name">name</a>, <a href="#zig_package-deps">deps</a>, <a href="#zig_package-main">main</a>, <a href="#zig_package-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_package-deps"></a>deps |  Other packages required when building the package.<br><br>Note, the Zig compiler requires that every package dependency is specified with its own package dependencies on the command-line, recursively. Meaning the entire Zig package dependency tree will be represented on the command-line without deduplication of shared nodes. Keep this in mind when you defined the granularity of your Zig packages.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_package-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_package-srcs"></a>srcs |  Other source files required when building the package.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


