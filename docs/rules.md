<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API re-exports

<a id="zig_binary"></a>

## zig_binary

<pre>
zig_binary(<a href="#zig_binary-name">name</a>, <a href="#zig_binary-main">main</a>, <a href="#zig_binary-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="zig_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="zig_binary-main"></a>main |  The main source file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="zig_binary-srcs"></a>srcs |  Other source files required to build the target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


