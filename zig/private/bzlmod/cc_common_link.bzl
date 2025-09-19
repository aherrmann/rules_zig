"""Implementation of a repository rule that exposes private APIs of cc_common.link."""

def _cc_common_link(rctx):
    rctx.file("BUILD.bazel", """\
exports_files(["cc_common_link.bzl"])
""")
    rctx.file("cc_common_link.bzl", """\
def cc_common_link(*args, **kwargs):
    return cc_common.link(*args, **kwargs)
""")

cc_common_link = repository_rule(
    implementation = _cc_common_link,
)
