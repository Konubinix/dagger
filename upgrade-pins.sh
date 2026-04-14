#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"
exec dagger ${DAGGER_EXTRA_ARGS:-} call upgrade-pins export --path=image-pins.json
