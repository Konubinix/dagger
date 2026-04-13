#!/usr/bin/env bash
# [[file:tests/testing.org::*The host test entry point][The host test entry point:1]]
set -eu
cd "$(dirname "$0")"
for arg in "$@"; do
    if [ "$arg" = "-v" ]; then
        export DAGGER_VERBOSE=1
    fi
done
exec pytest tests/test_sdk.py "$@"
# The host test entry point:1 ends here
