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


<a id="zig_configure"></a>

## zig_configure

<pre>
zig_configure(<a href="#zig_configure-name">name</a>, <a href="#zig_configure-actual">actual</a>, <a href="#zig_configure-mode">mode</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_configure-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_configure-actual"></a>actual |  The target to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_configure-mode"></a>mode |  The build mode setting   | String | optional | <code>""</code> |


<a id="zig_configure_binary"></a>

## zig_configure_binary

<pre>
zig_configure_binary(<a href="#zig_configure_binary-name">name</a>, <a href="#zig_configure_binary-actual">actual</a>, <a href="#zig_configure_binary-mode">mode</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_configure_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_configure_binary-actual"></a>actual |  The target to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_configure_binary-mode"></a>mode |  The build mode setting   | String | optional | <code>""</code> |


<a id="zig_configure_test"></a>

## zig_configure_test

<pre>
zig_configure_test(<a href="#zig_configure_test-name">name</a>, <a href="#zig_configure_test-actual">actual</a>, <a href="#zig_configure_test-mode">mode</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_configure_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_configure_test-actual"></a>actual |  The target to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_configure_test-mode"></a>mode |  The build mode setting   | String | optional | <code>""</code> |


<a id="zig_library"></a>

## zig_library

<pre>
zig_library(<a href="#zig_library-name">name</a>, <a href="#zig_library-deps">deps</a>, <a href="#zig_library-main">main</a>, <a href="#zig_library-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_library-deps"></a>deps |  Packages or libraries required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_library-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_library-srcs"></a>srcs |  Other source files required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


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


<a id="zig_test"></a>

## zig_test

<pre>
zig_test(<a href="#zig_test-name">name</a>, <a href="#zig_test-deps">deps</a>, <a href="#zig_test-main">main</a>, <a href="#zig_test-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_test-deps"></a>deps |  Packages or libraries required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="zig_test-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_test-srcs"></a>srcs |  Other source files required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


