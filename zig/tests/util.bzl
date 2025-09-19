"""Utilities for unit and analysis tests."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")

def _is_flag_set(flag, args):
    """Check whether the given flag is set.

    Args:
      flag: String, The name of the flag, including any `--` prefix.
      args: sequence of String, The list of arguments to search in.

    Returns:
      True if the flag is set, False otherwise.
    """
    for arg in args:
        if arg == flag:
            return True
    return False

def assert_flag_set(env, flag, args):
    """Assert that the given flag is set.

    Args:
      env: The Skylib unittest environment object.
      flag: String, The name of the flag, including any `--` prefix.
      args: sequence of String, The list of arguments to search in.
    """
    is_set = _is_flag_set(flag, args)
    asserts.true(env, is_set, "The flag {} should have been set.".format(flag))

def assert_flag_unset(env, flag, args):
    """Assert that the given flag is not set.

    Args:
      env: The Skylib unittest environment object.
      flag: String, The name of the flag, including any `--` prefix.
      args: sequence of String, The list of arguments to search in.
    """
    is_set = _is_flag_set(flag, args)
    asserts.false(env, is_set, "The flag {} should not have been set.".format(flag))

def assert_find_unique_option(env, name, args):
    """Assert that the given option is set and unique and return its value.

    Args:
      env: The Skylib unittest environment object.
      name: String, The name of the flag, including any `--` prefix.
      args: sequence of String, The list of arguments to search in.

    Returns:
      The option value of the argument or `None` if unset.
    """
    index = -1
    for i, arg in enumerate(args):
        if arg == name:
            asserts.equals(env, -1, index, "The option {} should be unique.".format(name))
            index = i
    asserts.true(env, index + 1 <= len(args), "The option {} should have an argument.".format(name))
    asserts.false(env, index == -1, "The option {} should be set.".format(name))
    if index != -1:
        return args[index + 1]
    else:
        return None

def assert_find_unique_surrounded_arguments(env, start, end, args):
    """Find a sequence of arguments surrounded by a start and end marker.

    Assert that such a sequence exists and that there is no further occurence
    of the start marker afterwards.
    Return the sequence of surrounded arguments excluding the markers.

    Args:
      env: The Skylib unittest environment object.
      start: String, The start marker, including any `--` prefix.
      end: String, The end marker, including any `--` prefix.
      args: sequence of String, The list of arguments to search in.

    Returns:
      The sequence of surrounded arguments.
    """
    start_offset = -1
    end_offset = -1

    for i, arg in enumerate(args):
        if start_offset == -1:
            if arg == start:
                start_offset = i
        elif start_offset != -1 and end_offset == -1:
            if arg == end:
                end_offset = i
        elif arg == start:
            unittest.fail(env, "Secondary start marker '{}' encountered.".format(start))

    asserts.true(env, start_offset != -1, "Start marker '{}' expected but not found.".format(start))
    asserts.true(env, end_offset != -1, "End marker '{}' expected but not found.".format(end))

    return args[start_offset + 1:end_offset]

def assert_find_action(env, mnemonic):
    """Assert that the given action mnemonic exists and return the first instance.

    Args:
      env: The Skylib unittest environment object.
      mnemonic: String, The action mnemonic to look for.

    Returns:
      The action object or `None` if not found.
    """
    actions = analysistest.target_actions(env)

    for action in actions:
        if action.mnemonic == mnemonic:
            return action

    asserts.true(env, False, "Expected an action with mnemonic {}.".format(mnemonic))

    return None

def assert_find_actions_in_exact_order(env, expected_mnemonics):
    """Assert that the given action mnemonics appear in the actual actions in order.

    Args:
      env: The Skylib unittest environment object.
      expected_mnemonics: List of strings, the mnemonics to look for in order.

    Returns:
      List of action objects corresponding to the matched mnemonics.
    """
    actions = analysistest.target_actions(env)
    actual_mnemonics = [a.mnemonic for a in actions]

    matched_actions = []
    start = 0

    for exp in expected_mnemonics:
        found_at = -1
        for i in range(start, len(actual_mnemonics)):
            if actual_mnemonics[i] == exp:
                found_at = i
                break

        if found_at == -1:
            asserts.true(
                env,
                False,
                "Expected mnemonic '{}' in order {} but actual sequence was {}.".format(
                    exp,
                    expected_mnemonics,
                    actual_mnemonics,
                ),
            )

        matched_actions.append(actions[found_at])
        start = found_at + 1

    return matched_actions

def canonical_label(label_str):
    """Canonicalize a given label.

    Applies `str(Label(...))` to the given label to convert it to canonical form.
    If the input had a leading `@//` and the result does not start with `@`,
    then this retains the `@//` prefix for Bazel 5.3.2 compatibility.

    Args:
      label_str: String, The label to canonicalize.

    Returns:
      String, The canonicalized label.
    """
    result = str(Label(label_str))

    if label_str.startswith("@//") and not result.startswith("@"):
        result = "@" + result

    return result
