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
  "0.14.0": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.14.0/zig-linux-aarch64-0.14.0.tar.xz",
      "shasum": "ab64e3ea277f6fc5f3d723dcd95d9ce1ab282c8ed0f431b4de880d30df891e4f"
    },
    "aarch64-macos": {
      "tarball": "https://ziglang.org/download/0.14.0/zig-macos-aarch64-0.14.0.tar.xz",
      "shasum": "b71e4b7c4b4be9953657877f7f9e6f7ee89114c716da7c070f4a238220e95d7e"
    },
    "aarch64-windows": {
      "tarball": "https://ziglang.org/download/0.14.0/zig-windows-aarch64-0.14.0.zip",
      "shasum": "03e984383ebb8f85293557cfa9f48ee8698e7c400239570c9ff1aef3bffaf046"
    },
    "x86-linux": {
      "tarball": "https://ziglang.org/download/0.14.0/zig-linux-x86-0.14.0.tar.xz",
      "shasum": "55d1ba21de5109686ffa675b9cc1dd66930093c202995a637ce3e397816e4c08"
    },
    "x86-windows": {
      "tarball": "https://ziglang.org/download/0.14.0/zig-windows-x86-0.14.0.zip",
      "shasum": "1a867d808cf4fa9184358395d94441390b6b24ee8d00d356ca11ea7cbfd3a4ec"
    },
    "x86_64-linux": {
      "tarball": "https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz",
      "shasum": "473ec26806133cf4d1918caf1a410f8403a13d979726a9045b421b685031a982"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/download/0.14.0/zig-macos-x86_64-0.14.0.tar.xz",
      "shasum": "685816166f21f0b8d6fc7aa6a36e91396dcd82ca6556dfbe3e329deffc01fec3"
    },
    "x86_64-windows": {
      "tarball": "https://ziglang.org/download/0.14.0/zig-windows-x86_64-0.14.0.zip",
      "shasum": "f53e5f9011ba20bbc3e0e6d0a9441b31eb227a97bac0e7d24172f1b8b27b4371"
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
  },
  "0.12.1": {
    "aarch64-linux": {
      "tarball": "https://ziglang.org/download/0.12.1/zig-linux-aarch64-0.12.1.tar.xz",
      "shasum": "27d4fef393e8d8b5f3b1d19f4dd43bfdb469b4ed17bbc4c2283c1b1fe650ef7f"
    },
    "aarch64-macos": {
      "tarball": "https://ziglang.org/download/0.12.1/zig-macos-aarch64-0.12.1.tar.xz",
      "shasum": "6587860dbbc070e1ee069e1a3d18ced83b7ba7a80bf67b2c57caf7c9ce5208b1"
    },
    "aarch64-windows": {
      "tarball": "https://ziglang.org/download/0.12.1/zig-windows-aarch64-0.12.1.zip",
      "shasum": "e1286114a11be4695a6ad5cf0ba6a0e5f489bb3b029a5237de93598133f0c13a"
    },
    "x86-linux": {
      "tarball": "https://ziglang.org/download/0.12.1/zig-linux-x86-0.12.1.tar.xz",
      "shasum": "c36ac019ca0fc3167e50d17e2affd3d072a06c519761737d0639adfdf2dcfddd"
    },
    "x86-windows": {
      "tarball": "https://ziglang.org/download/0.12.1/zig-windows-x86-0.12.1.zip",
      "shasum": "4f0cc9258527e7b8bcf742772b3069122086a5cd857b38a1c08002462ac81f80"
    },
    "x86_64-linux": {
      "tarball": "https://ziglang.org/download/0.12.1/zig-linux-x86_64-0.12.1.tar.xz",
      "shasum": "8860fc9725c2d9297a63008f853e9b11e3c5a2441217f99c1e3104cc6fa4a443"
    },
    "x86_64-macos": {
      "tarball": "https://ziglang.org/download/0.12.1/zig-macos-x86_64-0.12.1.tar.xz",
      "shasum": "68f309c6e431d56eb42648d7fe86e8028a23464d401a467831e27c26f1a8d9c9"
    },
    "x86_64-windows": {
      "tarball": "https://ziglang.org/download/0.12.1/zig-windows-x86_64-0.12.1.zip",
      "shasum": "52459b147c2de4d7c28f6b1a4b3d571c114e96836bf8e31c953a7d2f5e94251c"
    }
  },
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
