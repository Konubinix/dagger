#!/usr/bin/env bash
# [[file:TECHNICAL.org::*init-examples.sh][init-examples.sh:1]]
set -eu
cd "$(dirname "$0")"
exec dagger ${DAGGER_EXTRA_ARGS:-} call dind-init-examples -o .
# init-examples.sh:1 ends here
