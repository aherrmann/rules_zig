<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Implementation of the settings rule.

<a id="settings"></a>

## settings

<pre>
settings(<a href="#settings-name">name</a>, <a href="#settings-mode">mode</a>, <a href="#settings-threaded">threaded</a>)
</pre>

Collection of all Zig build settings.

This rule is only intended for internal use.
It collects the values of all relevant build settings,
such as `@rules_zig//zig/settings:mode`.

You can build the settings target to obtain a JSON file
capturing all configured Zig build settings.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="settings-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="settings-mode"></a>mode |  The build mode setting.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="settings-threaded"></a>threaded |  The Zig multi- or single-threaded setting.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


