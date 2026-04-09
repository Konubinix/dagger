#!/usr/bin/env bash
# [[file:TECHNICAL.org::*Run script (mode 2)][Run script (mode 2):1]]
set -eu
cd "$(dirname "$0")"
args=()
if [ "${1:-}" = "--no-cache" ]; then
    args+=(--no-cache)
    shift
fi
exec dagger call --progress=plain dev run "--args=$*" export --path=.
# Run script (mode 2):1 ends here
