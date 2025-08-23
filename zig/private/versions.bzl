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
  "0.14.1": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.14.1/zig-aarch64-linux-0.14.1.tar.xz",
      "shasum": "f7a654acc967864f7a050ddacfaa778c7504a0eca8d2b678839c21eea47c992b"
    },
    "aarch64-macos": {
      "tarball": "https://ziglang.org/download/0.14.1/zig-aarch64-macos-0.14.1.tar.xz",
      "shasum": "39f3dc5e79c22088ce878edc821dedb4ca5a1cd9f5ef915e9b3cc3053e8faefa"
    },
    "aarch64-windows": {
      "tarball": "https://ziglang.org/download/0.14.1/zig-aarch64-windows-0.14.1.zip",
      "shasum": "b5aac0ccc40dd91e8311b1f257717d8e3903b5fefb8f659de6d65a840ad1d0e7"
    },
    "x86-linux": {
      "tarball": "https://ziglang.org/download/0.14.1/zig-x86-linux-0.14.1.tar.xz",
      "shasum": "4bce6347fa112247443cb0952c19e560d1f90b910506cf895fd07a7b8d1c4a76"
    },
    "x86-windows": {
      "tarball": "https://ziglang.org/download/0.14.1/zig-x86-windows-0.14.1.zip",
      "shasum": "3ee730c2a5523570dc4dc1b724f3e4f30174ebc1fa109ca472a719586a473b18"
    },
    "x86_64-linux": {
      "tarball": "https://ziglang.org/download/0.14.1/zig-x86_64-linux-0.14.1.tar.xz",
      "shasum": "24aeeec8af16c381934a6cd7d95c807a8cb2cf7df9fa40d359aa884195c4716c"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/download/0.14.1/zig-x86_64-macos-0.14.1.tar.xz",
      "shasum": "b0f8bdfb9035783db58dd6c19d7dea89892acc3814421853e5752fe4573e5f43"
    },
    "x86_64-windows": {
      "tarball": "https://ziglang.org/download/0.14.1/zig-x86_64-windows-0.14.1.zip",
      "shasum": "554f5378228923ffd558eac35e21af020c73789d87afeabf4bfd16f2e6feed2c"
    }
  },
  "0.13.0": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.13.0/zig-linux-aarch64-0.13.0.tar.xz",
      "shasum": "041ac42323837eb5624068acd8b00cd5777dac4cf91179e8dad7a7e90dd0c556"
    },
    "aarch64-macos": {
      "tarball": "https://ziglang.org/download/0.13.0/zig-macos-aarch64-0.13.0.tar.xz",
      "shasum": "46fae219656545dfaf4dce12fb4e8685cec5b51d721beee9389ab4194d43394c"
    },
    "aarch64-windows": {
      "tarball": "https://ziglang.org/download/0.13.0/zig-windows-aarch64-0.13.0.zip",
      "shasum": "95ff88427af7ba2b4f312f45d2377ce7a033e5e3c620c8caaa396a9aba20efda"
    },
    "x86-linux": {
      "tarball": "https://ziglang.org/download/0.13.0/zig-linux-x86-0.13.0.tar.xz",
      "shasum": "876159cc1e15efb571e61843b39a2327f8925951d48b9a7a03048c36f72180f7"
    },
    "x86-windows": {
      "tarball": "https://ziglang.org/download/0.13.0/zig-windows-x86-0.13.0.zip",
      "shasum": "eb3d533c3cf868bff7e74455dc005d18fd836c42e50b27106b31e9fec6dffc4a"
    },
    "x86_64-linux": {
      "tarball": "https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz",
      "shasum": "d45312e61ebcc48032b77bc4cf7fd6915c11fa16e4aad116b66c9468211230ea"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/download/0.13.0/zig-macos-x86_64-0.13.0.tar.xz",
      "shasum": "8b06ed1091b2269b700b3b07f8e3be3b833000841bae5aa6a09b1a8b4773effd"
    },
    "x86_64-windows": {
      "tarball": "https://ziglang.org/download/0.13.0/zig-windows-x86_64-0.13.0.zip",
      "shasum": "d859994725ef9402381e557c60bb57497215682e355204d754ee3df75ee3c158"
    }
  }
}
""")

# vim: ft=bzl
