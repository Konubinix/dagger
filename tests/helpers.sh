#!/usr/bin/env bash
# [[file:testing.org::*Test sandbox setup][Test sandbox setup:1]]
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export PATH="${ROOT}/tests:$PATH"
# Test sandbox setup:1 ends here
