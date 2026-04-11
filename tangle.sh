#!/usr/bin/env bash
# [[file:TECHNICAL.org::*tangle.sh][tangle.sh:1]]
set -eu
cd "$(dirname "$0")"
exec dagger ${DAGGER_EXTRA_ARGS:-} call dind-tangle -o .
# tangle.sh:1 ends here
