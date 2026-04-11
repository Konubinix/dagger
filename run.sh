#!/usr/bin/env bash
# [[file:TECHNICAL.org::*run.sh][run.sh:1]]
set -eu
cd "$(dirname "$0")"
args=""
if [ "${1:-}" = "--no-cache" ]; then
    args="--no-cache"
    shift
fi
for f in "$@"; do
    args="$args --files=$f"
done
exec dagger ${DAGGER_EXTRA_ARGS:-} call dind-run-org $args -o .
# run.sh:1 ends here
