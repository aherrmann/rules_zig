<!-- Generated with Stardoc: http://skydoc.bazel.build -->

This module implements an alias rule to the resolved target toolchain.


<a id="resolved_target_toolchain"></a>

## resolved_target_toolchain

<pre>
resolved_target_toolchain(<a href="#resolved_target_toolchain-name">name</a>)
</pre>

Exposes a concrete toolchain which is the result of Bazel resolving the
toolchain for the execution or target platform.
Workaround for https://github.com/bazelbuild/bazel/issues/14009


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="resolved_target_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |


