#!/usr/bin/env nix-shell
#!nix-shell -i bash -p python3Packages.pytest
# [[file:tests/testing.org::*The test entry point][The test entry point:1]]
set -eu
cd "$(dirname "$0")"
pytest tests/test_use_cases.py "$@"
# The test entry point:1 ends here
