"""Expand location placeholders and make variables on attributes.
"""

load("@aspect_bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")

def location_expansion(*, ctx, targets, outputs, attribute_name, strings):
    """Perform location make variable expansion on the given strings.

    Args:
      ctx: Context object.
      targets: List of Target, Expand locations of these targets.
      outputs: List of File, Outputs of the rule to expand.
      attribute_name: String, The name of the attribute we're expanding.
      strings: List of String, The actual string values to expand.

    Returns:
      The given strings with location and make variable references substituted.
    """
    result = []

    for s in strings:
        result.append(
            expand_variables(
                ctx,
                expand_locations(
                    ctx,
                    s,
                    targets,
                ),
                outputs,
                attribute_name,
            ),
        )

    return result
