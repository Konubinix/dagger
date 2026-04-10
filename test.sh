#!/usr/bin/env bash
# [[file:tests/testing.org::*The test entry point][The test entry point:1]]
set -eu
cd "$(dirname "$0")"
exec pytest tests/test_sdk.py -v
# The test entry point:1 ends here
