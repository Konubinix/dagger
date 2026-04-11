#!/usr/bin/env bash
# [[file:tests/testing.org::*Docker-in-Docker test entry point][Docker-in-Docker test entry point:1]]
set -eu
cd "$(dirname "$0")"
exec dagger --progress plain call dind-run-tests stdout
# Docker-in-Docker test entry point:1 ends here
