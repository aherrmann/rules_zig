"""Utility function for escaping Bazel labels into valid path components."""

# Taken from https://github.com/bazelbuild/rules_cc/blob/109e43da9b210aa1806ac27bb640d2233c9703ce/cc/private/cc_common.bzl#L681-L701

_PATH_ESCAPE_REPLACEMENTS = {
    "_": "_U",
    "/": "_S",
    "\\": "_B",
    ":": "_C",
    "@": "_A",
}

# buildifier: disable=function-docstring
def escape_label(*, label):
    path = label.package + ":" + label.name
    if label.repo_name:
        path = label.repo_name + "@" + path
    return escape_label_str(path)

# buildifier: disable=function-docstring
def escape_label_str(label_str):
    result = []
    for idx in range(len(label_str)):
        c = label_str[idx]
        result.append(_PATH_ESCAPE_REPLACEMENTS.get(
            c,
            c,  # no escaping by default
        ))
    return "".join(result)
