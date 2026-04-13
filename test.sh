#!/usr/bin/env bash
# [[file:tests/testing.org::*The test entry point][The test entry point:1]]
set -eu
cd "$(dirname "$0")"
exec dagger ${DAGGER_EXTRA_ARGS:-} call dind-run-tests stdout
# The test entry point:1 ends here
