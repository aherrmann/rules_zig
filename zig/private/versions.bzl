"""Mirror of release info

TODO[AH]: generate this file from https://ziglang.org/download/index.json"""

# The integrity hashes can be computed with
# shasum -b -a 384 [downloaded file] | awk '{ print $1 }' | xxd -r -p | base64
TOOL_VERSIONS = {
    "0.10.1": {
        "x86_64-linux": "sha256-Zpnw5ykwgbQkKPMsnZyYOFQJS9Ff7lSJ8SxM9FGMw4A=",
    },
}
