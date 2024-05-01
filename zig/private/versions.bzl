"""Mirror of Zig release info.

Generated from https://ziglang.org/download/index.json.
"""

def _parse(json_string):
    result = {}

    data = json.decode(json_string)
    for version, platforms in data.items():
        for platform, info in platforms.items():
            result.setdefault(version, {})[platform] = struct(
                url = info["tarball"],
                sha256 = info["shasum"],
            )

    return result

TOOL_VERSIONS = _parse("""\
{
  "0.12.0": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-linux-aarch64-0.12.0.tar.xz",
      "shasum": "754f1029484079b7e0ca3b913a0a2f2a6afd5a28990cb224fe8845e72f09de63"
    },
    "aarch64-macos": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-macos-aarch64-0.12.0.tar.xz",
      "shasum": "294e224c14fd0822cfb15a35cf39aa14bd9967867999bf8bdfe3db7ddec2a27f"
    },
    "aarch64-windows": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-windows-aarch64-0.12.0.zip",
      "shasum": "04c6b92689241ca7a8a59b5f12d2ca2820c09d5043c3c4808b7e93e41c7bf97b"
    },
    "x86-linux": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-linux-x86-0.12.0.tar.xz",
      "shasum": "fb752fceb88749a80d625a6efdb23bea8208962b5150d6d14c92d20efda629a5"
    },
    "x86-windows": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-windows-x86-0.12.0.zip",
      "shasum": "497dc9fd415cadf948872f137d6cc0870507488f79db9547b8f2adb73cda9981"
    },
    "x86_64-linux": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-linux-x86_64-0.12.0.tar.xz",
      "shasum": "c7ae866b8a76a568e2d5cfd31fe89cdb629bdd161fdd5018b29a4a0a17045cad"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-macos-x86_64-0.12.0.tar.xz",
      "shasum": "4d411bf413e7667821324da248e8589278180dbc197f4f282b7dbb599a689311"
    },
    "x86_64-windows": {
      "tarball": "https://ziglang.org/download/0.12.0/zig-windows-x86_64-0.12.0.zip",
      "shasum": "2199eb4c2000ddb1fba85ba78f1fcf9c1fb8b3e57658f6a627a8e513131893f5"
    }
  },
  "0.11.0": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-linux-aarch64-0.11.0.tar.xz",
      "shasum": "956eb095d8ba44ac6ebd27f7c9956e47d92937c103bf754745d0a39cdaa5d4c6"
    },
    "aarch64-macos": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-macos-aarch64-0.11.0.tar.xz",
      "shasum": "c6ebf927bb13a707d74267474a9f553274e64906fd21bf1c75a20bde8cadf7b2"
    },
    "aarch64-windows": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-windows-aarch64-0.11.0.zip",
      "shasum": "5d4bd13db5ecb0ddc749231e00f125c1d31087d708e9ff9b45c4f4e13e48c661"
    },
    "x86-linux": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-linux-x86-0.11.0.tar.xz",
      "shasum": "7b0dc3e0e070ae0e0d2240b1892af6a1f9faac3516cae24e57f7a0e7b04662a8"
    },
    "x86-windows": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-windows-x86-0.11.0.zip",
      "shasum": "e72b362897f28c671633e650aa05289f2e62b154efcca977094456c8dac3aefa"
    },
    "x86_64-linux": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz",
      "shasum": "2d00e789fec4f71790a6e7bf83ff91d564943c5ee843c5fd966efc474b423047"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-macos-x86_64-0.11.0.tar.xz",
      "shasum": "1c1c6b9a906b42baae73656e24e108fd8444bb50b6e8fd03e9e7a3f8b5f05686"
    },
    "x86_64-windows": {
      "tarball": "https://ziglang.org/download/0.11.0/zig-windows-x86_64-0.11.0.zip",
      "shasum": "142caa3b804d86b4752556c9b6b039b7517a08afa3af842645c7e2dcd125f652"
    }
  }
}
""")

# vim: ft=bzl
