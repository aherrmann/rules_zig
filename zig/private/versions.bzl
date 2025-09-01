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
  "0.15.1": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.15.1/zig-aarch64-linux-0.15.1.tar.xz",
      "shasum": "bb4a8d2ad735e7fba764c497ddf4243cb129fece4148da3222a7046d3f1f19fe"
    },
    "aarch64-macos": {
      "tarball": "https://ziglang.org/download/0.15.1/zig-aarch64-macos-0.15.1.tar.xz",
      "shasum": "c4bd624d901c1268f2deb9d8eb2d86a2f8b97bafa3f118025344242da2c54d7b"
    },
    "aarch64-windows": {
      "tarball": "https://ziglang.org/download/0.15.1/zig-aarch64-windows-0.15.1.zip",
      "shasum": "1f1bf16228b0ffcc882b713dc5e11a6db4219cb30997e13c72e8e723c2104ec6"
    },
    "x86-linux": {
      "tarball": "https://ziglang.org/download/0.15.1/zig-x86-linux-0.15.1.tar.xz",
      "shasum": "dff166f25fdd06e8341d831a71211b5ba7411463a6b264bdefa8868438690b6a"
    },
    "x86-windows": {
      "tarball": "https://ziglang.org/download/0.15.1/zig-x86-windows-0.15.1.zip",
      "shasum": "fb1c07cffbb43615d3158ab8b8f5db5da1d48875eca99e1d7a8a0064ff63fc5b"
    },
    "x86_64-linux": {
      "tarball": "https://ziglang.org/download/0.15.1/zig-x86_64-linux-0.15.1.tar.xz",
      "shasum": "c61c5da6edeea14ca51ecd5e4520c6f4189ef5250383db33d01848293bfafe05"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/download/0.15.1/zig-x86_64-macos-0.15.1.tar.xz",
      "shasum": "9919392e0287cccc106dfbcbb46c7c1c3fa05d919567bb58d7eb16bca4116184"
    },
    "x86_64-windows": {
      "tarball": "https://ziglang.org/download/0.15.1/zig-x86_64-windows-0.15.1.zip",
      "shasum": "91e69e887ca8c943ce9a515df3af013d95a66a190a3df3f89221277ebad29e34"
    }
  },
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
  }
}
""")

# vim: ft=bzl
