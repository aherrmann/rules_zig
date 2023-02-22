"""Mirror of release info

TODO[AH]: generate this file from https://ziglang.org/download/index.json"""

# The integrity hashes can be computed with
# shasum -b -a 384 [downloaded file] | awk '{ print $1 }' | xxd -r -p | base64
# Or using the sha256 hashes from ziglang.org converted with Python:
# "sha256-" + base64.b64encode(bytes.fromhex("SHA256")).decode()
TOOL_VERSIONS = {
    "0.10.1": {
        "linux-x86_64": "sha256-Zpnw5ykwgbQkKPMsnZyYOFQJS9Ff7lSJ8SxM9FGMw4A=",
        "macos-x86_64": "sha256-Akg1ULidKjBwwu0AM1f9bmowWXB7juP7wMZ/g8qJhDc=",
    },
}
