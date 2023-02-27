"""Utilities for unit and analysis tests."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

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
